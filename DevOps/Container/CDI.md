CDI(Container Device Interface)는 컨테이너 런타임이 GPU, FPGA 등 서드파티 디바이스를 표준화된 방식으로 지원할 수 있도록 하는 CNCF 명세이다. CNI(Container Networking Interface)의 디바이스 버전이라고 이해할 수 있다.

기존에 NVIDIA GPU를 컨테이너에서 사용하려면 NVIDIA Container Runtime이라는 전용 런타임이 필요했다. 이 런타임은 `NVIDIA_VISIBLE_DEVICES` 환경변수를 감지하여 GPU 디바이스와 드라이버 라이브러리를 컨테이너에 주입하는 방식으로 동작했다.

```bash
# 기존 방식: 환경변수 기반
docker run --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=0,1 nvidia/cuda:12.0-base nvidia-smi
```

이 방식의 문제점:

- 벤더별 전용 런타임이 필요하다
- 표준화되지 않아 다른 디바이스(AMD GPU, Intel GPU, FPGA 등)마다 다른 메커니즘이 필요하다
- rootless 컨테이너와의 호환성이 제한적이다
- 컨테이너 런타임(containerd, CRI-O)이 디바이스 마운트 과정을 인지하지 못한다

CDI는 이러한 문제를 해결하기 위해 디바이스 접근을 표준화한다.

## CDI 핵심 개념

**디바이스 명명 규칙**

CDI 디바이스는 정규화된 이름(Fully Qualified Name)으로 식별된다.

```
<vendor>/<class>=<name>
```

```
nvidia.com/gpu=0           # 첫 번째 NVIDIA GPU
nvidia.com/gpu=1           # 두 번째 NVIDIA GPU
nvidia.com/gpu=all         # 모든 NVIDIA GPU
amd.com/gpu=0              # AMD GPU
intel.com/qat=dev0         # Intel QAT 디바이스
```

**CDI Spec 파일**

CDI 명세는 JSON 또는 YAML 형식으로 `/etc/cdi/` 또는 `/var/run/cdi/`에 저장된다.

```yaml
# /var/run/cdi/nvidia.yaml
cdiVersion: "0.6.0"
kind: "nvidia.com/gpu"
devices:
  - name: "0"
    containerEdits:
      deviceNodes:
        - path: /dev/nvidia0
          type: c
          major: 195
          minor: 0
      mounts:
        - hostPath: /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.550.54.14
          containerPath: /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.550.54.14
          options: ["ro", "nosuid", "nodev", "bind"]
        - hostPath: /usr/lib/x86_64-linux-gnu/libcuda.so.550.54.14
          containerPath: /usr/lib/x86_64-linux-gnu/libcuda.so.550.54.14
          options: ["ro", "nosuid", "nodev", "bind"]
      hooks:
        - hookName: createContainer
          path: /usr/bin/nvidia-ctk
          args:
            [
              "nvidia-ctk",
              "hook",
              "create-symlinks",
              "--link",
              "libcuda.so.1::/usr/lib/x86_64-linux-gnu/libcuda.so",
            ]
containerEdits:
  deviceNodes:
    - path: /dev/nvidiactl
    - path: /dev/nvidia-uvm
    - path: /dev/nvidia-uvm-tools
```

**CDI Spec 구성 요소**

- **deviceNodes**: 컨테이너에 노출할 디바이스 노드 (`/dev/nvidia0` 등)
- **mounts**: bind 마운트할 드라이버 라이브러리 경로
- **hooks**: 컨테이너 라이프사이클 훅 (심볼릭 링크 생성, ldcache 업데이트 등)
- **env**: 설정할 환경변수

**동작 흐름**

```
1. 드라이버 설치 시 nvidia-ctk가 CDI spec 생성
   $ nvidia-ctk cdi generate --output=/var/run/cdi/nvidia.yaml

2. 사용자가 컨테이너 실행 요청
   $ docker run --device nvidia.com/gpu=0 myimage

3. 컨테이너 런타임이 /var/run/cdi/nvidia.yaml 읽음

4. OCI spec에 deviceNodes, mounts, hooks 적용

5. 컨테이너 시작 시 hooks 실행 (심볼릭 링크, ldcache 업데이트)

6. 컨테이너 내에서 GPU 사용 가능
```

## Kubernetes에서의 CDI 지원

Kubernetes는 Device Plugin을 통해 GPU 등 하드웨어 리소스를 관리한다. CDI 지원은 점진적으로 추가되었다.

- Kubernetes 1.28: `DevicePluginCDIDevices` feature gate (alpha)
- Kubernetes 1.29: 기본 활성화 (beta)
- Kubernetes 1.31: GA (정식 지원)

**Device List Strategy**

NVIDIA k8s-device-plugin은 GPU 디바이스 목록을 컨테이너에 전달하는 여러 전략을 지원한다.

- **envvar (기존 기본값)**: `NVIDIA_VISIBLE_DEVICES` 환경변수를 설정하고 NVIDIA Container Runtime이 이를 해석한다.

```yaml
env:
  - name: NVIDIA_VISIBLE_DEVICES
    value: "0,1"
```

- **volume-mounts**: 볼륨 마운트 형태로 디바이스 정보를 전달한다. 마찬가지로 NVIDIA Container Runtime이 필요하다.

- **cdi-annotations**: Pod 어노테이션을 통해 CDI 디바이스를 지정한다. NVIDIA Container Runtime 없이 동작한다.

```yaml
annotations:
  cdi.k8s.io/nvidia-gpu: "nvidia.com/gpu=0,nvidia.com/gpu=1"
```

- **cdi-cri (최신 표준)**: kubelet이 CRI의 `CDIDevices` 필드를 통해 containerd/CRI-O에 직접 전달한다. 가장 표준화된 방식이다.

```go
// CRI ContainerConfig
CDIDevices: []*CDIDevice{
    {Name: "nvidia.com/gpu=0"},
    {Name: "nvidia.com/gpu=1"},
}
```

**전략별 비교**

- **envvar**: NVIDIA Runtime 필요, 모든 K8s 버전 지원, NVIDIA 전용, rootless 지원 제한적
- **cdi-annotations**: NVIDIA Runtime 불필요, K8s 1.28+, CDI 표준, rootless 지원
- **cdi-cri**: NVIDIA Runtime 불필요, K8s 1.31+, CDI + CRI 표준, rootless 지원

## Bottlerocket의 CDI-CRI 전환

Bottlerocket은 AWS에서 개발한 컨테이너 전용 Linux 배포판이다.

**주요 변경사항**

- **v1.47.0**: nvidia 변형에서 device-list-strategy 기본값이 `cdi-cri`로 변경
- **v1.53.0**: 모든 nvidia 변형이 R580 드라이버로 마이그레이션

**변경 이유**

- 업계 표준(CNCF CDI)으로의 전환
- NVIDIA Container Runtime 의존성 제거
- Kubernetes 1.31의 CDI-CRI GA 지원에 맞춤
- rootless 컨테이너 호환성 향상

**설정 방법**

Bottlerocket에서 device-list-strategy를 변경하려면:

```toml
# /etc/bottlerocket/config.toml
[settings.kubernetes.kubelet-device-plugins.nvidia-device-plugin]
device-list-strategy = "cdi-cri" # 또는 "envvar", "volume-mounts"
```

듀얼 모드로 호환성을 확보할 수도 있다.

```toml
device-list-strategy = ["cdi-cri", "volume-mounts"]
```

## 라이브러리 마운트와 0바이트 문제

CDI 방식에서 드라이버 라이브러리는 호스트에서 컨테이너로 bind 마운트된다. 이 과정에서 발생할 수 있는 문제가 있다.

**문제 현상**

```bash
$ ldconfig
/sbin/ldconfig.real: File /usr/lib/aarch64-linux-gnu/libnvidia-ml.so is empty, not checked
```

컨테이너 내의 NVIDIA 라이브러리 파일이 0바이트로 나타난다.

**원인 분석**

- **libnvidia-container의 설계 한계**: libnvidia-container는 컨테이너 런타임(Docker/containerd)의 인지 없이 라이브러리를 bind 마운트한다. 런타임은 이 파일들이 마운트된 것인지 알지 못하므로, 컨테이너 종료 시 적절히 정리하지 못한다.

- **드라이버 업그레이드 시나리오**:

```
1. 컨테이너 빌드 시점: 호스트에 R535 드라이버
   - libnvidia-ml.so.535.xx가 bind 마운트됨

2. 이미지 저장: docker save로 이미지 저장
   - bind 마운트 파일이 빈 파일로 저장됨

3. 드라이버 업그레이드: 호스트가 R580으로 업그레이드

4. 이미지 로드: docker load로 다른 시스템에서 로드
   - 빈 파일이 그대로 복원됨
```

- **CDI spec 불일치**: CDI spec이 생성될 때의 드라이버 버전과 컨테이너 실행 시점의 드라이버 버전이 다를 경우:

```yaml
# 오래된 CDI spec
mounts:
  - hostPath: /usr/lib/aarch64-linux-gnu/libnvidia-ml.so.535.104.05
    containerPath: /usr/lib/aarch64-linux-gnu/libnvidia-ml.so.535.104.05
# 실제 호스트에는 libnvidia-ml.so.580.xx가 있음
# -> 마운트 실패 또는 빈 파일
```

**해결 방법**

- **CDI spec 재생성**: 드라이버 업데이트 후 반드시 CDI spec을 재생성한다.

```bash
sudo nvidia-ctk cdi generate --output=/var/run/cdi/nvidia.yaml
```

- **컨테이너 이미지 빌드 시 주의**: nvidia-container-runtime 대신 표준 런타임으로 빌드한다.

```bash
# 나쁜 예: nvidia 런타임으로 빌드
docker build --runtime=nvidia -t myimage .

# 좋은 예: 표준 런타임으로 빌드
docker build -t myimage .
```

- **기존 이미지 정리**:

```dockerfile
# 빈 라이브러리 파일 제거
RUN find /usr/lib -name "libnvidia*.so*" -size 0 -delete && \
    find /usr/lib -name "libcuda*.so*" -size 0 -delete && \
    ldconfig
```

- **버전 일치 확인**:

```bash
# 호스트 드라이버 버전
nvidia-smi --query-gpu=driver_version --format=csv,noheader

# CDI spec의 라이브러리 경로 확인
cat /var/run/cdi/nvidia.yaml | grep hostPath

# 실제 라이브러리 존재 확인
ls -la /usr/lib/x86_64-linux-gnu/libnvidia-ml.so*
```

## CDI 디버깅

**CDI spec 검증**

```bash
# spec 파일 목록
ls -la /etc/cdi/ /var/run/cdi/

# spec 내용 확인
nvidia-ctk cdi list

# 특정 디바이스 정보
nvidia-ctk cdi list --device nvidia.com/gpu=0
```

**컨테이너 런타임 로그**

containerd에서 CDI 관련 로그 확인:

```bash
journalctl -u containerd | grep -i cdi
```

**수동 테스트**

```bash
# CDI 디바이스로 컨테이너 실행
docker run --rm --device nvidia.com/gpu=all nvidia/cuda:12.0-base nvidia-smi

# 또는 ctr 사용
sudo ctr run --rm --device nvidia.com/gpu=0 docker.io/nvidia/cuda:12.0-base test nvidia-smi
```

**라이브러리 마운트 확인**

```bash
# 컨테이너 내에서 라이브러리 확인
docker run --rm --device nvidia.com/gpu=all nvidia/cuda:12.0-base \
	ls -la /usr/lib/x86_64-linux-gnu/libnvidia* /usr/lib/x86_64-linux-gnu/libcuda*

# ldconfig 캐시 확인
docker run --rm --device nvidia.com/gpu=all nvidia/cuda:12.0-base \
	ldconfig -p | grep nvidia
```

## 지원 런타임 버전

- **containerd**: 1.7.0+ (`enable_cdi = true` 설정 필요)
- **CRI-O**: 1.23.0+ (기본 활성화)
- **Docker**: 25.0.0+ (28.2.0부터 기본 활성화)
- **Podman**: 4.1.0+ (기본 활성화)

containerd 설정 예시:

```toml
# /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri"]
enable_cdi = true
cdi_spec_dirs = ["/etc/cdi", "/var/run/cdi"]
```

---
참고

- <https://github.com/cncf-tags/container-device-interface>
- <https://github.com/cncf-tags/container-device-interface/blob/main/SPEC.md>
- <https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html>
- <https://github.com/NVIDIA/k8s-device-plugin>
- <https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/>
- <https://bottlerocket.dev/en/os/latest/api/settings/kubelet-device-plugins/>

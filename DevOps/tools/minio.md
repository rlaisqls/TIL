
![image](https://github.com/rlaisqls/TIL/assets/81006587/e22783af-abce-40a5-9b35-2d40adc17425)

MinIO는 GNU Affero General Public License v3.0 하에 배포되는 **고성능 객체 스토리지**이다. Amazon S3 클라우드 스토리지 서비스와 API가 호환되며, 머신러닝, 분석, 애플리케이션 데이터 워크로드를 위한 고성능 인프라 구축에 사용된다.

## 아키텍처

각 MinIO Tenant는 Kubernetes 클러스터 내 독립적인 객체 스토어이다. 아래 다이어그램은 Kubernetes에 배포된 MinIO Tenant의 아키텍처다:

![image](https://github.com/rlaisqls/TIL/assets/81006587/0a8a17d5-d6e3-4481-bb0f-7bf0e025dc35)

MinIO는 Tenant 접근 및 관리를 위한 다양한 방법을 제공한다.

## MinIO Console

MinIO Console은 MinIO Tenant와 상호작용하기 위한 그래픽 사용자 인터페이스(GUI)다. MinIO Operator는 기본적으로 각 Tenant에 Console을 설치하고 구성한다.

![image](https://github.com/rlaisqls/TIL/assets/81006587/48b6fbf5-4550-4189-b708-4d744108dc82)

관리자는 Console을 통해 사용자 생성, 정책 구성, 버킷 복제 등 다양한 작업을 수행할 수 있다. 또한 Tenant의 상태, 사용량, 복구 상태를 한눈에 확인할 수 있다.

## MinIO Operator 배포 및 Tenant 생성

Kubernetes 클러스터에서 객체 스토리지 운영을 위해 MinIO Operator를 설치하고 4-노드 MinIO Tenant를 생성하는 과정이다.

### 사전 요구사항

#### MinIO Tenant Namespace

MinIO는 Namespace당 *하나*의 Tenant만 지원한다. 다음 명령으로 MinIO Tenant용 Namespace를 생성한다.

```sh
kubectl create namespace minio-tenant-1
```

MinIO Operator Console은 Tenant 생성 과정에서 Namespace 생성을 지원한다.

### Tenant Storage Class

MinIO Kubernetes Operator는 Tenant 배포 시 Persistent Volume Claim(`PVC`)을 자동 생성한다.

기본적으로 각 `PVC`는 `default` Kubernetes [`Storage Class`](https://kubernetes.io/docs/concepts/storage/storage-classes/)로 생성된다. `default` Storage Class가 생성된 `PVC`를 지원하지 못하면 Tenant 배포가 실패할 수 있다.

MinIO Tenant는 `StorageClass`의 `volumeBindingMode`가 `WaitForFirstConsumer`로 설정되어야 한다. 기본 `StorageClass`는 `Immediate` 설정을 사용할 수 있는데, 이는 `PVC` 바인딩 시 문제를 일으킬 수 있다. MinIO Tenant용으로 사용자 정의 `StorageClass` 생성을 강력히 권장한다.

다음 `StorageClass` 객체는 [MinIO DirectPV 관리 드라이브](https://github.com/minio/directpv)를 사용한 MinIO Tenant 지원에 필요한 필드를 포함한다:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: directpv-min-io
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

### Tenant Persistent Volumes

MinIO Operator는 Tenant의 각 볼륨마다 하나의 Persistent Volume Claim(PVC)을 생성하고, Tenant 메트릭 및 로그 수집용으로 추가 2개의 PVC를 생성한다. Tenant가 정상적으로 시작하려면 클러스터에 각 PVC의 용량 요구사항을 충족하는 충분한 [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)가 있어야 한다. 예를 들어 16개 볼륨을 가진 Tenant는 총 18개(16 + 2)의 PV가 필요하다. 각 PVC가 1TB를 요청한다면 각 PV는 최소 1TB 용량을 제공해야 한다.

로컬 드라이브에서 Persistent Volume을 자동 프로비저닝하기 위해 [MinIO DirectPV Driver](https://github.com/minio/directpv) 사용을 권장한다. 아래 절차는 MinIO DirectPV가 설치 및 구성되어 있다고 가정한다.

MinIO DirectPV를 배포할 수 없는 클러스터는 [Local Persistent Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#local)를 사용한다.

다음은 `local` PV의 예시다:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: <PV-NAME>
spec:
  capacity:
    storage: 1Ti
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: </mnt/disks/ssd1>
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - <NODE-NAME>
```

괄호 안의 값 `<VALUE>`를 로컬 드라이브에 맞게 변경한다.

필요한 PVC 수는 `minio` 서버 Pod 수 × 노드당 드라이브 수로 계산한다. 예를 들어 노드당 4개 드라이브를 가진 4-노드 Tenant는 16개의 PVC와 PV가 필요하다.

최상의 객체 스토리지 성능을 위해 다음 CSI 드라이버 사용을 강력히 권장한다:

- [MinIO DirectPV](https://github.com/minio/directpv)
- [Local Persistent Volume](https://kubernetes.io/docs/concepts/storage/volumes/#local)

### 절차

#### 1) MinIO Operator 설치

Kubernetes `krew` 플러그인 매니저로 MinIO Operator 및 플러그인을 설치한다:

```sh
kubectl krew update
kubectl krew install minio
```

`krew` 설치는 [설치 문서](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)를 참고한다.

플러그인 설치 확인:

```sh
kubectl minio version
```

`krew` 대신 [Operator Releases Page](https://github.com/minio/operator/releases)에서 직접 `kubectl-minio` 플러그인을 다운로드할 수도 있다. 운영 체제에 맞는 패키지를 다운로드하고 압축을 해제한 뒤, 바이너리를 실행 가능하도록 설정(`chmod +x`)하고 시스템 `PATH`에 추가한다.

아래는 Linux 환경에서 최신 안정 버전을 다운로드하고 설치하는 예시다:

```sh
wget -qO- https://github.com/minio/operator/releases/latest/download/kubectl-minio_linux_amd64_v1.zip | sudo bsdtar -xvf- -C /usr/local/bin
sudo chmod +x /usr/local/bin/kubectl-minio
```

플러그인 설치 확인:

```sh
kubectl minio version
```

Operator 초기화:

```sh
kubectl minio init
```

Operator 상태 확인:

```sh
kubectl get pods -n minio-operator
```

출력 예시:

```sh
NAME                              READY   STATUS    RESTARTS   AGE
console-6b6cf8946c-9cj25          1/1     Running   0          99s
minio-operator-69fd675557-lsrqg   1/1     Running   0          99s
```

`console-*` Pod는 MinIO Tenant를 생성하고 관리하는 GUI인 MinIO Operator Console을 실행한다.

`minio-operator-*` Pod는 MinIO Operator 본체를 실행한다.

#### 2) Operator Console 접근

MinIO Operator Console 로컬 프록시 생성:

```sh
kubectl minio proxy -n minio-operator
```

출력 예시:

```sh
kubectl minio proxy
Starting port forward of the Console UI.

To connect open a browser and go to http://localhost:9090

Current JWT to login: TOKENSTRING
```

제공된 주소로 브라우저를 열고 JWT 토큰으로 Operator Console에 로그인한다.

**+ Create Tenant**를 클릭하여 Tenant 생성 절차를 시작한다.

#### 3) Tenant 구성

Operator Console의 **Create New Tenant** 가이드를 통해 MinIO Tenant를 구성한다. 기본 구성 항목은 다음과 같다.

- **Name** - 새 Tenant의 *Name*, *Namespace*, *Storage Class*를 지정한다.

  *Storage Class*는 MinIO Tenant를 지원하는 [Local Persistent Volumes](#local-persistent-volumes)에 해당하는 [Storage Class](#default-storage-class)여야 한다.

  *Namespace*는 다른 MinIO Tenant를 포함하지 않는 기존 [Namespace](#minio-tenant-namespace)여야 한다.

  *Advanced Mode*를 활성화하면 고급 구성 옵션에 접근할 수 있다.

- **Tenant Size** - Tenant의 *Number of Servers*, *Number of Drives per Server*, *Total Size*를 지정한다.

  *Resource Allocation* 섹션에 입력값 기반 Tenant 구성 요약이 표시된다.

  *Advanced Mode*가 활성화되어 있으면 추가 구성 항목이 표시될 수 있다.

- **Preview Configuration** - 새 Tenant의 세부 설정을 요약한다.

요구사항에 맞게 구성 후 **Create**를 클릭하여 Tenant를 생성한다.

Operator Console에 MinIO Tenant 연결용 자격 증명이 표시된다. 반드시 이 단계에서 자격 증명을 다운로드하고 안전하게 보관해야 한다. 나중에 자격 증명을 쉽게 조회할 수 없다.

Operator Console에서 Tenant 생성 진행 상황을 모니터링할 수 있다.

#### 4) Tenant 연결

MinIO Operator가 생성한 서비스 목록 조회:

```sh
kubectl get svc -n NAMESPACE
```

`NAMESPACE`를 MinIO Tenant의 Namespace로 변경한다. 출력 예시:

```sh
NAME                             TYPE            CLUSTER-IP        EXTERNAL-IP   PORT(S)
minio                            LoadBalancer    10.104.10.9       <pending>     443:31834/TCP
myminio-console           LoadBalancer    10.104.216.5      <pending>     9443:31425/TCP
myminio-hl                ClusterIP       None              <none>        9000/TCP
myminio-log-hl-svc        ClusterIP       None              <none>        5432/TCP
myminio-log-search-api    ClusterIP       10.102.151.239    <none>        8080/TCP
myminio-prometheus-hl-svc ClusterIP       None              <none>        9090/TCP
```

Kubernetes 클러스터 내부 애플리케이션은 `minio` 서비스를 통해 Tenant의 객체 스토리지 작업을 수행한다.

관리자는 `minio-tenant-1-console` 서비스를 통해 MinIO Console에 접근하여 사용자, 그룹, 정책 등을 관리한다.

MinIO Tenant는 기본적으로 TLS가 활성화된다. MinIO Operator는 Kubernetes `certificates.k8s.io` API로 필요한 x.509 인증서를 생성한다. 각 인증서는 클러스터 배포 시 구성된 Kubernetes Certificate Authority(CA)로 서명된다. Kubernetes는 클러스터의 Pod에 CA를 마운트하지만, Pod는 기본적으로 해당 CA를 신뢰하지 않는다. MinIO TLS 인증서 검증을 활성화하려면 `update-ca-certificates` 유틸리티가 CA를 찾아 시스템 신뢰 저장소에 추가할 수 있도록 CA를 디렉터리에 복사해야 한다:

```sh
cp /var/run/secrets/kubernetes.io/serviceaccount/ca.crt /usr/local/share/ca-certificates/
update-ca-certificates
```

Kubernetes 클러스터 외부 애플리케이션은 MinIO Tenant 서비스를 노출하기 위해 [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) 또는 [Load Balancer](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)를 구성해야 한다. 또는 `kubectl port-forward` 명령으로 로컬 호스트에서 MinIO Tenant로 트래픽을 임시로 전달할 수 있다.

## 일관성 보장 (Consistency Guarantees)

MinIO는 distributed 및 standalone 모드 모두에서 모든 I/O 작업에 대해 엄격한 read-after-write 및 list-after-write 일관성 모델을 따른다. 이러한 일관성 보장은 distributed 설정에서 xfs, zfs, btrfs 등의 디스크 파일시스템을 사용할 때만 보장된다.

테스트 결과 ext4는 POSIX O_DIRECT/Fdatasync 시맨틱을 준수하지 않는 것으로 확인되었다. ext4는 일관성 보장보다 성능을 우선시한다. 따라서 설정에서 ext4 사용을 피해야 한다.

MinIO distributed 설정이 NFS 볼륨을 사용하는 경우 MinIO가 이러한 일관성을 보장하지 못한다. NFS는 엄격한 일관성을 제공하지 않기 때문이다. 반드시 NFS를 사용해야 한다면 NFSv3 대신 NFSv4를 사용하여 상대적으로 나은 결과를 얻을 것을 권장한다.

---
reference
- https://github.com/minio/operator/blob/master/README.md

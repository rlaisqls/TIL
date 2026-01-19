
Pod Readiness는 Pod가 트래픽을 처리할 준비가 되었는지를 나타내는 추가적인 지표이다. Pod Readiness는 외부에서 해당 Pod의 주소가 `Endpoints` 객체에 표시될지 여부를 결정한다. Deployment와 같이 Pod를 관리하는 Kubernetes 리소스들은 롤링 업데이트를 진행할 때 Pod Readiness를 고려하여 의사결정을 한다.

롤링 배포 중에 새 Pod가 Ready 상태가 되었지만 Service, NetworkPolicy, 또는 로드 밸런서가 아직 새 Pod를 받아들일 준비가 되지 않은 경우가 있다. 이로 인해 서비스 중단이나 백엔드 용량 손실이 발생할 수 있다. Pod spec에 아무 Probe도 정의되어 있지 않으면 Kubernetes는 세 가지 Probe 모두 성공으로 간주한다.

사용자는 Pod spec에 Readiness 검사를 지정할 수 있다. 그러면 Kubelet이 지정된 검사를 실행하고 성공 또는 실패에 따라 Pod 상태를 업데이트한다.

## Pod Phase

Probe는 Pod의 `.Status.Phase` 필드에 영향을 미친다. 다음은 Pod Phase 목록과 각각에 대한 설명이다:

- **Pending**: 클러스터에서 Pod가 수락되었지만, 하나 이상의 컨테이너가 아직 설정되지 않았거나 실행 준비가 되지 않은 상태이다. Pod가 스케줄링되기를 기다리는 시간과 네트워크를 통해 컨테이너 이미지를 다운로드하는 시간이 포함된다.

- **Running**: Pod가 노드에 스케줄링되었고 모든 컨테이너가 생성되었다. 적어도 하나의 컨테이너가 실행 중이거나 시작 또는 재시작 과정에 있다. 일부 컨테이너는 CrashLoopBackoff와 같은 실패 상태일 수 있다.

- **Succeeded**: Pod의 모든 컨테이너가 성공적으로 종료되었으며 재시작되지 않는다.

- **Failed**: Pod의 모든 컨테이너가 종료되었고, 적어도 하나의 컨테이너가 실패로 종료되었다. 즉, 컨테이너가 0이 아닌 상태 코드로 종료되었거나 시스템에 의해 종료되었다.

- **Unknown**: 어떤 이유로 Pod의 상태를 확인할 수 없다. 이 Phase는 일반적으로 Pod가 실행 중인 Kubelet과의 통신 오류로 인해 발생한다.

## Probe 종류

Kubelet은 Pod의 개별 컨테이너에 대해 여러 유형의 헬스 체크를 수행한다: `livenessProbe`, `readinessProbe`, `startupProbe`. Kubelet(그리고 확장하면 노드 자체)은 HTTP 헬스 체크를 수행하기 위해 해당 노드에서 실행 중인 모든 컨테이너에 연결할 수 있어야 한다.

- **Liveness Probe**
  - Liveness Probe는 **컨테이너에서 실행 중인 애플리케이션이 정상 상태인지**를 판단한다. Liveness Probe가 비정상 상태를 감지하면 Kubernetes는 컨테이너를 죽이고 재배포를 시도한다.
  - Pod 설정의 `spec.containers.livenessProbe` 속성에서 구성한다.

- **Startup Probe**
  - Startup Probe는 **컨테이너 내 애플리케이션이 시작되었는지**를 확인한다. Startup Probe는 다른 모든 Probe보다 먼저 실행되며, 성공적으로 완료되기 전까지 다른 Probe를 비활성화한다. 컨테이너가 Startup Probe에 실패하면 컨테이너는 죽고 Pod의 `restartPolicy`를 따른다.
  - 이 Probe는 주기적으로 실행되는 Readiness Probe와 달리 시작 시에만 실행된다.
  - Pod 설정의 `spec.containers.startupProbe` 속성에서 구성한다.
  - **Startup Probe가 필요한 이유**: Liveness Probe가 처음부터 실행되면 애플리케이션이 아직 초기화 중일 때 계속 재시작되는 문제가 생길 수 있다. Startup Probe 또는 `initialDelaySeconds`로 이 문제를 해결할 수 있다.

- **Readiness Probe**
  - Readiness Probe는 **컨테이너가 요청을 처리할 준비가 되었는지**를 판단한다. Readiness Probe가 실패 상태를 반환하면 Kubernetes는 모든 Service의 엔드포인트에서 해당 컨테이너의 IP 주소를 제거한다.
  - 개발자는 Readiness Probe를 사용하여 실행 중인 컨테이너가 트래픽을 받지 않아야 함을 Kubernetes에 알린다. 네트워크 연결 설정, 파일 로딩, 캐시 워밍과 같이 시간이 많이 걸리는 초기 작업을 수행할 때 유용하다.

### Probe 방식: httpGet vs exec

Probe는 컨테이너 내에서 바이너리 실행을 시도하는 exec Probe, TCP Probe, 또는 HTTP Probe가 될 수 있다.

`httpGet`과 `exec`로 curl을 실행하는 것은 요청의 출발점이 다르다:

- **httpGet**: Kubelet에서 요청을 보낸다. 즉, Pod 외부에서 요청이 발생한다.
- **exec curl**: 컨테이너 내부에서 curl 명령을 직접 실행한다. Pod 내부에서 요청이 발생한다.

이 차이는 네트워크 정책이나 방화벽 설정에 따라 Probe 결과가 달라질 수 있음을 의미한다.

### Probe 결과

각 Probe는 세 가지 결과 중 하나를 가진다:

- **Success**: 컨테이너가 진단을 통과했다.
- **Failure**: 컨테이너가 진단에 실패했다.
- **Unknown**: 진단 자체가 실패했으므로 아무 조치도 취하지 않는다.

Probe가 `failureThreshold` 횟수 이상 실패하면 Kubernetes는 검사가 실패한 것으로 간주한다. 이에 따른 효과는 Probe 유형에 따라 다르다.

## Probe 실패 시 동작

**Liveness Probe 실패 시**:

Kubelet이 컨테이너를 종료한다. Liveness Probe는 잘못 사용하거나 잘못 구성하면 예기치 않은 장애를 쉽게 일으킬 수 있다.

Liveness Probe의 의도된 사용 사례는 Kubelet에게 컨테이너를 언제 재시작해야 하는지 알려주는 것이다. 하지만 "뭔가 잘못되면 재시작한다"는 전략은 위험하다.

예를 들어, 웹 앱의 메인 페이지를 로드하는 Liveness Probe를 만들었다고 가정하자. 컨테이너 코드 외부의 시스템 변경으로 인해 메인 페이지가 `404`나 `500` 오류를 반환하게 되었다면 어떻게 될까? 백엔드 데이터베이스 장애, 필수 서비스 장애, 버그를 노출하는 기능 플래그 변경 등이 이런 시나리오의 흔한 원인이다. 이 경우 Liveness Probe는 컨테이너를 재시작한다.

가장 좋은 경우에도 이는 도움이 되지 않는다. 컨테이너를 재시작해도 시스템의 다른 곳에 있는 문제가 해결되지 않으며 오히려 문제를 빠르게 악화시킬 수 있다. Kubernetes에는 실패한 컨테이너 재시작에 점점 더 긴 지연을 추가하는 컨테이너 재시작 백오프(`CrashLoopBackoff`)가 있다.

<u>Pod 수가 충분히 많거나 장애가 충분히 빠르면 애플리케이션은 홈페이지 오류에서 완전한 다운 상태로 전환될 수 있다</u>. 이것이 바로 [Cascading Failure](https://en.wikipedia.org/wiki/Cascading_failure)이다. 한 서비스의 장애가 연쇄적으로 다른 서비스까지 전파되는 현상이다.

애플리케이션에 따라 **Pod는 재시작 시 캐시된 데이터를 잃을 수도 있다**. 성능 저하 상황에서 데이터를 다시 가져오는 것이 어렵거나 불가능할 수 있다. 이 때문에 Liveness Probe는 주의해서 사용해야 한다. Pod가 Liveness Probe를 사용할 때는 테스트하는 컨테이너에만 의존하고 다른 의존성이 없어야 한다. 많은 엔지니어들은 "PHP가 실행 중이고 내 API를 제공하고 있다"와 같은 최소한의 기준 검증을 제공하는 특정 헬스 체크 엔드포인트를 사용한다.

**ECS/ALB와의 비교**: ECS와 ALB 환경에서의 Health Check는 Kubernetes의 Probe와 다르게 동작한다. ECS는 Health check 실패 시 컨테이너를 종료한다(Liveness Probe와 유사). ALB는 Health check 실패 시 타겟 그룹에서 제외하고 컨테이너를 종료한다. ALB의 Health Check는 Readiness Probe와 Liveness Probe를 겸하는 셈이다. Kubernetes에서는 이 둘을 분리할 수 있어서 더 세밀한 제어가 가능하다.

**Startup Probe와 Liveness Probe의 관계**:

Startup Probe는 Liveness Probe가 작동하기 전에 유예 기간을 제공할 수 있다. **Startup Probe가 성공하기 전에는 Liveness Probe가 컨테이너를 종료하지 않는다**. 컨테이너가 시작하는 데 몇 분이 걸리도록 허용하면서도 시작 후 비정상이 되면 빠르게 종료하는 경우에 사용할 수 있다.

**Readiness Probe 실패 시**:

Kubelet은 컨테이너를 종료하지 않는다. 대신 Kubelet은 Pod의 상태에 실패를 기록한다. Pod의 IP 주소가 endpoint 객체에 포함되지 않으며 Service가 해당 Pod로 트래픽을 라우팅하지 않는다.

이 상태는 Pod 자체에는 영향을 미치지 않지만 다른 Kubernetes 메커니즘이 이에 반응한다. 대표적인 예가 ReplicaSet(그리고 확장하면 Deployment)이다. Readiness Probe 실패는 ReplicaSet 컨트롤러가 해당 Pod를 준비되지 않은 것으로 카운트하게 하여, 너무 많은 새 Pod가 비정상일 때 배포가 중단될 수 있다. `Endpoints`/`EndpointSlice` 컨트롤러도 Readiness Probe 실패에 반응한다.

## Probe 설정 예제

아래 예제에서 서버는 포트 8080의 `/healthz` 경로에 HTTP GET을 수행하는 Liveness Probe를 가지고 있고, Readiness Probe는 동일한 포트의 `/`를 사용한다.

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: go-web
spec:
  containers:
  - name: go-web
    image: go-web:v0.0.1
    ports:
    - containerPort: 8080
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
    readinessProbe:
      httpGet:
        path: /
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

### Probe 설정 옵션

- **initialDelaySeconds**: 컨테이너가 시작된 후 Liveness 또는 Readiness Probe가 시작되기까지의 시간(초). 기본값 0, 최소값 0.
- **periodSeconds**: Probe가 수행되는 주기(초). 기본값 10, 최소값 1.
- **timeoutSeconds**: Probe가 타임아웃되는 시간(초). 기본값 1, 최소값 1.
- **successThreshold**: 실패 후 Probe가 성공으로 간주되기 위한 최소 연속 성공 횟수. 기본값 1, **Liveness와 Startup Probe는 반드시 1이어야 한다**. 실패하면 어차피 컨테이너가 재시작되고 새로 시도하기 때문에 연속 성공 횟수를 늘릴 필요가 없기 때문이다.
- **failureThreshold**: Probe가 실패할 때 Kubernetes가 포기하기 전에 시도하는 횟수. Liveness Probe의 경우 포기는 컨테이너 재시작을 의미한다. Readiness Probe의 경우 Pod가 Unready로 표시된다. 기본값 3, 최소값 1.

## Readiness Gate

애플리케이션 개발자는 Readiness Gate를 사용하여 Pod 내 애플리케이션이 준비되었는지 판단하는 데 도움을 줄 수 있다. Kubernetes 1.14부터 안정화되어 사용 가능하며, `readinessGates`를 사용하려면 매니페스트 작성자가 Pod spec에 Readiness Gate를 추가하여 Kubelet이 Pod Readiness를 평가할 추가 조건 목록을 지정해야 한다.

이는 Pod spec의 Readiness Gate에 있는 `conditionType` 속성에서 수행된다. `conditionType`은 일치하는 타입을 가진 Pod의 condition 목록에 있는 조건이다. Readiness Gate는 Pod의 `status.condition` 필드의 현재 상태로 제어되며, Kubelet이 Pod의 `status.conditions` 필드에서 해당 조건을 찾을 수 없으면 조건의 상태는 기본적으로 False가 된다.

다음 예제에서 feature-Y Readiness Gate는 true이고 feature-X는 false이므로 Pod의 상태는 최종적으로 false이다:

```yaml
kind: Pod
…
spec:
  readinessGates:
  - conditionType: www.example.com/feature-X
  - conditionType: www.example.com/feature-Y
…
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: 2021-04-25T00:00:00Z
    status: "False"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: 2021-04-25T00:00:00Z
    status: "False"
    type: www.example.com/feature-X
  - lastProbeTime: null
    lastTransitionTime: 2021-04-25T00:00:00Z
    status: "True"
    type: www.example.com/feature-Y
  containerStatuses:
  - containerID: docker://xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    ready : true
```

AWS ALB와 같은 로드 밸런서는 트래픽을 보내기 전에 Pod 라이프사이클의 일부로 Readiness Gate를 사용할 수 있다.

## Pod 종료와 Probe

### 삭제 중 Probe 동작

Pod가 삭제 중일 때는 Liveness Probe와 Startup Probe가 성공으로 고정된다. 이미 종료 중인 Pod를 다시 재시작할 필요가 없기 때문이다.

### preStop Hook

`preStop` Hook은 SIGTERM 시그널을 처리하지 못하는 애플리케이션에 필요하다. 컨테이너가 종료되기 전에 정리 작업을 수행할 수 있는 기회를 제공한다.

```yaml
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", "sleep 10"]
```

## QoS Class

Pod의 QoS (Quality of Service) 클래스는 Pod 내 모든 컨테이너의 리소스 설정 전체를 기준으로 결정된다. Init 컨테이너, Sidecar 컨테이너, 애플리케이션 컨테이너 모두가 동일한 QoS 클래스를 갖는다.

## Garbage Collection

Kubernetes의 Garbage Collection은 의존 객체(Dependent Object)를 삭제하는 세 가지 모드를 제공한다.

- **Background**: `deletionTimestamp`만 붙이고 즉시 반환한다. 실제 삭제는 비동기로 GC가 처리한다. Finalizer를 사용하지 않으며, 빠르게 응답하지만 의존 객체가 언제 삭제될지 보장되지 않는다.

- **Foreground**: 의존 객체가 모두 삭제된 후에 반환한다. `foregroundDeletion` finalizer가 추가되고, GC가 의존 객체들을 삭제한 후 finalizer가 제거되면 그때서야 원본 객체의 삭제가 완료된다.

- **Orphan**: 소유자(Owner) 객체만 삭제하고 의존 객체는 그대로 남겨둔다. 남겨진 객체들은 더 이상 소유자가 없는 상태(orphan)가 된다.

## Pod 이미지 업데이트

실행 중인 Pod의 컨테이너 이미지를 직접 업데이트할 수 있다.

```bash
kubectl set image pods/test test=ubuntu
```

이 명령은 `test`라는 Pod의 `test` 컨테이너 이미지를 `ubuntu`로 변경한다.

---

## 클러스터 구성요소 간 통신

Kubelet은 Kubernetes API 서버에 연결할 수 있어야 하며, Pod와 Kubelet 간의 통신은 CNI에 의해 가능해진다.

![image](https://github.com/rlaisqls/TIL/assets/81006587/fe158dbc-addc-438d-b922-2e6ad0854b4a)

위 그림에서 클러스터의 모든 구성 요소가 만드는 연결을 볼 수 있다:

- **CNI**: Pod와 서비스에 IP를 부여하는 네트워킹을 가능하게 하는 Kubelet의 네트워크 플러그인이다.
- **gRPC**: API 서버에서 etcd로 통신하기 위한 API이다.
- **Kubelet**: 모든 Kubernetes 노드에는 Kubelet이 있으며, 할당된 모든 Pod가 실행 중이고 원하는 상태로 구성되어 있는지 확인한다.
- **CRI**: Kubelet에 컴파일된 gRPC API로, Kubelet이 gRPC API를 사용하여 컨테이너 런타임과 통신할 수 있게 한다. 컨테이너 런타임 제공자는 Kubelet이 OCI 표준(runC)을 사용하여 컨테이너와 통신할 수 있도록 CRI API에 맞게 조정해야 한다.

---
참고
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/#liveness-probe
- https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/#resource-sharing-within-containers
- https://kubernetes.io/docs/concepts/architecture/garbage-collection/#foreground-deletion
- https://smartetx.com/kubernetes/the-kubernetes-termination-lifecycle/
- https://developers.redhat.com/blog/2020/11/10/you-probably-need-liveness-and-readiness-probes
- https://medium.com/devops-mojo/kubernetes-probes-liveness-readiness-startup-overview-introduction-to-probes-types-configure-health-checks-206ff7c24487

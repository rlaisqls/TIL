EndpointSlice는 Kubernetes 1.17에서 도입된 리소스로, Service의 네트워크 엔드포인트를 확장 가능한 방식으로 추적한다. 기존 Endpoints 리소스의 확장성 한계를 극복하기 위해 설계되었으며, 현재 Kubernetes에서 Service 엔드포인트를 관리하는 기본 메커니즘이다.

EndpointSlice가 왜 필요한지 이해하려면, 먼저 기존 Endpoints 리소스의 문제점을 알아야 한다.

Endpoints는 하나의 오브젝트에 Service의 모든 엔드포인트를 저장한다. 예를 들어, 1000개의 Pod를 가진 Service가 있다면:

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: large-service
subsets:
  - addresses:
      - ip: 10.0.0.1
      - ip: 10.0.0.2
      # ... 1000개의 IP 주소
      - ip: 10.0.3.232
    ports:
      - port: 8080
```

이 방식의 문제점은 이런 것들이 있다:

1. **etcd 크기 제한**: etcd는 단일 오브젝트의 최대 크기를 1.5MB로 제한한다. 엔드포인트가 많아지면 이 한계에 도달할 수 있다.

2. **전체 업데이트 비용**: Pod 하나가 추가되거나 삭제될 때마다 전체 Endpoints 오브젝트를 업데이트해야 한다. 1000개 중 1개만 변경되어도 1000개 전체를 다시 전송한다.

3. **Watch 부하**: kube-proxy와 같은 컴포넌트가 Endpoints를 watch할 때, 작은 변경에도 전체 데이터를 받아야 한다.

4. **API 서버 부하**: 대규모 클러스터에서 Endpoints 업데이트가 빈번하면 API 서버에 심각한 부하가 발생한다.

## EndpointSlice 구조

EndpointSlice는 엔드포인트를 여러 개의 "슬라이스"로 나눠서 저장한다. 기본적으로 하나의 EndpointSlice에는 최대 100개의 엔드포인트가 저장된다.

```yaml
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: my-service-abc12
  namespace: default
  labels:
    kubernetes.io/service-name: my-service
    endpointslice.kubernetes.io/managed-by: endpointslice-controller.k8s.io
  ownerReferences:
    - apiVersion: v1
      kind: Service
      name: my-service
      uid: 1234-5678-abcd
addressType: IPv4
ports:
  - name: http
    protocol: TCP
    port: 8080
  - name: https
    protocol: TCP
    port: 8443
endpoints:
  - addresses:
      - "10.0.1.5"
    conditions:
      ready: true
      serving: true
      terminating: false
    nodeName: node-1
    zone: us-east-1a
    hints:
      forZones:
        - name: us-east-1a
  - addresses:
      - "10.0.2.10"
    conditions:
      ready: true
      serving: true
      terminating: false
    nodeName: node-2
    zone: us-east-1b
```

### 주요 필드 설명

**addressType**

EndpointSlice가 담고 있는 주소의 유형을 지정한다:

- `IPv4`: IPv4 주소 (가장 일반적)
- `IPv6`: IPv6 주소
- `FQDN`: 완전한 도메인 이름 (외부 서비스 연결 시 사용)

하나의 Service에 대해 IPv4와 IPv6 EndpointSlice가 각각 생성될 수 있다. 이를 통해 듀얼 스택 네트워킹을 지원한다.

**ports**

이 EndpointSlice의 모든 엔드포인트에 공통으로 적용되는 포트 정보다. Endpoints와 달리 EndpointSlice는 포트 정보를 최상위 레벨에 한 번만 정의한다.

```yaml
ports:
  - name: http # 포트 이름 (Service의 포트 이름과 매칭)
    protocol: TCP # TCP, UDP, SCTP
    port: 8080 # 실제 포트 번호
    appProtocol: HTTP # 애플리케이션 프로토콜 (선택사항)
```

`appProtocol` 필드는 Kubernetes 1.20에서 추가되었으며, 이 포트에서 사용하는 애플리케이션 레벨 프로토콜을 명시한다. Service Mesh나 Ingress Controller가 이 정보를 활용할 수 있다.

**endpoints**

실제 엔드포인트 목록이다. 각 엔드포인트는 다음 정보를 포함한다:

```yaml
endpoints:
  - addresses: # IP 주소 목록 (보통 1개)
      - "10.0.1.5"
    conditions: # 엔드포인트 상태
      ready: true
      serving: true
      terminating: false
    hostname: pod-1 # Pod의 hostname (선택사항)
    nodeName: node-1 # Pod가 실행 중인 노드
    zone: us-east-1a # 가용 영역
    targetRef: # 참조하는 오브젝트 (보통 Pod)
      kind: Pod
      name: my-pod-xyz
      namespace: default
      uid: abcd-1234
    hints: # 토폴로지 힌트 (Topology Aware Routing용)
      forZones:
        - name: us-east-1a
```

## Endpoint Conditions

각 엔드포인트는 세 가지 상태 조건을 가진다. 이 조건들은 kube-proxy가 트래픽을 라우팅할 때 중요한 역할을 한다.

### ready

Pod가 트래픽을 받을 준비가 되었는지를 나타낸다.

- `true`: Pod의 readinessProbe가 성공하고, Pod가 Running 상태
- `false`: readinessProbe 실패 또는 Pod가 아직 준비되지 않음
- `nil`: 알 수 없음 (조건이 설정되지 않음)

```
Pod 생성 → ContainerCreating → Running → readinessProbe 성공 → ready: true
                                       → readinessProbe 실패 → ready: false
```

### serving

Pod가 요청을 처리할 수 있는 상태인지를 나타낸다. `ready`와 비슷하지만 종료 중인 Pod에서 차이가 있다.

- 종료 중인 Pod도 요청을 처리할 수 있으면 `serving: true`가 될 수 있다
- `ready`는 종료 중인 Pod에서 항상 `false`가 된다

이 차이가 왜 중요할까?

Graceful shutdown 시나리오를 생각해보자. Pod가 SIGTERM을 받으면:

1. `terminating: true`로 설정됨
2. `ready: false`로 변경됨 (기본 동작)
3. 하지만 Pod는 여전히 진행 중인 요청을 처리 중일 수 있음

`serving` 필드를 통해 "종료 중이지만 여전히 요청을 처리할 수 있는" 상태를 표현할 수 있다.

### terminating

Pod가 종료 중인지를 나타낸다.

- `true`: Pod에 deletionTimestamp가 설정됨 (삭제 요청됨)
- `false`: Pod가 정상 실행 중
- `nil`: 알 수 없음

## EndpointSlice Controller

EndpointSlice는 어떻게 생성되고 관리될까? kube-controller-manager에 포함된 EndpointSlice Controller가 이 역할을 담당한다.

### 동작 과정

```
┌─────────────┐     ┌───────────────────────┐     ┌─────────────────┐
│   Service   │────▶│ EndpointSlice         │────▶│  EndpointSlice  │
│  (selector) │     │    Controller         │     │    (생성됨)     │
└─────────────┘     └───────────────────────┘     └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Pod 목록      │
                    │ (selector 매칭) │
                    └─────────────────┘
```

1. **Service 감시**: Controller는 모든 Service를 watch한다
2. **Pod 매칭**: Service의 selector에 맞는 Pod을 찾는다
3. **EndpointSlice 생성/업데이트**: 매칭된 Pod 정보로 EndpointSlice를 관리한다

### 슬라이싱 알고리즘

EndpointSlice Controller는 다음 규칙에 따라 엔드포인트를 슬라이스로 나눈다:

1. **최대 엔드포인트 수**: 기본적으로 하나의 EndpointSlice에 최대 100개 엔드포인트 (`--max-endpoints-per-slice` 플래그로 조절 가능)

2. **기존 슬라이스 재사용**: 가능하면 기존 EndpointSlice에 엔드포인트를 추가한다

3. **포트 구성 기준 분리**: 다른 포트 구성을 가진 엔드포인트는 별도의 EndpointSlice에 저장된다

예를 들어, 250개의 Pod를 가진 Service의 경우:

```
┌─────────────────────────────────────────────────────────────┐
│                     Service: my-service                      │
│                       (250 Pods)                             │
├─────────────────┬─────────────────┬─────────────────────────┤
│ EndpointSlice 1 │ EndpointSlice 2 │ EndpointSlice 3         │
│   (100개)       │   (100개)       │   (50개)                │
└─────────────────┴─────────────────┴─────────────────────────┘
```

### 변경 최소화 전략

EndpointSlice Controller는 변경을 최소화하기 위해 다음 전략을 사용한다:

1. **안정적인 슬라이스 유지**: 가능하면 기존 EndpointSlice를 그대로 유지
2. **부분 업데이트**: 변경된 엔드포인트가 있는 슬라이스만 업데이트
3. **빈 슬라이스 정리**: 모든 엔드포인트가 제거된 슬라이스는 삭제

이를 통해 Pod 하나가 변경되어도 해당 Pod가 속한 EndpointSlice 하나만 업데이트된다.

### Reconcile 동작 원리

그렇다면 Controller는 특정 Pod가 삭제됐을 때, 그 IP가 어느 슬라이스에 있는지 어떻게 효율적으로 찾을까?

핵심은 **역방향 검색을 하지 않는다**는 것이다. "이 IP가 어느 슬라이스에 있지?"라고 찾는 대신, Service 단위로 전체 상태를 비교(reconcile)하면서 자연스럽게 어떤 슬라이스를 수정할지 알게 된다.

**Informer 캐시 구조**

Controller는 매번 etcd를 조회하지 않고, 메모리에 캐시를 유지한다:

```
┌─────────────────────────────────────────────────────────────┐
│                  EndpointSlice Controller                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Informer Cache (메모리)                 │    │
│  │  ┌─────────────────┐  ┌─────────────────────────┐   │    │
│  │  │ EndpointSlice   │  │ Pod Informer            │   │    │
│  │  │ Informer        │  │ (Pod 변경 감지)          │   │    │
│  │  └────────┬────────┘  └───────────┬─────────────┘   │    │
│  │           │                       │                  │    │
│  │           ▼                       ▼                  │    │
│  │  ┌─────────────────────────────────────────────┐    │    │
│  │  │   Label 기반 인덱스 (O(1) 조회)              │    │    │
│  │  │   Service → []EndpointSlice 매핑             │    │    │
│  │  └─────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**Pod 삭제 시 Reconcile 흐름**

```
Pod 10.0.1.4 삭제됨
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│ 1. Desired State 계산 (현재 살아있는 Pod들)                 │
│    → [10.0.1.1, 10.0.1.2, 10.0.1.3]                       │
└───────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│ 2. Current State 조회 (캐시에서 해당 Service의 모든 슬라이스)│
│    slice-abc: [10.0.1.1, 10.0.1.2]                        │
│    slice-def: [10.0.1.3, 10.0.1.4]  ← 삭제된 IP 포함       │
└───────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│ 3. 각 슬라이스를 순회하며 비교                              │
│    slice-abc: 모든 IP가 desired에 있음 → 변경 없음         │
│    slice-def: 10.0.1.4가 desired에 없음 → 수정 필요        │
└───────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│ 4. slice-def만 etcd에 업데이트                             │
│    slice-def: [10.0.1.3]                                  │
└───────────────────────────────────────────────────────────┘
```

**Pod UID 기반 매칭**

실제로는 IP가 아니라 Pod의 UID로 엔드포인트를 식별한다:

```go
func (r *reconciler) reconcile(service *v1.Service, pods []*v1.Pod) {
    // 1. Desired: 현재 살아있는 Pod → Endpoint 변환
    desiredEndpoints := map[string]endpoint{}  // key: Pod UID
    for _, pod := range pods {
        if isPodReady(pod) {
            desiredEndpoints[pod.UID] = endpoint{
                ip:      pod.Status.PodIP,
                podName: pod.Name,
            }
        }
    }

    // 2. Current: 캐시에서 기존 슬라이스들 가져오기 (Label 인덱스로 O(1))
    existingSlices := r.endpointSliceLister.List(
        labels.Set{"kubernetes.io/service-name": service.Name}.AsSelector(),
    )

    // 3. 각 슬라이스 순회하며 diff 계산
    for _, slice := range existingSlices {
        needsUpdate := false
        newEndpoints := []discovery.Endpoint{}

        for _, ep := range slice.Endpoints {
            podUID := ep.TargetRef.UID

            if _, exists := desiredEndpoints[podUID]; exists {
                // 이 endpoint는 유지
                newEndpoints = append(newEndpoints, ep)
                delete(desiredEndpoints, podUID)  // 처리됨 표시
            } else {
                // 이 endpoint는 삭제 대상 (desired에 없음)
                needsUpdate = true
            }
        }

        if needsUpdate {
            slice.Endpoints = newEndpoints
            r.client.Update(slice)  // 이 슬라이스만 업데이트
        }
    }
}
```

EndpointSlice의 각 endpoint는 `targetRef.uid`를 통해 원본 Pod를 참조한다:

```yaml
endpoints:
  - addresses:
      - "10.0.1.4"
    targetRef:
      kind: Pod
      name: my-pod-xyz
      uid: "abc-123"    # ← 이 UID로 매칭
```

슬라이스 개수는 `(Pod 수 / 100)` 정도라서 1000개 Pod여도 10개 슬라이스만 순회하면 된다. 그리고 읽기는 모두 메모리 캐시에서, 쓰기만 etcd로 가기 때문에 효율적이다.

## 라벨과 소유권

EndpointSlice는 특정 라벨을 통해 Service와 연결된다.

```yaml
labels:
  kubernetes.io/service-name: my-service
```

이 라벨은 EndpointSlice가 어느 Service에 속하는지를 나타낸다. kube-proxy는 이 라벨을 사용해 Service에 해당하는 모든 EndpointSlice를 찾는다.

```yaml
labels:
  endpointslice.kubernetes.io/managed-by: endpointslice-controller.k8s.io
```

이 라벨은 EndpointSlice를 누가 관리하는지를 나타낸다:

- `endpointslice-controller.k8s.io`: 기본 Kubernetes 컨트롤러
- `endpointslicemirroring-controller.k8s.io`: Endpoints 미러링 컨트롤러
- 커스텀 컨트롤러의 경우 자체 식별자 사용

### OwnerReferences

```yaml
ownerReferences:
  - apiVersion: v1
    kind: Service
    name: my-service
    uid: 1234-5678-abcd
    controller: true
    blockOwnerDeletion: true
```

OwnerReferences를 통해 Service가 삭제되면 연관된 EndpointSlice도 자동으로 가비지 컬렉션된다.

## Endpoints 미러링

기존 Endpoints 리소스와의 호환성을 위해, Kubernetes는 Endpoints Mirroring Controller를 제공한다.

### 동작 방식

```
┌─────────────┐                ┌─────────────────┐
│  Endpoints  │ ───미러링───▶ │  EndpointSlice  │
│  (수동생성)  │                │  (자동생성)     │
└─────────────┘                └─────────────────┘
```

selector가 없는 Service에 대해 수동으로 Endpoints를 생성하면, 미러링 컨트롤러가 자동으로 해당 EndpointSlice를 생성한다.

```yaml
# 수동으로 생성한 Endpoints
apiVersion: v1
kind: Endpoints
metadata:
  name: external-service
subsets:
  - addresses:
      - ip: 192.168.1.100
    ports:
      - port: 3306
---
# 자동으로 생성되는 EndpointSlice
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: external-service-abc12
  labels:
    kubernetes.io/service-name: external-service
    endpointslice.kubernetes.io/managed-by: endpointslicemirroring-controller.k8s.io
addressType: IPv4
ports:
  - port: 3306
endpoints:
  - addresses:
      - "192.168.1.100"
```

## kube-proxy와의 상호작용

kube-proxy는 EndpointSlice를 watch하여 iptables/IPVS 규칙을 생성한다.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  EndpointSlice  │────▶│   kube-proxy    │────▶│ iptables/IPVS   │
│    (watch)      │     │   (처리)         │     │   (규칙 생성)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

1. kube-proxy는 `kubernetes.io/service-name` 라벨로 EndpointSlice를 필터링
2. `ready: true`인 엔드포인트만 라우팅 규칙에 포함
3. Topology Aware Routing이 활성화된 경우 `hints`를 참조하여 같은 Zone 엔드포인트 우선

EndpointSlice 덕분에 kube-proxy의 성능이 크게 향상된다:

- 변경된 슬라이스만 처리하면 됨
- 전체 엔드포인트 목록을 다시 계산할 필요 없음
- 메모리 사용량 감소

## 정리

EndpointSlice는:

- 최대 100개씩 엔드포인트를 분할하여 확장성 문제를 해결한다
- `ready`, `serving`, `terminating` 조건으로 세밀한 상태 관리가 가능하다
- Zone, Node 정보와 hints를 통해 Topology Aware Routing을 지원한다
- Endpoints 미러링을 통해 기존 방식과 호환된다
- kube-proxy가 효율적으로 라우팅 규칙을 관리할 수 있게 한다

대규모 클러스터에서 Service의 확장성과 성능을 보장하는 핵심 메커니즘이며, Kubernetes 1.21부터 기본으로 사용된다.

---

참고

- <https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/>
- <https://kubernetes.io/docs/reference/kubernetes-api/service-resources/endpoint-slice-v1/>
- <https://kubernetes.io/docs/reference/networking/virtual-ips/> - kube-proxy 동작 원리
- <https://github.com/kubernetes/enhancements/tree/master/keps/sig-network/0752-endpointslices>

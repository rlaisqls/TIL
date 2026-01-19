Kubernetes Scheduling Framework는 kube-scheduler의 플러그인 기반 확장 메커니즘이다.

기존의 커스텀 스케줄링 방식들이 가진 한계를 극복하고, 유연하면서도 안정적인 확장성을 제공하기 위해 설계되었다.

## 등장 과정

Kubernetes에서 커스텀 스케줄링을 적용하기 위한 여러 시행착오가 있었다.

### Scheduler Extender

매 스케줄링마다 HTTP webhook을 호출하여 커스텀 결과를 받아오는 방식이다.

- 외부 서비스와의 HTTP 통신으로 인한 지연 발생
- 네트워크 장애 시 스케줄링 실패 가능성

### Custom Scheduler

완전히 별도의 스케줄러를 띄우는 방식이다.

- 여러 스케줄러가 동시에 동작하면 race condition 발생 가능
- 따라서 Pod에 `schedulerName`을 딱 하나씩 명시하는 방식으로만 사용한다.

### Scheduling Framework

분리 없이 kube-scheduler에서 모든 것을 처리하고, 플러그인으로 기능을 확장하는 형태이다.

- 단일 스케줄러에서 플러그인 방식으로 확장
- race condition 방지
- 기본 스케줄러의 최적화를 그대로 활용 가능

## 스케줄링 주기 구조

스케줄링은 두 단계로 나뉜다.

- **Scheduling Cycle**: 노드 선택 (직렬 실행)
- **Binding Cycle**: API Server에 바인딩 통보 (병렬 실행 가능)

Scheduling Cycle이 직렬인 이유는 두 Pod가 동시에 같은 리소스를 선점하는 race condition을 막기 위함이다. Binding은 네트워크 I/O라 느리므로, 기다리는 동안 다음 Pod 스케줄링을 병렬로 수행한다.

## Scheduling Cycle

### Queue Sort

스케줄링 큐에서 Pod의 정렬 순서를 결정한다.

스케줄러의 우선순위 큐는 힙(Heap)을 사용하여 구현된다. 힙에 대한 비교 함수는 하나만 존재할 수 있으므로, 기본적으로 Pod의 우선순위(Priority)를 기준으로 정렬하고 우선순위가 같으면 타임스탬프를 비교한다.

### PreFilter

스케줄링 주기가 시작될 때 호출된다.

- 모든 PreFilter 플러그인이 성공을 반환해야 다음 단계로 진행됨
- 실패하면 Pod가 거부되어 스케줄링 프로세스가 실패함
- 스케줄링 프로세스 시작 전에 Pod 정보를 사전 처리할 수 있음
- 클러스터가 충족해야 하는 전제 조건 및 Pod 요구 사항을 확인함

**기본 플러그인**

- `NodeResourcesFit`: Pod가 요청한 리소스를 노드가 제공할 수 있는지 사전 계산함
- `PodTopologySpread`: 토폴로지 분산 제약 조건을 사전 계산함
- `InterPodAffinity`: Pod 간 친화성/반친화성 규칙을 사전 계산함
- `VolumeBinding`: Pod가 요청한 PVC를 바인딩할 수 있는지 확인함

### Filter

Pod를 스케줄링할 수 없는 노드를 필터링하는 데 사용된다.

- Filter 플러그인의 실행 순서를 구성할 수 있음
- 다수의 노드를 필터링할 수 있는 정책의 우선 순위를 높게 지정하면 효율적임 (예: NodeSelector)
- 노드는 필터링 정책을 동시에(Concurrently) 실행함
- 스케줄링 주기 동안 Filter 플러그인이 여러 번 호출됨

**기본 플러그인**

- `NodeUnschedulable`: `node.spec.unschedulable`이 true인 노드를 필터링함
- `NodeName`: Pod의 `spec.nodeName`과 일치하지 않는 노드를 필터링함
- `TaintToleration`: Pod의 toleration과 노드의 taint를 비교하여 필터링함
- `PodTopologySpread`: 토폴로지 분산 제약을 만족하지 않는 노드를 필터링함
- `NodePorts`: Pod가 요청한 포트가 이미 사용 중인 노드를 필터링함
- `NodeResourcesFit`: 리소스가 부족한 노드를 필터링함 (requests/limits 확인)
- `NodeAffinity`: Pod의 nodeAffinity 규칙과 일치하지 않는 노드를 필터링함
- `InterPodAffinity`: Pod 간 친화성/반친화성 규칙을 만족하지 않는 노드를 필터링함
- `VolumeBinding`: PV/PVC 바인딩이 불가능한 노드를 필터링함
- `VolumeZone`: 볼륨의 zone 제약을 만족하지 않는 노드를 필터링함

### PostFilter

Kubernetes 1.19에서 도입되었다.

Filter 단계에서 Pod가 실패한 후 수행되는 작업을 처리한다.

- 선점(Preemption) 처리
- 자동 스케일링(Auto Scaling) 트리거

**기본 플러그인**

- `DefaultPreemption`: Filter 단계에서 모든 노드가 실패했을 때 선점을 수행함. 우선순위가 낮은 Pod를 축출하여 새 Pod가 스케줄링될 수 있도록 함

**선점 예시**

```yaml
# 높은 우선순위 PriorityClass
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
preemptionPolicy: PreemptLowerPriority
---
# Pod에 적용
apiVersion: v1
kind: Pod
spec:
  priorityClassName: high-priority
```

### PreFilter, Filter, PostFilter가 분리된 이유

이 세 단계가 분리된 이유는 각 단계의 목적과 실행 시점이 다르기 때문이다.

- PreFilter는 Pod당 한 번만 실행되고, Filter는 노드마다 실행된다. PreFilter에서 비용이 큰 계산을 한 번만 수행하고 Filter에서 재사용할 수 있다. 만약 합쳐져 있다면 노드마다 같은 계산을 반복해야 한다. 예를 들어 `NodeResourcesFit` 플러그인은 PreFilter에서 Pod의 리소스 요청량을 미리 계산해두고, Filter에서는 각 노드의 가용 리소스와 비교만 수행한다.

- PreFilter에서 실패하면 수백 개 노드를 검사할 필요 없이 바로 스케줄링 실패로 처리할 수 있다. 클러스터 전체 조건이나 Pod 자체의 문제를 먼저 확인하여 불필요한 연산을 줄인다.

- 관심사 분리
  - PreFilter: 이 Pod가 스케줄링 가능한 상태인가?
  - Filter: 이 특정 노드가 적합한가?
  - PostFilter: 아무 노드도 안 되면 어떻게 복구할까?

PostFilter는 Filter에서 모든 노드가 실패했을 때만 호출되므로, 정상적인 스케줄링 경로에서는 실행되지 않는다. 선점(Preemption)이나 Auto Scaling 트리거 같은 복구 로직을 분리하여 관리할 수 있다.

**상태 공유를 통한 플러그인 재사용**

하나의 플러그인이 여러 인터페이스(`PreFilterPlugin`, `FilterPlugin` 등)를 구현하여 여러 단계에 등록될 수 있다. 이를 통해 PreFilter에서 계산한 결과를 CycleState에 저장하고 Filter에서 재사용할 수 있다. 만약 별도 플러그인이었다면 같은 계산을 반복해야 한다.

### PreScore

Score 플러그인에서 사용되는 정보를 생성하는 데 사용된다.

- Filter 단계를 통과한 노드 목록을 얻음
- 일부 정보를 사전 처리하거나 로그/모니터링 정보를 생성할 수 있음

**기본 플러그인**

- `InterPodAffinity`: Score 단계를 위해 친화성 관련 정보를 준비함
- `PodTopologySpread`: Score 단계를 위해 토폴로지 분산 정보를 준비함
- `TaintToleration`: Score 단계를 위해 taint/toleration 정보를 준비함

### Score

Filter 후 남은 노드 중에서 최적의 노드를 선택한다.

두 단계로 나뉜다:

1. **Scoring**: 구성된 채점 정책을 호출하여 남은 노드의 점수를 매김
2. **Normalization**: 점수를 0에서 100 사이로 정규화함

**기본 플러그인**

- `NodeResourcesBalancedAllocation`: 리소스 사용량이 균형 잡힌 노드에 높은 점수를 줌
- `NodeResourcesFit`: 리소스 여유가 있는 노드에 점수를 줌
- `NodeAffinity`: Pod의 nodeAffinity `preferredDuringScheduling` 규칙에 따라 점수를 줌
- `InterPodAffinity`: Pod 간 친화성 규칙에 따라 점수를 줌
- `TaintToleration`: toleration이 더 잘 맞는 노드에 높은 점수를 줌
- `PodTopologySpread`: 토폴로지 분산이 잘 되는 노드에 높은 점수를 줌
- `ImageLocality`: Pod가 사용할 이미지가 이미 있는 노드에 높은 점수를 줌

**NodeResourcesFit Score 전략**

- `LeastAllocated`: 리소스 사용량이 적은 노드 선호 (기본값)
- `MostAllocated`: 리소스 사용량이 많은 노드 선호 (bin packing)
- `RequestedToCapacityRatio`: 지정된 비율에 가까운 노드 선호

### Reserve

스케줄러는 이 단계에서 스케줄링 결과를 캐시한다.

후속 단계에서 오류나 실패가 발생하면 UnReserve 단계로 들어가 데이터를 롤백한다.

**기본 플러그인**

- `VolumeBinding`: PV/PVC 바인딩을 예약함

### Permit

Scheduler Framework V2에 도입된 기능이다.

Reserve 단계 후, Bind 작업 전에 Pod를 가로채는 정책을 정의할 수 있다. 조건에 따라 다음 작업을 수행할 수 있다:

- **Approve**: Pod가 Permit 단계를 통과할 수 있음
- **Deny**: Pod가 거부되고 Permit 단계를 통과하지 못함 (스케줄링 실패)
- **Wait**: Pod가 대기 상태에 있음 (타임아웃 기간 설정 가능)

**활용 예시**

- Gang Scheduling: 여러 Pod가 동시에 스케줄링되어야 할 때 Wait으로 대기시킴
- 승인 프로세스: 외부 시스템의 승인을 기다림

## Binding Cycle

Kube-apiserver에서 제공하는 API 작업 호출을 포함하므로 시간이 많이 걸린다. 스케줄링 효율성을 높이기 위해 비동기적으로 실행된다. 이 단계는 스레드에 안전하지 않다.

### PreBind

Bind 작업 전에 실행된다. 데이터 정보를 얻고 업데이트할 수 있다.

**기본 플러그인**

- `VolumeBinding`: PV/PVC를 실제로 바인딩함

### Bind

Kube-apiserver에서 제공하는 API 작업을 호출하여 Pod를 해당 노드에 바인딩한다.

**기본 플러그인**

- `DefaultBinder`: kube-apiserver에 Pod-Node 바인딩을 요청함

### PostBind

Bind 작업 후에 실행된다. 바인딩 완료 후 정리 작업이나 알림을 수행할 수 있다.

### UnReserve

Reserve 단계에서 생성된 캐시를 지우고 데이터를 초기 상태로 롤백하는 데 사용된다. 후속 단계(Permit, PreBind, Bind)에서 실패가 발생했을 때 호출된다.

---

참고

- https://github.com/kubernetes/community/blob/master/contributors/design-proposals/scheduling/scheduler_extender.md
- https://kubernetes.io/docs/concepts/scheduling-eviction/scheduling-framework/

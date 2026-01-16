## k8s Scheduler의 동작

- Pod를 정의하면 그 Pod를 정의할 수 있는 적절한 Node를 찾아서 배치해줌.
  - 적절한 Node는 selector, taint & toleration, priority 등 설정값에 따라 정함
  - 그리고 nodeName에 node 이름을 추가해줌
- 만약 nodeName을 지정하여 생성하면 스케줄 동작 없이 직접 원하는 노드에 바로 스케줄링함

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ...
spec:
  containers: ...
  nodeSelector:
    type: hello
  # nodeName: ip-10-12-34-56.ap-northeast-2.compute.internal
```

---

## 스케줄러 내부 구조

### Scheduling Cycle vs Binding Cycle

Pod 스케줄링은 두 단계로 나뉜다:

1. **Scheduling Cycle**: 노드 선택 (직렬 실행)
2. **Binding Cycle**: API Server에 바인딩 통보 (병렬 실행 가능)

Scheduling Cycle이 직렬인 이유는 두 Pod가 동시에 같은 리소스를 선점하는 race condition을 막기 위함이다. Binding은 네트워크 I/O라 느리므로, 이걸 기다리는 동안 다음 Pod 스케줄링을 병렬로 진행한다.

### 스케줄링 큐

스케줄러는 세 개의 큐를 관리한다:

- **ActiveQ**: 스케줄링 대기 중인 Pod
- **BackoffQ**: 실패 후 재시도 대기 중인 Pod (1초 → 2초 → ... → 최대 10초)
- **Unschedulable Pod Pool**: 현재 클러스터 상태로는 스케줄링 불가능한 Pod

> QueueingHint (v1.32)
>
> - 이전에 기본값으론 스케줄링 실패한 Pod가 노드 추가, Pod 삭제 같은 이벤트에 무조건 스케줄링을 재시도했다. v1.32부터는 각 플러그인이 '이 이벤트가 실제로 이 Pod와 연관있는지' 판단해서 불필요한 재시도를 줄인다.

---

## Scheduling Framework

v1.19부터 스케줄러가 플러그인 기반으로 바뀌었다.

확장 포인트:

```
PreEnqueue → QueueSort → PreFilter → Filter → PostFilter
    → PreScore → Score → NormalizeScore → Reserve → Permit
    → PreBind → Bind → PostBind
```

- **QueueSort**: 큐 정렬. 하나만 활성화 가능
- **Filter**: 노드별로 병렬 실행
- **PostFilter**: feasible 노드가 없을 때만 호출. Preemption이 여기서 동작
- **Permit**: Wait 반환 가능. Gang Scheduling 구현에 사용

기본 플러그인:

- `NodeResourcesFit`: 리소스 검사. LeastAllocated/MostAllocated/RequestedToCapacityRatio 전략
- `TaintToleration`: Taint/Toleration 검사
- `InterPodAffinity`: Pod 간 affinity/anti-affinity. 대규모 클러스터에서 O(N²) 성능 이슈가 있어서 1.22부터 인덱싱 도입
- `ImageLocality`: 이미지가 이미 있는 노드 선호

---

## 1. Labels and Selectors

특정 라벨이 붙어있는 노드에 스케줄링하는 방법

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ...
spec:
  containers: ...
  nodeSelector:
    type: hello
```

---

## 2. Taints and Tolerations

스케줄링해도 되는 노드를 지정하는 방법

```yaml
apiVersion: v1
kind: Node
spec:
  taints:
    - effect: NoSchedule
      key: CriticalAddonsOnly
      value: "true"
---
apiVersion: v1
kind: Pod
spec:
  tolerations:
    - key: "key1"
  operator: "Exists"
  effect: "NoSchedule"
```

- `Taint`: '오염시키다'
  - (Node에 설정) 이 Node는 오염되어있음
- `Toleration` : '관용'
  - (Pod에 설정) 이 오염은 무시해도 됨

- Taint 옵션
  - `NoSchedule`: tolerance 없이 Pod를 스케줄링하지 않는다.
  - `NoExecute`: tolerance 없이 Pod를 스케줄링, 실행하지 않는다.
    - 노드에 NoExecute taint가 추가되면, 지정된 시간(`tolerationSeconds`)이 지난 후 toleration이 없는 기존 Pod가 퇴출된다.
  - `PreferredNoSchedule`: tolerance가 없이 Pod를 스케줄링하지 않으려 하지만, 클러스터에 리소스가 부족한 경우, taint가 있는 노드에도 Pod를 스케줄링할 수 있다.

### Toleration과 Taint Effect 관계

Toleration의 effect와 Taint의 effect 간 호환성을 정리하면 다음과 같다:

| Toleration ╲ Taint       | PreferNoSchedule | NoSchedule | NoExecute |
|--------------------------|------------------|------------|-----------|
| PreferNoSchedule         | O                | X          | X         |
| NoSchedule               | O                | O          | X         |
| NoExecute                | O                | X          | O         |
| effect 미지정 (빈 값)    | O                | O          | O         |

- **O**: 해당 Toleration으로 해당 Taint를 tolerate 가능 = Pod가 그 노드에 스케줄링 가능
- **X**: 해당 Toleration으로 해당 Taint를 tolerate 불가 = Pod가 그 노드에 스케줄링 불가

effect를 지정하지 않으면(빈 값) 모든 effect의 Taint를 tolerate할 수 있다.


- 용도
  - 특정 노드들을 전용 용도로 쓰고 싶을 때
    - 특정 Pod들만 이 노드에 스케줄링되도록
    - ex. GPU를 쓰는 컨테이너만 GPU 노드에 스케줄링 되도록
  - Node에 문제가 있어 내쫒을 때
    - effect `NoExecute`로
    - k8s에선 이 용도로 아래 taint들을 사용함
      - `node.kubernetes.io/not-ready` (Node가 준비되지 않음)
      - `node.kubernetes.io/unreachable` (노드 컨트롤러와 통신되지 않음)
      - `memory-pressure`, `disk-pressure`, `pid-pressure`, `network-unavailable`...

    - Note) Kubernetes는 기본적으로 모든 파드에 not-ready, unreachable에 300초 toleration으로 자동으로 추가한다. 즉, 노드 문제가 감지되면 5분 후에 노드에서 빠진다.
    - DeamonSet은 두 taint + pressure taint들에 완전 toleration을 가짐. 노드당 하나씩 떠야하므로.

      ```yaml
      tolerations:
        - key: "node.kubernetes.io/not-ready"
      operator: "Exists"
      effect: "NoExecute"
      tolerationSeconds: 300
      ```

### PodDisruptionBudget과 Drain

Drain으로 노드를 비울 때 주의할 점이 있다. Deployment의 Rolling Update와 달리, drain으로 evict되면 pod가 바로 삭제된다.

- **Rolling Update**: Ready 상태를 기준으로 `maxSurge 25%`, `maxUnavailable 25%`가 기본값이므로 Pod가 1개여도 새 Pod가 먼저 Ready된 후 기존 Pod가 삭제됨
- **Drain/Evict**: Pod를 직접 삭제하므로, 1개뿐인 Pod는 그냥 중단됨

따라서 evict로부터 Pod를 보호하려면 PodDisruptionBudget(PDB)을 설정해야 한다.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 1  # 또는 maxUnavailable: 1
  selector:
    matchLabels:
      app: my-app
```

- `minAvailable`: 항상 유지해야 하는 최소 Pod 수 (정수 또는 백분율)
- `maxUnavailable`: 동시에 중단될 수 있는 최대 Pod 수 (정수 또는 백분율)

PDB가 설정되면 drain 시 해당 조건을 만족할 때까지 eviction이 대기한다.

- <https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction>

---

## 3. Affinity

- taint, toleration은 노드에 다른 포드가 예약되는 걸 막고 특정 노드로 제한하는 역할이라면
- nodeAffinity는 pod 입장에서 이 노드에 스케줄링되면 좋겠다 (친밀감, 관련성)
  - `requiredDuringSchedulingIgnoredDuringExecution`
  - `preferredDuringSchedulingIgnoredDuringExecution`
  - (`requiredDuringschedulingrequiredduringexecution`를 지원할 계획이 있다고 함)

  - `requiredDuringSchedulingIgnoredDuringExecution`
  - nodeSelector와 같음

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
    name: with-node-affinity
    spec:
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
            - key: topology.kubernetes.io/zone
            operator: In
            values:
            - antarctica-east1
            - antarctica-west1
    containers:
    - name: with-node-affinity
        image: registry.k8s.io/pause:3.8
    ```

    - NodeSelector와 다른 점:
    - In, NotIn, Exists, DoesNotExist, Gt, Lt 등 조건

  - `preferredDuringSchedulingIgnoredDuringExecution`
    - 선호함. 일치하는 노드 없어도 스케줄링함.
    - weight (규칙과 일치하는 두 개의 가능한 노드가있는 경우, 일치하는 가중치 합이 높은 노드에 스케줄링)

- Pod Affinity (Anti-affinity)
  - Pod들 간의 위치 관계를 정의하여 함께 배치하거나(affinity) 떨어뜨려 배치(anti-affinity)
  - topologyKey를 기준으로 도메인을 나눔 (node, zone, region 등)

  **사용 사례**:
  - Affinity:
    - 같은 서비스의 Pod들을 동일 존에 배치하여 존 간 트래픽 비용 절감
    - 특정 라이센스나 하드웨어가 있는 노드에 관련 Pod들을 함께 배치
  - Anti-Affinity:
    - 고가용성을 위해 같은 서비스의 Pod들을 다른 노드/존에 분산
    - 리소스 경쟁이나 간섭을 피하기 위해 특정 Pod들을 분리

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  affinity:
    # Pod Affinity: 캐시 서버와 같은 노드에 배치
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - cache
          topologyKey: kubernetes.io/hostname
          namespaces: ["default", "web"] # 특정 네임스페이스 범위 지정
    # Pod Anti-Affinity: 같은 web-server끼리는 다른 존에 배치
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - web-server
          topologyKey: topology.kubernetes.io/zone
      # 선호 조건: 다른 노드에 배치 시도 (가중치 100)
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
                - key: app
                  operator: In
                  values:
                    - web-server
            topologyKey: kubernetes.io/hostname
  containers:
    - name: web-server
      image: nginx
```

**TopologyKey 예시**:

- `kubernetes.io/hostname`: 노드 단위
- `topology.kubernetes.io/zone`: 가용 영역 단위
- `topology.kubernetes.io/region`: 리전 단위
- 커스텀 라벨도 사용 가능 (예: `rack`, `switch`)

**주의사항**:

- 대칭성 문제: A가 B를 선호해도 B가 A를 선호한다는 보장 없음
- 순환 의존성 방지 필요
- 너무 엄격한 규칙은 스케줄링 불가능 상황 초래
- namespace 필드로 검색 범위 제한 가능 (기본값: 같은 네임스페이스)

---

## 4. Pod Topology Spread Constraints

Anti-Affinity는 "분리됨/안됨"만 표현 가능. Topology Spread는 "각 도메인에 균등하게"를 표현한다.

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: mypod
  labels:
    foo: bar
spec:
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: zone
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          foo: bar
  containers:
    - name: pause
      image: registry.k8s.io/pause:3.1
```

- `maxSkew`: 가장 많은 도메인과 가장 적은 도메인의 Pod 수 차이 허용치
- `whenUnsatisfiable`: `DoNotSchedule`(기본값) 또는 `ScheduleAnyway`
- `minDomains` (v1.28): 최소 도메인 수 지정 가능
- `nodeAffinityPolicy`, `nodeTaintsPolicy` (v1.26): nodeAffinity/taint 고려 여부

클러스터 기본값 (v1.24+):

```yaml
defaultConstraints:
  - maxSkew: 3
    topologyKey: "kubernetes.io/hostname"
    whenUnsatisfiable: ScheduleAnyway
  - maxSkew: 5
    topologyKey: "topology.kubernetes.io/zone"
    whenUnsatisfiable: ScheduleAnyway
```

스케일 다운 시 분산이 깨질 수 있다. 스케줄러는 새 Pod 배치만 담당하고 기존 Pod 재배치는 안 한다.

---

## 5. Priority Classes & Preemption

Pod의 우선순위를 정의하여 스케줄링 순서와 리소스 부족 시 선점(Preemption) 동작을 제어

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
preemptionPolicy: PreemptLowerPriority # 낮은 우선순위 Pod 선점 가능
description: "This priority class should be used for critical service pods only."
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  priorityClassName: high-priority
  containers:
    - name: nginx
      image: nginx
```

- Priority 설정
  - `value`: 우선순위 값 (높을수록 우선순위 높음, -2147483648 ~ 1000000000)
  - `globalDefault`: 클러스터 전체 기본값으로 설정 (하나만 가능)
  - 시스템 예약 우선순위:
    - `system-cluster-critical`: 2000000000
    - `system-node-critical`: 2000001000

- Preemption:
  - 높은 우선순위 Pod가 스케줄링될 공간이 없을 때, 낮은 우선순위 Pod를 evict하고 그 자리에 스케줄링
  - 과정
    1. 높은 우선순위 Pod가 pending 상태
    2. 스케줄러가 낮은 우선순위 Pod를 찾아 evict 대상 선정
    3. PodDisruptionBudget을 고려하여 eviction 수행
    4. 낮은 우선순위 Pod에 graceful termination period 부여
    5. 높은 우선순위 Pod가 해당 노드에 스케줄링

- `nominatedNodeName`: preemption 발생 시 설정됨. 단, 보장은 아님
  - victim의 graceful termination(기본 30초) 동안 더 높은 우선순위 Pod가 올 수 있음
  - 다른 pending Pod가 먼저 스케줄링될 수 있음

- `preemptionPolicy: Never` (v1.24+): 우선순위는 높지만 preemption은 안 함. 큐에서 앞에 서있다가 자리 나면 들어감

- Kubelet Eviction에도 priority가 고려됨
  - 정확히는 아래 정보에따라 순서대로 고려함
    1. pod의 자원 사용이 requests를 초과하는지 **여부**
    2. Pod 우선 순위
    3. requests 대비 자원 사용량

  - 따라서 아래처럼 동작함
    1. BestEffort 또는 사용량이 requests를 초과한 Burstable Pod들
    - Priority가 낮은 순서대로
    - 동일 Priority 내에서는 requests 대비 초과 사용량이 많은 순서대로
    2. Guaranteed Pod와 사용량이 requests 미만인 Burstable Pod들
    - Priority가 낮은 순서대로 evict (가장 마지막에 제거)

  > QoS 클래스: 리소스 요청/제한에 따라 3개로 분류
  >
  > - **Guaranteed**: 모든 컨테이너가 CPU/메모리 requests와 limits을 동일하게 설정
  > - **Burstable**: 최소 하나의 컨테이너가 requests나 limits을 설정
  > - **BestEffort**: requests와 limits이 모두 미설정
  - 참고
    - EphemeralStorage는 QoS 분류가 적용되지 않음
    - inode나 PID 부족 시에는 requests가 없으므로 Priority만으로 결정
    - 스케줄러 preemption과 kubelet eviction은 다른 메커니즘

Preemption 제한사항

### 1. 낮은 우선순위 Pod에 대한 Inter-Pod Affinity 보장되지 않음

높은 우선순위 Pod가 낮은 우선순위 Pod와 같은 노드에 있어야 하는 affinity가 있으면 문제가 된다.

- 예시
  - 낮은 우선순위의 cache-pod
  - 높은 우선순위의 web-pod (cache pod와 같은 노드에 있어야 함)
  - 이 때 스케줄러가 preemption 시도
    - affinity를 보장하려면, 모든 low-priority Pod(cache-pod 포함) 제거를 시뮬레이션 해야함
    - 근데 web pod보다 우선순위 낮은 pod가 cache-pod밖에 없다면?
    - web-pod 스케줄링 시도 → 실패 (필요한 cache-pod가 없어서)
    - 결론: 이 노드는 preemption 불가능, web은 계속 pending 상태로 남음

- 해결책: affinity 대상 Pod의 우선순위를 같거나 높게 설정

### 2. Cross-Node Preemption 지원 안 함

같은 노드 내에서만 preemption을 수행한다. 다른 노드의 Pod를 쫓아내서 문제를 해결할 수 있어도 안 한다.

- 예시 (Node1과 Node2가 모두 zone-a에 있음)

  ```yaml
  # Node1에서 실행 중인 낮은 우선순위 Pod
  apiVersion: v1
  kind: Pod
  metadata:
    name: pod-a
  spec:
    priorityClassName: low-priority
    affinity:
      podAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app: web  # "app: web" 라벨 Pod와 같은 zone 금지
          topologyKey: topology.kubernetes.io/zone
  ```

  ```yaml
  # Node2에 스케줄링하려는 높은 우선순위 Pod
  apiVersion: v1
  kind: Pod
  metadata:
    name: web-pod
    labels:
      app: web
  spec:
    priorityClassName: high-priority
  ```

- 흐름:
  1. web-pod를 Node2에 스케줄링하려 함
  2. pod-a의 anti-affinity 때문에 zone-a 전체가 막힘
  3. pod-a를 쫓아내면 해결되는데, pod-a는 Node1에 있음
  4. 스케줄러는 다른 노드의 Pod를 건드리지 않음 → web-pod는 pending

### 3. nominatedNodeName Race Condition

preemption이 발생하면 `status.nominatedNodeName`이 설정된다. 근데 이게 race condition이 있다.

- 흐름:
  1. Pod P가 스케줄링 불가 → preemption 로직이 Node N을 선택
  2. 스케줄러가 Pod P의 nominatedNodeName을 N으로 업데이트하려고 API 요청
  3. 그 사이에 다른 Pod Q가 스케줄링되어 Node N에 배치됨
  4. Pod P는 nominatedNodeName=N이지만, 실제로 N에 자리가 없음

- 결과:
  - nominatedNodeName이 설정된 Pod가 있으면 다른 작은 Pod들이 그 노드에 스케줄링 안 됨
  - 근데 정작 nominated Pod는 자리가 없어서 못 들어감
  - 노드 리소스가 낭비되는 상황

- nominatedNodeName은 보장이 아님. 스케줄러가 "먼저 시도해볼 노드" 정도의 의미

### 4. Graceful Termination 동안 다른 Pod가 끼어듦

victim Pod들이 종료되는 동안 (기본 30초) 다른 일이 생길 수 있다.

- 시나리오 1: 더 높은 우선순위 Pod가 등장
  1. Pod P (priority: 100)가 preemption 시작, victim 종료 대기 중
  2. Pod Q (priority: 200)가 생성됨
  3. victim 종료 완료
  4. 스케줄러가 Q를 먼저 스케줄링 (더 높은 우선순위니까)
  5. P는 다시 pending

- 시나리오 2: 같은 우선순위 Pod가 끼어듦
  1. Pod P가 preemption 시작
  2. Pod Q (같은 우선순위, 더 작은 리소스 요청)가 생성됨
  3. victim 일부만 종료된 시점에 Q가 들어갈 자리가 생김
  4. Q가 먼저 스케줄링됨
  5. P는 자리 부족으로 다시 preemption 시도

- 완화책: 낮은 우선순위 Pod에 `terminationGracePeriodSeconds: 0` 설정

### 5. PDB는 Best-Effort

PodDisruptionBudget을 존중하려고 "노력"하지만 보장은 아니다.

- 동작:
  1. 스케줄러가 PDB를 위반하지 않는 victim을 찾으려고 시도
  2. 그런 victim이 없으면? PDB를 무시하고 preemption 진행

- 더 심각한 문제 (race condition):
  - PDB가 `minAvailable: 2`이고 현재 Pod 3개
  - 스케줄러가 "1개 evict 가능"이라고 판단
  - 근데 동시에 2개를 evict하려고 하면?
  - 스케줄러는 자기가 보낸 eviction 요청을 고려 안 함
  - 결과: PDB가 `minAvailable: 2`인데 Pod가 1개만 남는 상황

- 이건 스케줄러와 PDB 컨트롤러 간의 race condition. 알려진 이슈다. (kubernetes/kubernetes#91492)

### 6. Priority Inflation

너무 많은 Pod가 높은 우선순위를 가지면 preemption이 무의미해진다.

- 모든 Pod가 priority: 1000이면 preemption이 발생 안 함
- 해결책: ResourceQuota로 PriorityClass별 Pod 수 제한

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: high-priority-quota
spec:
  hard:
    pods: "10"
  scopeSelector:
    matchExpressions:
    - operator: In
      scopeName: PriorityClass
      values: ["high-priority"]
```

---

## 6. 스케줄러 성능 튜닝

### percentageOfNodesToScore

모든 노드를 다 스코어링하여 계산하면 성능에 부정적 영향이 있을 수 있다다. 이 값을 설정하면 feasible 노드를 해당 비율만큼 찾은 후 스코어링으로 넘어간다.

기본값:

- 100개 노드: 50%
- 5000개 노드: 10%
- 최소값: 5% (하드코딩)

```yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
percentageOfNodesToScore: 50
```

### 노드 순회 방식

특정 노드가 항상 먼저 검사되는 걸 막기 위해 라운드 로빈으로 순회한다. 이전에 멈춘 곳부터 시작. 멀티 존이면 존도 인터리빙:

```
Zone1: Node1, Node2, Node3
Zone2: Node4, Node5

순회: Node1 → Node4 → Node2 → Node5 → Node3 → Node1 → ...
```

---

## 7. NodeResourcesFit 스코어링 전략

- **LeastAllocated** (기본값): 리소스가 여유로운 노드 선호. 워크로드 분산
- **MostAllocated**: 리소스를 많이 쓰는 노드 선호. Bin Packing. Cluster Autoscaler와 같이 쓸 때 유용 (빈 노드를 만들어서 스케일 다운)
- **RequestedToCapacityRatio**: `shape` 파라미터로 커스텀 스코어링 함수 정의

```yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
profiles:
  - pluginConfig:
      - args:
          scoringStrategy:
            type: MostAllocated
            resources:
              - name: cpu
                weight: 1
              - name: memory
                weight: 1
        name: NodeResourcesFit
```

---

## 8. Gang Scheduling

기본 스케줄러는 All-or-Nothing 스케줄링을 지원 안 함. ML 학습에서 8개 Pod 중 7개만 뜨면 데드락.

외부 스케줄러 필요:

- **Volcano**: CNCF 프로젝트. Job 큐, PodGroup, Fair-share 스케줄링
- **Coscheduling Plugin**: kubernetes-sigs/scheduler-plugins. 기본 스케줄러에 플러그인으로 붙음

---

## 9. Descheduler

스케줄러는 새 Pod 배치만 담당. 이미 스케줄링된 Pod 재배치는 Descheduler가 한다.

주요 전략:

- `RemoveDuplicates`: 노드당 ReplicaSet Pod 중복 제거
- `LowNodeUtilization`: 활용도 낮은 노드의 Pod evict → 통합
- `HighNodeUtilization`: 빈 노드 만들기 (오토스케일링용)
- `RemovePodsViolatingNodeAffinity`: affinity 조건 안 맞게 된 Pod 제거
- `RemovePodsViolatingTopologySpreadConstraint`: 분산 깨진 경우 재조정

system-cluster-critical, system-node-critical Pod는 안 건드림. PDB 존중.

---

## Configuring Scheduler Profiles

- 스케줄러의 동작을 커스터마이징하기 위한 프로파일 설정
- 스케줄링 단계:
  1. **PreFilter**: Pod 스케줄링 전 사전 검증
  2. **Filter**: 스케줄링 가능한 노드 필터링
  3. **PostFilter**: 필터링 실패 시 처리
  4. **PreScore**: 점수 계산 전처리
  5. **Score**: 각 노드에 점수 부여
  6. **Reserve**: 선택된 노드에 리소스 예약
  7. **Bind**: Pod를 노드에 바인딩

```yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
profiles:
  - schedulerName: default-scheduler
    plugins:
      preFilter:
        enabled:
          - name: NodeResourcesFit
          - name: NodePorts
        disabled:
          - name: NodeAffinity
      filter:
        enabled:
          - name: NodeUnschedulable
          - name: TaintToleration
      score:
        enabled:
          - name: NodeResourcesFit
            weight: 1
          - name: ImageLocality
            weight: 2
    pluginConfig:
      - name: NodeResourcesFit
        args:
          scoringStrategy:
            type: LeastAllocated
            resources:
              - name: cpu
                weight: 1
              - name: memory
                weight: 1
```
---

## 10. 리소스 관리와 스케줄링

스케줄러가 Pod를 노드에 배치할 때 리소스 요청량(requests)과 제한량(limits)을 기준으로 결정한다.

### 리소스 종류

**CPU**

- Compressible 리소스: 부족하면 throttling됨 (Pod가 죽지 않음)
- 단위: 밀리코어(m). 1000m = 1 CPU 코어

**Memory**

- Incompressible 리소스: 부족하면 OOM Killed됨
- 단위: 바이트 (Mi, Gi 등)

**Ephemeral Storage**

로컬 디스크 기반 임시 스토리지로, 다음 항목들이 포함된다:

- kubelet이 관리하는 컨테이너 로그
- `emptyDir` 볼륨
- Writable Layer (컨테이너가 이미지 위에 쓴 데이터)
  - 참고: `docker commit`을 하면 이 Writable Layer가 추가된 이미지가 생성됨

Ephemeral Storage는 **overlay2**라는 디스크 드라이버를 사용한다. Docker 네트워크 드라이버에 bridge, host, overlay가 있듯이, 디스크 드라이버에는 overlay2, aufs, devicemapper 등이 있다. Writable Layer에 파일을 쓸 때 어떻게 처리하는지가 디스크 드라이버에 따라 다르다.

### 가용 리소스 계산

노드의 가용 리소스(Allocatable)에서 다음이 기본적으로 제외된다:

- **kube-reserved**: kubelet, container runtime 등 k8s 컴포넌트용
  - 클라우드 환경에서는 노드 크기에 따라 수식이 달라짐
- **system-reserved**: OS, systemd 등 시스템 데몬용
  - 기본값은 설정되어 있지 않음

### Pod 리소스 총합 계산 방식

Pod의 리소스 요청량은 컨테이너 종류에 따라 다르게 계산된다:

**일반 Container**

모든 app container의 requests/limits이 Pod 총 리소스에 더해진다. 동시에 실행되기 때문이다.

**Init Container**

일반 init container의 requests/limits 중 **가장 높은 값**만 Pod 총 리소스에 더해진다. Init Container들은 순차적으로 실행되므로 그 중 가장 큰 리소스 요구량만 고려한다.

**Native Sidecar (Restartable Init Container)**

모든 native sidecar container의 requests/limits이 Pod 총 리소스에 더해진다. 일반 container와 동일하다.

> The resource usage calculation changes for the pod as restartable init container resources are now added to the sum of the resource requests by the main containers.

Native sidecar를 가장 위에 선언하면(init container 중 가장 먼저 실행), **native sidecar 용량 + init container 중 최대 용량**이 Pod 총 리소스가 된다. 다른 init container가 먼저 실행되면 공간을 공유한다.

```
예시 1: native sidecar가 먼저 실행
- native sidecar container: 200m
- init container: 300m
- container: 100m
= Pod 총합: 600m (200 + max(300, 200) + 100 = 200 + 300 + 100)

예시 2: init container가 먼저 실행
- init container: 300m  
- native sidecar container: 200m
- container: 100m
= Pod 총합: 400m (max(300, 200+200) + 100 = 300 + 100)
```

### QoS Class와 OOM Score

Pod의 리소스 설정에 따라 QoS Class가 결정되고, 이는 OOM 발생 시 어떤 Pod가 먼저 종료될지 결정한다.

**QoS Class 분류**

| QoS Class   | 조건                                                        |
|-------------|-------------------------------------------------------------|
| Guaranteed  | 모든 컨테이너에 CPU/Memory requests = limits 이며 모두 지정됨 |
| Burstable   | 위 두 조건이 아닌 나머지                                      |
| BestEffort  | 모든 컨테이너에 requests/limits 모두 미지정                   |

**OOM Score**

| QoS Class   | OOM Score                                                          | 비고           |
|-------------|--------------------------------------------------------------------|----------------|
| BestEffort  | 1000                                                               | 가장 먼저 종료  |
| Burstable   | min(max(2, 1000 - 1000 × (메모리 Requests / 머신 메모리 용량)), 999) | 덜 쓰는 것 우선 |
| Guaranteed  | -998                                                               | 가장 나중에 종료 |

Burstable의 경우 실제 메모리 사용량이 아닌 requests를 기준으로 점수가 계산된다. 따라서 requests 대비 실제 사용량이 낮은 Pod가 먼저 종료될 수 있다.


---

참고

- <https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/>
- <https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/>
  - <https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/>
- <https://github.com/kubernetes/design-proposals-archive/blob/main/scheduling/podaffinity.md>
- <https://github.com/kubernetes/design-proposals-archive/blob/main/scheduling/nodeaffinity.md>
- <https://kubernetes.io/blog/2017/03/advanced-scheduling-in-kubernetes/>
- <https://kubernetes.io/docs/concepts/scheduling-eviction/scheduling-framework/>
- <https://kubernetes.io/docs/reference/scheduling/config/>
- <https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/>
- <https://kubernetes.io/docs/concepts/scheduling-eviction/scheduler-perf-tuning/>
- <https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/>
- <https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/>
- <https://kubernetes.io/docs/concepts/scheduling-eviction/resource-bin-packing/>
- <https://kubernetes.io/blog/2024/12/12/scheduler-queueinghint/>
- <https://github.com/kubernetes-sigs/descheduler>
- <https://github.com/kubernetes-sigs/scheduler-plugins>
- <https://volcano.sh/en/docs/>

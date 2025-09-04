k8s Scheduler의 동작:

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

1. Labels and Selectors

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

2. Taints and Tolerations

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

- PodDisruptionBudget
  - <https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction>

---

3. Affinity

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

4. Priority Classes & Preemption

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

1. 낮은 우선순위 Pod에 대한 Inter-Pod Affinity 보장되지 않음

- 예시

  - 낮은 우선순위의 cache-pod
  - 높은 우선순의의 web-pod (cache pod와 같은 노드에 있어야 함)
  - 이 때 스케줄러가 preemption 시도

    - affinity를 보장하려면, 모든 low-priority Pod(cache-pod 포함) 제거를 시뮬레이션 해야함
    - 근데 web pod보다 우선순위 낮은 pod가 cache-pod밖에 없다면?
    - web-pod 스케줄링 시도 → 실패 (필요한 cache-pod가 없어서)
    - 결론: 이 노드는 preemption 불가능, web은 계속 pending 상대로 남음

  - 따라서 이 경우 affinity가 깨질 수 있음

    - affinity 규칙을 만족하는 Pod 조합의 permutation이 너무 많아 성능 저하
    - 높은 우선순위 Pod가 낮은 우선순위 Pod에 의존하는 것은 설계상 모순
    - 사용자에게 혼란을 주고 스케줄링 예측 가능성 저하

  - 해결책
    - cache-pod의 우선순위를 web-pod와 같거나 높게 설정
    - affinity 대신 다른 방법 사용 (예: 같은 Deployment로 관리)

2. 특정 노드에 Pod를 스케줄링하기 위해 다른 노드의 Pod를 제거하지 않음

- 같은 노드 내에서만 preemption을 수행
- 예시 (Node1과 Node2가 모두 a zone에 있음)

  ```yaml
  # Node1에서 이미 실행 중인 Pod
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
              app: web  # "app: web" 라벨을 가진 Pod와 같은 zone에 있으면 안됨
          topologyKey: topology.kubernetes.io/zone
    containers: [...]

  # Node2에 스케줄링하려는 높은 우선순위 Pod
  apiVersion: v1
  kind: Pod
  metadata:
    name: web-pod
    labels:
      app: web  # 이 라벨 때문에 pod-a의 anti-affinity에 걸림
  spec:
    priorityClassName: high-priority
    containers: [...]
  ```

1. web-pod를 Node2에 스케줄링하려 함
2. Node1의 pod-a가 "같은 zone(zone-a)에 app:web Pod 금지" 규칙을 가지고,
   web-pod는 app:web 라벨을 가지므로, zone-a 어디에도 배치 불가
3. 해결하려면 Node1의 pod-a를 제거해야 함 (= Cross Node Preemption)

- 하지만 이는 다른 노드의 Pod를 건드리는 것
- web-pod의 priority가 높지만 preemption 하지 못하고 pending으로 남음

---

1. 낮은 우선순위 Pod에 대한 Inter-Pod Affinity. 깨지는지, 아닌지

2. ignoredDuringExecution이어도 내쫒는가

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

참고

- <https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/>
- <https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/>
  - <https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/>
- <https://github.com/kubernetes/design-proposals-archive/blob/main/scheduling/podaffinity.md>
- <https://github.com/kubernetes/design-proposals-archive/blob/main/scheduling/nodeaffinity.md>
- <https://kubernetes.io/blog/2017/03/advanced-scheduling-in-kubernetes/>

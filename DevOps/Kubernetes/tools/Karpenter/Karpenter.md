## Karpenter의 스케줄링 우선순위

Karpenter는 pod를 스케줄링할 때 아래와 같은 순서로 조건을 체크하여 스케줄할 노드를 선택한다:

1. **기존 노드 활용 시도** (`addToExistingNode`)

   - 이미 존재하는 노드에 추가 가능한지 확인
   - 단, toleration하지 않은 taint가 붙어있으면 불가 (PreferNoSchedule 포함)

2. **생성 중인 노드 활용** (`addToInflightNode`)

   - 현재 생성 중인 노드에 추가 가능한지 확인

3. **새 노드 생성** (`addToNewNodeClaim`)

   - 새로운 노드를 추가해서 스케줄링 가능한지 확인

4. **제약 조건 완화 (Relax)**
   - Affinity, Topology 무시하고 재시도
   - `PreferNoSchedule` 무시하고 재시도

> `PreferNoSchedule` taint가 있는 노드에 pod를 배치할 수 있음에도 불구하고, 완전히 toleration된 새로운 노드를 생성할 수 있다면 그 선택을 우선한다.

### 코드 분석

```go
// trySchedule 함수는 pod 스케줄링을 시도하고, 실패 시 제약 조건을 완화하며 재시도
func (s *Scheduler) trySchedule(ctx context.Context, p *corev1.Pod) error {
    for {
        if ctx.Err() != nil {
            return ctx.Err()
        }
        err := s.add(ctx, p)
        if err == nil {
            return nil
        }
        // Reserved offering error가 아닌 경우에만 제약 조건 완화
        if IsReservedOfferingError(err) {
            return err
        }
        // 더 이상 완화할 수 없으면 루프 종료
        if relaxed := s.preferences.Relax(ctx, p); !relaxed {
            return err
        }
        if e := s.topology.Update(ctx, p); e != nil && !errors.Is(e, context.DeadlineExceeded) {
            log.FromContext(ctx).Error(e, "failed updating topology")
        }
        // pod가 완화되어 요구사항이 변경될 수 있으므로 캐시된 podData 업데이트
        s.updateCachedPodData(p)
    }
}

// add 함수는 순차적으로 노드 배치 옵션을 시도
func (s *Scheduler) add(ctx context.Context, pod *corev1.Pod) error {
    // 먼저 기존 노드에 스케줄링 시도
    if err := s.addToExistingNode(ctx, pod); err == nil {
        return nil
    }
    // 새 노드 클레임을 pod 수가 적은 순으로 정렬
    sort.Slice(s.newNodeClaims, func(a, b int) bool { return len(s.newNodeClaims[a].Pods) < len(s.newNodeClaims[b].Pods) })

    // 생성 중인 노드 선택
    if err := s.addToInflightNode(ctx, pod); err == nil {
        return nil
    }
    if len(s.nodeClaimTemplates) == 0 {
        return fmt.Errorf("nodepool requirements filtered out all available instance types")
    }
    // 새 노드 생성
    err := s.addToNewNodeClaim(ctx, pod)
    if err == nil {
        return nil
    }
    return err
}

// Relax 함수는 순차적으로 제약 조건을 완화
func (p *Preferences) Relax(ctx context.Context, pod *v1.Pod) bool {
    relaxations := []func(*v1.Pod) *string{
        p.removeRequiredNodeAffinityTerm,
        p.removePreferredPodAffinityTerm,
        p.removePreferredPodAntiAffinityTerm,
        p.removePreferredNodeAffinityTerm,
        p.removeTopologySpreadScheduleAnyway}

    // ToleratePreferNoSchedule 설정이 활성화된 경우에만 추가
    if p.ToleratePreferNoSchedule {
        relaxations = append(relaxations, p.toleratePreferNoScheduleTaints)
    }

    for _, relaxFunc := range relaxations {
        if reason := relaxFunc(pod); reason != nil {
            log.FromContext(ctx).WithValues("Pod", klog.KObj(pod)).V(1).Info(fmt.Sprintf("relaxing soft constraints for pod since it previously failed to schedule, %s", lo.FromPtr(reason)))
            return true
        }
    }
    return false
}
```

이러한 개선사항을 통해 Karpenter는 Kubernetes의 `PreferNoSchedule` taint 의미론을 올바르게 구현하게 되었으며, 더 유연하고 효율적인 노드 프로비저닝이 가능해졌다.


---

## Karpenter 리소스

Karpenter는 여러 CRD를 사용하여 노드 프로비저닝을 관리한다.

### EC2NodeClass

EC2 인스턴스의 세부 설정을 정의한다. AMI, 서브넷, 보안 그룹 등을 지정한다.

```yaml
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiSelectorTerms:
    - alias: al2023@latest
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "my-cluster"  # AWS에서 라벨로 지정
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "my-cluster"
  instanceStorePolicy: RAID0
  metadataOptions:
    httpPutResponseHopLimit: 2  # IMDS 인증 요청 시 필요
```

**주요 설정**

- **subnet/securityGroup SelectorTerms**: AWS에서 태그를 붙여서 사용할 리소스 지정
- **httpPutResponseHopLimit**: IMDS(Instance Metadata Service)로 인증 정보를 요청할 때 두 홉을 거치므로 2로 설정해야 함
  - 첫 번째 홉: Container → EC2
  - 두 번째 홉: EC2 → AWS 인증 서버

**kubelet 설정 주의사항**

- `registry-qps` 기본값이 낮아서 이미지 pull이 병목될 수 있음
- buildkit rootless 사용 시 `max_user_namespace` 설정 필요

### NodePool

프로비저닝할 노드의 제약 조건과 동작을 정의한다.

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand", "spot"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["m5.large", "m5.xlarge"]
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
  limits:
    cpu: 1000
    memory: 1000Gi
```

**terminationGracePeriod**

PDB 등으로 제거가 차단된 Pod는 `terminationGracePeriod`에 도달할 때까지 유지된다. 이 시간이 지나면 해당 Pod는 강제로 삭제된다.

### NodeClaim

Karpenter가 실제로 생성한 노드를 나타내는 리소스이다. 직접 생성하지 않고 NodePool에 의해 자동 생성된다.

---

## Disruption

Karpenter의 Disruption은 노드를 자동으로 교체하거나 정리하는 기능이다.

### Control Flow

**Disruption Controller**

중단 가능한 노드를 자동으로 발견하고 필요시 대체 노드를 생성한다.
- Drift → Consolidation 순서로 한 번에 하나씩 실행
- Disruption Budget으로 동시 중단 수 제어

**Termination Controller**

Kubernetes Graceful Node Shutdown 방식으로 노드를 정상 종료한다.

### Automated Graceful Methods

**Consolidation**

사용량이 적거나 빈 노드를 통합한다:
- `WhenEmpty`: 빈 노드만 제거
- `WhenEmptyOrUnderutilized`: 사용량 적은 노드도 대상

**Drift**

설정이 변경된 노드를 새 설정의 노드로 교체한다:
- NodePool 또는 EC2NodeClass 변경 감지
- AMI 업데이트 시 자동 롤링 교체

### Automated Forceful Methods

**Expiration**

`expireAfter` 옵션에 의해 만료된 노드를 교체한다. 주기적인 노드 갱신에 유용하다.

**Interruption**

Spot Instance Interruption 등 AWS 이벤트에 대응한다. SQS 큐를 통해 이벤트를 수신하고 미리 대응한다.

**Node Auto Repair**

비정상 상태(NotReady, Unknown)가 지속되는 노드를 자동으로 교체한다.

### Disruption Budget

동시에 중단될 수 있는 노드 수를 제한한다:

```yaml
spec:
  disruption:
    budgets:
      - nodes: "10%"
      - nodes: "0"
        schedule: "0 9 * * 1-5"  # 평일 업무시간에는 중단 금지
        duration: 8h
```


---

reference

- https://karpenter.sh/docs/
- https://github.com/kubernetes-sigs/karpenter/blob/f71feda1d241cfdd0a3977a946d8fac5dd5ce553/pkg/controllers/provisioning/scheduling/scheduler.gos


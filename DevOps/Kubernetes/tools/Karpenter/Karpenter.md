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

reference

- https://karpenter.sh/docs/
- https://github.com/kubernetes-sigs/karpenter/blob/f71feda1d241cfdd0a3977a946d8fac5dd5ce553/pkg/controllers/provisioning/scheduling/scheduler.gos


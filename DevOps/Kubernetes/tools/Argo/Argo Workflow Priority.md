
**1. Controller에서 Priority 추출** ([controller.go](https://github.com/argoproj/argo-workflows/blob/44f9ea7fed2266321f1e16bff5dcb06a7cd80523/workflow/controller/controller.go#L820))

```go
func getWfPriority(obj interface{}) (int32, time.Time) {
    un, ok := obj.(*unstructured.Unstructured)
    if !ok {
        return 0, time.Now()
    }
    priority, hasPriority, err := unstructured.NestedInt64(un.Object, "spec", "priority")
    if err != nil {
        return 0, un.GetCreationTimestamp().Time
    }
    if !hasPriority {
        priority = 0
    }
    return int32(priority), un.GetCreationTimestamp().Time
}
```

**2. Throttler에 Priority 전달** ([controller.go](https://github.com/argoproj/argo-workflows/blob/44f9ea7fed2266321f1e16bff5dcb06a7cd80523/workflow/controller/controller.go#L911))

```go
AddFunc: func(obj interface{}) {
    key, err := cache.MetaNamespaceKeyFunc(obj)
    if err == nil {
        wfc.wfQueue.AddAfter(key, wfc.Config.InitialDelay.Duration)
        priority, creation := getWfPriority(obj)  // 여기서 priority 추출
        wfc.throttler.Add(key, priority, creation)  // throttler에 전달
    }
},
UpdateFunc: func(old, new interface{}) {
    // ...
    priority, creation := getWfPriority(new)
    wfc.throttler.Add(key, priority, creation)
}
```

**3. Semaphore의 Priority Queue 사용** ([semaphore.go](https://github.com/argoproj/argo-workflows/blob/44f9ea7fed2266321f1e16bff5dcb06a7cd80523/workflow/sync/semaphore.go#L146))

```go
// addToQueue에서 priority queue에 추
func (s *prioritySemaphore) addToQueue(holderKey string, priority int32, creationTime time.Time) error {
    if _, ok := s.lockHolder[holderKey]; ok {
        s.log.Debugf("Lock is already acquired by %s", holderKey)
        return nil
    }
    s.pending.add(holderKey, priority, creationTime)  // Priority Queue에 추가
    s.log.Debugf("Added into queue: %s", holderKey)
    return nil
}

// checkAcquire에서 priority 순서 확인
func (s *prioritySemaphore) checkAcquire(holderKey string, _ *transaction) (bool, bool, string) {
    // ...
    if s.pending.Len() > 0 {
        item := s.pending.peek()  // 가장 높은 priority item을 peek
        if !isSameWorkflowNodeKeys(holderKey, item.key) {
            // 현재 요청한 workflow가 최고 priority가 아니면 대기
            if len(s.lockHolder) < limit {
                s.nextWorkflow(workflowKey(item.key))  // 최고 priority workflow를 먼저 실행
            }
            return false, false, waitingMsg
        }
    }
    // ...
}
```

**4. Priority Queue의 정렬 로직** ([multi_throttler.go](https://github.com/argoproj/argo-workflows/blob/44f9ea7fed2266321f1e16bff5dcb06a7cd80523/workflow/sync/multi_throttler.go#L238))

```go
func (pq priorityQueue) Less(i, j int) bool {
    if pq.items[i].priority == pq.items[j].priority {
        return pq.items[i].creationTime.Before(pq.items[j].creationTime)  // 같은 priority면 생성시간 순
    }
    return pq.items[i].priority > pq.items[j].priority  // 높은 priority가 먼저
}
```

---

1. **Workflow 생성/업데이트 시**: Controller가 `spec.priority` 값을 추출하여 throttler에 전달
2. **Throttling 발생 시**: Priority Queue에서 가장 높은 priority를 가진 workflow가 먼저 선택됨
3. **Semaphore 대기 시**: 높은 priority workflow가 lock을 먼저 획득할 기회를 가짐
4. **동일한 priority일 때**: 생성 시간이 빠른 workflow가 우선


## HPA(Horizontal Pod Autoscaler)

<img width="385" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/dbeeda64-b697-440b-b9eb-2ab16d3d02c0">

- **Horizontal Pod Autoscaler**는 metric server를 통해 파드의 리소스를 감시하여 리소스가 부족한 경우 Controller의 replicas를 증가시켜 파드의 수를 늘린다.
- 위의 그림 처럼 Pod가 수평적으로 증가하는 것을 Scale Out, 수평적으로 감소하는 것을 Scale In 이라고 한다.
- Pod를 증가시키기 때문에 기존의 트래픽이 분산되어 서비스를 더 안정적으로 유지할 수 있게 된다.
- Replica의 수와 상관 없이 돌아갈 수 있는 Stateless 서비스에 적합하다.
- 트래픽이 급증하여 spike가 생기는 경우에 대응할 수 있다.
- 사용하는 매트릭과, 목표하는 매트릭을 계산하여 desire replica 수를 계산한다.

    ```bash
    desiredReplicas = ceil[currentReplicas * ( currentMetricValue / desiredMetricValue )]
    ```

- Pod가 시작하고 얼마 되지 않았을 때는 적절한 메트릭 값이 나오지 않을 수 있으므로, HPA에는 시작한 지 30초 이상 된 포드부터 매트릭이 적용된다. `--horizontal-pod-autoscaler-initial-readiness-delay` 옵션을 사용하여 이 값을 직접 설정할 수 있다.

- **예시**
    ```yaml
    apiVersion: autoscaling/v1
    kind: HorizontalPodAutoscaler
    metadata:
    name: k8s-autoscaler
    spec:
      maxReplicas: 10
      minReplicas: 2
      scaleTargetRef:
        apiVersion: apps/v1
        kind: Deployment
        name: k8s-autoscaler
      metrics:
      - type: Resource
        resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
      behavior:
        scaleDown:
            policies:
            - type: Pods
            value: 4
            periodSeconds: 60
            - type: Percent
            value: 10
            periodSeconds: 60
    ```

### Container resource

- HorizontalPodAutoscaler API는 Pod 뿐만 아니라 각 컨테이너의 리소스도 스케일링의 조건으로 넣을 수 있도록 하는 설정을 제공한다.

```yaml
...
type: ContainerResource
containerResource:
  name: cpu
  container: application
  target:
    type: Utilization
    averageUtilization: 60
...
```

### Scaling policies

- `spec`의 `behavior` 부분에 스케일링을 위한 정책을 설정할 수 있다.
- 위에 정의된 policy부터 적용된다.
- `periodSeconds`는 특정 시간 안에 scale을 조정할 수 있는 최대, 최소값을 정의한다.
  - 아래 예시에서는 60초동안 최대 4개의 replica가 scale down 될 수 있고, 60초 동안 현재의 최대 10% 만큼 scale down될 수 있다.

```yaml
...
behavior:
  scaleDown:
    policies:
    - type: Pods
      value: 4
      periodSeconds: 60
    - type: Percent
      value: 10
      periodSeconds: 60
  scaleUp:
    stabilizationWindowSeconds: 0 # 메트릭들이 계속 변동하여 오차가 발생하는 것을 조정하기 위해 사용하는 옵션
    policies:
    - type: Percent
      value: 100
      periodSeconds: 15
    - type: Pods
      value: 4
      periodSeconds: 15
    selectPolicy: Max
...
```

## VPA(Vertical Pod Autoscaler)

<img width="403" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/39ff5c76-c464-4efa-aa3f-7593a9dab180">

- Vertical Pod Autoscaler는 파드의 리소스를 감시하여, 파드의 리소스가 부족한 경우 파드를 Restart하며 파드의 리소스 제한을 증가시킨다.
- 이처럼 파드의 리소스가 수직적으로 증가하는 것을 Scale Up, 감소하는 것을 Scale Down이라고 한다.
- 리소스 활용률을 최적화하고 비용을 절감할 수 있다.
- 컨테이너의 리소스 Request를 조정한다.

- **예시**
    ```yaml
    apiVersion: autoscaling.k8s.io/v1
    kind: VerticalPodAutoscaler
    metadata:
    name: k8s-autoscaler-vpa
    spec:
        targetRef:
            apiVersion: "apps/v1"
            kind:       Deployment
            name:       k8s-autoscaler
        updatePolicy:
            updateMode: "Auto"
    ```

---

## 여담

- HPA와 VPA는 보통 Kubernetes component에 있는 metric 서버가 제공하는 값을 받아 스케일링 여부를 결정하는데, 원한다면 다른 custom metric을 적용할 수 있다. [(참고)](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#support-for-metrics-apis)

---
참고
- https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- https://medium.com/nerd-for-tech/autoscaling-in-kubernetes-hpa-vpa-ab61a2177950
- https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler
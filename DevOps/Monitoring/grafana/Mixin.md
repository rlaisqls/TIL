
Prometheus는 강력한 모니터링 및 알림 시스템이지만, 유연성이 높은만큼 사전 구성(configuration)이 많이 필요하다.

이에 따라 어떤 애플리케이션에 대한 모니터링을 쉽게 설정할 수 있도록 묶어놓은 것이 Mixin이다.

예시

- <https://github.com/kubernetes-monitoring/kubernetes-mixin>
- <https://github.com/adinhodovic/argo-cd-mixin>

## 목적 및 목표

Monitoring Mixins는 다음과 같은 특성을 가지는 구성 단위이다:

1. **플랫폼 중립성**: Kubernetes 외에도 다양한 환경에서 쉽게 설치할 수 있어야 한다.
2. **애플리케이션과 함께 배포**: 해당 애플리케이션 개발자가 직접 정의하거나 함께 배포할 수 있도록.
3. **협업 및 진화 가능성**: 사용자 정의를 복사해서 사용하는 대신, 원본에 기여하거나 버전 업그레이드가 가능한 구조.
4. **재사용성과 구성 가능성**: 각 조직의 라벨 체계나 환경에 맞춰 설정을 조정하고, 확장이 가능해야 한다.

Monitoring Mixin은 다음 구성 요소를 포함하는 패키지이다

- Prometheus alert 규칙
- Prometheus recording rules
- Grafana dashboard 정의

Mixin은 Jsonnet을 기반으로 구성된다. Jsonnet은 함수형 구성 언어로, 설정 값들을 파라미터화하고, 구성 요소 간의 중복을 줄이며, 구조적 재사용이 용이하다.

### 구성 예시

```jsonnet
{
  _config+:: {
    kubeStateMetricsSelector: 'job="default/kube-state-metrics"',
    allowedNotReadyPods: 0,
  },
  groups+: [
    {
      name: "kubernetes",
      rules: [
        {
          alert: "KubePodNotReady",
          expr: |||
            sum by (namespace, pod) (
              kube_pod_status_phase{%(kubeStateMetricsSelector)s, phase!~"Running|Succeeded"}
            ) > $(allowedNotReadyPods)s
          ||| % $._config,
          "for": "1h",
          labels: {
            severity: "critical",
          },
          annotations: {
            message: "{{ $labels.namespace }}/{{ $labels.pod }} is not ready.",
          },
        },
      ],
    },
  ],
}

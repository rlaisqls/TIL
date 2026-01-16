Datadog은 Anormaly detection 기준 설정을 위해 최대 6주간의 데이터를 학습하고, 아래 세 알고리즘 중 하나에 따라 계산한다.

#### Basic (기본)

- 반복적인 계절성 패턴이 없는 지표에 사용한다.
- 간단한 롤링 윈도우 분위수 계산으로 예상 값의 범위를 결정한다.
- 적은 양의 데이터를 사용하고 변화하는 조건에 빠르게 적응하지만, 계절적 동작이나 장기 추세를 반영할 수 없다.

#### Agile (민첩)

- 계절성이 있고 변동이 예상되는 지표에 사용한다. 이 알고리즘은 지표 수준의 변화에 빠르게 적응한다.
- [SARIMA](https://en.wikipedia.org/wiki/Autoregressive_integrated_moving_average) 알고리즘의 견고한 버전으로, 직전의 과거 데이터를 예측에 반영하여 수준 변화에 대해 빠른 업데이트를 가능하게 한다.
- 단, 최근의 장기 지속 이상치에 대해서는 견고성이 떨어지는 단점이 있다.

#### Robust (견고)

- 계절성이 있고 안정적일 것으로 예상되는 지표에 사용하며, 느린 수준 변화는 이상치로 간주된다.
- [seasonal-trend decomposition](https://en.wikipedia.org/wiki/Decomposition_of_time_series) 알고리즘 중 하나로, 안정적이며 오랫동안 지속되는 이상치가 발생하더라도 예측이 일정하게 유지된다.
- 단, 의도된 수준 변화(예: 코드 변경으로 인한 지표 수준 변화)에 대한 반응이 더 느리다는 단점이 있다.

---
참고

- <https://docs.datadoghq.com/monitors/types/anomaly/#anomaly-detection-algorithms>

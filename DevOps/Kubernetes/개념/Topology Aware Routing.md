
Topology Aware Routing은 Kubernetes Service의 트래픽을 가능한 한 같은 Zone(가용 영역) 내의 엔드포인트로 라우팅하는 기능이다. 클러스터가 여러 Zone에 걸쳐 배포되어 있을 때, 이 기능을 활성화하면 네트워크 지연 시간을 줄이고 Zone 간 데이터 전송 비용을 절감할 수 있다.

멀티 Zone 클러스터에서 Service로 요청이 들어오면, 기본적으로 kube-proxy는 모든 엔드포인트 중 하나를 무작위로 선택한다. 이 말은 Zone A에 있는 Pod가 Zone B나 Zone C에 있는 엔드포인트로 트래픽을 보낼 수도 있다는 것이다.

```
┌─────────────────────────────────────────────────────────────┐
│                        Cluster                               │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐    │
│  │    Zone A     │  │    Zone B     │  │    Zone C     │    │
│  │  ┌─────────┐  │  │  ┌─────────┐  │  │  ┌─────────┐  │    │
│  │  │ Client  │──┼──┼──│Endpoint │  │  │  │Endpoint │  │    │
│  │  │   Pod   │  │  │  │   Pod   │  │  │  │   Pod   │  │    │
│  │  └─────────┘  │  │  └─────────┘  │  │  └─────────┘  │    │
│  │  ┌─────────┐  │  │               │  │               │    │
│  │  │Endpoint │  │  │               │  │               │    │
│  │  │   Pod   │  │  │               │  │               │    │
│  │  └─────────┘  │  │               │  │               │    │
│  └───────────────┘  └───────────────┘  └───────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

왜 이것이 문제가 될까?

1. **네트워크 지연**: Zone 간 통신은 같은 Zone 내 통신보다 지연 시간이 길다
2. **비용**: 클라우드 환경에서 Zone 간 데이터 전송은 추가 비용이 발생한다 (AWS의 경우 GB당 $0.01)
3. **대역폭**: Zone 간 네트워크 대역폭은 제한될 수 있다

Topology Aware Routing을 활성화하면, kube-proxy가 가능한 한 같은 Zone 내의 엔드포인트로 트래픽을 라우팅한다.

## 활성화 방법

Service에 `service.kubernetes.io/topology-mode` 어노테이션을 설정하면 된다.

```yaml

apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    service.kubernetes.io/topology-mode: Auto
spec:
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 8080

```

### 모드 설정

- **Auto**: Kubernetes가 자동으로 토폴로지 힌트를 계산한다. 엔드포인트가 충분하면 Zone 인식 라우팅이 활성화된다.
- **Disabled**: 토폴로지 인식 라우팅을 비활성화한다 (기본값).

> 이전 버전(v1.21~v1.26)에서는 `service.kubernetes.io/topology-aware-hints: auto` 어노테이션을 사용했다. 현재도 호환되지만 새로운 `topology-mode` 어노테이션 사용을 권장한다.

## 동작 원리

그렇다면 Topology Aware Routing은 어떻게 작동할까?

EndpointSlice 컨트롤러가 핵심 역할을 한다. 이 컨트롤러는 각 엔드포인트에 "hints"를 할당하여, 해당 엔드포인트가 어느 Zone에서 소비되어야 하는지 알려준다.

```yaml

apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: my-service-abc
  labels:
    kubernetes.io/service-name: my-service
addressType: IPv4
endpoints:
  - addresses:
      - "10.0.1.5"
    conditions:
      ready: true
    zone: zone-a
    hints:
      forZones:
        - name: zone-a
  - addresses:
      - "10.0.2.10"
    conditions:
      ready: true
    zone: zone-b
    hints:
      forZones:
        - name: zone-b

```

kube-proxy는 이 hints를 읽어서, 자신이 실행 중인 노드의 Zone과 일치하는 엔드포인트만 iptables/ipvs 규칙에 포함시킨다.

### 힌트 계산 과정

EndpointSlice 컨트롤러는 다음 과정을 거쳐 힌트를 계산한다:

1. 각 Zone에 있는 노드의 CPU 코어 수를 기반으로 Zone의 "용량 비율"을 계산한다
2. 각 Zone에 있는 ready 상태의 엔드포인트 수를 파악한다
3. Zone 용량 비율에 맞게 엔드포인트를 각 Zone에 할당한다

예를 들어, 3개의 Zone이 있고 각각 CPU 코어가 100개, 100개, 200개라면:

- Zone A: 25% 비율
- Zone B: 25% 비율
- Zone C: 50% 비율

12개의 엔드포인트가 있다면, Zone A에 3개, Zone B에 3개, Zone C에 6개가 할당된다.

## Safeguards

Topology Aware Routing은 몇 가지 안전 장치(safeguard)가 있어서, 특정 조건에서는 자동으로 비활성화된다.

**비활성화되는 조건**:

- 엔드포인트 수가 Zone 수보다 적은 경우
- 하나 이상의 Zone에 노드가 없는 경우
- 힌트 할당으로 인해 특정 Zone에 과도한 부하가 예상되는 경우 (150% 초과)
- 특정 Zone에 ready 상태의 엔드포인트가 없는 경우

이런 조건에서 hints가 비워지면, kube-proxy는 클러스터의 모든 엔드포인트를 사용하게 된다.

## 주의사항

Topology Aware Routing을 사용할 때 고려해야 할 점들이 있다.

**엔드포인트 분산**

각 Zone에 충분한 엔드포인트가 있어야 한다. 만약 Zone A에만 엔드포인트가 몰려있다면, Zone B와 Zone C의 클라이언트는 결국 Zone A로 트래픽을 보내야 한다.

**불균등한 트래픽**

Zone별 트래픽 양이 다를 수 있다. CPU 코어 기반 용량 비율이 실제 트래픽 패턴과 맞지 않으면, 일부 엔드포인트에 과부하가 걸릴 수 있다.

**Headless Service 미지원**

ClusterIP가 None인 Headless Service에서는 Topology Aware Routing이 동작하지 않는다.

**externalTrafficPolicy와의 관계**

`externalTrafficPolicy: Local`이 설정된 Service에서는 Topology Aware Routing이 무시된다. 이 정책은 이미 노드 로컬 엔드포인트만 사용하도록 제한하기 때문이다.

## 정리

Topology Aware Routing은 멀티 Zone 클러스터에서:

- Zone 간 네트워크 지연을 줄인다
- Zone 간 데이터 전송 비용을 절감한다
- 간단한 어노테이션 하나로 활성화할 수 있다

다만, 각 Zone에 충분한 엔드포인트가 분산되어 있어야 효과적으로 동작하며, 여러 safeguard 조건에 의해 자동으로 비활성화될 수 있다는 점을 기억해야 한다.

---
참고

- <https://kubernetes.io/docs/concepts/services-networking/topology-aware-routing/>
- <https://kubernetes.io/docs/concepts/services-networking/service-topology/>
- <https://kubernetes.io/docs/reference/networking/virtual-ips/> - kube-proxy의 hints 처리

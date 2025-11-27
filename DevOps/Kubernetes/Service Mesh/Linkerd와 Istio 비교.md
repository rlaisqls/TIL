Service Mesh는 마이크로서비스 간의 통신을 관리하는 인프라 계층이다.

Kubernetes 환경에서 가장 많이 사용되는 Service Mesh인 Linkerd와 Istio의 구조와 특징을 비교해보자.

## Service Mesh가 필요한 이유

마이크로서비스 아키텍처에서는 수십, 수백 개의 서비스가 서로 통신한다. 이때 몇 가지 문제가 발생한다.

- 서비스 간 통신은 기본적으로 암호화되지 않는다.
- 어떤 서비스가 어떤 서비스와 통신하는지 파악하기 어렵다.
- 특정 서비스에 장애가 발생하면 연쇄적으로 다른 서비스에 영향을 미친다.
- 트래픽을 세밀하게 제어하기 어렵다.

이런 문제를 해결하기 위해 각 서비스에 프록시를 붙여서 모든 트래픽을 가로채고 관리하는 방식이 등장했다. 이것이 Service Mesh다.

그런데 Service Mesh를 구현하는 방식은 여러 가지가 있다. 대표적인 두 가지가 Linkerd와 Istio다. 이 둘은 어떻게 다를까?

## 공통 구조: Control Plane과 Data Plane

Service Mesh는 크게 두 부분으로 나뉜다.

**Control Plane**: 정책을 관리하고, 프록시에 설정을 배포하며, 인증서를 발급한다. 머리 역할이다.

**Data Plane**: 실제로 트래픽을 처리하는 프록시들이다. 손발 역할이다.

Linkerd와 Istio 모두 이 구조를 따르지만, 각 부분을 구현하는 방식이 다르다. 특히 Data Plane의 프록시가 핵심적인 차이점이다.

## Linkerd의 구조

Linkerd는 2017년 CNCF에 합류한 최초의 Service Mesh다. 현재는 CNCF Graduated 프로젝트로, 프로덕션 환경에서 검증되었다.

### Control Plane

Linkerd의 Control Plane은 단일 네임스페이스(기본값: `linkerd`)에 배포되며, 세 가지 핵심 컴포넌트가 있다.

- **Identity**: mTLS 인증서를 발급하는 CA(Certificate Authority)다. 각 프록시에 24시간마다 갱신되는 TLS 인증서를 발급한다.
- **Destination**: 서비스 디스커버리를 담당한다. 프록시가 "이 서비스는 어디에 있어?"라고 물으면 주소를 알려준다.
- **Proxy Injector**: 새로운 Pod가 생성될 때 자동으로 프록시를 주입하는 Admission Controller다.

### Data Plane: linkerd2-proxy

여기가 Linkerd의 가장 큰 특징이다. Linkerd는 자체 개발한 `linkerd2-proxy`를 사용한다.

linkerd2-proxy는 Rust로 작성된 초경량 마이크로 프록시다. 왜 Rust일까?

Service Mesh 프록시는 까다로운 요구사항을 가진다.

1. 모든 Pod에 하나씩 배포되므로 메모리와 CPU 사용량이 최소화되어야 한다.
2. 모든 트래픽이 프록시를 거치므로 지연 시간이 최소화되어야 한다.
3. 민감한 데이터를 다루므로 보안 취약점이 없어야 한다.

Rust는 이 세 가지를 모두 만족한다.

- 가비지 컬렉터가 없어서 tail latency가 예측 가능하다. Go 같은 GC 언어는 GC가 실행될 때 지연이 발생할 수 있다.
- 메모리 안전성이 언어 차원에서 보장된다. C/C++에서 흔한 버퍼 오버플로우, use-after-free 같은 취약점이 구조적으로 불가능하다.
- 네이티브 코드로 컴파일되어 빠르다.

linkerd2-proxy는 범용 프록시가 아니다. Service Mesh sidecar라는 단 하나의 용도만을 위해 설계되었다. 불필요한 기능이 없으므로 더 가볍고 빠르다.

### 트래픽 흐름

Linkerd에서 트래픽이 어떻게 흐르는지 살펴보자.

```
[Pod A] → [outbound proxy] → [inbound proxy] → [Pod B]
```

1. Pod A가 Pod B에 요청을 보낸다.
2. `linkerd-init` 컨테이너가 설정한 iptables 규칙에 의해 트래픽이 outbound proxy로 리다이렉트된다.
3. Outbound proxy가 서비스 디스커버리, 로드 밸런싱, 재시도, 타임아웃을 처리한다.
4. Inbound proxy가 인증 정책을 적용하고 트래픽을 Pod B로 전달한다.
5. 양쪽 프록시가 메트릭을 수집하여 Control Plane에 보고한다.

기본적으로 모든 TCP 트래픽에 mTLS가 적용된다. 별도의 설정 없이도 서비스 간 통신이 암호화된다.

## Istio의 구조: Sidecar Mode

Istio는 2017년 Google, IBM, Lyft가 공동으로 발표한 Service Mesh다. 2022년 CNCF에 기증되어 현재는 Graduated 프로젝트다.

Istio는 두 가지 Data Plane 모드를 지원한다. 먼저 전통적인 Sidecar Mode를 살펴보자.

### Control Plane: Istiod

Istio의 Control Plane은 `istiod`라는 단일 바이너리로 통합되어 있다. 이전에는 Pilot, Citadel, Galley 등 여러 컴포넌트로 분리되어 있었는데, 운영 복잡성을 줄이기 위해 하나로 합쳐졌다.

istiod가 하는 일:

- 서비스 디스커버리
- 프록시 설정 배포 (xDS API)
- 인증서 발급 및 관리

### Data Plane: Envoy

Istio는 Envoy 프록시를 사용한다. Envoy는 Lyft에서 개발한 C++ 기반의 고성능 프록시로, L7 프록시 영역에서 사실상 표준이 되었다.

Envoy는 범용 프록시다. HTTP, gRPC, TCP, WebSocket 등 다양한 프로토콜을 지원하고, 헤더 조작, 레이트 리밋, 리버스 프록시 등 수많은 기능을 제공한다.

이런 범용성은 장점이자 단점이다.

**장점**: 복잡한 트래픽 제어가 가능하다. 카나리 배포, 장애 주입, A/B 테스트 등 다양한 시나리오를 구현할 수 있다.
**단점**: 리소스를 많이 사용한다. Service Mesh sidecar로 쓰기엔 무겁다.

벤치마크에 따르면, Envoy sidecar는 약 0.5 CPU 코어와 50MB 메모리를 사용한다. 대규모 환경에서는 이 오버헤드가 상당하다.

### 트래픽 흐름

```
[Pod A] → [Envoy sidecar] → [Envoy sidecar] → [Pod B]
```

Linkerd와 기본적으로 같은 구조다. istio-init 컨테이너가 iptables를 설정하고, 모든 트래픽이 Envoy를 통과한다.

## Istio의 구조: Ambient Mode

2022년 Istio는 새로운 Data Plane 아키텍처인 Ambient Mode를 발표했다. 2024년 11월 Istio 1.24에서 GA(General Availability)가 되었다.

왜 새로운 모드가 필요했을까?

Sidecar 모드의 근본적인 문제는 모든 Pod에 프록시가 필요하다는 것이다. 1000개의 Pod가 있으면 1000개의 Envoy가 필요하다. 각각 0.5 CPU, 50MB 메모리를 사용하면 총 500 CPU 코어, 50GB 메모리가 프록시에만 사용된다.

Ambient Mode는 이 문제를 해결하기 위해 프록시를 공유하는 방식을 도입했다.

### 핵심 아이디어: L4와 L7의 분리

Service Mesh가 제공하는 기능은 크게 두 가지로 나눌 수 있다.

**L4 기능**: mTLS, TCP 레벨 인가, 기본적인 텔레메트리
**L7 기능**: HTTP 라우팅, 헤더 기반 정책, 상세한 메트릭

많은 서비스는 L4 기능만 있어도 충분하다. 그런데 Sidecar 모드에서는 L4만 필요해도 전체 Envoy를 배포해야 한다.

Ambient Mode는 L4와 L7을 분리한다.

### ztunnel: L4 전용 노드 프록시

ztunnel(Zero-Trust Tunnel)은 Rust로 작성된 경량 L4 프록시다. 각 노드에 DaemonSet으로 배포된다.

```
Node 1                    Node 2
┌──────────────────┐     ┌──────────────────┐
│  Pod A  Pod B    │     │  Pod C  Pod D    │
│    │      │      │     │    │      │      │
│    └──┬───┘      │     │    └──┬───┘      │
│       │          │     │       │          │
│  [ztunnel]       │     │  [ztunnel]       │
└───────┼──────────┘     └───────┼──────────┘
        │         HBONE          │
        └────────────────────────┘
```

ztunnel이 하는 일:

- mTLS 터널링 (HBONE 프로토콜 사용)
- L4 인가 정책
- 기본적인 텔레메트리

ztunnel은 의도적으로 L4로 제한되어 있다. L7 기능이 없으므로 매우 가볍다. 벤치마크에 따르면 약 0.06 vCPU, 12MB 메모리를 사용한다.

### waypoint proxy: L7 전용 프록시

L7 기능이 필요한 서비스를 위해 waypoint proxy가 있다. 이 프록시는 Envoy 기반이지만, Pod마다 배포되지 않고 네임스페이스 단위로 배포된다.

L7 기능이 필요한 서비스만 waypoint를 통과한다. 필요하지 않은 서비스는 ztunnel만 거친다.

```
                    [waypoint proxy]
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
     [Pod A]          [Pod B]           [Pod C]
```

### 리소스 효율성

Ambient Mode의 리소스 효율성을 구체적인 숫자로 살펴보자.

1000 RPS, 1KB 페이로드 기준:

- Sidecar Envoy: 0.20 vCPU, 60MB 메모리
- Waypoint: 0.25 vCPU, 60MB 메모리
- ztunnel: 0.06 vCPU, 12MB 메모리

L4만 필요한 서비스의 경우, Ambient Mode는 Sidecar 대비 70% 이상의 CPU를 절약한다. Solo.io의 테스트에서는 네임스페이스당 약 1.3 CPU 코어를 절약했다고 한다.

또한 컨테이너 수가 줄어든다. Sidecar 모드에서 1000개 Pod는 2000개 컨테이너(애플리케이션 + sidecar)를 의미한다. Ambient Mode에서는 1000개 컨테이너 + 노드당 1개 ztunnel이다. 운영 복잡성이 크게 줄어든다.

### 레이턴시 성능

레이턴시도 개선된다.

1KB HTTP 요청의 p90 레이턴시:

- Sidecar Mode: ~0.63ms
- Ambient Mode (L4): ~0.16ms

L7 처리는 L4 처리보다 훨씬 복잡하다. HTTP 파싱, 헤더 검사, 라우팅 규칙 적용 등의 작업이 필요하다. Sidecar Mode에서는 모든 트래픽이 이 과정을 거친다. Ambient Mode에서는 L4만 필요한 트래픽은 가벼운 ztunnel만 통과한다.

## Linkerd vs Istio 성능 비교

이제 Linkerd와 Istio(Sidecar Mode)를 직접 비교해보자.

### 레이턴시

2024년 LiveWyer의 벤치마크에 따르면:

200 RPS 기준:

- Linkerd 중앙값: 17ms (베이스라인 대비 +11ms)
- Istio 중앙값: 25ms (베이스라인 대비 +19ms)

최대 레이턴시:

- Linkerd: 92ms
- Istio: 221ms

Linkerd가 Istio보다 40%~400% 더 낮은 레이턴시 오버헤드를 보인다.

### 리소스 사용량

Linkerd의 벤치마크에 따르면:

- Linkerd는 Istio 대비 약 1/8의 CPU를 사용한다.
- 메모리 사용량은 약 1/9 수준이다.

왜 이런 차이가 날까?

1. 프록시 설계 철학: linkerd2-proxy는 Service Mesh 전용으로 설계되었고, Envoy는 범용 프록시다.
2. 언어: Rust vs C++. Rust가 메모리 효율성에서 약간 앞선다.
3. 기능 범위: Linkerd는 핵심 기능에 집중하고, Istio는 더 많은 기능을 제공한다.

### 기능 비교

리소스 효율성에서는 Linkerd가 앞서지만, 기능 면에서는 Istio가 더 풍부하다.

| 기능 | Linkerd | Istio |
|------|---------|-------|
| mTLS | O | O |
| 트래픽 라우팅 | 기본적 | 고급 |
| 카나리 배포 | 제한적 | 완전 지원 |
| 장애 주입 | X | O |
| 멀티 클러스터 | O | O |
| WebAssembly 확장 | X | O |
| VM 지원 | 제한적 | 완전 지원 |

Istio의 강점은 복잡한 트래픽 관리다. 헤더 기반 라우팅, 가중치 기반 트래픽 분배, 장애 주입 테스트 등이 필요하다면 Istio가 적합하다.

Linkerd의 강점은 단순함과 효율성이다. "Service Mesh가 필요하지만 복잡한 기능은 필요 없다"면 Linkerd가 좋은 선택이다.

## 어떤 것을 선택해야 할까?

음. 이제 세 가지 선택지가 있다.

### Linkerd를 선택해야 하는 경우

- 리소스 효율성이 중요하다.
- 낮은 레이턴시가 필수다.
- 운영 복잡성을 최소화하고 싶다.
- 기본적인 mTLS, 옵저버빌리티, 재시도/타임아웃만 필요하다.
- 팀의 Service Mesh 경험이 적다.

### Istio Sidecar Mode를 선택해야 하는 경우

- 고급 트래픽 관리 기능이 필요하다 (카나리 배포, 장애 주입 등).
- 기존에 Envoy를 사용하고 있어서 익숙하다.
- WebAssembly 확장이 필요하다.
- VM 워크로드도 메시에 포함해야 한다.
- 리소스 비용보다 기능이 더 중요하다.

### Istio Ambient Mode를 선택해야 하는 경우

- Istio의 기능이 필요하지만 리소스 오버헤드가 걱정된다.
- 대부분의 서비스는 L4 기능만 필요하고, 일부만 L7이 필요하다.
- Sidecar 주입으로 인한 운영 복잡성을 줄이고 싶다.
- 새로운 프로젝트여서 GA 직후의 기술을 도입해도 괜찮다.

다만 Ambient Mode는 2024년 11월에 GA가 되었으므로, Sidecar Mode만큼 battle-tested되지는 않았다. 보수적인 환경이라면 좀 더 지켜보는 것이 좋다.

## 정리

Service Mesh의 두 주요 구현체인 Linkerd와 Istio를 살펴보았다.

- **Service Mesh**는 마이크로서비스 간 통신을 관리하는 인프라 계층이다. mTLS, 옵저버빌리티, 트래픽 관리를 제공한다.

- **Linkerd**는 Rust 기반의 경량 프록시(linkerd2-proxy)를 사용한다. 리소스 효율성과 단순함이 강점이다. Istio 대비 1/8의 CPU, 1/9의 메모리를 사용하고, 40%~400% 낮은 레이턴시 오버헤드를 보인다.

- **Istio Sidecar Mode**는 Envoy 프록시를 모든 Pod에 배포한다. 고급 트래픽 관리 기능이 풍부하지만, 리소스 오버헤드가 크다.

- **Istio Ambient Mode**는 L4와 L7을 분리하여 리소스 효율성을 높였다. ztunnel(노드 단위 L4 프록시)과 waypoint(선택적 L7 프록시)를 사용한다. Sidecar 대비 70% 이상의 리소스를 절약할 수 있다.

선택은 요구사항에 따라 달라진다.

- 단순함과 효율성: Linkerd
- 풍부한 기능: Istio Sidecar
- 효율성 + Istio 기능: Istio Ambient

---
참고

- Linkerd 공식 문서: <https://linkerd.io/2-edge/reference/architecture/>
- Istio 공식 문서: <https://istio.io/latest/docs/ops/deployment/architecture/>
- Istio Ambient Mode GA 발표: <https://istio.io/latest/blog/2024/ambient-reaches-ga/>
- LiveWyer 2024 Service Mesh 벤치마크: <https://livewyer.io/blog/2024/05/08/comparison-of-service-meshes/>
- Linkerd vs Istio 비교 (Buoyant): <https://www.buoyant.io/linkerd-vs-istio>
- Why Linkerd doesn't use Envoy: <https://linkerd.io/2020/12/03/why-linkerd-doesnt-use-envoy/>
- Istio Ambient vs Sidecar 네트워크 비용 비교: <https://jimmysong.io/en/blog/istio-sidecar-vs-ambient-network-cost-performance/>

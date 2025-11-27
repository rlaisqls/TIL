
Gateway API는 Kubernetes에서 트래픽 라우팅을 관리하기 위한 차세대 API이다.

기존 Ingress의 한계를 극복하고 더 유연하고 표준화된 방식으로 L4/L7 트래픽을 관리할 수 있다. 왜 이런 변화가 필요했고, 어떤 구현체를 선택해야 할지 알아보자.

## Ingress의 한계

Ingress는 오랫동안 Kubernetes에서 외부 트래픽을 내부 서비스로 라우팅하는 표준이었다. 하지만 사용하다 보면 몇 가지 문제를 마주하게 된다.

**프로토콜 제약**

Ingress는 HTTP/HTTPS만 지원한다. TCP나 UDP 트래픽을 라우팅하려면 별도의 Service를 NodePort나 LoadBalancer로 노출해야 한다. gRPC도 직접적으로 지원하지 않는다.

**어노테이션 지옥**

Ingress 스펙 자체는 매우 단순하다. 그래서 트래픽 분할, 헤더 조작, 리다이렉트 같은 고급 기능은 어노테이션으로 구현해야 한다.

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "8m"
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "20"
```

문제는 이 어노테이션이 구현체마다 다르다는 것이다. NGINX Ingress에서 Traefik으로 옮기려면? 모든 어노테이션을 다시 작성해야 한다. 이식성이 사실상 없다.

**역할 분리의 부재**

Ingress는 단일 리소스에 모든 설정이 들어간다. 인프라 팀이 관리해야 할 로드밸런서 설정과 개발팀이 관리해야 할 라우팅 규칙이 뒤섞여 있다. RBAC으로 분리하려 해도 깔끔하지 않다.

이런 문제들을 해결하기 위해 Gateway API가 등장했다.

## Gateway API의 구조

Gateway API는 세 가지 핵심 리소스로 구성된다. 각 리소스가 분리되어 있어서 역할별로 관리 책임을 나눌 수 있다.

**GatewayClass**

어떤 컨트롤러가 Gateway를 구현할지 정의한다. StorageClass가 스토리지 프로비저너를 지정하는 것과 비슷하다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: istio
spec:
  controllerName: istio.io/gateway-controller
```

인프라 제공자가 클러스터에 한 번 설정해두면, 다른 팀들은 이 GatewayClass를 참조해서 Gateway를 만들면 된다.

**Gateway**

실제 로드밸런서 인스턴스를 정의한다. 어떤 포트에서 어떤 프로토콜로 트래픽을 받을지, TLS 설정은 어떻게 할지 등을 명시한다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
  namespace: gateway-infra
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 80
    protocol: HTTP
  - name: https
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: my-cert
```

클러스터 운영자나 플랫폼 팀이 관리한다. TLS 인증서 같은 민감한 설정이 여기에 들어간다.

**HTTPRoute (그리고 다른 Route들)**

실제 라우팅 규칙을 정의한다. 어떤 호스트, 어떤 경로로 들어온 요청을 어떤 서비스로 보낼지 명시한다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-route
  namespace: my-app
spec:
  parentRefs:
  - name: my-gateway
    namespace: gateway-infra
  hostnames:
  - "api.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /v1
    backendRefs:
    - name: my-service
      port: 8080
```

애플리케이션 개발자가 자신의 네임스페이스에서 관리한다. `parentRefs`로 어떤 Gateway에 연결할지 지정한다.

이 분리가 왜 중요할까?

## 역할 기반 설계

Ingress에서는 하나의 리소스에 모든 권한이 필요했다. Gateway API는 네 가지 역할로 책임을 분리한다.

```
┌─────────────────────────────────────────────────────────────┐
│ 인프라 제공자 (Infrastructure Provider)                      │
│ → GatewayClass 정의                                         │
│ → 클라우드 제공자, 플랫폼 팀                                   │
├─────────────────────────────────────────────────────────────┤
│ 클러스터 운영자 (Cluster Operator)                           │
│ → Gateway 생성 및 관리                                       │
│ → TLS 인증서, 포트 설정                                      │
├─────────────────────────────────────────────────────────────┤
│ 애플리케이션 개발자 (Application Developer)                   │
│ → HTTPRoute 정의                                            │
│ → 자신의 서비스에 대한 라우팅 규칙                             │
└─────────────────────────────────────────────────────────────┘
```

개발자는 Gateway 네임스페이스에 접근하지 않아도 된다. 자신의 네임스페이스에서 HTTPRoute만 만들고, `parentRefs`로 공유 Gateway를 참조하면 끝이다.

이렇게 하면 플랫폼 팀은 Gateway 설정을 중앙에서 관리하면서도, 개발팀에게 라우팅 자율권을 줄 수 있다.

## Ingress에서 없던 기능들

Gateway API는 어노테이션 없이 스펙 자체에서 고급 기능을 지원한다.

**트래픽 분할 (카나리 배포)**

```yaml
rules:
- backendRefs:
  - name: v1-service
    port: 8080
    weight: 90
  - name: v2-service
    port: 8080
    weight: 10
```

새 버전으로 10%만 트래픽을 보내는 카나리 배포가 스펙 한 줄로 가능하다.

**헤더 기반 라우팅**

```yaml
rules:
- matches:
  - headers:
    - name: X-Version
      value: beta
  backendRefs:
  - name: beta-service
    port: 8080
```

특정 헤더가 있는 요청만 베타 서비스로 보낼 수 있다.

**요청/응답 수정**

```yaml
rules:
- filters:
  - type: RequestHeaderModifier
    requestHeaderModifier:
      add:
      - name: X-Request-ID
        value: "generated-id"
  - type: ResponseHeaderModifier
    responseHeaderModifier:
      remove:
      - X-Powered-By
```

프록시 단에서 헤더를 추가하거나 제거할 수 있다.

**다양한 프로토콜 지원**

- `HTTPRoute`: HTTP/HTTPS 트래픽
- `TCPRoute`: TCP 트래픽 (데이터베이스 등)
- `UDPRoute`: UDP 트래픽 (DNS, 게임 서버 등)
- `GRPCRoute`: gRPC 트래픽
- `TLSRoute`: TLS 패스스루

## 구현체 비교

Gateway API는 스펙이고, 실제 구현은 여러 프로젝트에서 제공한다. 2024년 기준 주요 구현체들을 살펴보자.

**Istio**

서비스 메시로 유명한 Istio는 Gateway API의 주요 기여자이기도 하다. 북-남(외부→내부) 트래픽과 동-서(서비스↔서비스) 트래픽 모두 Gateway API로 관리할 수 있다.

- 장점: 가장 성숙한 구현체, 풍부한 트래픽 관리 기능, mTLS 지원
- 단점: 사이드카 프록시로 인한 리소스 오버헤드, 복잡한 설정
- 적합한 경우: 서비스 메시가 필요하거나, 이미 Istio를 사용 중인 경우

**Envoy Gateway**

Envoy 프로젝트의 공식 Gateway API 구현체다. Istio 없이 Envoy만 사용하고 싶을 때 선택한다.

- 장점: Envoy 생태계 활용, Istio보다 가벼움, 활발한 개발
- 단점: 서비스 메시 기능 없음 (인그레스 전용)
- 적합한 경우: 순수 인그레스 컨트롤러가 필요한 경우

**Cilium**

eBPF 기반 네트워킹으로 주목받는 Cilium도 Gateway API를 지원한다. 사이드카 없이 커널 레벨에서 서비스 메시 기능을 제공한다.

- 장점: eBPF로 높은 성능, 사이드카리스 서비스 메시, 네트워크 정책 통합
- 단점: 대규모 라우트에서 확장성 이슈 보고됨, 비교적 새로운 구현
- 적합한 경우: eBPF 기반 네트워킹을 사용하거나, 사이드카 오버헤드를 피하고 싶은 경우

**NGINX Gateway Fabric**

NGINX 기반의 공식 Gateway API 구현체다. 기존 NGINX Ingress Controller와는 별개 프로젝트다.

- 장점: NGINX의 안정성과 성능, 익숙한 기술 스택
- 단점: NGINX Ingress 대비 기능이 아직 부족
- 적합한 경우: NGINX에 익숙하고, Gateway API로 전환하려는 경우

**Traefik**

클라우드 네이티브 리버스 프록시 Traefik도 Gateway API v1.4.0을 지원한다.

- 장점: 자동 서비스 디스커버리, Let's Encrypt 통합, 가벼움
- 단점: 일부 고급 기능은 Traefik 자체 CRD 필요
- 적합한 경우: 간단한 설정으로 빠르게 시작하고 싶은 경우

**컨트롤 플레인 리소스 비교**

벤치마크에 따르면 컨트롤 플레인 CPU 사용량은:

```
Cilium > NGINX ≈ Envoy Gateway > Istio ≈ kgateway
```

Cilium은 Istio 대비 약 7.5배, Envoy Gateway는 약 2.9배 CPU를 사용한다. 대규모 클러스터에서는 이 차이가 유의미할 수 있다.

## Ingress NGINX의 지원 종료

2025년 11월, Kubernetes SIG Network에서 Ingress NGINX Controller의 지원 종료를 공식 발표했다. 타임라인은 다음과 같다:

- 2026년 3월까지: Best-effort 유지보수 (버그 수정, 보안 패치)
- 2026년 3월 이후: 더 이상의 릴리스, 버그 수정, 보안 취약점 대응 없음

공식 블로그에 따르면, 프로젝트의 인기에 비해 메인테이너가 항상 부족했다 한다. 수년간 한두 명이 퇴근 후와 주말에 개인 시간을 들여 개발해왔다고.

기술 부채도 문제였다. `snippets` 어노테이션으로 임의의 NGINX 설정을 주입할 수 있는 기능은 한때 유연성으로 여겨졌지만, 지금은 심각한 보안 결함으로 분류된다. 과거의 유연함이 현재의 기술 부채가 된 것이다.

Kubernetes 공식 블로그는 Gateway API로의 전환을 권장하고 있다:

> Gateway API is the modern, powerful, and flexible successor to the Ingress API. It is the future of Kubernetes traffic management.

## 마이그레이션 고려사항

Ingress에서 Gateway API로 전환할 때 알아둬야 할 차이점들이 있다.

**Default Backend가 없다**

Ingress의 `defaultBackend`는 Gateway API에 없다. 대신 catch-all 경로를 명시적으로 정의해야 한다:

```yaml
rules:
- matches:
  - path:
      type: PathPrefix
      value: /
  backendRefs:
  - name: default-service
    port: 80
```

**TLS 설정 위치가 다르다**

Ingress에서는 `tls` 섹션이 호스트별로 인증서를 지정했다. Gateway API에서는 Gateway의 `listeners`에서 TLS를 설정한다:

```yaml
# Ingress
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls

# Gateway API
spec:
  listeners:
  - name: https
    port: 443
    protocol: HTTPS
    hostname: api.example.com
    tls:
      certificateRefs:
      - name: api-tls
```

**IngressClass → GatewayClass + parentRefs**

어떤 컨트롤러를 사용할지 지정하는 방식이 다르다:

```yaml
# Ingress
spec:
  ingressClassName: nginx

# HTTPRoute
spec:
  parentRefs:
  - name: my-gateway
    namespace: gateway-infra
```

HTTPRoute는 특정 Gateway를 직접 참조한다. 더 명시적이고 유연하다.

**자동 변환 도구**

Kubernetes SIG에서 제공하는 `ingress2gateway` 도구로 기본적인 변환을 자동화할 수 있다:

```bash
ingress2gateway print --input-file ingress.yaml
```

하지만 어노테이션 기반 기능은 수동으로 변환해야 한다.

## 정리

Gateway API는 Ingress의 여러 한계를 해결한다.

- 프로토콜 제약 → HTTP, TCP, UDP, gRPC, TLS 모두 지원
- 어노테이션 지옥 → 스펙 자체에서 고급 기능 지원, 구현체 간 이식성 확보
- 역할 분리 부재 → GatewayClass, Gateway, Route로 책임 분리

구현체 선택은 요구사항에 따라 달라진다:

- 서비스 메시가 필요하면 Istio
- 순수 인그레스만 필요하면 Envoy Gateway 또는 NGINX Gateway Fabric
- eBPF 기반 고성능이 필요하면 Cilium
- 빠른 시작이 필요하면 Traefik

---
참고

- <https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/>
- <https://gateway-api.sigs.k8s.io/>
- <https://gateway-api.sigs.k8s.io/implementations/>
- <https://gateway-api.sigs.k8s.io/guides/migrating-from-ingress/>
- <https://github.com/kubernetes-sigs/ingress2gateway>
- <https://konghq.com/blog/engineering/gateway-api-vs-ingress>
- <https://www.tigera.io/blog/is-it-time-to-migrate-a-practical-look-at-kubernetes-ingress-vs-gateway-api/>
- <https://github.com/howardjohn/gateway-api-bench>
- <https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/>
- <https://docs.cilium.io/en/latest/network/servicemesh/gateway-api/gateway-api/>

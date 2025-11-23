Ingress는 클러스터 외부에서 내부 서비스로의 HTTP/HTTPS 라우팅을 정의하는 Kubernetes 리소스이다.

Ingress는 두 부분으로 구성된다:

1. Ingress yaml 리소스: 라우팅 규칙을 정의하는 YAML 설정
2. Ingress Controller: 실제로 트래픽을 처리하는 구현체 (NGINX, Traefik, HAProxy 등)

이 분리가 중요한 이유는, Kubernetes 자체는 Ingress 규칙만 정의할 뿐 실제 구현은 제공하지 않기 때문이다. 사용자가 원하는 Ingress Controller를 선택해서 설치해야 한다.

### 리소스 예시

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
spec:
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 80
    - host: admin.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: admin
                port:
                  number: 80
```

이제 하나의 LoadBalancer로 모든 트래픽을 받아서, 호스트명과 경로에 따라 적절한 서비스로 라우팅할 수 있다.

HTTPS를 사용하려면 TLS 인증서를 Secret으로 저장하고 Ingress에서 참조한다:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: <base64 encoded cert>
  tls.key: <base64 encoded key>
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  tls:
    - hosts:
        - example.com
      secretName: tls-secret
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
```

Ingress Controller가 이 설정을 읽어서 자동으로 HTTPS를 처리한다.

### 동작 원리

1. Ingress Controller가 클러스터 내에 Deployment로 배포된다
2. Controller는 Kubernetes API를 watch하여 Ingress 리소스의 변경을 감지한다
3. 새로운 Ingress 규칙이 생성되면, Controller는 자신의 설정을 동적으로 업데이트한다
   - NGINX Ingress Controller라면 nginx.conf를 재생성하고 reload
   - Traefik이라면 내부 라우팅 테이블을 업데이트
4. Controller 앞에는 LoadBalancer 타입의 Service가 있어서 외부 트래픽을 받는다
5. 들어온 요청의 Host 헤더와 경로를 보고 적절한 백엔드 Service로 프록시한다

예를 들어 NGINX Ingress Controller의 경우:

```
외부 요청 (example.com/api/users)
    ↓
LoadBalancer Service (외부 IP)
    ↓
NGINX Ingress Controller Pod
    ↓ (nginx.conf의 규칙에 따라 라우팅)
api Service
    ↓
api Pod들
```

## Ingress의 한계

Ingress는 많은 문제를 해결했지만, 사용하다 보면 한계가 드러난다.

### 1. 제한적인 라우팅 기능

Ingress는 기본적으로 Host와 Path만으로 라우팅한다. 하지만 실제로는 더 복잡한 라우팅이 필요할 때가 많다:

- HTTP 헤더 기반 라우팅 (예: `User-Agent`에 따라 다른 서비스로)
- 쿼리 파라미터 기반 라우팅
- HTTP 메서드 기반 라우팅 (GET/POST/PUT 등)
- 가중치 기반 트래픽 분산 (카나리 배포)

이런 기능들을 사용하려면 annotation을 사용해야 한다:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: canary-ingress
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "20"
spec:
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-v2
                port:
                  number: 80
```

문제는 이 annotation이 표준이 아니라는 것이다. 각 Ingress Controller마다 다른 annotation을 사용한다.

### 2. Annotation 의존성

Ingress 스펙 자체가 매우 제한적이라, 실제 기능은 대부분 annotation에 의존한다:

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

이런 annotation들은:

- Controller마다 다르다 (NGINX와 Traefik이 서로 호환되지 않음)
- 타입 체크가 없다 (오타가 있어도 에러가 나지 않고 조용히 무시됨)
- 검증이 어렵다
- 문서화가 분산되어 있다

### 3. TCP/UDP 지원 부족

Ingress는 HTTP/HTTPS에 특화되어 있다. TCP나 UDP 프로토콜을 사용하는 서비스(예: 데이터베이스, gRPC, DNS)는 Ingress로 처리할 수 없다.

대신 ConfigMap을 통해 우회하는 방법을 써야 한다:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-services
  namespace: ingress-nginx
data:
  5432: "default/postgres:5432"
  3306: "default/mysql:3306"
```

### 4. 표준화의 부재

가장 큰 문제는 Ingress가 너무 최소 스펙이라는 것이다. 실제 기능은 각 구현체(Controller)에 맡겨져 있고, 이들 사이에 이식성이 없다.

NGINX Ingress에서 Traefik으로 마이그레이션하려면 모든 annotation을 다시 작성해야 한다. 이것은 Kubernetes의 철학인 "선언적이고 이식 가능한 설정"과 맞지 않는다.

## Gateway API

이런 문제들을 해결하기 위해 Kubernetes SIG-Network에서 Gateway API를 설계했다. Gateway API는 Ingress의 단순한 대체가 아니라, 완전히 새로운 접근 방식이다.

### 설계 철학

Gateway API의 핵심 설계 원칙:

1. 역할 지향적 (Role-oriented): 플랫폼 운영자와 애플리케이션 개발자의 역할을 명확히 분리
2. 확장 가능 (Extensible): annotation 대신 CRD를 통한 타입 안전한 확장
3. 표현력 (Expressive): 복잡한 라우팅을 표준 방식으로 표현
4. 이식성 (Portable): 다양한 구현체 간 호환성

### 핵심 리소스

Gateway API는 세 가지 주요 리소스로 구성된다:

**GatewayClass**

인프라 제공자가 정의하는 템플릿이다. Ingress의 IngressClass와 유사하지만 더 구조화되어 있다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: istio
spec:
  controllerName: istio.io/gateway-controller
  description: Istio-based Gateway
```

플랫폼 팀이 관리하며, 어떤 Gateway Controller를 사용할지 정의한다.

**Gateway**

실제 로드밸런서 인스턴스를 나타낸다. 리스너(포트, 프로토콜, TLS 설정)를 정의한다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main-gateway
  namespace: infra
spec:
  gatewayClassName: istio
  listeners:
    - name: http
      protocol: HTTP
      port: 80
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: tls-cert
```

플랫폼 팀이 관리하며, 네트워크 진입점을 정의한다.

**HTTPRoute**

트래픽 라우팅 규칙을 정의한다. 애플리케이션 팀이 관리한다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: frontend-route
  namespace: apps
spec:
  parentRefs:
    - name: main-gateway
      namespace: infra
  hostnames:
    - "example.com"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: api
          port: 80
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: frontend
          port: 80
```

### 역할 분리의 실현

Gateway API의 가장 큰 장점은 역할을 명확히 분리한다는 것이다.
따라서 필요에 따라 RBAC를 세부적으로 설정할 수 있게 된다.

- 플랫폼
  - GatewayClass 선택 (어떤 구현체를 사용할지)
  - Gateway 생성 (몇 개의 진입점, 어떤 포트, TLS 설정)
  - 네트워크 정책 (방화벽, 보안)

- 애플리케이션
  - HTTPRoute 생성 (자신의 서비스로 가는 라우팅 규칙)
  - 서비스 배포 및 관리

```yaml
# ex. 플랫폼 팀만 Gateway를 생성/수정할 수 있음
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: gateway-admin
  namespace: infra
rules:
  - apiGroups: ["gateway.networking.k8s.io"]
    resources: ["gateways"]
    verbs: ["*"]
---
# 애플리케이션 팀은 자기 namespace에서 HTTPRoute만 관리
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-developer
  namespace: apps
rules:
  - apiGroups: ["gateway.networking.k8s.io"]
    resources: ["httproutes"]
    verbs: ["*"]
```

### 고급 라우팅 기능

Gateway API는 annotation 없이도 복잡한 라우팅을 표현할 수 있다.

**헤더 기반 라우팅**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: header-based-route
spec:
  parentRefs:
    - name: main-gateway
  rules:
    - matches:
        - headers:
            - name: X-Version
              value: beta
      backendRefs:
        - name: frontend-beta
          port: 80
    - backendRefs:
        - name: frontend-stable
          port: 80
```

`X-Version: beta` 헤더가 있으면 베타 버전으로, 없으면 안정 버전으로 라우팅된다.

**가중치 기반 트래픽 분산**

트래픽의 80%는 v1으로, 20%는 v2로 보낸다. 카나리 배포에 유용하다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: canary-route
spec:
  parentRefs:
    - name: main-gateway
  hostnames:
    - "example.com"
  rules:
    - backendRefs:
        - name: frontend-v1
          port: 80
          weight: 80
        - name: frontend-v2
          port: 80
          weight: 20
```

**HTTP 메서드와 쿼리 파라미터**

같은 경로라도 HTTP 메서드에 따라 다른 서비스로 라우팅할 수 있다. CQRS 패턴에 유용하다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: method-based-route
spec:
  parentRefs:
    - name: main-gateway
  rules:
    - matches:
        - method: POST
          path:
            value: /api/users
      backendRefs:
        - name: user-write-service
          port: 80
    - matches:
        - method: GET
          path:
            value: /api/users
      backendRefs:
        - name: user-read-service
          port: 80
```

**요청/응답 변환**

`/api/v1/users` 요청이 들어오면:

1. `X-API-Version: v1` 헤더를 추가
2. `X-Legacy-Auth` 헤더를 제거
3. 경로를 `/api/users`로 변경
4. api-service로 전달

annotation 없이 표준 방식으로 요청을 변환할 수 있다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: transform-route
spec:
  parentRefs:
    - name: main-gateway
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api/v1
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: X-API-Version
                value: "v1"
            remove:
              - "X-Legacy-Auth"
        - type: URLRewrite
          urlRewrite:
            path:
              type: ReplacePrefixMatch
              replacePrefixMatch: /api
      backendRefs:
        - name: api-service
          port: 80
```

### TCP와 UDP 지원

Gateway API는 L4 프로토콜을 일급 객체로 지원한다.
더 이상 ConfigMap 해킹이 필요 없다. TCP와 UDP를 HTTP와 동일한 방식으로 다룰 수 있다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: database-gateway
spec:
  gatewayClassName: istio
  listeners:
    - name: postgres
      protocol: TCP
      port: 5432
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
metadata:
  name: postgres-route
spec:
  parentRefs:
    - name: database-gateway
  rules:
    - backendRefs:
        - name: postgres
          port: 5432
```

### 크로스 네임스페이스 라우팅

Gateway API는 네임스페이스 간 참조를 안전하게 지원한다.

```yaml
# infra 네임스페이스의 Gateway
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shared-gateway
  namespace: infra
spec:
  gatewayClassName: istio
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels:
              shared-gateway-access: "true"
---
# apps 네임스페이스의 HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-route
  namespace: apps
  labels:
    shared-gateway-access: "true"
spec:
  parentRefs:
    - name: shared-gateway
      namespace: infra
  hostnames:
    - "myapp.example.com"
  rules:
    - backendRefs:
        - name: myapp
          port: 80
```

`allowedRoutes`로 어떤 네임스페이스가 이 Gateway를 사용할 수 있는지 제어한다. 플랫폼 팀은 하나의 Gateway를 여러 팀이 안전하게 공유하도록 할 수 있다.

## Ingress vs Gateway API 비교

지금까지 배운 내용을 바탕으로 두 방식을 비교해보자.

### 아키텍처 차이

**Ingress:**

```
Ingress 리소스 (규칙 + 인프라 설정 혼재)
    ↓
Ingress Controller (구현체마다 다름)
    ↓
Service
```

**Gateway API:**

```
GatewayClass (인프라 선택) ← 플랫폼 팀
    ↓
Gateway (진입점 설정) ← 플랫폼 팀
    ↓
HTTPRoute (라우팅 규칙) ← 애플리케이션 팀
    ↓
Service
```

### 기능 비교

| 기능                | Ingress        | Gateway API |
| ------------------- | -------------- | ----------- |
| HTTP/HTTPS 라우팅   | O              | O           |
| TCP/UDP 라우팅      | △ (annotation) | O           |
| 헤더 기반 라우팅    | △ (annotation) | O           |
| 가중치 트래픽 분산  | △ (annotation) | O           |
| 역할 분리           | X              | O           |
| 크로스 네임스페이스 | X              | O           |
| 타입 안전성         | X (annotation) | O (CRD)     |
| 이식성              | X              | O           |
| 요청/응답 변환      | △ (annotation) | O           |

---

참고

- <https://kubernetes.io/docs/concepts/services-networking/ingress>
- <https://gateway-api.sigs.k8s.io>
- <https://gateway-api.sigs.k8s.io/concepts/migrating-from-ingress>
- <https://docs.nginx.com/nginx-gateway-fabric>
- <https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api>
- <https://gateway-api.sigs.k8s.io/implementations>

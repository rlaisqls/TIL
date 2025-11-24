Ingress는 클러스터 외부에서 내부 서비스로의 HTTP/HTTPS 라우팅을 정의하는 Kubernetes 리소스이다.

Ingress는 두 부분으로 구성된다:

1. Ingress yaml 리소스: 라우팅 규칙을 정의하는 YAML 설정
2. Ingress Controller: 실제로 트래픽을 처리하는 구현체 (NGINX, Traefik, HAProxy 등)

Kubernetes 자체는 Ingress 규칙만 정의할 뿐 실제 구현은 제공하지 않는다. 사용자가 원하는 Ingress Controller를 선택해서 설치해야 한다.

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

### 동작

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

### 한계

Ingress는 많은 문제를 해결했지만, 사용하다 보면 한계가 드러난다.

#### Annotation 의존성과 표준화 부재

Ingress 스펙 자체는 Host와 Path 기반 라우팅만 지원한다. 실제 프로덕션에서 필요한 기능들은 annotation으로 해결해야 한다:

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "20"
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/rate-limit: "100"
```

이런 annotation의 문제점은 아래와 같은 것들이 있다.

- Controller마다 호환 X: NGINX와 Traefik이 서로 호환되지 않아 마이그레이션시 Ingress를 완전히 다시 작성해야한다.
- 타입 안전성 없음: 오타가 있어도 에러 없이 조용히 무시된다.
- 검증 불가: 배포 전에 설정 오류를 잡을 수 없다.

#### L7 전용 설계

Ingress는 HTTP/HTTPS만 지원한다. TCP/UDP 프로토콜(데이터베이스, gRPC, DNS 등)은 ConfigMap을 통한 우회 방법으로만 처리할 수 있다.

예를 들어 NGINX Ingress Controller에서 TCP 포트를 노출하려면 아래 ConfigMap을 Ingress Controller에 마운트하고, Controller의 args에 `--tcp-services-configmap` 플래그로 지정해야 한다. 표준 Kubernetes 리소스가 아닌 Controller 전용 설정이므로 이식성이 없고 관리가 복잡하다.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-services
  namespace: ingress-nginx
data:
  5432: "default/postgres:5432"  # 외부 포트: namespace/service:포트
  3306: "default/mysql:3306"
```

## Gateway API

이런 문제들을 해결하기 위해 Kubernetes SIG-Network에서 Gateway API를 설계했다. Gateway API는 Ingress의 단순한 대체가 아니라, 완전히 새로운 접근 방식이다.

### 설계 철학

1. 역할 지향적 (Role-oriented): 플랫폼 운영자와 애플리케이션 개발자의 역할을 명확히 분리
2. 확장 가능 (Extensible): annotation 대신 CRD를 통한 타입 안전한 확장
3. 표현력 (Expressive): 복잡한 라우팅을 표준 방식으로 표현
4. 이식성 (Portable): 다양한 구현체 간 호환성

### 핵심 리소스

Gateway API는 세 가지 주요 리소스로 구성된다

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

### 역할 분리

Gateway API는 리소스를 세 계층으로 분리하여 플랫폼 팀과 애플리케이션 팀의 책임을 명확히 구분한다:

- 플랫폼 팀: GatewayClass, Gateway 관리 (인프라, 포트, TLS 설정)
- 애플리케이션 팀: HTTPRoute 관리 (자신의 서비스 라우팅 규칙)

이를 통해 RBAC로 세밀한 권한 제어가 가능하다. 플랫폼 팀은 Gateway를, 개발 팀은 자신의 네임스페이스에서 HTTPRoute만 관리할 수 있도록 설정할 수 있다.

### 고급 라우팅 기능

Gateway API는 annotation 없이도 표준 스펙으로 복잡한 라우팅을 표현할 수 있다:

| 기능 | 설명 | 사용 예시 |
|------|------|-----------|
| 헤더 기반 라우팅 | HTTP 헤더 값으로 라우팅 | `X-Version: beta` 헤더면 베타 서비스로 |
| 가중치 트래픽 분산 | 백엔드별 트래픽 비율 조정 | v1: 80%, v2: 20% (카나리 배포) |
| 메서드 기반 라우팅 | GET/POST 등으로 분기 | GET → read-service, POST → write-service (CQRS) |
| 요청/응답 변환 | 헤더 추가/제거, 경로 재작성 | `/api/v1/*` → `/api/*`, 헤더 추가 |

예시: 가중치 기반 카나리 배포

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

### TCP/UDP 지원과 크로스 네임스페이스 라우팅

Gateway API는 L4 프로토콜(TCP/UDP)을 HTTP와 동일하게 TCPRoute, UDPRoute 리소스로 다룰 수 있다. 더 이상 ConfigMap 우회가 필요 없다.

또한 `allowedRoutes`를 통해 네임스페이스 간 안전한 공유가 가능하다. 플랫폼 팀이 infra 네임스페이스에 Gateway를 생성하면, 여러 애플리케이션 팀이 자신의 네임스페이스에서 HTTPRoute로 이를 참조할 수 있다.

## 비교

지금까지 알아본 내용을 바탕으로 두 방식을 비교해보자.

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

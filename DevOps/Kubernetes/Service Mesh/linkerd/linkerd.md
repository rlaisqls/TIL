
### Control Plane

Control plane은 Kubernetes의 전용 네임스페이스 (`linkerd`)에서 Linkerd 전체 제어를 위해 실행되는 서비스 집합이다.

- Destination Service
  - 프록시가 서비스 디스커버리 정보를 가져오는 역할
  - 서비스가 어디에 있는지, 어떤 TLS 인증서가 필요한지 등의 정보를 gRPC API로 제공
  - 정책 정보와 service profile(재시도, 타임아웃, per-route metrics에 사용)을 프록시에 전달

- Identity Service
  - mTLS를 위한 인증서 발급 기능을 수행
  - 프록시가 부트스트랩 시 CSR(Certificate Signing Request)을 보내면, CA 역할을 하여 서명된 인증서를 반환
  - 프록시 간 통신에 필요한 TLS 신뢰 체계를 구축

- Proxy Injector
  - Kubernetes의 Admission Webhook으로 동작
  - Pod 생성 시 `linkerd.io/inject: enabled` 애노테이션이 있을 경우, 두 컨테이너를 Pod에 주입
    - `linkerd-init` (iptables 설정)
    - `linkerd-proxy` (data plane 프록시)
  - 설정은 Pod 생성 시점에 적용되며, 런타임 시 변하지 않는다
  - 다양한 iptables 모드를 지원하며, CNI 플러그인을 통해 우회 가능

### Data Plane

Data plane은 각 서비스 인스턴스에 사이드카 컨테이너로 주입된 경량 프록시이다. 프록시는 트래픽을 가로채고, control plane과 통신하여 설정을 동적으로 반영한다.

#### Proxy (`linkerd2-proxy`)

Rust로 작성된 초경량 고성능 프록시로, 일반 목적의 프록시가 아니라 서비스 메시용으로 최적화되어 있다.

**주요 기능:**

- HTTP/1, HTTP/2, TCP에 대한 **투명하고 설정이 필요 없는 프록싱**
- Prometheus용 **자동 메트릭 수집** (HTTP, TCP 모두)
- **WebSocket 지원**
- **레벨7(HTTP)** 기반 지연 시간 인식 로드 밸런싱
- **레벨4(TCP)** 기반 로드 밸런싱
- **자동 TLS 및 mTLS**
- **Tap API**를 통한 실시간 트래픽 관찰

**서비스 디스커버리:** DNS 또는 gRPC 기반 destination service 사용

#### Meshed Connections

두 Pod가 모두 Linkerd 프록시를 주입받은 경우, 프록시간의 TCP 연결은 **meshed connection**이라 부른다. 연결을 시작, 혹은 수락한 프록시는 통신에서 아래같은 역할을 한다.

- **Outbound Proxy**(연결을 시작한 Pod의 프록시)
  - 서비스 디스커버리
  - 로드 밸런싱
  - 재시도, 타임아웃, 서킷 브레이커
- **Inbound Proxy**(연결을 수락하는 프록시)
  - 인증 및 권한 정책 적용

---
참고

- <https://linkerd.io/2-edge/reference/architecture/>

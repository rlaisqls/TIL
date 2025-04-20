
Calico는 Kubernetes 기반 워크로드와 비-Kubernetes 또는 레거시 워크로드 간의 안전하고 원활한 통신을 가능하게 하는 네트워크 및 보안 솔루션이다.

Kubernetes에서는 기본적으로 모든 Pod 간 네트워크 트래픽이 허용되어 모든 Pod가 서로 자유롭게 통신할 수 있다. Calico는 네트워크 계층의 보안을 강화하고, 대규모 클라우드 네이티브 애플리케이션을 보호하기 위한 고급 네트워크 정책을 제공한다.

## 구성 요소

### Calico CNI (Container Network Interface)

Calico CNI는 여러 데이터플레인을 제어하는 컨트롤 플레인이다. L3/L4 계층의 네트워크 솔루션으로, 컨테이너, Kubernetes 클러스터, 가상 머신, 호스트 기반 워크로드 간의 안전한 통신을 제공한다.

**주요 기능**

- 데이터 암호화 기능 내장
- 고급 IP 주소 관리(IPAM)
- 오버레이 및 논오버레이 네트워킹 지원
- 다양한 데이터플레인 선택 가능: iptables, eBPF, Windows HNS, VPP

---

### Calico 네트워크 정책 모듈

Calico 네트워크 정책은 Calico CNI와 연동되는 정책 인터페이스로, 실제 네트워크 데이터플레인에서 실행될 규칙을 정의한다.

**특징**

- 제로 트러스트 보안 모델 기반 (기본 차단, 필요한 경우에만 허용)
- Kubernetes API 서버와 통합되어, Kubernetes의 네트워크 정책과 함께 사용 가능
- 레거시 시스템(베어 메탈, 비클러스터 호스트)도 동일한 정책 모델로 보호 가능

**주요 기능**

- **네임스페이스 및 글로벌 정책**: 클러스터 내, Pod 간, 외부와의 트래픽 제어
- **네트워크 세트(Network Sets)**: CIDR, 서브넷, 도메인 등을 통한 입/출력 IP 범위 제한
- **L7(애플리케이션 계층) 정책**: HTTP 메서드, 경로, 보안 ID 등의 속성을 기반으로 트래픽 제어

## 기능

| 기능 | 설명 |
|------|------|
| 데이터플레인 | eBPF, iptables(Linux), Windows HNS, VPP 지원 |
| 네트워킹 | - BGP 또는 오버레이 기반 확장 가능한 Pod 네트워킹<br/>- 맞춤형 IP 주소 관리 |
| 보안 | - 워크로드 및 호스트 엔드포인트에 대한 네트워크 정책 적용<br/>- WireGuard를 통한 전송 데이터 암호화 |
| 모니터링 | Prometheus를 통한 Calico 컴포넌트 메트릭 수집 |
| 사용자 인터페이스 | `kubectl`, `calicoctl` CLI 도구 |
| API | - Calico 리소스를 위한 API<br/>- 오퍼레이터 설치 및 설정용 Installation API |
| 지원 및 유지관리 | 커뮤니티 기반 지원, 전 세계 166개국에서 매일 2백만 개 이상의 노드에서 사용 중 |

---

## 참고

- <https://www.calicolabs.com>
- <https://www.tigera.io/project-calico>


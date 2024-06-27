
- MetalLB는 BareMetal LoadBalancer의 약자로, Kubernetes 클러스터에 연결되어 온프레미스 환경(IDC)에서 로드밸런서 타입 서비스를 구현해주는 툴이다.
- MetalLB가 제공하는 기능을 크게 나누면 주소를 할당해주는 기능과 외부와 연결하는 기능 두 가지로 나누어 볼 수 있다.

## 주소 할당

- 클라우드 제공업체의 Kubernetes 클러스터에서는 로드밸런서를 요청하면 클라우드 플랫폼이 IP 주소를 할당해준다. 베어메탈 클러스터에서는 MetalLB가 이 할당을 담당한다.
- MetalLB에 사용할 수 있는 IP 주소 풀을 제공하면 해당 풀에서 LB를 생성해준다.

## 외부 연결

- MetalLB가 서비스에 외부 IP 주소를 할당한 후에는 해당 IP가 클러스터에 "존재한다"는 것을 클러스터 외부 네트워크에 알려야 한다. MetalLB는 이를 위해 사용되는 모드에 따라 ARP, BGP같은 표준 네트워킹 및 라우팅 프로토콜을 사용한다.

### Layer 2 mode (ARP/NDP)

- L2 모드는 클러스터의 한 머신이 서비스의 소유권을 가지고, 표준 주소 검색 프로토콜(IPv4면 [ARP](https://en.wikipedia.org/wiki/Address_Resolution_Protocol), IPv6면 [NDP](https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol))을 사용하여 로컬 네트워크에서 해당 IP에 도달할 수 있게 한다. 
- 쉽게 말하면 한 머신이 여러 IP 주소를 가지고 있는 것이다.

> https://metallb.universe.tf/concepts/layer2/

<img src="https://github.com/rlaisqls/TIL/assets/81006587/bd580874-cfeb-43e7-b91d-1f1e5ce6d3b1" style="height: 200px">

#### 한계점

- 한 머신이 여러 IP 주소를 가지고 퍼트리는 방식이기에 성능 병목지점이 될 수 있다.
- MetalLB는 장애가 발생하면 ARP 패킷을 전송하여 서비스 IP와 관련된 MAC 주소가 변경되었음을 클라이언트에 알리는데, 일부 운영체제에서는 ARP 패킷을 늦게 처리하여 문제가 될 수 있다.
- 다른 네트워크와 대역을 분리하여 설정해야한다.

### BGP
- BGP 모드에서는 클러스터의 모든 머신이 제어하는 주변 라우터와 [BGP](https://en.wikipedia.org/wiki/Border_Gateway_Protocol) 피어링 세션을 설정하고, 이러한 라우터에 서비스 IP로 트래픽을 전달하는 방법을 알려준다.
- BGP를 사용하면 여러 노드에 걸쳐 고르게 로드 밸런싱할 수 있고, BGP의 정책 메커니즘 덕분에 세밀한 트래픽 제어가 가능하다.

> https://metallb.universe.tf/concepts/bgp/

<img src="https://github.com/rlaisqls/TIL/assets/81006587/1fcd20ee-19ea-42f5-8355-a983e8f92e01" style="height: 200px">

#### 한계점

- BGP 세션이 종료될 때(노드 장애나 스피커 파드 재시작 시) 모든 활성 연결이 재설정될 수 있다. 이를 완화하기 위해 BGP 피어 추가 시 노드 셀렉터를 사용하여 BGP 세션을 특정 노드로 제한할 수 있다.
- MetalLB는 단일 자율 시스템 번호(ASN)와 단일 라우터에 속해야 한다.

---
참고
- https://metallb.universe.tf/concepts
- https://metallb.universe.tf/concepts/layer2/
- https://metallb.universe.tf/concepts/bgp/
- https://docs.openshift.com/container-platform/4.13/networking/metallb/about-metallb.html
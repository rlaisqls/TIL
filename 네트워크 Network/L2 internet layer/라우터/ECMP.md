# ECMP(equal-cost multi-path routing)

<img src="https://upload.wikimedia.org/wikipedia/commons/4/4a/802d1aqECMP_%28cropped%29.gif" height=400px/>

ECMP는 하나의 목적지로 패킷 라우팅을 수행하면서 여러 개의 경로를 선택하는 라우팅 기법이다. 이름처럼 같은 Cost를 가진 여러 경로에 트래픽을 분산시킨다. 같은 Cost로 판정되려면 static, OSPF, BGP 에서 다음의 속성이 같아야 한다.

- Destination Subnet
- Distance
- Metric
- Priority

ECMP는 다음 홉에 대한 선택을 단일 라우터로 국한시킬 수 있기 때문에 대부분의 라우팅 프로토콜과 결합하여 사용할 수 있다.


### 트래픽 분배 방법

트래픽을 분배하는 방법에 대한 설정은 다음과 같다.

<img width="734" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/cbbe6fc5-ea1f-418b-9b9c-4ca293a85b7a">

- source IP (default)
  - source IP 기반으로 경로 선택. 동일한 source IP의 경우 동일한 경로로 통신
- source-destination IP
  - 동일한 source IP와 destination IP 쌍(pair)에 대해 동일한 경로로 통신
- weighted
  - Route 또는 interface weight 설정에 따라 분배 (가중치가 높을수록 선택 가능성 높음)
- usage (spillover)
  - 설정한 임계치에 도달할 때까지 하나의 경로만 사용하고 임계치에 도달하면 다음 경로 사용

세션 단위로 분배를 하게 되며, ECMP route중 하나에서 fail이 발생하면 자동으로 routing table에서 삭제되고 트래픽은 남아있는 경로로 통신하게 된다. 라우팅 fail에 대한 별도의 설정은 필요 없다.

### 장점
- 다중 경로를 통해 트래픽을 분산시킴으로써 대역폭이 증가할 수 있다. 

### 단점
- TCP, path MTU discovery와 같은 인터넷 프로토콜의 동작에 혼란을 가져온다. 
- 여러 개의 경로를 통해 전송되던 데이터 흐름이 어느 순간 하나의 경로로 수렴할 경우, 대역폭의 증가없이 트래픽 경로의 복잡도만 증가한다.
- 시스템의 물리적인 토폴로지와 논리적 토폴로지가 다를 경우 (VLAN가 적용되었거나 ATM, MPLS와 같은 virtual circuit-based 구조를 가진 시스템 등), 다른 라우팅 프로토콜과 제대로 연동되지 않을 수 있다.

---
참고
- https://en.wikipedia.org/wiki/Equal-cost_multi-path_routing
- https://ebt-forti.tistory.com/465
- https://docs.vmware.com/kr/VMware-NSX/4.1/administration/GUID-443B6B0D-F179-429E-83F3-E136038332E0.html
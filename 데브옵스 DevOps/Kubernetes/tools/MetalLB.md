# MetalLB

K8s에서 LB를 사용하기 위해선 AWS, GCP, Azure 등 플랫폼에서 제공해주는 서비스를 사용해야하고, 온프레미스 클러스터에서는 추가 모듈 설치가 필요하다.

MetalLB는 BareMetal Loadbalancer의 약자로, 베어메탈 환경에서 사용할 수 있는 로드밸런서를 제공하는 오픈소스 프로젝트이다.

MetalLB의 동작에는 두가지 방식이 있다.

## 1. L2 Mode

L2 모드는 2계층 통신을 이용한다.

1. 각 노드마다 speaker라는 데몬셋이 생성되고, 호스트 네트워크를 사용한다. 
2. 리더 speaker pod를 선출한다. 리더는 ARP(GARP)로 해당 External IP에 대한 소유를 주장한다.
   - arpping을 이용하여 어떤 Speaker pod가 external IP를 관리하는지 직접 찾을 수 있다.
   - 아래는 arpping을 이용하여 nginx ingress controller 서비스를 담당하는 Speaker pod를 찾는 예제이다. `FA:16:3E:5A:39:4C`라는 MAC주소를 가진 node가 Speaker Pod를 가졌다는 뜻이다.

     ```c
        $ arping -I ens3 192.168.1.240
        ARPING 192.168.1.240 from 192.168.1.35 ens3
        Unicast reply from 192.168.1.240 [FA:16:3E:5A:39:4C]  1.077ms
        Unicast reply from 192.168.1.240 [FA:16:3E:5A:39:4C]  1.321ms
        Unicast reply from 192.168.1.240 [FA:16:3E:5A:39:4C]  0.883ms
        Unicast reply from 192.168.1.240 [FA:16:3E:5A:39:4C]  0.968ms
        ^CSent 4 probes (1 broadcast(s))
        Received 4 response(s)
     ```
    
3. 모든 트래픽이 리더 pod로만 오도록 한다.
4. DNAT으로 나머지 노드에 뿌려준다.

<img width="473" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/d55f9dfb-0838-4eff-a676-635df69e95ef">

특정 노드에 과한 부하가 발생할 수 있고, 리더 Pod가 알수없는 이유로 죽는다면 일시적 장애가 발생하기 때문에 테스트 또는 소규모의 환경에서만 사용하는 것이 권장된다.

## 2. BGP Mode

> In BGP mode, all machines in the cluster establish BGP peering sessions with nearby routers that you control, and tell those routers how to forward traffic to the service IPs. Using BGP allows for true load balancing across multiple nodes, and fine-grained traffic control thanks to BGP’s policy mechanisms.

<img width="400" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/00d3689a-2aef-4231-9dca-bdc436bb9553">

1. Speaker Pod에 BGP가 동작하여 서비스 정보(External IP)를 전파한다.
   - BGP 커뮤니티, localpref 등 BGP 관련 설정을 할 수 있다.
2. 외부에서 라우터를 통해 ECMP 라우팅으로 분산 접속한다.

L2모드와 다르게 speaker pod가 장애나더라도 매우 짧은 시간안에 장애복구가 가능하다. 하지만, 단순히 MetalLB만 설정하는 것이 아니라 BGP 라우팅 설정과 라우팅 전파 관련 최적화 설정이 필요하다.

**FRR Mode**

BGP 계층의 백엔드로 FRR을 사용하는, BGP 모드에서 사용할 수 있는 별도 모드이다. FRR 모드가 켜지면 아래와 같은 기능들을 사용할 수 있다.

- BFD가 지원되는 BGP 세션
- BGP와 BFD의 IPv6 지원
- 멀티 프로토콜 BGP

기본 구현과 비교하여 FRR 모드에는 다음과 같은 제한이 있다

- BGP Advertisement의 RouterID 필드는 재정의할 수 있지만 모든 광고에 대해 동일해야 한다 (다른 RouterID를 가진 다른 광고가 있을 수 없음).
- BGP Advertisement의 myAsn 필드는 재정의할 수 있지만 모든 광고에 대해 동일해야 한다(myAsn이 다른 광고가 있을 수 없음).
- eBGP 피어가 노드에서 여러 홉 떨어져 있는 경우 ebgp-multihop 플래그를 true로 설정해야 한다.

---
참고 
- https://mlops-for-all.github.io/en/docs/appendix/metallb/
- https://www.linkedin.com/pulse/metallb-loadbalancer-bgp-k8s-rock-music-dipankar-shaw/
- https://stackoverflow.com/questions/62380153/hw-do-you-get-metallb-to-arp-around-its-ip
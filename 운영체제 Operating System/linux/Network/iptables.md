
Iptables 방화벽은 규칙을 관리하기 위해 테이블을 사용한다. 이 테이블은 사용자가 익숙한 형태에 따라 규칙을 구분한다. 예를 들어 만약 하나의 규칙이 network 주소 변환을 다룬다면 그것은 nat 테이블로 놓여질 것이다. 만약 그 규칙이 패킷을 목적지로 허용하는데 사용된다면 그것은 filter 테이블에 추가 될 것이다.  이러한 각각의 iptables 테이블 내에서 규칙들은 분리된 체인안에서 더 조직화(organize)된다. 테이블들이 일반적인 규칙의 목적에 의해 정의되는 동안 빌트인 체인들은 그것들을 트리거 하는 netfilter hook들을 표현한다. 체인들은 기본적으로 언제 규칙이 평가될지를 결정한다.

아래는 빌트인 체인들의 이름인데 이것들은 [netfilter](Netfilter.md) 이름을 그대로 사용한다.

- PREROUTING : `NF_IP_PRE_ROUTING` Hook에 의해 트리거 된다.
- INPUT : `NF_IP_LOCAL_IN` Hook에 의해 트리거 된다.
- FORWARD : `NF_IP_FORWARD` Hook에 의해 트리거 된다.
- OUTPUT : `NF_IP_LOCAL_OUT` Hook에 의해 트리거 된다.
- POSTROUTING : `NF_IP_POST_ROUTING` Hook에 의해 트리거 된다.

체인들은 관리자가 패킷의 delivery path에서 규칙이 어디로 평가되어질지를 허용하는데, 각각의 테이블이 여러개의 체인을 가지게 된 이후에, 하나의 테이블에 미치는 영향은 패킷이 처리되는 동안 여러개의 지점에서 영향을 받을 수 있다. 어떤 특정 타입의 결정은 오직 네트워크 스택안에서 특정 포인트에 인지되기 때문에 모든 테이블은 각각의 커널 Hook에 등록된 체인을 여러개 가질 수도, 가지지 못할 수도 있다. 

오직 5개의 netfilter 커널 Hook만이 존재하기 때문에, 여러개의 테이블로 부터 생성된 체인들은 각각의 hook에 등록된다. 예를 들어 3개 테이블이 `PREROUTING` 체인을 가지고 있고 이 체인들이 연관된 `NF_IP_PRE_ROUTING` hook에 연관되어 등록되어 있을 때, 그것들은 우선순위를 명시한다. 그 우선순위는 어떤 순서가 각 테이블의 PREROUTING 체인이 호출되는지를 지시한다. 각각의 규칙은 내부에 가장 높은 우선순위인 PREROUTING 체인이 순차적으로 평가되는데 그것은 다음 PREROUTING 체인으로 움직이기 전에 평가 된다. 

## 테이블

- **Filter Table**
  - Iptables에서 가장 널리 사용되는 테이블. 이 Filter 테이블은 패킷이 계속해서 원하는 목적지로 보내거나 요청을 거부하는데에 대한 결정을 하는데 사용된다. 방화벽 용어로 이것은 “filtering” 패킷들로 알려진다.

- **NAT Table**
  - 네트워크 주소 변환 규칙을 구현하는데 사용된다. 패킷들이 네트워크 스택에 들어오면, 이 테이블에 있는 규칙들은 패킷의 source 혹은 destination 주소를 변경하거나 변경하는 방법을 결정한다. 보통 direct access가 불가능할 때 네트워크에 패킷들을 라우팅하는데 종종 사용된다. 

- **Mangle Table**
  - 다양한 방법으로 패킷의 IP 헤더를 변경하는데 사용된다. 예를 들어 패킷의 TTL (Time to Live) Value를 조정할수 있다. 이 테이블은 다른 테이블과 다른 네트워킹 툴에 의해 더 처리되기 위해 패킷위에 내부 커널 “mark”를 위치 시킨다. 이 “marks”는 실제 패킷을 건들이지는 않지만 패킷의 커널의 표현에 mark를 추가하는 것이다. 

- **Raw Table**
  - Iptables 방화벽은 stateful 방식이다. 이것은 패킷들은 이전 패킷들과 연관되어 평가된다는 것이다. Connection tracking 기능들은 netfilter 프레임워크의 최상단에서 빌드 되고, 이것은 iptables가 ongoing connection 혹은 관계없는 패킷의 스트림으로의 세션 일부분으로 패킷을 살펴 볼 수 있도록 허용해준다. 이 Raw 테이블은 배우 좁게 정의된 기능이다. 이것의 유일한 목적은 connection tracking을 위한 패킷을 표시하기 위한 메커니즘을 제공하는 것이다.

- **Security Table**
  - 내부의 internal SELinux 보안 context marks를 패킷에 설정하는데 사용된다. 이것은 SELinux나 다른 시스템들이 어떻게 패킷을 핸들링하는데 영향을 미치는지에 대해 관여한다. 

<img width="539" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/fcf6269b-31e2-452f-a9f1-8eb713c3cb3a">

하나의 패킷이 netfilter Hook을 트리거 할 때, 연관된 체인들은 아래 표에 있는 것 처럼 위에서 아래로 리스트 되어 있는 순서대로 처리가 된다. Columns에 있는 hook들은 패킷이 트리거 할 때 수행되고, 이것들은 incoming / outgoing 패킷 인지, 라우팅 decision인지, 패킷이 필터링 영역을 지나가는지에 의존한다. 특정 이벤트가 테이블의 체인이 프로세싱 하는 동안 스킵할 수 있도록 해주기도 한다. 예를 들어 오직 첫번째 패킷만이 하나의 connection안에서 NAT 규칙으로 수행될 때, 첫번째 패킷을 위해 만들어진 nat 결정은 추가적인 evaluation없이 모든 차후의 패킷으로 적용된다. NAT된 connection으로 response는 자동적으로 reverse NAT 규칙이 정확하게 라우팅 되게 된다.  

## Chain Traversal Order

서버는 패킷이 라우팅 될 곳을 알고 있고, 방화벽 규칙이 전파되는 것을 허용한다고 가정하면, 다음의 flow가 다른 상황에서 traverse 되는지의 path를 보여준다.

- 들어오는 패킷이 local system을 목적지로 한다 : PREROUTING -> INPUT
- 들어오는 패킷이 다른 호스트로 목적지로 한다 : PREROUTING -> FORWARD -> POSTROUTING
- 내부에(local) 생성된 패킷들 : OUTPUT -> POSTROUTING

만약 이전 테이블에서 ordering layout에 대한 위 3가지 정보를 통합한다면, 우리는 local 시스템으로 향하는 incoming 패킷이 처음으로 raw, mangle, nat 테이블의 PREROUTING 체인에 대해 평가가 되는 것을 볼 수 있을 것이다. 그것은 그때 mangle, filter, security, nat테이블의 INPUT 체인을 traverse할 것이다.  

## IPTables Rules

규칙들은 특정한 테이블의 특정한 체인안에 놓여진다. 각각의 체인이 호출될 때, in question 패킷은 순서대로 체인안에서 각각의 규칙에 대해 체크를 하게 된다. 각각의 규칙은 매칭된 component와 action component를 가진다. 

### Matching
하나의 규칙의 matching 비율은 영역을 명시하는데 그 영역은 하나의 패킷이 순서대로 만나야 하는 것이다. 그것은 연관된 액션 혹은 타켓을 위한 것인데, 이 Matching 시스템은 매우 flexible 해서 iptables을 확장할 수 있게 한다. 규칙들은 프로토콜 타입, destination 혹은 source 주소, 포트, 네트워크, input 혹은 output interface, 헤더, connection state에 의해 매치하기 위해 구성된다. 이것들은 다른 트래픽사이들에서 구별하기 위해 공평하게 복잡한 규칙 집합(set)을 생성해서 통합될 수 있다. 

### Targets

타겟은 하나의 패킷이 하나의 규칙의 matching 영역을 만났을 때 트리거 되는 액션이다. 타겟들은 점진적으로 아래 두개의 영역으로 나뉘어 진다. 

- **Terminating targets**: 체인내에서 evaulation을 끝내고 netfilter Hook으로 컨트롤을 리턴하는 것이다. 제공된 return value에 의존하고 그 Hook은 패킷을 drop하거나 패킷이 다음 스테이지로 계속해서 수행할 수 있도록 해준다.
- **Non-terminating targets**: 체인 내에서 evaluation을 계속 수행하고 행위를 수행한다. 비록 각각의 체인이 결과적으로 최종 terminating decision으로 전달해야만 한다면, non-terminating targets의 숫자는 사전에 수행되어질 수 있다. 

규칙내에서 각각의 타겟의 가용성은 context에 의존적이다. 예를 들어 테이블과 체인 타입은 가용한 타겟을 가르키고, 규칙내에서 활성화된 extension들과 matching을 구분하는 것은 타겟의 가용성에 영향을 미칠 수 있다.

## IPTables and Connection Tracking

Connection tracking은 iptables이 ongoing connection의 context안에 보여지는 패킷에 대해 결정할 수 있게 한다. Connection tracking 시스템은 iptables 에게 “stateful” operation을 수행하는데 필요한 기능들을 제공한다. 

Connection tracking은 패킷이 네트워크 스택에 들어온 후 바로 적용된다. raw table 체인과 어떤 기본적인 온전한 체크들은 하나의 connection과 패킷을 연관시키는데 이전의 패킷위에 수행되는 유일한 로직이다. 시스팀은 각각의 패킷들을 현재 존재하는 connection들의 집합과 체크하고, 그것은 connection의 state를 업데이트 한다. 필요할 때 시스템에 새로운 connection을 추가한다. 패킷들은 하나의 raw 체인에서  NOTRACK tarket으로 표시된다. 그리고 connection tracking 경로를 bypass 한다.

### Available States
- `NEW` : 하나의 패킷이 현재 Connection과 관계 없이 도착했을 때, 그리고 첫번째 패킷으로 맞지 않을 때 새로운 connection은 시스템이 이 라벨(NEW)로 추가된다. 이것은 둘다 TCP, UDP로 적용된다.
- `ESTABLISHED` : 하나의 Connection이 NEW에서 ESTABLISHED로 변하는 것은 connection이 valid response를 받을 때이다. TCP Connection을 위해 이것은 SYN/ACK를 의미하고 UDP와 ICMP 트래픽을 위해서는 오리지날 패킷의 source와 destination이 바뀌는 곳에 response를 의미한다. 
- `RELATED` : 존재하는 connection의 일부가 아니고 시스템에서 이미 connection에 연계되고 있는 패킷들은 RELATED라고 label이 붙는다. 이것은 helper connection을 의미한다. FTP 데이터 전송 connection의 경우나 ICMP 응답일 수 있다. 
- `INVALID` : 만약 패킷들이 존재하는 connection과 연관이 없고 새로운 connection을 열기 위해 적절하지 않고, identify될수 없거나 다른 이유로써 라우팅 되지 않는 다면 INVALID로 표시된다.
- `UNTRACKED` :  패킷들은 tracking을 bypass하기 위해 raw 테이블 체인안에서 target 되어지면 UNTRACKED 라고 표시된다.
- `SNAT` : source address가 NAT operation에 의해 변경되었을 때 가상의 상태가 셋팅된다. 이것은 connection tracking system에 의해 사용되어 져서 source address가 reply 패킷에서 변경되는지를 알수 있다. 
- `DNAT` : destination address가 NAT operation에 의해 변경되었을 때 가상의 상태가 셋팅된다. 이것은 reply 패킷들을 라우팅할 때 connection tracking system에 의해 사용되어 져서 destination address를 변경되는지 알 수 있다. 

위 state들은 connection tracking system에서 추적되고 관리자는 connection lifetime에서 특정 포인트로 타겟팅 하는 규칙을 만들수 있다. 이것은 보다 빈틈없고 안전한 규칙이 필요로 하는 기능들을 제공한다.

![image](https://github.com/rlaisqls/TIL/assets/81006587/be9ddedb-9bee-4af5-9dfe-292819909bff)

---
reference
- [Kubernetes and networking](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/)
- https://kevinalmansa.github.io/network%20security/IPTables/
- https://kubernetes.io/docs/concepts/cluster-administration/networking/
- https://www.digitalocean.com/community/tutorials/a-deep-dive-into-iptables-and-netfilter-architecture
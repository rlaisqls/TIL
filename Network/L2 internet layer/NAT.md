
2011년 2월, 인터넷 주소 관리기구인 IANA는 더 이상의 IPv4 할당이 없을 것이라고 선언했다. IPv4는 약 43억 개의 한정된 주소를 사용할 수 있는데 반해 인터넷의 수요가 빠르게 증가하여 각 대륙에 할당한 IPv4가 동이 나버려 더 이상 할당할 수 없게 된 것이다.

IPv6가 조금씩 상용화 되고 있긴 하지만, 이상하게도 우린 아직도 IPv4를 원활하게 사용하고 있다. 많지 않은 수의 IPv4로 현재까지 별 탈 없이 인터넷을 사용할 수 있게 된 것은 Private Network(이하 사설망) 덕분이라고 볼 수 있다.

## Private Network(사설망)의 탄생

> 사설망 또는 프라이빗 네트워크(private network)는 인터넷 어드레싱 아키텍처에서 사설 IP 주소 공간을 이용하는 네트워크이며 RFC 1918과 RFC 4193 표준을 준수한다. 이러한 주소는 가정, 사무실, 기업 랜에 쓰인다.

Private Network(사설망)는 IPv4 중 특정 대역을 공인 인터넷이 아닌 가정, 기업 등의 한정된 공간에 사용한 네트워크를 의미한다. 사설망에 소속된 IP인 사설 IP 대역은 다음과 같으며 오로지 **사설망**(내부망)에서만 사용 가능하기 때문에 공인망(외부망, 인터넷)에선 사용할 수 없다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/10e7225c-d27e-42a2-818d-d21edbc7e66e)

이 사설 IP는 사설망에만 해당한다면 어디에서나 사용할 수 있다. 일반적으로 집에서 사용하는 컴퓨터, IPTV, 휴대폰, 플레이스테이션 등은 공유기가 할당해주는 사설 IP를 사용하고, 기업도 스위치나 라우터, 방화벽과 같은 네트워크 장비 혹은 비슷한 장비에 사설 IP와 서브넷 마스크를 지정하고 게이트웨이(사설 IP 할당)로 사용하며 이에 연결된 컴퓨터에 사설 IP를 할당한다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/8e636e94-69f3-4af0-8107-cae6fd427c3e)

이렇게 사설망과 공인망이 사용하는 IP에 따라 분리되면서 공인망과 사설망의 경계에서 별도의 조치가 필요해졌다. 사설망에서 공인 인터넷으로 나가고자 할 때 자신의 출발지 IP(Source IP)를 사설 IP 그대로 쓸 수 없기 때문이다. 그렇기에 사설 IP를 공인 IP로 변환해야한다.

IP를 변환하는 것은 사설망과 공인망의 통신에서만 필요한 것이 아니다. 자사의 사설망(내부망)과 전용 회선(Leased Line)을 통해 대외사의 사설망(내부망)을 연결할 경우, 이 경우의 통신에서도 IP를 변환해야 한다. 자신의 실제 IP를 노출시키지 않아야 하거나 반대편 기업의 실제 IP로 목적지 IP를 변환하여야 할 필요가 있을 때 사용한다. 이에 IP를 변환하기 위한 방법을 고안한 것이 바로 Network Address Translation(NAT)이다. 

## NAT이란?

> 네트워크 주소 변환(영어: network address translation, 줄여서 NAT)은 컴퓨터 네트워킹에서 쓰이는 용어로써, IP 패킷의 TCP/UDP 포트 숫자와 소스 및 목적지의 IP 주소 등을 재기록하면서 라우터를 통해 네트워크 트래픽을 주고받는 기술을 말한다. 

Network Address Translation(이하 NAT)는 IP 주소 혹은 IP 패킷의 TCP/UDP Port 숫자를 변환 및 재기록하여 네트워크 트래픽을 주고받는 기술을 의미한다. 지금까지 설명한 내용을 적용해보자면 사설망에서 공인망으로, 공인망에서 사설망으로 통신하고자 할 때 공인망/사설망에서 사용하는 IP로 변환하는 것을 의미한다고 볼 수 있다.

여기서 IP 주소뿐만 아니라 IP 패킷의 TCP/UDP Port 숫자를 변환한다고 말한 이유는 실제로 NAT 의미가 IP 주소뿐만 아니라 Port까지 변환시켜 사용하는 것을 포함하기 때문이다. 이를 Port Address Translation(이하 PAT 또는 NAPT)라고 부른다. NAT와 PAT의 예시를 각각 살펴보자.

<img width="696" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/c4f03592-c003-4e93-879f-40c2c126b2ff">

사용자 1(`10.10.10.10/24`)이 공유기를 통해 공인망에 존재하는 웹 서버(`125.209.22.142:80`)에 접속하려고 한다. 사용자 1은 사설 IP를 보유하고 있기 때문에 공인망으로 나아가기 위해서는 자신의 사설 IP를 공인 IP로 반드시 변환(NAT)해야 한다. 그리고 NAT Device(이하 NAT 장비, 공유기 등)가 이를 수행해준다.

1. 사용자가 웹 서버에 접속하기 위해 NAT 장비(Gateway)에 패킷을 보내는데 IP/Port 정보이다.
   
2. 이를 받아든 NAT 장비가 자신에게 허용된 규칙을 확인하고 공인망의 웹서버에게 보내기 위해 사용자의 사설 IP를 자신의 공인 IP로 변환하여 웹서버에게 전달한다. 정확히 말하면 공인망에 맞닿아 있는 자신의 인터페이스 IP로 변환하는 것이다.
   
3.  웹서버가 사용자가 보낸 요청을 처리하고 응답을 사용자에게 보낸다. 목적지에서 출발지로 패킷을 다시 보내는 것이다.

4. 응답 패킷을 받은 NAT 장비가 과거 사용자가 보낸 요청에 대한 응답임을 기억(Stateful)한다. 그리고 목적지 IP를 공인 IP에서 사용자의 실제 사설 IP로 변환하여 전달한다.

여기서 문제가 하나 발생한다. NAT 장비에 할당된 공인 IP는 하나이지만 사용자는 2명이다. 사용자 1이 자신의 출발 포트를 9999로 지정하여 NAT 장비에 전송했음을 위 과정을 통해 알 수 있었다. 그런데 동시에 사용자 2도 자신의 출발 포트를 9999로 설정하여 전송한다면 어떻게 될까? 패킷이 공인망으로 나아갈 땐 문제가 없겠지만 되돌아올 때 문제가 발생할 것이다. 왜냐하면 목적지가 공인 IP이고 포트는 9999인데 이게 사용자 1인지 사용자 2인지 구분할 방법이 없기 때문이다.

이에 사용되는 것이 바로 **PAT(Port Address Translation)**이다. 사용자 1과 사용자 2로부터 패킷을 전달받아 사용자의 IP에 대해 NAT 장비가 NAT를 실시할 때 출발지 포트를 임의로 변경하는 것이다. 예를 들어 사용자 1의 출발지 포트를 `10000`으로 바꾸고 사용자 2의 출발지 포트를 `20000`으로 바꾼다면, 공인 IP는 하나이지만 사용자마다 포트로 구분할 수 있으니 문제가 해결된다.

위 그림을 보면 사용자 1에게 받은 패킷은 출발지 포트를 `10000`로 변환하여 구분한 것을 알 수 있다. 그리고 패킷이 되돌아 올 때 변경된 목적지 포트를 보고 포트 `10000`은 사용자 1임을 구별할 수 있게 될 것이다.

<img width="708" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/1eb703aa-1778-43e1-ac3f-029c9fc8bfbb">

NAT에는 목적지의 IP 변경도 존재한다. L4 스위치의 목적지 IP NAT가 가장 대표적이다.

<img width="710" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/f6212649-35ad-435c-87ba-6c1cae0af158">

## Session Table & Stateful

NAT를 수행하는 네트워크 장비의 종류는 매우 다양하다. 주로 관문 역할(Gateway)을 하는 네트워크 장비가 주로 NAT를 수행한다. 가정에서는 공유기가 내부망과 공인망의 경계에서 NAT를 실시하며, 기업에서는 방화벽, VPN, L4 스위치 등이 이 역할을 좀 더 많이 수행한다. 공인망에 노출되는 관문에 해당하는 장비인만큼 보안 기능을 곁들인 장비가 맡는 것이다.

NAT를 수행하는 장비들은 자신에게 설정된 규칙(Rule)에 따라 허용/거부를 판단하고, NAT를 실시하고 이를 기록해둔다. 이를 수행하는 장비들을 보통 Session 장비라고 부르며 NAT를 실시한 내역을 기록한 테이블을 Session Table이라고 부른다. 위의 예시 또한 세션 테이블을 생성한다.

<img width="677" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/184e91e3-4dcb-4e3a-b98c-488a8c4b14a6">

위에서 설명했던 예시와 같은 상황에서 사용자 1의 세션 테이블에 어떠한 IP와 어떠한 Port로 NAT/PAT되어있는지 기록되어있는 모습이다. 공인 IP가 1개라 사용자별로 출발지 포트를 구분하여 기록되었다.

<img width="693" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/b1100fd9-cb3b-45ff-84c4-0e5b04322f86">

위 사진은 L4 스위치를 거쳐 실제 서버로 Request가 유입되면서 목적지인 실제 서버의 사설 IP로 NAT된 것이 세션 테이블에 반영이 되어있는 모습이다.

보통 세션 장비에 정해진 Rule(이하 규칙)에 의해 허용된 IP만이 NAT를 실시할 수 있고 세션 테이블에 이름을 올릴 수 있게 된다. 주로 방화벽과 같은 장비가 이러한 작업을 수행한다. 그리고 테이블에 기록된 IP는 규칙에 의해 나가거나/들어온 뒤 다시 들어오거나/나갈 수 있다. 즉 규칙에 의해 한 번 허용이 된 패킷(Request)은 반대 방향(Response)에 대한 정책을 별도로 수립할 필요 없이 테이블에 기록된 세션을 보고 네트워크 장비가 통과시킨다는 것을 의미한다. 이러한 특성을 Stateful이라고 얘기한다.

## NAT의 용어와 종류

NAT는 어느 관점에서 보느냐에 따라 부르는 용어가 달라진다.

- IP와 IP를 일대일 방식으로 변환하면 **Static NAT**
- IP Pool과 IP 1개 혹은 IP Pool을 다대다 방식으로 변환하면 **Dynamic NAT**
- 포트까지 같이 변환하면 **Newtork Address Port Translation(NAPT)**
- Source IP를 변환하면 **Source IP NAT(SNAT)**
- Destination IP를 변환하면 Destination **IP NAT(DNAT)**

---
참고
- https://www.stevenjlee.net/2020/07/11/%EC%9D%B4%ED%95%B4%ED%95%98%EA%B8%B0-nat-network-address-translation-%EB%84%A4%ED%8A%B8%EC%9B%8C%ED%81%AC-%EC%A3%BC%EC%86%8C-%EB%B3%80%ED%99%98/
- https://en.wikipedia.org/wiki/Network_address_translation
- https://learn.microsoft.com/ko-kr/azure/rtos/netx-duo/netx-duo-nat/chapter1
- https://archive.md/20130103041130/http://publib.boulder.ibm.com/infocenter/iseries/v5r3/index.jsp?topic=/rzajw/rzajwstatic.htm
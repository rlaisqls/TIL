# 📡 OSI 7 Layer
OSI 모형은 국제표준화기구(ISO)에서 개발한 모델로, 컴퓨터 네트워크 프로토콜 디자인과 통신을 계층으로 나누어 설명한 것이다. 일반적으로 OSI 7 계층(OSI 7 Layer)이라고 한다. 분산된 이기종 시스템간의 네트워크 상호호환을 위한 표준 아키텍처를 정의하여, 통신을 하기 위한 업무를 계층별로 분할하고 분업할 수 있다는 점에서 의의를 가진다.

<img src="https://images.velog.io/images/shleecloud/post/5a6d1fcc-2d48-4003-b892-7ffd64f943ee/osi.jpeg"></img>

<br>

# 계층 기능

## 1. 물리 계층(Physical Layer)
 - 네트워크 데이터가 전송되기 위한 기본적인 하드웨어 기술을 담당한다. 다양한 특징의 하드웨어 기술이 접목되어 있기에 OSI 아키텍처에서 가장 복잡한 계층으로 간주된다. 리피터, 네트워크 허브, 모뎀 등의 장비가 물리계층에 속하며 비트단위의 데이터를 다룬다.

## 2. 데이터 링크 계층(Date Link Layer)
  - 장치 간 신호를 전달하는 물리 계층을 이용하여 네트워크 상의 주변 장치들 간 데이터를 전송한다. 포인트 투 포인트(Point to Point) 간 신뢰성있는 전송을 보장하기 위한 계층이다. 즉, 네트워크 위의 두 개체가 데이터를 주고받는 과정에서 오류를 잡아내는 것이 목적이다. 네트워크 브릿지나 스위치 등이 이 계층에서 동작하며, 직접 이어진 곳에만 연결할 수 있다.

 - ### 대표 프로토콜
    [Ethernet, Token ring](./L1%E2%80%85network%E2%80%85access%E2%80%85layer/Ethernet%EA%B3%BC%E2%80%85TokenRing.md), PPP

## 3. 네트워크 계층(Network Layer)
 - 여러개의 노드를 거쳐 패킷을 최종 수신대상에게 전달(End-To-End)하기 위한 경로 설정을 담당한다. 호스트를 식별하고 라우팅 등의 패킷포워딩을 수행하여 패킷이 목적지에 도달할 수 있도록 한다.
 - ### 대표 프로토콜
    <a src="./IP.md">IP</a>, DHCP, ARP, IGMP, ICMP

## 4. 전송 계층(Transport Layer)
 - 종단간 연결의 신뢰성과 유효성을 보장한다. 양 끝단의 사용자들이 통신하는 과정에서 생기는 오류를 검출, 복구하고 흐름을 제어하는 일을 담당한다. 프로세스를 특정하여 데이터를 전송하기 위해서 Port 번호를 사용하며, 주로 세그먼트(Segment) 라는 데이터 단위를 사용한다. 
 - ### 대표 프로토콜
    TCP, UDP 

## 5. 세션 계층(Session Layer)
 - 장치간의 연결을 관리 및 종료하고 체크포인팅과 유휴, 재시작 과정 등을 수행하며 호스트가 정상적으로 통신할 수 있도록 하는 계층이다. 통신을 하기 위한 세션을 확립/유지/중단하는 등의 역할을 담당한다. 
 - ### 대표 프로토콜
    Telnet, SSH (telnet과 SSH는 7계층으로 분류되기도 함 <a href="https://www.reddit.com/r/ccna/comments/5umh4m/comment/ddy5blj/?utm_source=share&utm_medium=web2x&context=3">참</a><a href="https://networkengineering.stackexchange.com/questions/29622/how-we-can-assume-which-network-protocol-is-working-in-which-osi-layer/30493#30493">고</a>)


## 6. 표현 계층(Presentation Layer)
  - 송·수신해야하는 데이터를 암·복호화 하는 일을 담당한다. 이 계층의 대표적인 프로토콜로는 ASCII, EBCDID, MPEG, JPEG 등이 있지만 응용계층과 구분하지 않고 수행하는 경우도 있다.

## 7. 응용 계층(Application Layer)
 - 사용자가 네트워크에 접근할 수 있는 응용 프로세스를 제공하는 계층이다. 네트워크 활동의 기반이 되는 인터페이스를 보여주고 사용자와 직접 상호작용할 수 있도록 한다.
 - ### 대표 프로토콜
    <a href="https://github.com/rlaisqls/TIL/blob/main/%EB%84%A4%ED%8A%B8%EC%9B%8C%ED%81%AC/HTTP.md">HTTP</a>, SMTP, FTP, DNS

<br>
<br>
<br>

---

더 알아보기<br>
OSI 계층별 프로토콜 예시 <br> https://en.wikipedia.org/wiki/List_of_network_protocols_(OSI_model)<br>
5-7 Layer 계층 구분 <br> https://www.reddit.com/r/ccna/comments/5umh4m/comment/ddy5blj/?utm_source=share&utm_medium=web2x&context=3 <br> https://networkengineering.stackexchange.com/questions/29622/how-we-can-assume-which-network-protocol-is-working-in-which-osi-layer/30493#30493

WebRTC(Web Real-Time Communication)란 웹 애플리케이션과 사이트가 중간자 없이 브라우저 간에 오디오나 영상 미디어를 스트림 하거나, 데이터를 자유롭게 교환할 수 있도록 하는 기술이다. 한마디로 요약하자면 드라이버나 플러그인 설치 없이 웹 브라우저 간 P2P 연결을 통해 데이터 교환을 가능하게 하는 기술이다. 

WebRTC는 기존의 웹 2.0에서 한층 더 나아가, 서버와 같은 중간자를 거치지 않고 브라우저 간을 P2P로 연결하는 기술이다. 화상 통화와 실시간 스트리밍, 파일 공유, 스크린 공유 등의 기능을 WebRTC 기반으로 구현할 수 있다. P2P 연결은 중개 서버를 거치지 않기 때문에 빠른 속도가 보장되며, HTTPS가 강제되기 때문에 중간자 공격에 대한 보안이 보장된다. 

WebRTC는 P2P 방식의 커뮤니케이션이기 때문에 각각의 웹 브라우저는 다음과 같은 절차를 밟아야한다.
1. 각 브라우저가 P2P 커뮤니케이션에 동의
2. 서로의 주소를 공유
3. 보안 사항 및 방화벽 우회
4. 멀티미디어 데이터를 실시간으로 교환

일반적인 웹 개발의 접근 방법으로는 2번, 3번의 단계를 해결하기 어렵다. 왜냐하면 브라우저는 웹 서버가 아니기 때문에, 외부에서 접근할 수 있는 주소가 없기 때문이다.

따라서 WebRTC에서는 다른 네트워크와 연결을 이루기 위해 STUN/TURN 서버를 주로 사용한다.

### STUN (Session Traversal Utilities for NAT)

STUN은 session traversal uilities for nat의 약자이다.

STUN 서버는 NAT을 통과하는 클라이언트 장치의 Public IP주소와 포트를 확인하고 이를 활용해 클라이언트 간 연결을 수행할 수 있게 도와준다. 정확히는 어떤 종단이 NAT/Firewall 뒤에 있는지를 판단하게 해주고, 어떤 종단에 대한 Public IP Address를 결정하며 NAT/FIrewall의 유형에 대해서 알려준다.

즉, 클라이언트는 자신의 public ip를 확인하기 위해 stun 서버로 요청을 보내고 서버로 부터 자신의 public ip를 받는다. 그래서 이때부터 클라이언트는 자신이 받은 public ip를 이용하여 시그널링을 할때 받은 그 정보를 이용해서 시그널링을 하게 한다.

다만 Symmetirc nat을 사용하는 경우는 어플리케이션이 달라지면 nat의 매핑테이블이 바뀔 수 있기 때문에, STUN 만으로 문제를 해결할 수 없다. 또, 네트워크 방화벽이 설정되어 있는 경우에도 STUN 서버를 통해 연결하기 어려울 수 있다.

<img style="height: 300px" alt="image" src="https://github.com/user-attachments/assets/90902a8c-db67-4c04-a150-d3078bd0c13b"/>

### TURN (Traversal Using Relays around NAT)

STUN은 NAT 뒤의 공인 IP주소를 알아내 클라이언트끼리 이를 활용해 연결할 수 있도록 중계하는 역할을 했다면 TURN은 데이터를 중계해준다.

따라서 공인IP가 변경되어도 중계서버인 TURN을 통해 데이터를 주고받을 수 있게 해준다.

TURN서버는 하나의 공인 주소를 가지고 있고 이 주소를 통해 클라이언트들이 직접적으로 미디어를 릴레이하기 때문에 네트워크와 컴퓨팅 자원이 소모된다.

대표적인 TURN 서버 구현으로 [Coturn](https://github.com/coturn/coturn)이 있다.
 
TURN 서버는 ICE의 일부로 사용될 수 있도록 디자인되었다.

<img style="height: 300px" alt="image" src="https://github.com/user-attachments/assets/813ccb38-a21d-4ff9-ad3b-2993771a6984"/>

### ICE (Interactive Connectivity Establishment)

위에서 얘기한 STUN, TURN 서버를 이용해서 획득했던 IP 주소와 프로토콜, 포트의 조합으로 구성된 연결 가능한 네트워크 주소들을 후보(Candidate) 라고 부른다. 그리고 이 과정을 후보 찾기(Finding Candidate)라고 부른다.

이렇게 후보들을 수집하면 일반적으로 3개의 주소를 얻게 된다.

- 자신의 사설 IP와 포트 넘버
- 자신의 공인 IP와 포트 넘버 (STUN, TURN 서버로부터 획득 가능)
- TURN 서버의 IP와 포트 넘버 (TURN 서버로부터 획득 가능)

이 모든 과정은 ICE(Interactive Connectivity Establishment) 라는 프레임워크 위에서 이루어진다. ICE는 두 개의 단말이 P2P 연결을 가능하게 하도록 최적의 경로를 찾아주는 프레임워크이다.

ICE 프레임워크는 STUN, 또는 TURN 서버를 이용해 상대방과 연결 가능한 후보들을 갖고 있다는 것이다. 두 브라우저가 P2P 통신을 위해 통신할 수 있는 주소를 알아냈으므로 미디어와 관련된 정보를 교환하기만 하면 되는데, WebRTC에선 정보 교환시에 SDP라는 프로토콜을 사용한다. 

### SDP (Session Description Protocol) 

<img style="height: 300px" src="https://github.com/user-attachments/assets/4e5327a8-5e9a-435e-938c-d6ecb870070b">

SDP는 WebRTC에서 스트리밍 미디어의 세부 정보, 전송 주소 갗은 초기 세션 메타데이터를 전달하기 위해 채택한 프로토콜이다.

SDP에는 다음과 같은 데이터들이 포함된다.
- 메타데이터
    - 세션 이름 및 목적
    - 세션이 활성화된 시간
    - 세션을 구성하는 미디어
    - 해당 미디어를 수신하는 데 필요한 정보(주소, 포트, 형식 등)
- 미디어 데이터 
    - 미디어 유형(비디오, 오디오 등)
    - 미디어 전송 프로토콜(RTP/UDP/IP, H.320 등)
    - 미디어 형식(H.261 video, MPEG video 등)

SDP는 초기 정보를 교환할 떄 한 피어가 미디어 스트림을 교환할 것이라고 제안한 후에, 상대방으로부터 응답이 오기를 기다린다.

그렇게 응답을 받게 되면, 각자의 피어가 수집한 ICE 후보 중에서 최적의 경로를 결정하고 협상하는 프로세스가 발생한다. 수집한 ICE 후보들로 패킷을 보내 가장 지연 시간이 적고 안정적인 경로를 찾는 것이다. 이렇게 최적의 ICE 후보가 선택되면, 기본적으로 필요한 모든 메타 데이터와 IP 주소 및 포트, 미디어 정보가 피어 간 합의가 완료된다.

이 과정을 통해 피어 간의 P2P 연결이 완전히 설정되고 활성화된다. 그 후 각 피어에 의해 로컬 데이터 스트림의 엔드포인트가 생성되며, 이 데이터는 양방향 통신 기술을 사용하여 최종적으로 양방향으로 전송된다.

이 과정에서 NAT의 보안 이슈 등으로 최선의 ICE 후보를 찾지 못할 수도 있기 때문에, 이때에는 폴백으로 세팅한 TURN 서버를 P2P 대용으로 설정한다. 통신에 TURN 폴백을 사용할 때 각 피어는 통신 세션 중에 실시간 멀티미디어 데이터를 중개하는 공용 TURN 서버만 알고 있으면 된다.

### 시그널링

TURN, SDP 등 WebRTC에서 클라이언트간 통신을 위해 준비하는 과정을 [시그널링](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Session_lifetime#signaling)이라고 부른다. 이 과정을 WebRTC 상에 정해진 스펙이 없으며, 사용자가 직접 이를 위한 솔루션을 구축해야한다.

시그널링 서버를 직접 구축한다면 웹소켓이나 Server-sent Event 등의 방법을 사용할 수도 있다. [(참고)](https://github.com/muaz-khan/WebRTC-Experiment/blob/master/Signaling.md)

---
참고
- https://mullvad.net/ko/help/webrtc
- https://wormwlrm.github.io/2021/01/24/Introducing-WebRTC.html
- https://developer.mozilla.org/ko/docs/Web/API/WebRTC_API/Protocols
- https://medium.com/sessionstack-blog/how-javascript-works-webrtc-and-the-mechanics-of-peer-to-peer-connectivity-87cc56c1d0ab
- https://www.rfc-editor.org/rfc/rfc8866.html



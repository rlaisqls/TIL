private 통신을 위해 UDP 포트를 열어놓고 [STUN과 ICE](/til/network/webrtc/)를 사용하여 통신하는 경우가 있다. 하지만 이 방법은 필요한 커넥션의 갯수만큼 많은 포트를 열어놓아야 하기 때문에, Tailnet에선 보안적으로 더 우수한 DERP(Designated Encrypted Relay for Packets) 라는 방법을 사용한다.

DERP는 각 수신자에게 가장 가까운 DERP를 통해 트래픽을 비대칭적으로 라우팅한다.

Tailscale 개인 키는 생성된 노드를 절대 떠나지 않는다. 이는 DERP 서버가 귀하의 트래픽을 해독할 수 있는 방법이 전혀 없다는 것을 의미한다. 단지 이미 암호화된 트래픽을 한 노드에서 다른 노드로 맹목적으로 전달할 뿐이다. 이는 남용을 방지하기 위해 약간 더 고급 프로토콜을 사용하기는 하지만 인터넷의 다른 라우터와 같다.

DERP는 IP 주소 대신 WireGuard 공개 키를 사용해 피어를 주소 지정하는 패킷 릴레이 시스템(클라이언트 및 서버)이다.DERP는 두 가지 유형의 패킷을 릴레이한다:

- NAT 트래버설 중 부채널로 사용되는 [disco](https://github.com/tailscale/tailscale/blob/main/disco/disco.go) 발견 메시지
- UDP가 차단되거나 NAT 트래버설이 실패했을 때 최후의 수단으로 사용되는 암호화된 WireGuard 패킷

### DERP Map

각 클라이언트는 조정 서버로부터 사용할 DERP 서버를 설명하는 "DERP 맵"을 받는다. 클라이언트는 지연 시간을 기준으로 "DERP 홈"을 선택한다.

클라이언트는 DERP 홈을 선택하고 이를 조정 서버에 보고한다. 그러면 서버는 이를 테일넷의 모든 피어와 공유한다. 피어가 패킷을 보내려고 하는데 WireGuard 세션이 열려 있지 않으면, NAT 트래버설을 시도하기 위해 디스코 메시지(일부는 직접, 일부는 DERP를 통해)를 보낸다. 클라이언트는 필요에 따라 여러 DERP 지역에 일시적으로 연결하고, DERP 홈 지역 연결만 영구적으로 유지된다.

### DERP 지역 Region

Tailscale은 사용자가 DERP 홈에 대한 낮은 지연 시간을 가질 수 있도록 다양한 지리적 지역에서 1개 이상의 DERP 노드(cmd/derper의 인스턴스)를 운영한다.

지역에는 일반적으로 여러 개의 노드가 "메시"(서로 라우팅)되어 있어 중복성을 제공한다. 이를 통해 클라우드 장애나 업그레이드 시 사용자를 더 높은 지연 시간의 지역으로 내보내지 않고도 대응할 수 있다. 대신 클라이언트는 해당 지역의 다음 노드에 다시 연결한다. 지역 내 각 노드는 해당 지역의 다른 모든 노드와 메시를 이루고 패킷을 다른 노드로 전달해야 한다. 패킷은 지역 라우팅은 없이 지역 내에서 한 번씩만 라우팅된다.

조정 서버는 테일넷의 기능으로 지역 내 노드 목록을 할당하므로, 테일넷 내의 모든 노드는 일반적으로 동일한 노드에 있어야 하고 전달이 필요없는 상태이다. 장애가 발생한 후에만 특정 테일넷의 클라이언트가 지역 내 노드 간에 분할되어 노드 간 전달이 필요하고, 시간이 지나면 다시 균형을 이룬다. 또한 운영자가 더 빨리 균형을 맞추고 싶을 때 특정 클라이언트의 TCP 연결을 강제로 닫아 기본 연결로 다시 연결하도록 하는 관리자 전용 DERP 프레임 유형도 있다. (Tailscale의 내부에서 거의 사용되지 않는 cmd/derpprune 유지 관리 도구에서 사용하는 (*derphttp.Client).ClosePeer 메서드를 사용)

---
참고

- <https://tailscale.com/kb/1232/derp-servers>
- <https://pkg.go.dev/tailscale.com/derp#section-readme>
- <https://svrforum.com/svr/977239>

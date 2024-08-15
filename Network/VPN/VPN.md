VPN이란 가상사설망이다. TCP/IP 기반의 개방형 네트워크인 인터넷에서 한 네트워크에서 다른 네트워크로 이동하는 모든 데이터 정보를 암호화하여 사설망 기능을 제공하기 위해 도입된 기술이다. 즉, 원격지에서 특정 네트워크(서버)와 마치 유선으로 연결된 것처럼 연결하는 것이다. VPN 터널은 암호화되기 때문에 해킹을 당했을 시에도 통신 데이터를 보호할 수 있다. 

VPN의 종류는 대표적으로 IPsec VPN, SSL VPN이 있다.

### IPsec VPN 

IPsec VPN은 VPN 게이트웨이(서버) 장비 2개를 서로 연결함으로써 네트워크와 네트워크를 연결하는 VPN이다. 기업의 본사 네트워크와 지사 네트워크를 연결하는 용도로 주로 사용된다.
 
IPSec VPN을 IPSec VPN이라 부르는 이유는 VPN 터널을 생성하고 데이터를 암호화하는 방식에 있어 IPSec의 규칙을 철저히 따르기 때문이다. 여기서 IPSec의 역할은 인터넷 경유 구간에서 안전한 터널을 생성하고. 패킷을 인증할 수단을 제공하며, 패킷을 암호화할 키를 관리하고 제공하는 것이다.

게이트웨이가 각 망마다 1개씩 필요하기 때문에 비용이 많이 든다.
 
OSI 7계층 중 3계층인 네트워크 계층에서 동작한다. (IP 프로토콜 사용)

IPsec VPN은 TCP, UDP를 모두 지원한다.

<img style="height: 200px" alt="image" src="https://github.com/user-attachments/assets/699434bc-b3f6-40e5-a9e6-2bbac414b180">

### SSL VPN

SSL VPN은 Client to Site 방식으로 사용되는 VPN이다. 즉 사용자가 네트워크에 접근하기 위해 사용되는 VPN이라는 의미이다. 사내 SSL VPN을 구축했다면, 사용자는 인터넷만 연결되어 있을 때 언제, 어디서든 VPN을 통해 사내 네트워크에 접근할 수 있다. 

SSL 프로토콜은 사용자로 하여금 접속하고자 하는 SSL VPN이 진짜인지, 접속하려는 사용자가 인가된 사용자인지 검증이 가능하도록 하며, 암호화 프로토콜을 제공해 사용자와 SSL VPN이 암호화 터널을 통한 통신을 할 수 있도록 지원한다.

VPN 장비가 하나만 있으면 되기 때문에 IPsec VPN에 비해 적은 비용이 든다.

OSI 7계층 중 6계층인 표현 계층에서 동작한다. SSL VPN은 UDP를 지원하기 않기 때문에 사용 가능한 어플리케이션이 제한적이다.  

<img style="height: 250px" alt="image" src="https://github.com/user-attachments/assets/8315a0dc-b160-4d39-8c29-7626adb02975">

---
참고
- https://nordvpn.com/ko/blog/ssl-vpn-protocol
- https://aws-hyoh.tistory.com/161
- https://tailscale.com/compare/ipsec



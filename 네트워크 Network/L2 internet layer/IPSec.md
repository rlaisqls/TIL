# IPSec

IPSec IP계층(네트워크 계층)을 안전하게 보호하기 위한 기법이다. 대부분의 네트워크 응용프로그램은 IP 계층을 사용하기 때문에 IP계층에서 동작하는 보안, 즉, 페킷에 대한 보안을 제공하는 IP Security(IPSec)가 필요하다.

## 모드

IPSec에는 두 가지 모드가 있는데, IP의 내용(payload)만을 보호하느냐, 아니면 헤더까지 모두 보호하느냐에 따라서 전송 모드(Transport Mode), 후자는 터널 모드(Tunnel Model)로 나뉜다.

### 전송 모드(Transport Mode)

전송모드는 전송 계층와 네트워크 계층 사이에 전달되는 payload를 보호한다. 중간에 IPSec 계층이 있기 때문에 IPSec 헤더가 붙고, 이후에 네트워크 계층에서는 이것이 모두 상위층에서 보낸 데이터(payload)로 취급이 되므로 IP 헤더가 붙고 아래 계층으로 전달된다. 

<img width="721" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/4b197eee-8018-48a3-956d-7acd1d3e4dda">

전송모드는 host-to-host(end-to-end)간 데이터 보호가 필요할때 사용된다. 아래는 전송모드의 데이터 전송 흐름을 보여준다.

왼쪽 컴퓨터(host)는 IPSec을 적용하여 데이터를 보낸다. 네트워크를 통해서 오른쪽 컴퓨터로 데이터가 도착한다.

이 사이에서 다른 사람이 데이터를 가져가도 IPSec로 보호 되어있으므로 볼 수 없고, 라우터를 거쳐 종점에 도착했을 떄의 두 당사자만 데이터를 확인할 수 있다. 그래서 tls와 유사하게 종단 간의 보호(End-To-End Protection, E2EP)가 이루어 질 수 있다. 다만 보호가 이뤄지는 계층이 다르다는 점이 차이이다.

<img width="872" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/b7cd4012-3ba7-433c-a202-270fc7cee45e">

### 터널 모드(Tunnel Mode)

터널 모드의 IPSec은 IP 헤더를 포함한 IP 계층의 모든 것을 보호한다. IP 헤더까지 완전히 보호하고 IPSec의 헤더를 추가하였으니 기존의 IP 헤더를 볼 수 없어서 새로운 IP 헤더가 추가된다. 

<img width="721" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/156a91f3-d726-49e8-b697-482c2b5763cc">

이 IPSec 헤더와 새로운 헤더는 종단이 아닌 그 중간자가, 대부분의 경우 라우터가 추가해준다. 

아래는 그 흐름을 보여준다. 전송모드와는 다르게 호스트 A는 별다른 IPSec의 조취를 취하지 않는다. 하지만 Router A에서 IPSec을 적용하고 새로운 IP 헤더를 추가한다.

이 헤더에는 목적지 라우터의 주소가 있어서 Router B로 보낸다. Router B는 이후에 적절한 조치를 취하고 새 IP 헤더와 IPSec 헤더를 제거한 후 Host B에게 전달한다.

마치 RouterA, RouterB가 터널 역할을 하는 것과 같다. 터널 모드는 주로 종단-종단 간 통신이 아닌 경우에 사용된다. (두개의 라우터간, 호스트와 라우터간, 라우터와 호스트간)

<img width="709" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/ce11a46a-c463-4c94-a9e2-d2228b01f0ed">

## 프로토콜

IPSec은 또 두가지 보안 프로토콜을 제공한다.

- **AH(Authentication Header Protocol)** -  인증에 대해서만 검사하는 인증헤더 프로토콜
- **ESP(Encapsulating Security Payload)** - 페이로드 전체를 보호하여 기밀성을 제공하는 보안 페이로드 캡슐화

### AH(Authentication Header)

발신지 호스트를 인증하고 IP 패킷의 무결성을 보장한다. 인증을 위해서 해시함수와 대칭키가 사용되어 Message Digest를 생성하고 헤더에 삽입한다. AH는 인증과 무결성을 보장하지만 비밀은 보장해주지 않는다.

<img width="702" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/5008934b-7666-4d0f-bee5-a544cc9f0706">

- **Next Header** : IPSec 다음에 오는 페이로드의. TCP인지 UDP인지 또는 ICMP인지 의미한다.
- **Payload Length** : 인증헤더의 길이. 
- **Security Parameter Index** : 32bit 보안 매개변수 색인(SPI) 필드, Security Association에 대한 식별자
- **Sequence Number** : 32bit 순서번호 (replay attack을 방지)
- **Authentication Data** : 헤더를 포함하여 전체 페킷에 대한 데이터를 인증 데이터로 만든다. 이때 IP 헤더의 변경될 수 있는 데이터는 제외된다.

### ESP(Encapsulating Security Payload)

AH가 데이터의 기밀성을 보장할 수 없지만 ESP는 기밀성을 보장할 수 있다. 또한 AH가 보장하는 IP패킷의 무결성 등 AH가 제공하는 서비스를 모두 보장할 수 있다.

<img width="729" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/f51f3240-55bb-4f3f-a0f8-bcd00e67751f">

ESP 헤더 구성 대부분은 AH의 필드와 유사하다.

AH와는 다르게 인증데이터가 IP헤더를 포함하지 않는다. ESP 헤더까지만 인증데이터로 만들고 ESP Trailer에 붙이게 된다.

|Services|AH|ESP|
|-|-|-|
|Access Control|O|O|
|Message Authentication\n(Message Integrity)|O|O|
|Confidentiality|X|O|
|Replay Attack Protection|O|O|
|Entity Authentication\n(Data Source Authentication)|O|O|

---
reference
- https://aws.amazon.com/ko/what-is/ipsec/
- https://www.cloudflare.com/ko-kr/learning/network-layer/what-is-ipsec/
- https://en.wikipedia.org/wiki/IPsec
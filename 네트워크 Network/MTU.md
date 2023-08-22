# MTU(Maximum Transmission Unit)

- 데이터링크에서 하나의 프레임 또는 패킷에 담아 운반 가능한 최대 크기
- MTU란 TCP/IP 네트워크 등과 같은 패킷 또는 프레임 기반의 네트워크에서 전송될 수 있는 최대 크기의 패킷 또는 프레임을 말한다.
- 한 번에 전송할 수 있는 최대 전송량(Byte)인 MTU 값은 매체에 따라 달라진다.
- Ethernet 환경이라면 MTU 기본값은 1500, FDDI 인 경우 4000, X.25는 576, Gigabit MTU는 9000 정도 등 매체 특성에 따라 한 번에 전송량이 결정된다.
- 상위 계층(즉, 물리적, 데이터링크, 네트워크, 인터넷, 애플리케이션 중 네트워크 계층 이상 계층을 말함)의 데이터(헤더 포함된 전체 사이즈)의 수용 가능한 최대 크기로도 생각할 수 있다.
- 따라서, 상위 계층 프로토콜(네트워크 계층 이상)은 하위 계층인 데이터링크에서의 MTU에서 맞추어야 합니다. 그래서 IP 단편화 등을 시행할 수밖에 없다.
- 기본적인 MTU 1500을 초과하는 것은 "Jumbo Frame"이라고 불린다.
- Offical Maxtimun MTU 값은 65535이다.
 
## 2계층 (Data-Link Layer) 네트워크에서 종류별 MTU 권고값

- DIX Ethernet : 1500 bytes
- 802.3 Ethernet : 1492 byte

## 3계층 (IP Layer)에서 MTU 권고값

- IPv4에서 MTU 최소 권고값은 576byte이다. (RFC 791에서 IP 패킷 구조상으로 볼 때는 68~65,535바이트 범위로써 가능하나, 수신 처리 가능한 MTU 최소값은 576바이트로 권고)
- IPv6에서 MTU 최소 권고값은 1280 bytes이다.

## MTU값 계산

- MTU는 Ethernet프레임을 제외한 IP datagram의 최대 크기를 의미한다. 
- 즉, MTU가 1500이라고 할 때 IP Header의 크기 20byte 와 TCP Header의 크기 20byte를 제외하면 실제 사용자 data는 최대 1460까지 하나의 패킷으로 전송될 수 있다.
- Window 계열에서는 PC의 기본 MTU가 1500으로 설정되어 있으며 레지스터리에 특정 값을 적어주지 않으면 자신의 MTU값을 1500으로 설정한다. 
그러나 Win2000부터 Media의 특성을 인식하여 dynamic하게 MTU를 설정하게 된다.

## 운영체제별 MTU 확인 방법

- 윈도우 : `netsh interface ip show interface`
- Linux : `ifconfig`

## MSS(Maximum Segment Size)

- MSS는 Maximum Segment size의 약어로 TCP상에서의 전송할 수 있는 사용자 데이터의 최대 크기이다. 
- MSS값은 기본적으로 설정된 MTU 값에 의해 결정된다. 
- 예를 들어 Ethernet일 경우 MTU 1500에 IP 헤더크기 20byte TCP 헤더 크기 20byte를 제외한 1460이 MSS 값이다.

```bash
MSS = MTU – IP Header의 크기(최소 20byte) – TCP Header의 크기(최소 20byte)
```

---
참고
- http://ktword.co.kr/test/view/view.php?nav=2&opt=&m_temp1=638&id=484
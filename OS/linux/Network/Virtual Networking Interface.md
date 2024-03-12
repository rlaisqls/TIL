
리눅스는 컨테이너 기술의 기반이 되는 virtual networking 관련 기능들을 제공한다. virtual networking에 자주 사용되는 대표적인 네트워크 인터페이스를 알아보자.

## Bridge

Linux Bridge는 일반적인 네트워크 스위치와 유사하게 동작한다. Bridge는 주로 라우터, 게이트웨이, VM 등에서 패킷을 목적지로 전달(forwarding)하는 역할을 수행한다. Bridge는 STP, VLAN filter, multicast snooping등의 기능도 추가적으로 지원한다.

<img src="https://github.com/team-aliens/.github/assets/81006587/8ae445a2-cd94-4736-8c8a-5f23f65f7cd3" height=270px/>

아래의 소스코드는 리눅스에서 Bridge를 생성하고, 서로 다른 네트워크 인터페이스와 연결하는 과정을 코드로 작성한 예시이다. 이 과정을 거치면, 브릿지를 통해 VM 1, VM 2과 network naemspace 1은 서로 통신이 가능해진다.

```bash
$ ip link add br0 type bridge # bridge 생성
$ ip link set eth0 master br0 # bridge와 host의 eth0 네트워크 인터페이스 연결
$ ip link set tap1 master br0 # bridge와 VM1의 tap 디바이스 연결
$ ip link set tap2 master br0 # bridge와 VM2의 tap 디바이스 연결
$ ip link set veth1 master br0 # bridge와 network namespace 1를 veth로 연결
```

## Bonded Interface

Linux Bonding Driver(네트워크 본딩)는 서로 다른 네트워크 인터페이스를 하나의 논리적 인터페이스로 묶는 기능을 수행한다. Bonding Driver는 크게 `hot-standby`와 `load balacing` 모드로 나뉜다.

`Hot-standby` 모드는 네트워크 인터페이스를 Active와 Standby로 나누고 Active에서 네트워크 장애 발생 시, 트래픽을 Standby로 전송하여 장애에 대응하는 방식으로 작동한다.

`Load balancing` 모드는 패킷을 여러 네트워크 인터페이스에 분배하여 네트워크 처리량과 대역폭을 증가시키는 등 성능 향상을 위해 사용된다. Load balancing 모드에서는 Round-Robin, XOR, Broadcast 등의 세부적인 트래픽 분배 정책을 선택할 수 있다.

![image](https://github.com/team-aliens/.github/assets/81006587/21dbf9d3-e17f-4ca9-a9ae-28b299d2ada0)

아래는 두 네트워크 인터페이스(eth0, eth1)을 hot-standy 모드로 묶는 예시이다.

```bash
$ ip link add bond0 type bond miimon 100 mode active-backup # bond0 인터페이스 추가, 모니터링 주기 100ms, active-backup 모드
$ ip link set eth0 master bond0 # eth0을 bond0 인터페이스에 추가
$ ip link set eth1 master bond0 # eth1을 bond0 인터페이스에 추가
```

## Team Device

Team Device는 bonded interface와 유사하지만, L2 레벨에서 여러 개의 NIC를 하나의 논리적 그룹으로 묶는 기능을 수행한다.

![image](https://github.com/team-aliens/.github/assets/81006587/d3d5a481-0711-414d-acb0-1313d2bfeb78)

아래는 팀 디바이스를 생성하고 2개의 네트워크 인터페이스(eth0, eth1)를 묶는 과정을 수행하는 예시이다.

```bash
$ teamd -o -n -U -d -t team0 -c '{"runner": {"name": "activebackup"},"link_watch": {"name": "ethtool"}}'
$ ip link set eth0 down
$ ip link set eth1 down
$ teamdctl team0 port add eth0
$ teamdctl team0 port add eth1
```

## VLAN

VLAN은 virtual LAN의 줄임말로 하나의 스위치에서 브로드캐스트 도메인을 논리적으로 분할하기 위해 활용된다. 브로드캐스트에서는 일반적으로 동일한 LAN에 포함된 모든 네트워크 단말로 패킷을 송출한다. VLAN은 하나의 스위치에서 태그를 붙이는 방식으로 LAN을 논리적으로 분할하여 브로트캐스트 과정에서 발생하는 불필요한 대역폭 낭비 등을 개선한다.

VLAN을 위한 프로토콜은 IEEE 802.1Q에서 정의하고 있다. IEEE 802.1Q는 일반적으로 VLAN tagging이라고도 불린다. VLAN 헤더에는 VLAN ID 필드가 존재한다. VLAN ID는 VLAN을 구분하기 위해 활용되며 12bit로 4,096개의 값을 가질 수 있다.

<img src="https://github.com/team-aliens/.github/assets/81006587/d9e33e48-b1b7-4edf-9b27-16a733a864e2" height=270px/>
<img src="https://github.com/team-aliens/.github/assets/81006587/743b0af7-fc08-4b62-b1b0-997a99e91885" height=270px/>

아래는 메인 네트워크 인터페이스(eth0)를 2개의 VLAN(eth0.2, eth0.3)으로 분리하는 예시이다.

```bash
ip link add link eth0 name eth0.2 type vlan id 2
ip link add link eth0 name eth0.3 type vlan id 3
```

## veth

veth는 virtual Ethernet의 줄임말로, 로컬 이더넷 터널에 해당한다. veth는 한 쌍으로 생성되며, 한 쪽에서 다른 쪽으로 패킷을 전송할 수 있으며, 한 쪽에 다운된 경우 나머지 한 쪽도 정상적으로 기능하지 않는 것이 특징이다.

veth 타입의 장비는 기본적으로 리눅스의 디폴트 네임스페이스에 속하게 되며, 활성화되지 않은 상태로 생성된다. veth0과 veth1은 직접 연결되어있기 때문에 활성화 상태는 항상 동시에 변경된다. 

<img src="https://github.com/team-aliens/.github/assets/81006587/d72ca9f4-9550-48fc-a7a0-4cf918281532" height=270px/>

아래의 코드는 호스트 머신에서 두 개의 네트워크 네임스페이스(netns1, netns2)를 생성하고, VETH를 활용하여 호스트 네트워크와 새롭게 생성된 네트워크 네임스페이스를 연결하는 과정을 구현한 것이다.

```bash
$ ip netns add netns1
$ ip netns add netns2
$ ip link add veth1 netns netns1 type veth peer name veth2 netns netns2
```

---
참고
- https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/
- https://www.44bits.io/ko/keyword/veth
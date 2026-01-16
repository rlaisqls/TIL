
---

## 개요

<img width="725" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/58a8c56e-08ef-4f5c-a109-42596b582f06">


- **스위치**: 같은 네트워크 내에서 통신을 중재하는 L2 장비
- 이더넷을 구성하기 위해 사용되는 경우 이더넷 스위치라고도 불린다
- 패킷 경합을 없애서 여러 단말이 동시에 효율적으로 통신할 수 있게 함
- 구조가 간단하고 가격이 저렴함. 신뢰성과 성능이 높음.

## **MAC 주소 테이블**

---

<img width="544" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/5668a962-d4c6-47e2-bd9f-01b2df70d3d5">


- 여러 NIC와 포트로 연결됨
- 각 NIC의 MAC을 기억해놓고, 어느 호스트가 특정 MAC 주소와 연결하고 싶다 요청하면 연결해줌
- 허브는 한 포트로 신호가 들어오면 같은 신호를 다른 모든 포트로 전달함
    - 반면 스위치는 플러딩할 때만 모든 포트로 전달하고, 나머지의 경우에는 정보를 **MAC 주소 Table**에 저장해서 필요한 포트에만 전달하기 때문에 속도가 더 빠름

## 동작 과정

---

1. **Address learning:** 
이더넷 프레임이 수신되면, source MAC 주소를 읽어서 수신 port 번호와 함께 MAC Table에 기록한다.
2. **Flooding:**
Destination MAC address가 MAC Table에 등록되어 있지 않은 Unicast 프레임(Unknown Unicast)이거나, ARP Request와 같은 브로드캐스트인 경우, 수신 port를 제외한 다른 모든 port로 프레임을 전송한다. 
    
    허브에서 데이터를 전송하는 것도 Flooding이라 부른다.
    
3. **Filtering:**
Destination MAC address가 MAC Table에 등록되어 있고, 등록되어 있는 port 번호가 프레임이 수신된 port 번호와 동일한 경우 해당 프레임이 포워딩 당하지 않도록 차단한다.
4. **Forwarding:**
Destination MAC address가 MAC Table에 등록되어 있고, 등록되어 있는 port 번호가 프레임이 수신된 port 번호와 동일하지 않은 Unicast인 경우 등록되어 있는 port로 프레임을 전송한다.
5. **Aging:**
MAC Table에 Entry가 등록될때 Timer도 같이 start 되며, 해당 Entry의 MAC address를 source MAC으로 하는 프레임이 수신되면 Timer가 reset 되어 다시 시작된다.
    
    Timer가 경과되면 해당 Entry는 MAC Table에서 삭제된다. TTL 같은 개념이다

# VLAN

---

## 개요

- **VLAN**: 하나의 물리 스위치에서 여러개의 가상 네트워크를 만드는 것
- 옛날에는 스위치가 고가였기 때문에, 한 스위치를 분할해 사용하고자 하는 목적으로 생긴 개념이다.
- 물리적으로 스위치를 분리할 때 보다 장비를 효율적으로 사용
- 물리적 구성과 상관 없이 네트워크를 분리할 수 있다.
- 한 대의 스위치에 연결되더라도 VLAN으로 분리된 단말 간에는 3계층 통신이 필요하다.

<img width="430" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/286ef68b-8b25-4cf2-9199-a48828efb44b">


## 종류

---

- **포트 기반 VLAN**
    - 어떤 단말이 접속하든지 스위치의 포트를 기준으로 VLAN을 할당한다.
    - 일반적으로 언급하는 대부분의 VLAN은 이 포트기반 VLAN을 뜻한다.
- **주소 기반 VLAN**
    - 스위치의 고정 포트가 아닌, 단말의 MAC 주소를 기준으로 VLAN을 할당한다.
    - 단말이 연결되면 단말의 MAC 주소를 인식한 스위치가 해당 포트를 지정된 VLAN으로 변경한다.
    - 단말에 따라 VLAN 정보가 바뀔 수 있어 다이나믹 VLAN이라고도 부른다.

## 스위치 간 연결

---

- 태그 기능이 없는 VLAN 네트워크에서 여러 스위치를 연결하려면 VLAN의 갯수 만큼 포트를 사용해야한다.
    
    <img width="446" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/ca16ce62-fcb4-44cb-ad7e-d8a539fe0ed4">

    
- VLAN이 더 많아지면 위와 같은 구조는 비효율적이다.
- 그렇기 때문에, 여러 스위치를 연결하기 위해선 Tagged Port를 사용한다.
    - 태그 포트는 통신할 때 이더넷 프레임에 VLAN 정보를 같이 담아 보낸다.
    - 태그 포트로 트래픽이 들어오면 태그를 벗겨내면서 해당 VLAN으로 패킷을 전송한다.
    - 이 경우 일반적인 포트는 Untagged Port, 또는 Access Port라고 부른다.
    
    <img width="448" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/960594f2-b8fd-4d04-b1d2-061a6b3b9422">

    

## Loop

---

- IT 환경에서는 SPoF(Single Point of Failure: 단일 장애점)로 인한 장애를 피하기 위해 노력한다.
- 만약 네트워크를 스위치 하나로 구성하면, 그 스위치에 장애가 발생했을 때 전체 네트워크에 장애가 발생한다. 그러나 이런 SPoF를 피하기 위하기 위해 스위치 두 대 이상으로 네트워크를 구성하면 패킷이 루프되어 네트워크를 마비시킬 수 있다.
- 루프의 원인은 크게 두가지가 있다.
    - **브로드캐스트 스톰 (Broadcast Storm)**
        - 루프 구조로 연결된 상태에서 브로드캐스트를 발생시키면 스위치는 이 패킷을 모든 포트로 플러딩한다. 플러딩된 패킷은 다른 스위치로도 보내지고 이 패킷을 받은 스위치는 패킷이 유입된 포트를 제외한 모든 포트로 다시 플러딩한다.
        - 이렇게 계속해서 브로드캐스트가 반복되는 것을 브로드캐스트 스톰이라 한다.
            
            <img width="356" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/9d4ce217-407b-4f9b-9118-158152533e60">

            
    - ****스위치 MAC 러닝 중복 (Port Flapping)****
        - 스위치는 출발지 MAC 주소를 학습하는데, 직접 전달되는 패킷과 스위치를 돌아 들어간 패킷 간의 포트가 다르면 MAC 주소를 정상적으로 학습할 수 없다.
        - MAC 주소 테이블에서는 하나의 MAC 주소에 대해 하나의 포트만 학습할 수 있으므로 동일한 MAC 주소가 여러 포트에서 학습되면 MAC 테이블이 반복 갱신되어 문제가 생긴다.
        - 브로드캐스트 스톰과 달리 동적 라우팅이나 잘못된 설정 등 통제 가능한 원인으로 인해 생긴다. ([참고](https://www.manageengine.com/network-monitoring/tech-topics/route-flapping.html#common))
            
            <img width="374" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/98fff75b-72f0-4f33-8be0-22c68d9e620d">

            

## STP(Spanning Tree Protocol)

---

STP는 스위치가 연결된 구조를 학습하고, 통신할 수 있는 최소 경로의 포트만 남기고 나머지를 block하여 루프를 없앤다. 이름에서 알 수 있듯 스패닝 트리 알고리즘을 활용한다.

**참고를 위한 스패닝 트리 사진**
<img width="716" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/a4f13761-027e-414c-880f-3327ae039aaf">




### **BPDU(Bridge Protocol Data Unit)**

- 스패닝 트리 프로토콜을 이용해 루프를 예방하려면 전체 스위치가 어떻게 연결되는지 알아야 한다. 이를 위해 BPDU라는 프로토콜이 사용된다.
- 2초마다 한번씩 정보를 보내 확인한다.
    - 만약 한 port에 문제가 생겨도, 트리를 다시 파악하여 재구성한다.
- Configuration BPDU에는 `Bridge ID`, `Root Bridge ID`, `Port ID`, 경로, Timer 등의 정보가 있다.

### **STP 동작과정**

- 모든 스위치는 처음에 자신을 루트로 인식해 BPDU를 통해 2초마다 자신이 루트임을 광고한다
1. 루트를 선정한다.
    - 브릿지 ID가 더 적은 스위치가 있으면 그 스위치를 루트 스위치로 인식한다.
2. 루트가 아닌 스위치는 Root에서 온 BPDU를 받은 포트를 `Root port`로 선정한다.
    - Root port는 루트 브릿지로 가는 경로가 가장 짧은 포트이다.
3. 스위치와 스위치가 연결되는 포드는 하나의 `Designated port`를 선정한다.
    - Root Bridge의 BPDU를 다른 스위치들에게 전달하기 위해 지정된 포트이다.
    - Root-Bridge는 모든 포트가 DP로 설정이 되어 Forward 상태가 된다.
    - Root port도 아니고 Designated port도 아닌 포트는 대체(Alternate) 포트로 지정되고, Blocking 상태가 된다.

최종적으로 아래와 같은 형태가 되어서, 스위치 사이에 loop가 생기지 않게 된다.

<img width="391" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/bc3fe66d-89b4-4c63-95fd-57c679c36361">


### **스위치 포트 상태**

스패닝 트리를 구성할 때 각 스위치의 상태는 아래와 같이 바뀐다.

- **Blocking** (20초)
    - 패킷 데이터를 차단한 상태로 상대방이 보내는 BPDU를 기다린다.
    - Max Age 기간 동안 상대방 스위치에서 BPDU를 받지 못했거나 후순위 BPDU를 받았을 떄 포트는 리스닝 상태로 변경된다.
- **Listening** (15초)
    - 해당 포트가 전송 상태로 변경되는 것을 결정하고 준비하는 단계이다. 이 상태부터 자신의 BPDU 정보를 상대방에게 전송하기 시작한다.
- **Learning** (15초)
    - 러닝 상태는 해당 포트를 포워딩하기로 결정하고 실제로 패킷 포워딩이 일어날 때 스위치가 곧바로 동작하도록 MAC 주소를 러닝하는 단계이다.
- **Forwarding**
    - 정상적인 통신이 가능해 패킷을 포워딩하는 단계이다.

스패닝 트리 프로토콜은 loop를 예방하기 위해  BPDU가 전달되는 시간을 고려하여 각 상태에서 충분히 대기한다. 그렇기 때문에 스위치에 신규로 장비를 붙이면 (해당 장비가 스위치가 아니더라도 검증을 위해) BPDU를 일정 시간 이상 기다린다.

## 향상된 STP

---

### RSTP (Rapid Spanning Tree Protocol)

- STP에서 백업 경로를 활성화하는데 시간이 너무 오래 걸리는 문제를 해결하기 위해 개발된 프로토콜
- STP는 토폴로지가 변경되면 말단에서 루트까지 보고하는 과정을 거쳤기에 느렸다. 하지만 RSTP에선 토폴로지 변경이 일어난 스위치 자신이 모든 네트워크에 토폴로지 변경을 직접 전파할 수 있다. (RSTP는 2~3초면 모든 변경을 전파할 수 있다)
    
    <img width="656" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/0c75effe-42ea-4156-807a-2488e0d55b41">

    
- 기본적인 구성과 동작 방식은 STP와 같지만 BPDU 메시지 형식을 더 다양하게 사용한다
        

### MST (Multiple Spanning Tree)

- STP, RSTP에서는 VLAN의 개수와 상관 없이 트리는 1개를 사용했다. (CST, Common Spanning Tree)
    - VLAN이 여러개인 경우, 해당 방식에선 루프가 생기는 토폴로지에서 한 개의 포트와 회선만 쓰니 더 비효율적이다. 또한 VLAN마다 최적의 경로가 다를 수 있는데 포트를 사용할 수 없어 멀리 돌아야하는 경우가 생긴다.
- 이 문제를 해결하기 위해 PVST(Per Vlan Spanning Tree)가 개발되었고, VLAN마다 별도의 Block port를 지정해 네트워크 로드를 셰어링할 수 있게 되었다.
    - 그러나 PVST는 모든 VLAN마다 별도의 스패닝 트리를 유지해야하므로 더 많은 부담이 되었고, 이런 단점을 보완하기 위해 MST가 개발됐다.
- MST는 **여러개의 VLAN**을 **리전**이라는 단위로 묶어 사용한다.
    - CST 보다는 효율적이고, PVST 보다는 오버헤드가 적다.

---

### 여담

> **스위치의 IP주소**
> 스위치는 2계층 장비여서 MAC 주소만 이해할 수 있다. 스위치 동작에 IP는 필요 없지만 일정 규모 이상의 네트워크에서 쓰이는 스위치는 대부분 관리목적으로 IP 주소가 할당된다.
> 스위치 구조는 크게 관리용 Control Plan과 패킷을 포워딩하는 Data plane으로 나뉘는데, IP는 컨트롤 플레인에 할당되게 된다.

---

**참고**
- [IT 엔지니어를 위한 네트워크 입문](https://m.yes24.com/Goods/Detail/93997435)
- https://pgono.tistory.com/57
- [https://net-study.club/entry/스패닝-트리-프로토콜STP-Spanning-Tree-Protocol](https://net-study.club/entry/%EC%8A%A4%ED%8C%A8%EB%8B%9D-%ED%8A%B8%EB%A6%AC-%ED%94%84%EB%A1%9C%ED%86%A0%EC%BD%9CSTP-Spanning-Tree-Protocol)
- [**https://en.wikipedia.org/wiki/Spanning_Tree_Protocol**](https://en.wikipedia.org/wiki/Spanning_Tree_Protocol)
- [**https://www.youtube.com/watch?v=Iw12n7vfUlg**](https://www.youtube.com/watch?v=Iw12n7vfUlg)
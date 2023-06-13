# VPC(Virtual Private Cloud)

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/a61614ad-4b4e-4533-ba3d-434ae438978d)

가상 프라이빗 클라우드(VPC)는 퍼블릭 클라우드 내에서 호스팅되는 안전하고 격리된 프라이빗 클라우드이다.

VPC를 사용하면 정의한 논리적으로 격리된 가상 네트워크에서 AWS 리소스를 효율적으로 관리할 수 있다. VPC별로 네트워크를 구성하거나 각각의 VPC에 따라 다르게 네트워크 설정을 줄 수 있다. 또한 각각의 VPC는 완전히 독립된 네트워크처럼 작동한다.

아래 그림은 VPC의 예시이다. VPC에는 리전의 각 가용성 영역에 하나의 서브넷이 있고, 각 서브넷에 EC2 인스턴스가 있고, VPC의 리소스와 인터넷 간의 통신을 허용하는 인터넷 게이트웨이가 있는 구조이다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/2546ee1d-2f1d-48c0-b996-31d039d27e58)

쉽게 예시를 들자면, 퍼블릭 클라우드를 붐비는 레스토랑으로, 가상 프라이빗 클라우드를 붐비는 레스토랑의 예약된 테이블로 생각해볼 수 있다. 식당이 사람들로 가득 차 있어서 내부가 혼잡해도 '예약석'이라고 표시된 테이블은 예약한 사람만 앉을 수 있다. 마찬가지로 퍼블릭 클라우드는 컴퓨팅 리소스에 액세스하는 다양한 클라우드 고객으로 가득 차 있지만, VPC는 이러한 리소스 중 일부를 한 고객만 사용할 수 있도록 예약한다.

## VPC를 구축하는 과정

### 1. ip 예약
![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/b09d481e-bdf6-4318-982f-404bc697ad01)

VPC를 구축하기위해서는 VPC의 아이피범위를 RFC1918이라는 사설 아이피대역에 맞추어 구축해야한다.

VPC에서 사용하는 사설 아이피 대역은 아래와 같다.

- `10.0.0.0 ~ 10.255.255.255`(10/8 prefix)
- `172.16.0.0 ~ 172.31.255.255`(182.16/12 prefix)
- `192.168.0.0 ~ 192.168.255.255`(192.168/16 prefix)

한번 설정된 아이피대역은 수정할 수 없으며 각 VPC는 하나의 리전에 종속된다. 각각의 VPC는 완전히 독립적이기때문에 만약 VPC간 통신을 원한다면 VPC 피어링 서비스를 고려해볼 수 있다.

### 2. 서브넷 설정

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/28fd0a05-3f4e-421a-bded-32e1567fe2ee)

서브넷이란 앞서 설정한 VPC를 잘게 쪼개는 과정이라고 생각할 수 있다. VPC 단 안에서 더 많은 네트워크 망을 구성하기 위해 설정하는 단계이다. 서브넷은 VPC안에 있는 VPC보다 더 작은 단위이기때문에 서브넷마스크가 더 높아지고, 아이피범위가 더 작아진다. 서브넷을 나누는 이유는 더 많은 네트워크망을 만들기 위해서이다.

서브넷은 가용 영역이라고 하는 Availability Zone(AZ) 여러 개에 걸쳐서 설정할 수 없으며 하나의 가용 영역 안에서 존재해야 한다는 특징을 가지고 있다.

이렇게 생성한 서브넷 안에 AWS의 여러 리소스들을 위치시킬 수 있다.

### 3. Route 설정

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/5a8df9db-5680-4d20-8023-0e785a61aebb)

네트워크 요청이 발생하면 데이터는 라우터로 향하게 되고 라우팅 테이블에 따라 네트워크 요청이 작동된다. 이때 **라우팅 테이블**이란 네트워크 트래픽을 어디로 전송할지 결정하는 데 사용되는 규직 집합, 즉, 목적지에 대한 이정표라고 할 수 있다.

기본적으로 VPC에 기본 Route table이 존재하지만 서브넷마다 다른 Route table을 할당할 수도 있다.
또한, 하나의 Route table을 여러 서브넷과 연결하는 것도 가능하다.

위의 그림은 각각의 서브넷에 Route table을 설정한 모습이다.

- Subnet1의 Route table은 `10.0.0.0/16`에 해당하는 네트워크 트래픽을 로컬로 향하도록 설정되어 있다. 반대로 말하면 그 이외의 트래픽은 허용되지 않는다는 것을 의미한다.
- Subnet2의 Route table은 `10.0.0.0/16`에 해당하는 네트워크 트래픽은 로컬로 보내지지만 그 외의 모든 트래픽(`0.0.0.0/0`)에 대해서는 인터넷과 연결시켜주는 관문이라고 할 수 있는 인터넷 게이트웨이(Internet Gateway)로 향하도록 설정한 모습이다.

이때 인터넷 게이트웨이와 연결하는 Route table을 갖는 서브넷을 `Public Subnet`이라 하고, 인터넷 게이트웨이와 연결하는 Route table을 갖지 않는 서브넷을 `Private Subnet`이라고 한다.

### 4. 네트워크 ACL과 보안그룹

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/cea2eb8e-b6c6-4ef2-a898-03022065e596)

**Network Access Control List(NACL)**과 **Security Group(보안 그룹)**은 방화벽과 같은 역할을 하며, 이 둘을 통해 인바운드 트래픽과 아웃바운드 트래픽 보안 정책을 설정할 수 있다.

Stateful한 방식으로 동작하는 보안그룹은 모든 허용을 차단하도록 기본설정 되어있으며 필요한 설정은 허용해주어야 한다. 서브넷이나 각각의 인스턴스에도 적용할 수 있다.

반면, 네트워크 ACL은 Stateless하게 작동하며, 기본이 open이고 불필요한 트래픽을 막도록 설정해야한다. 서브넷단위로 적용되며 리소스별로는 설정할 수 없다. NACL과 Security Group이 충돌하면 Security Group가 더 높은 우선순위를 갖는다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/c8b98048-75e3-4913-9881-6ddcbdfb5367)

### 5. Private 서브넷의 인터넷 연결

Private 서브넷이 인터넷과 통신하기 위해서는 Private 서브넷에서 외부로 요청하는 아웃바운드 트래픽을 받아 소스 IP 주소를 변환해 인터넷 게이트웨이로 트래픽을 보내는 **NAT 서비스**가 필요하다.

NAT 서비스를 구현하는 방법은 크게 두 가지가 있다. 하나는 AWS의 NAT Gateway를 이용하는 방법이 있고, 다른 하나는 EC2를 NAT용으로 사용하는 것이다.

NAT Gateway 또는 NAT 인스턴스는 Public 서브넷에서 동작해야 하며, Route table이 Private 서브넷에서 외부로 요청하는 아웃바운드 트래픽을 받을 수 있도록 설정한다.

### 6. VPN 추가 연결 옵션

#### (1) 다른 VPC와 연결 (VPC Peering Connection)

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/f7638f72-5175-451c-b8f1-794fa7602d8a)

다른 VPC와 연결하기 위해서는 두 VPC 간에 트래픽을 라우팅할 수 있도록 서로 다른 VPC 간의 네트워크를 이어줘야하는데, 이것을 VPC Peering이라 부른다.

이렇게 묶어주면 서로 다른 VPC의 인스턴스에서 동일한 네트워크에 속한 것처럼 통신이 가능하다.

다른 Region, 다른 AWS 계정의 VPC Peering 연결도 가능하지만, 연결할 VPC 간의 IP 범위가 겹치는 것은 불가능하다.

VPC Peering 연결 순서는 아래와 같다.

```
피어링 요청 → 피어링 요청 수락 → Route table 및 Security group 내 피어링 경로 업데이트
```

#### (2) On-Premise와 연결 (VPN과 DX)

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/7787fa30-0bdc-485a-92c7-2f178de23252)

기존 온프레미스와의 연결을 통해 하이브리드 환경을 구성하는 것도 가능하다.

- **AWS Client VPN :** VPN 소프트웨어 클라이언트를 사용하여 사용자를 AWS 또는 온프레미스 리소스에 연결하는 방식이다.
- **AWS Site-to-Site VPN :** 데이터 센터와 AWS Cloud(VPN Gateway / Transit Gateway) 사이에 암호화된 보안 연결 생성하는 방식이다. Site-to-Site VPN 연결은 VPC에 추가된 가상 프라이빗 게이트웨이와, 데이터 센터에 위치하는 고객 게이트웨이로 구성된다.
- **AWS Direct Connect :** AWS Cloud 환경으로 인터넷이 아닌 전용 네트워크 연결 생성하는 방식이다. (※ AWS 리소스에 대한 최단 경로)

---
출처
- https://aws.amazon.com/ko/vpc/
- https://blog.kico.co.kr/2022/03/08/aws-vpc/
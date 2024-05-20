
|속성|	NAT 게이트웨이|NAT 인스턴스|
|-|-|-|
|가용성|	고가용성. 각 가용 영역의 NAT 게이트웨이는 중복적으로 구현됩니다. 각 가용 영역에 하나의 NAT 게이트웨이를 만들어 아키텍처가 영역에 종속되지 않도록 한다.	|스크립트를 사용하여 인스턴스 간의 장애 조치를 관리한다.|
|대역폭|	최대 100Gbps까지 확장한다.|인스턴스 유형의 대역폭에 따라 다르다.|
|유지 관리|	AWS에서 관리한다. 유지 관리 작업을 수행할 필요가 없다.|사용자가 관리한다(예: 인스턴스에 소프트웨어 업데이트 또는 운영 체제 패치 설치).|
|성능|	소프트웨어가 NAT 트래픽 처리에 최적화되어 있다.	|NAT를 수행하도록 구성된 일반 AMI입니다.|
|비용|	사용하는 NAT 게이트웨이 수, 사용 기간, NAT 게이트웨이를 통해 보내는 데이터의 양에 따라 요금이 청구됩니다.|사용하는 NAT 인스턴스 수, 사용 기간, 인스턴스 유형과 크기에 따라 요금이 청구됩니다.|
|유형 및 크기|	균일하게 제공되므로, 유형 또는 크기를 결정할 필요가 없다.|예상 워크로드에 따라 적합한 인스턴스 유형과 크기를 선택한다.|
|퍼블릭 IP 주소|	생성할 때 퍼블릭 NAT 게이트웨이와 연결할 탄력적 IP 주소를 선택한다.|탄력적 IP 주소 또는 퍼블릭 IP 주소를 NAT 인스턴스와 함께 사용한다. 새 탄력적 IP 주소를 인스턴스와 연결하여 언제든지 퍼블릭 IP 주소를 변경할 수 있다.|
|프라이빗 IP 주소|	게이트웨이를 만들 때 서브넷의 IP 주소 범위에서 자동으로 선택됩니다.|인스턴스를 시작할 때 서브넷의 IP 주소 범위에서 특정 프라이빗 IP 주소를 할당한다.
|보안 그룹|	보안 그룹을 NAT 게이트웨이와 연결할 수 없다.|보안 그룹을 NAT 게이트웨이 기반 리소스와 연결하여 인바운드 및 아웃바운드 트래픽을 제어할 수 있다. NAT 인스턴스 뒤의 리소스 및 NAT 인스턴스와 연결하여 인바운드 및 아웃바운드 트래픽을 제어한다.|
|네트워크 ACL|	네트워크 ACL을 사용하여 NAT 게이트웨이가 위치하고 있는 서브넷에서 보내고 받는 트래픽을 제어한다.|네트워크 ACL을 사용하여 NAT 인스턴스가 위치하고 있는 서브넷에서 보내고 받는 트래픽을 제어한다.|
|흐름 로그|	흐름 로그를 사용하여 트래픽을 캡처한다.|흐름 로그를 사용하여 트래픽을 캡처한다.|
|Port forwarding|	지원하지 않음.|포트 전달을 지원하려면 구성을 수동으로 사용자 지정한다.|
|Bastion 서버|	지원하지 않음.|Bastion 서버로 사용한다|
|트래픽 지표|	NAT 게이트웨이에 대한 CloudWatch 지표를 확인한다.|인스턴스에 대한 CloudWatch 지표를 확인한다.|
|제한 시간 초과 동작|	연결 제한 시간이 초과하면 NAT 게이트웨이는 연결을 계속하려고 하는 NAT 게이트웨이 뒤의 리소스로 RST 패킷을 반환한다 (FIN 패킷을 보내지 않음).|	연결 제한 시간이 초과하면 NAT 인스턴스는 NAT 인스턴스 뒤의 리소스로 FIN 패킷을 전송하여 연결을 닫다.|
|IP 조각화	|UDP 프로토콜에서 IP 조각화된 패킷의 전달을 지원한다.<br>TCP 및 ICMP 프로토콜에 대해서는 조각화를 지원하지 않다. 이러한 프로토콜의 조각화된 패킷은 삭제됩니다.|UDP, TCP 및 ICMP 프로토콜에 대해 IP 조각화된 패킷의 재수집을 지원한다.|

## NAT 인스턴스에서 NAT 게이트웨이로 마이그레이션

이미 NAT 인스턴스를 사용하는 경우 이를 NAT 게이트웨이로 대체하는 것이 좋다. NAT 인스턴스와 동일한 서브넷에 NAT 게이트웨이를 만든 다음, NAT 인스턴스를 가리키는 라우팅 테이블의 기존 경로를 NAT 게이트웨이를 가리키는 경로로 대체할 수 있다. 현재 NAT 인스턴스에 사용하는 것과 동일한 탄력적 IP 주소를 NAT 게이트웨이에 사용하려는 경우에도 먼저 NAT 인스턴스의 탄력적 IP 주소를 연결 해제하고 NAT 게이트웨이를 만들 때 이 주소를 게이트웨이에 연결해야 한다.

NAT 인스턴스에서 NAT 게이트웨이로 라우팅을 변경하거나 NAT 인스턴스에서 탄력적 IP 주소의 연결을 해제하면 현재 연결이 끊어지고 연결을 다시 설정해야 한다. 중요한 작업(또는 NAT 인스턴스를 통해 작동하는 기타 작업)이 실행 중이지 않은지 확인한다.

---

- The DevOps team at an IT company is provisioning a two-tier application in a VPC with a public subnet and a private subnet. The team wants to use either a NAT instance or a NAT gateway in the public subnet to enable instances in the private subnet to initiate outbound IPv4 traffic to the internet but needs some technical assistance in terms of the configuration options available for the NAT instance and the NAT gateway.
    As a solutions architect, which of the following options would you identify as CORRECT? (Select three)

- NAT instance can be used as a bastion server

- Security Groups can be associated with a NAT instance

- NAT instance supports port forwarding

---
reference
- https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/vpc-nat-comparison.html
- https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/VPC_NAT_Instance.html
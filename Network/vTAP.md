
네트워크의 전략적 지점에서 패킷을 캡처하는 것은 트러블슈팅이든 보안 모니터링이든 매우 중요하다.

예를 들어, 사용자가 웹사이트에 간헐적으로 접근할 수 없다고 보고하면, IT 부서가 [캡처된 네트워크 패킷](https://www.techtarget.com/searchunifiedcommunications/tip/Check-packet-loss-to-manage-call-quality)을 분석하여 클라이언트와 웹 서버 또는 라우터 간의 상호작용을 살펴봄으로써 근본적인 문제를 찾을 수 있다.

또한 네트워크 트래픽 스트림을 수신하여 알려진 시그니처나 트래픽 이상을 기반으로 의심스럽거나 악의적인 트래픽이 식별되면 사용자에게 알리는 침입 탐지 시스템(IDS)을 사용할 수도 있다.

<img width="567" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/ad7d9b8d-35b6-44ee-bf29-b203e0739be9">

**TAP이란**

- 패킷을 얻으려면 가로채야 한다.

- **네트워크 TAP(Test Access Point)**은 네트워크 인터페이스의 네트워크 트래픽을 수신하고 패킷의 복사본을 다른 시스템으로 전송하거나 디스크에 직접 저장하는 가상 또는 물리적 장치이다.

- 물리적 TAP은 들어오는 광섬유 케이블의 빛을 복제할 수 있는 미러가 있는 박스처럼 단순할 수 있다.
- 또는 내장 로직, 소프트웨어, 네트워크 인터페이스를 갖춘 전원 장치일 수도 있다. 많은 전문 스위치에는 인터페이스를 TAP 포트로 지정하는 옵션이 있으며, 이를 SPAN(Switched Port Analyzer)이라고 한다.

**vTAP**

- 가상 TAP(vTAP)은 VMware ESX나 Oracle VM VirtualBox 같은 하이퍼바이저 내에 위치한다. 가상 트래픽 흐름이나 가상 스위치에 연결하여 유사한 방식으로 작동한다.

- vTAP의 장점은 트래픽이 하드웨어를 벗어나지 않고도 동일 하이퍼바이저 내의 두 가상 머신 간의 트래픽을 모니터링할 수 있다는 것이다.

- 방화벽, 스위치, 프록시 서버 같은 네트워크 장치의 가상화와 함께, 최근 몇 년간 인기 있는 옵션이 되었다.

- VTAP 구현 예시:

  <img width="588" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/ec65abd1-1f12-4850-bb60-0fab0ce241e8">

**클라우드에서의 TAP**

- 일부 CSP(클라우드 서비스 제공업체)는 고객이 네트워크 트래픽을 캡처할 수 있는 솔루션을 제공하고 있다.
  - 시스템이 회사 자체 로컬 데이터센터에 있든 클라우드 인스턴스에 호스팅되어 있든, 트러블슈팅과 보안 모니터링에 대한 가시성이 중요하기 때문이다.

- 하지만 CSP에게는 몇 가지 과제가 있다. 멀티테넌트 환경이므로 프라이버시와 보안 문제가 따르며, 고객에게 네트워크 인프라 하위 레이어의 접근 권한을 줄 수 없다.

- 퍼블릭 클라우드는 가상 서버가 데이터센터와 물리 시스템 간에 언제든 이동할 수 있어, 안정적인 vTAP 구성이 어렵다.

- 또한 클라우드 네트워크 트래픽은 전송 중 CSP 고유 헤더를 사용하는 경우가 많아, 전송 중 캡처한 트래픽을 일반 보안 장비에서 바로 분석하기 어렵다.

- vTAP 구성이 고객에게 어려웠기 때문에, 창의적인 사용자와 연구자들이 AWS용 NAT 설정 같은 해결 방법을 고안해왔다.

- 자사 제품이 네트워크 TAP에 의존하는 Gigamon 같은 회사도 OpenStack용 TAP as a service 같은 새로운 제품과 서비스를 개발했다.


---
참고
- https://www.techtarget.com/searchsecurity/tip/How-to-configure-a-vTAP-for-cloud-networks
- https://medium.com/oracledevs/network-monitoring-and-analysis-in-oci-using-vtap-and-opensearch-5100da1dbf23
- https://www.ateam-oracle.com/post/oci-vtap-and-linux-rsyslog
- https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/vtap.htm

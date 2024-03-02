
![image](https://user-images.githubusercontent.com/81006587/216500706-744fd3ac-ca09-443b-b026-9c27f276c2b0.png)


container를 돌리는 모든 소프트웨어들은(ex. docker, rkt, mesos, k8s) 각 컨테이너간의 네트워크를 구현한다. 그것은 모두 [네트워크 네임스페이스](../linux/network namespaces.md)를 통해 구현되고, 서로 비슷한 절차를 거쳐 브릿지를 생성한다. 약간의 차이는 있을 수 있지만 전반적인 흐름은 아주 유사하다.

그렇다면 그 작업을 표준화한 인터페이스를 만든다면 어떨까? 이를 위해 정의된 것이 바로 CNI(Container Network Interface)이다.

CNI는 컨테이너 네트워크 작업을 수행하는 코드가 대략적으로 어떤 동작을 해야하고, 어떻게 호출되어야햐는지를 정의한다. 컨테이너를 돌리는 소프트웨어는 CNI 스펙에 맞추어 함꼐 동작할 수 있도록 구현됐기 때문에 해당 Interface를 구현하는 구현체중 원하는 것을 선택하여 사용하기만 하면 된다.

CNI를 구현하는 플러그인으론 BRIDGE, VLAN, IPVLAN, MACVLAN, DHCP, Calico, Canal, romana, Weave, Flannel, NSX 등등이 있다.

(도커는 CNM이라는 별도 네트워킹을 구현하기 떄문에, CNI에 호환되지 않는다.)

## CNI Plugin이 하는 일

- 컨테이너를 ADD, DELETE, CHECK할 수 있어야한다.
- container id, network ns 등등의 파라미터를 지원해야한다.
- Pod에 IP 주소를 할당하고 관리해야한다.
- 조회 결과 반환시, 특정한 형식에 맞추어야한다. (JSON)

## IPAM

CNI 설정 파일은 CNI 플러그인의 유형, 사용할 서브넷과 라우트를 명시하는 IPAM(IP Address Management)이라는 섹션을 가지고있다. 하드코딩 없이 적절한 플러그인을 호출할 수 있도록 하는 역할을 한다.
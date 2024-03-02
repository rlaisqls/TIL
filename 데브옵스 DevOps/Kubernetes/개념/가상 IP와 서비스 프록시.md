
쿠버네티스 클러스터의 모든 노드는 `kube-proxy`를 실행한다. `kube-proxy`는 ExternalName 이외의 유형의 서비스에 대한 **"가상 IP"**의 역할을 한다.

<img width="616" alt="Screenshot 2023-02-02 at 18 59 36" src="https://user-images.githubusercontent.com/81006587/216293952-07df620b-77b7-44bf-a50f-8dc699107799.png">

service를 조회했을때 나오는 cluster IP가 바로 k8s의 프록시로 만들어진 가상 IP이다. 이 IP는 k8s 내부에서만 접근할 수 있다.

## 쿠버네티스에서 가상 IP를 사용하는 이유

쿠버네티스가 프록시를 통해 가상 IP를 만드는 이유는, 실제 IP와 DNS를 사용하기 부적절하기 때문이다. k8s의 서비스 객체는 IP를 할당할 수 있는 기기가 아니고 잠시 생겼다가 사라질 수 있는 유한한 존재이다.

하지만 서비스를 식별하고 호출할 수 있는 무언가가 필요하기 때문에 그 방법으로서 프록시로 만든 가상 IP를 사용하는 것이다.

## kube-proxy의 특징

- kube-proxy의 구성은 컨피그맵(ConfigMap)을 통해 이루어진다.
- kube-proxy를 위한 컨피그맵은 기동 중 구성의 재적용(live reloading)을 지원하지 않는다.
- kube-proxy를 위한 컨피그맵 파라미터는 기동 시에 검증이나 확인을 하지 않는다. 예를 들어, 운영 체계가 iptables 명령을 허용하지 않을 경우, 표준 커널 kube-proxy 구현체는 작동하지 않을 것이다. 마찬가지로, `netsh`을 지원하지 않는 운영 체계에서는, 윈도우 유저스페이스 모드로는 기동하지 않을 것이다.
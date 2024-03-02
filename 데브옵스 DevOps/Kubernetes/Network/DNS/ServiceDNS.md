
생성된 서비스의 IP는 어떻게 알 수 있을까? 서비스가 생성된 후 kubectl get svc를 이용하면 생성된 서비스와 IP를 받아올 수 있지만, 이는 서비스가 생성된 후이고, 계속해서 변경되는 임시 IP이다.

### DNS를 이용하는 방법
가장 쉬운 방법으로는 DNS 이름을 사용하는 방법이 있다.

서비스는 생성되면 `[서비스 명].[네임스페이스명].svc.cluster.local` 이라는 DNS 명으로 쿠버네티스 내부 DNS에 등록이 된다. 쿠버네티스 클러스터 내부에서는 이 DNS 명으로 서비스에 접근이 가능한데, 이때 DNS에서 리턴해주는 IP는 외부 IP (External IP)가 아니라 Cluster IP (내부 IP)이다.

간단한 테스트를 해보자. hello-node-svc 가 생성이 되었는데, 클러스터내의 pod 중 하나에서 ping으로 `hello-node-svc.default.svc.cluster.local` 을 테스트 하니 hello-node-svc의 클러스터 IP인 `10.23.241.62`가 리턴되는 것을 확인할 수 있다. 

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/c1cdf6d3-4506-4bc2-b639-cf0e2dc77d04)

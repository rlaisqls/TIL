
쿠버네티스의 Services는 뒷단에 있는 Pod의 label 정보를 바탕으로한 selector로 그 대상이 되는 Pod를 매칭한다. 만약 해당 Label을 단 새로운 Pod이 생겼다면, Service는 자동으로 그 Pod과 연결되어 트래픽을 보낸다.

이러한 일이 가능한 것은 service가 트래픽을 보낼 **오브젝트를 추적**해주는 **`EndPoint`**가 있기 때문이다. 매칭된 Pod의 IP 주소는 그 service의 endpoint가 되어 연결된다.

<u>service는 endpoints를 통해 트래픽을 보내는 주소의 목록을 관리</u>한다. endpoints는 labels와 selectors를 통해 자동으로 업데이트 될 수 있다. 그리고 경우에 따라 수동으로 endpoints를 설정할 수 있다.

service selector가 Pod의 label에 매칭되면 endpoints가 자동으로 만들어진다.

```js
kubectl apply -f [manifest file].yml
```

`myapp`이라는 이름의 Deployment와 Service를 생성하는 minifest file을 실행하고 endpoint를 확인해보면

```js
$ kubectl get endpoints

NAME        ENDPOINT                          AGE
myapp       10.244.1.143:80,10.244.2.204:80   23h
Kuberneted  10.10.50.50.:6443                 11d

```

두개의 endpoints를 가지고 있으며 모두 80 포트라는것을 확인 할 수 있다. 이 endpoint들은 매니페스트로 배포한 pod들의 ip 주소여야 한다. 이것을 확인하기위해 get pods 커맨드를 `-o wide` 옵션과 함께 확인해보자.

```js
$ kubectl get endpoints -o wide

NAME                               READY  STATUS   RESTARTS  AGE  IP               NODE
myapp-deployment-6d99f57cb4-ngc4g  1/1    Running  0         1h   10.244.1.143:80  kube-node2
myapp-deployment-6d99f57cb4-x5gsm  1/1    Running  0         1h   10.244.2.204:80  kube-node1

```

Pod의 IP 주소들이 엔드포인트의 주소들과 매칭된다는 것을 확인할 수 있다. 보이지 않는 곳에서 endpoints가 매칭된다는 사실을 확인했다.
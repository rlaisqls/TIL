
K8s의 포트는 노드와 서비스, 컨테이너별로 나뉘어있다. 이 개념에 대해 확실히 알아보자.

만약에 하나의 서비스에 2개의 노드가 있고, 그 노드에 각각 하나의 포드가 있다고 하면 아래 그림과 같은 모양이 된다.

<img src="https://user-images.githubusercontent.com/81006587/205223298-aef6933f-31a9-41d2-beb8-4884e2090efa.png" height=400px>

NodePort는 각 노드의 클러스터 레벨에서 노출되는 포트, (그림에서 `30001`)

Port는 서비스의 포트, (`80`)

targetPort는 포드에서 컨테이너로 가는 앱 컨테이너 포트를 말한다.

아래와 같이 설정할 수 있다.

```yml
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
    nodePort: 30000
```

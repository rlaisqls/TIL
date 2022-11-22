# ⚓ Pod 생성과정

<img height=450px src="https://user-images.githubusercontent.com/81006587/201905478-3e25b868-6274-425f-bdca-e068e9056986.png"/>

관리자가 애플리케이션을 배포하기 위해 ReplicaSet을 생성하면 다음과 같은 과정을 거쳐 Pod을 생성한다.

흐름을 보면 각 모듈은 서로 통신하지 않고 **오직 API Server와만 통신**하는 것을 알 수 있다. API Server를 통해 etcd에 `저장된 상태를 체크`하고 `현재 상태와 원하는 상태가 다르면 필요한 작업을 수행`한다. 각 모듈이 하는 일을 보면 다음과 같다.

### kubectl

- ReplicaSet 명세를 yml파일로 정의하고 kubectl 도구를 이용하여 API Server에 명령을 전달

- API Server는 새로운 ReplicaSet Object를 etcd에 저장

### Kube Controller

- Kube Controller에 포함된 ReplicaSet Controller가 ReplicaSet을 감시하다가 ReplicaSet에 정의된 Label Selector 조건을 만족하는 Pod이 존재하는지 체크

- 해당하는 Label의 Pod이 없으면 ReplicaSet의 Pod 템플릿을 보고 새로운 Pod(no assign)을 생성. 생성은 역시 API Server에 전달하고 API Server는 etcd에 저장

### Scheduler

- 할당되지 않은(no assign) Pod가 있는지 체크
- 할당되지 않은 Pod가 있으면 조건에 맞는 Node를 찾아 해당 Pod을 할당

### Kubelet

- Kubelet은 자신의 Node에 할당되었지만 아직 생성되지 않은 Pod이 있는지 체크
- 생성되지 않은 Pod이 있으면 명세를 보고 Pod을 생성
 Pod의 상태를 주기적으로 API Server에 전달








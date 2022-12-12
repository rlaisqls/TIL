# ⚓ Deplotments

> Deplotment는 Pod와 ReplicaSets를 위한 선언적 업데이트를 제공한다.

`Deployment`는 k8s의 핵심 개념중 하나인 `desired state`(목표 상태)를 설명하는 요소이다. Deployment에서 desired state를 정의하면 **배포 컨트롤러**가 원하는 상태로 복구한다.

Deploy를 만들어 실습해보자! 더 자세하고 정확한 설명은 <a href="https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#creating-a-deployment">공식 </a>를 참고하자.

## Creating a Deployment 

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

위 yml은 새로 만들 Deployment를 정의한다. 자세히 설명하자면 다음과 같다.

- `nginx-deployment`라는 이름을 가진 Deployment를 생성한다. (`.metadata.name`)
- 세 개의 replicated Pod를 가진 ReplicaSet을 생성한다. (`.spec.replicas`) 
- 생성될 ReplicaSet이 `nginx`라는 이름의 태그를 가진 Pod를 관리하도록 한다.(`.spec.selector`)

> **Note:**<br>`.spec.selector.matchLabels` 필드는 {key,value} 두 쌍의 맵이다. 값은 배열로 이뤄져있으며, 해당 키의 리스트에 속해있는 value를 가지는 포드를 모두 가지고 온다. 

- `template` 필드는 Deployment에 포함될 포드또는 템플릿을 정의하며, 아래와 같은 의미의 sub-field들을 가지고있다.
    - 포드에 `app: nginx` 라벨을 붙인다. (`.metadata.labels`)
    - 컨테이너가 어떤 이미지를 가질지 결정한다.
    - nginx라는 이름을 가진 하나의 Container를 만든다.(`.spec.template.spec.containers[0].name`)

### 실습

1. yml로 Deployment를 생성한다

```bash
kubectl apply -f https://k8s.io/examples/controllers/nginx-deployment.yml
```

2. `kubectl get deployments`로 Deployment가 생성되었는지 확인한다.

```bash
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   0/3     0            0           1s
```

각 정보는 아래와 같은 의미를 가지고 있다.

- `name`: namespace안에 있는 Deplotment들의 이름 리스트를 나타낸다.
- `READY`: 배포를 작성할 때 정의한 응용프로그램의 복제본이 몇 개만큼 준비되었는지를 표시한다.
- `UP-TO-DATE`: 원하는 상태에 도달하도록 업데이트된 복제본 수를 표시한다.
- `AVAILABLE`: 사용자가 사용할 수 있는 애플리케이션의 복제본 수를 표시한다.
- `AGE`: 애플리케이션이 동작한 기간을 표시한다.

`.spec.replicas`에 설정된 사항에 따르면, 3개의 replica가 있는 것이 목표 상태이다.

3. Deployment rollout status를 보기 위해 `kubectl rollout status deployment/nginx-deployment`를 실행한다.

그 출력물은 다음과 비슷할 것이다.

```
Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
deployment "nginx-deployment" successfully rolled out
```

4. 몇 초를 기다린 후, `kubectl get deployments`를 다시 실행한다.

그 출력물은 다음과 비슷할 것이다.

```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           18s
```

세 개의 모든 Replica들이 생성되었고, 사용 가능한 상태가 되었음을 알 수 있다.

5. Deploy에 의해 생성된 ReplicaSet(rs)를 보기 위해 `rs`를 실행한다.

그 결과는 다음과 같을 것이다.

```
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-75675f5897   3         3         3       18s
```

각 정보는 아래와 같은 의미를 가지고 있다.

- `name`: namespace안에 있는 Deplotment들의 이름 리스트를 나타낸다.
- `DESIRED`: 원하는 Replica의 개수를 표시한다.
- `CURRENT`: 현재 실행중인 Replica의 개수를 표시한다.
- `READY`: 배포를 작성할 때 정의한 응용프로그램의 복제본이 몇 개만큼 준비되었는지를 표시한다.
- `AGE`: 애플리케이션이 동작한 기간을 표시한다.

6. 각 포드에 자동으로 부여된 이름을 확인하기 위해서 `kubectl get pods --show-labels`를 실행한다.

```
NAME                                READY     STATUS    RESTARTS   AGE       LABELS
nginx-deployment-75675f5897-7ci7o   1/1       Running   0          18s       app=nginx,pod-template-hash=3123191453
nginx-deployment-75675f5897-kzszj   1/1       Running   0          18s       app=nginx,pod-template-hash=3123191453
nginx-deployment-75675f5897-qqcnn   1/1       Running   0          18s       app=nginx,pod-template-hash=3123191453
```

`nginx` pod에 대한 세개의 ReplicaSet이 만들어졌다.

> **Note:**<br>You must specify an appropriate selector and Pod template labels in a Deployment (in this case, app: nginx).<br>Do not overlap labels or selectors with other controllers (including other Deployments and StatefulSets). Kubernetes doesn't stop you from overlapping, and if multiple controllers have overlapping selectors those controllers might conflict and behave unexpectedly.

## Deployment 정보 수정하는법 

> **Note:**<br>Deployment의 rollout은 Deployment의 Pod template(`.spec.template`)에 따라 자동으로 작동된다. (label이나 container의 image 등을 조건으로 함) Deployment를 scaling하는 것과 같은 다른 종류의 update는 rollout의 트리거가 되지 않는다.

Deployment를 수정하는 방법을 알아보자.

1. nginx Pod 버전을 `1.14.2`에서 `1.16.1`로 업데이트해보자.

```java
kubectl set image deployment ${deployment_name} ${prev_image}=${next_image} --record
(kubectl set image deployment/nginx-deployment nginx=nginx:1.16.1)
```

둘 중 하나의 명령어를 사용할 수 있다.

2. rollout status를 보기 위해 `kubectl rollout status deployment/nginx-deployment`를 입력한다.

```
Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
```
또는
```
deployment "nginx-deployment" successfully rolled out
```
가 결과로 출력될 것이다.

그 외의 정보를 수정할때도 set 또는 edit 명령어를 사용할 수 있다.

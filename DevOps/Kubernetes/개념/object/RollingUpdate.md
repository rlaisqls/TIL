
Rolling Update는 k8s의 업데이트 방법 중 하나로, 새로운 버전의 애플리케이션을 배포하고 기존 버전을 점진적으로 대체하는 과정으로 진행된다. 새로운 버전의 Pod로 트래픽이 전달되기 전까지 기존 버전이 유지되므로 무중단으로 애플리케이션을 업데이트 가능한 장점이 있다. 그러나 새로운 버전의 Pod와 기존 Pod가 함께 유지되는 기간이 존재하기 때문에 업데이트 중에 리소스를 더 사용할 수 있다.

<img width="663" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/dd30250f-37c5-48be-ac07-72e38b26d64c">

기본적으로 Rolling Update는 다음과 같은 단계로 이뤄진다.

1. 새로운 버전의 애플리케이션을 배포한다. 이때 기존 버전은 유지된 상태로 새로운 버전의 Pod가 함께 생성된다.
2. 새로운 버전의 Pod가 정상적으로 동작하고, 준비 상태가 되면, 이전 버전의 Pod을 하나씩 종료한다. 이때 제거되는 Pod은 사용자 요청을 처리하는 중인 경우, 일정 시간 동안 대기한 후에 제거된다. (Graceful Shutdown)
3. 이전 버전의 Pod이 모두 종료되면, 새로운 버전의 Pod만 남게 되고, 이제는 새로운 버전의 애플리케이션이 모든 트래픽을 처리하게 된다.

> Rolling Update는 Deployment 등의 리소스 업데이트 시 Pod를 어떻게 교체할지에 대한 방법을 선택하는 것이며, Rolling Update 설정만으로는 무중단 배포를 설정했다고 말할 수 없다.<br/> Rolling Update를 수행하면서, 요청에 대한 에러 발생을 최소화하기 위한 설정은 Container Probe와 Graceful Shutdown에 대한 설정이 추가적으로 필요하다.

## Rolling Update 전략

Rolling Update는 `maxSurge`/`maxUnavailable` 값을 적절히 설정하는 것이 중요하다.

동시에 몇 개의 새로운 버전을 만들고, 몇 개의 기존 Pod를 삭제할지 서비스의 replica 수, 안정성을 고려해서 선택해야한다. 또한 이 값에 따라 다음과 같은 Rolling Update 전략이 가능하다.

**새로운 버전 Pod 생성 후, 기존 버전 Pod를 종료하는 방식**

```yaml
rollingUpdate:
  maxSurge: 1
  maxUnavailable: 0
```

- `maxSurge=1(또는 n)`, `maxUnavailable=0`으로 설정
- maxUnavailable 값이 0이기 때문에 새로운 버전의 Pod가 생성되야만 종료가 발생한다.
- replica + maxSurge 만큼의 Pod가 동시에 유지될 수 있다.
- 위 예시에서는 새로운 Pod가 1개가 생성되고 난 후 1개의 기존 Pod가 종료된다.
  - replica가 10개라면, 업데이트시 11개의 Pod가 동시에 유지될 수 있다.

    ![image](https://github.com/rlaisqls/TIL/assets/81006587/2fedf0ef-c578-4c65-bcdf-a5cfd9468d07)

**기존 버전 Pod 종료 후, 새로운 버전 Pod를 생성하는 방식**

```yaml
rollingUpdate:
  maxSurge: 0
  maxUnavailable: 1
```

- `maxSurge=0`, `maxUnavailable=1(또는 n)`으로 설정
- maxSurge 값이 0이기 때문에 기존 버전의 Pod가 종료되어야만 새로운 버전의 Pod가 생성된다.
- replica - maxUnavailable 만큼의 Pod가 동시에 유지될 수 있다.
- 위 예시에서는 기존 Pod가 1개가 종료되고 난 후 1개의 새로운 버전의 Pod가 생성된다.
  - replica가 10개라면, 업데이트시 9개의 Pod가 동시에 유지될 수 있다.

    ![image](https://github.com/rlaisqls/TIL/assets/81006587/6b7a09ca-f695-467b-9b81-54addcabe7fa)

## Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: springapp
spec:
  replicas: 3
  revisionHistoryLimit: 1
  selector:
    matchLabels:
      app: springapp
 
  # -- Configure Deployment Strategy (Rolling Update)
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
 
  template:
    metadata:
      labels:
        app: springapp
    spec:
      containers:
        - name: springapp
          image: <image-url>
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
              name: http
```

---
참고
- https://kubernetes.io/ko/docs/tutorials/kubernetes-basics/update/update-intro/
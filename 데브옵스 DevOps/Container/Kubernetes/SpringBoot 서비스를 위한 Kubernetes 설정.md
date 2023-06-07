# ⚓ SpringBoot 서비스를 위한 Kubernetes 설정

출처: https://velog.io/@airoasis/Spring-Boot-서비스를-위한-Kubernetes-설정

## Deployment

아래는 deployment설정의 예시이다.

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: main-server
  labels:
    app: main-server
spec:
  selector:
    matchLabels:
      app: main-server
  template:
    metadata:
      labels:
        app: main-server
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - main-server
              topologyKey: kubernetes.io/hostname
            weight: 100
      containers:
      - name: main-server
        image: main-server:latest
        env:
          - name: SPRING_PROFILES_ACTIVE
            value: develop
          - name: JAVA_TOOL_OPTIONS
            value: "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=localhost:5005 -Duser.timezone=Asia/Seoul"
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 20
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 20
          periodSeconds: 20
        resources:
          requests:
            cpu: 1
            memory: 1.5Gi
          limits:
            memory: 1.5Gi
```

위 설정에서 SpringBoot에 특화한 중요한 부분은 총 5가지 부분이 있다.

### 1. Pod Anti-affinity 설정

이 설정은 pod가 여러 node에 균일하게 배포되는 것을 보장한다. 만약 replicas를 3으로 설정하였는데 <u>모두 하나의 node에 배포되고 해당 node가 장애로 다운된다면 해당 서비스 또한 당분간 아예 서비스가 되지 않는다</u>. 하지만 Pod Anti-affinity 설정으로 최대한 동일한 pod가 같은 node에 배포되는 것을 방지하면 장애에 강한 서비스를 만들 수 있다.

> 여기서 `preferredDuringSchedulingIgnoredDuringExecution` 대신 `requiredDuringSchedulingIgnoredDuringExecution`를 사용하면 node에는 해당 pod가 하나밖에 생성 될수 없고, 추가로 scheduling 되어야 하는 pod는 pending 상태가 되어 node가 cluster 에 추가되면 그제서야 배치될 수 있다.

### 2. Spring Profile 설정

Spring profile을 kubernetes의 environment variable을 통해 설정한다. `SPRING_PROFILES_ACTIVE` 여기에 필요한 profile을 설정한다.

### 3. JVM 설정

Kubernetes의 environment variable인 `JAVA_TOOL_OPTIONS`를 통해 JVM 설정을 한다.

#### Remote debugging 설정

`-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=localhost:5005`를 통해 container 안에서 동작중인 spring boot application 을 debugging 할 수 있다. IntelliJ에서의 설정은 <a href="https://www.jetbrains.com/help/idea/tutorial-remote-debug.html">Tutorial: Remote debug</a>를 참고할 수 있다.

#### imezone 설정

Docker image의 default timezone은 UTC이다. 기본 설정으로는 log도 UTC로 남아 분석하기 힘들 수 있다. 따라서 `-Duser.timezone=Asia/Seoul` 설정으로 JVM의 timezone을 한국시간으로 변경한다.

(참고로 timezone 설정은 application code TimeZone.setDefault(TimeZone.getTimeZone("Asia/Seoul")); 로도 가능하다)

#### 4. Readiness & Liveness 설정

1부에서 Spring Boot Actuator를 포함하여 Spring Boot Application 을 개발하여 위와 같이 /health endpoint 를 활용하여 kubernetes 의 readiness 설정 및 liveness 설정을 할 수가 있다.

Readiness 설정으로 새로 시작하는 Spring Boot 서비스가 완전히 start 된 후에 request가 들어가도록 하여 무중단 배포를 위해 반드시 필요한 설정이다. 그리고 Liveness 설정으로 더이상 서비스가 불가능한 경우 해당 pod로의 request 유입을 막고 restart하게 하여 다시 서비스가 가능하게 한다.

#### 5. Resource request/limit 설정

Request / Limit 설정은 application 의 성격에 따라 달리해야 하고, 실제 서비스를 운영하면서 적절한 설정을 찾아야 한다. Java의 일반적인 특징으로 처음 시작할때 CPU와 Memory의 사용량이 급격히 증가하는데, 이를 감안하여 request/limit을 설정해야한다.

대부분의 경우 request/limit의 best practice는 memory의 request와 limit은 동일한 값으로 설정하고 cpu는 상대적으로 큰 limit이나 아예 설정을 하지않아 unbounded limit으로 설정하는 것이다. cpu는 compressible resource라 여러 pod가 cpu를 서로 사용하려고 할 때에 서비스는 단지 쓰로틀링되어 처리시간이 좀 더 걸리지만 memory는 incompressible resource라 memory가 부족하면 Pod가 종료되고 새롭게 scheduling 되어야 한다. 따라서 이렇게 종료되어 서비스의 불안정을 막기 위해 memory는 request와 limit을 동일하게 설정하여 되도록 이런 상황을 방지한다.

Goldilocks를 이용하면 VPA의 추천값을 Web을 통해 확인 가능하다.

## Autoscale & Fault tolerance

아래는 HPA(Horizontal Pod Autoscale) 및 PDB(Pod Disruption Budget) 예시이다.

```yml
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: main-server-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: main-server
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 90
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 30
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: main-server-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: main-server
---
```

#### 1. Horizontal Pod Autoscale (HPA)

❗️HPA를 사용할때는 deployment에서 replicas 설정을 하면 안된다.

HPA를 통해 Autoscale을 할 때 주의할 점은 **averageUtilization 의 기준은 resource request**라는 점이다. 결국 위 설정은 배포된 pod의 평균 CPU 사용량이 0.9 코어일 때 scale out을 한다.

그리고 behavior 설정을 통해 scale up은 즉각 반응하도록 하고 scale down은 서서히 하도록 설정하였다. 이것 또한 application이나 서비스의 특성에 따라 조절이 필요하다.

#### 2. Pod Disruption Budget (PDB)

PDB는 운영에서 반드시 필요한 설정이다. Pod는 항상 설정된 replica의 수 만큼 유지되지만 시스템 관리로 인해 특정 node를 다운 시켜야 하는 경우, 또는 cluster autoscaler 가 node의 수를 줄이는 경우 등과 같은 이유로 pod의 수가 줄어들어야 하는 경우가 있다.

이런 경우 PDB를 통해 최소한 운영 가능한 pod의 비율/개수를 정하거나 최대 서비스 가능하지 않은 pod의 비율/개수를 정하여 서비스의 안정성을 보장한다. 위에서는 최소 1개의 pod가 항상 보장되게 설정하였다. 결국 node가 scale down 되어야 하는 상황에서 최소 보장되어야 하는 PDB 설정을 만족하지 못하는 해당 node는 다운되지 않고 기다리다가 만족하는 상황이 되면 그때 다운되어진다.
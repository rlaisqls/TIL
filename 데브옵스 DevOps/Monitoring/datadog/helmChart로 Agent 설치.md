
### 1. helm을 설치한다.

맥에서는 `brew install helm`을 통해 설치할 수 있고, 윈도우에서는 Chocolatey, 리눅스에서는 Snap에서 패키지를 다운받으면 된다. 또는 바이너리 릴리즈를 다운받아서 직접 설치하는 방법도 있다.

자세한 것은 공식문서에서 확인해보자.

https://helm.sh/ko/docs/intro/install/

### 2. Datadog Operator

Datadog Operator를 Helm을 통해 설치하는 명령어는 다음과 같다.

```bash
$ helm repo add datadog https://helm.datadoghq.com
$ helm install -n datadog --create-namespace --set fullnameOverride="dd-op" mwp-datadog-operator datadog/datadog-operator
```

### 3. Kubernetes Secret으로 Datadog credential 생성

Datadog API, APP Key를 이용하여 Kubernetes secret을 생성한다. 

```js
$ kubectl create secret generic datadog-secrets --from-literal api-key=<DATADOG_API_KEY> --from-literal app-key=<DATADOG_APP_KEY>
```

### 4. Datadog Agent 및 Cluster Agent 설치 및 설정

생성한 Kubernetes secret을 사용하여 Agent를 생성하기 위한 매니페스트르 정의한다.

파일이름은 `datadog-operator.yml`로 생성했다.

```yml
apiVersion: datadoghq.com/v1alpha1
kind: DatadogAgent
metadata:
  namespace: datadog
  name: datadog
spec:
  credentials:
    apiSecret:
      secretName: datadog-secrets
      keyName: api-key
    appSecret:
      secretName: datadog-secrets
      keyName: app-key
  agent:
    image:
      name: "gcr.io/datadoghq/agent:latest"
    config:
      hostPort: 8125
      collectEvents: true
      tolerations:
        - operator: Exists
      env:
        - name: DD_DOGSTATSD_NON_LOCAL_TRAFFIC # Java JVM Metrics를 받기 위해 필요
          value: "true"
    log:
      enabled: true
      logsConfigContainerCollectAll: true
    apm:
      enabled: true
      hostPort: 8126
    process:
      enabled: true
      processCollectionEnabled: true
    systemProbe:
      bpfDebugEnabled: true
  features:
    kubeStateMetricsCore:
      enabled: true
    networkMonitoring:
      enabled: true
  clusterAgent:
    image:
      name: "gcr.io/datadoghq/cluster-agent:latest"
    config:
      clusterChecksEnabled: true
      replicas: 2
```

위와 같이 설정하면 Datadog agent가 DaemonSet 형태로 각 node에 설치된다.

Datadog cluster agent도 설치되어 효율적인 운영이 가능하다.

설정을 적용한다.

```bash
$ kubectl apply -f datadog-operator.yaml
```

이렇게 적용하면 Datadog agent가 생성되어 auto discovery를 통해 가능한 모든 metrics를 가져온 후, 서버로 전달하는 과정을 수행한다. 그리고 추가로 로깅, 모니터링, 그리고 application에 Datadog APM 을 적용하면 port 8126으로 받을 수 있도록 설정했다.

Agent는 DaemonSet 형태로 각 노드에 하나씩 배포된다. 해당 Pod를 명령어 `kubectl describe pod <생성된 포드명> -n datadog`으로 확인해보면 agent, `trace-agent`, `process-agent`, `system-probe` 이렇게 4개의 `container`가 올라가 있는걸 볼 수 있다.

Datadog에 로그인 하여 Integration tab으로 가서 Kubernetes 및 Istio를 추가해 주면 관련 모니터링을 위한 Dashboard가 추가된다.
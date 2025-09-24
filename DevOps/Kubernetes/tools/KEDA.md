큐 메세지 갯수 등 지정한 메트릭에 따라 스케일링하기 위해 사용

### SacaledObject

<https://keda.sh/docs/2.17/scalers/aws-sqs>

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: demo
  namespace: inflearn
spec:
  scaleTargetRef:
    name: demo
    # apiVersion:    {api-version-of-target-resource}     # Optional. Default: apps/v1
    # kind:          {kind-of-target-resource}            # Optional. Default: Deployment
  triggers:
    - type: aws-sqs-queue
      authenticationRef:
        name: dub-aws-credentials
      metadata:
        queueLength: "5" # 메세지 5개당 컨테이너 하나 생성
        queueURL: https://sqs.ap-northeast-2.amazonaws.com/123456789/test
        awsRegion: "ap-northeast-2"
        scaleOnInFlight: "true"
        scaleOnDelayed: "false"
  minReplicaCount: 0   # Optional. Default: 0
  maxReplicaCount: 10  # Optional. Default: 100
  pollingInterval: 1   # Optional. Default: 30 seconds
  cooldownPeriod: 1    # Optional. Default: 300 seconds
  initialCooldownPeriod:  0                             # Optional. Default: 0 seconds
  idleReplicaCount: 0                                   # Optional. Default: ignored, must be less than minReplicaCount
  advanced:                                             # Optional. Section to specify advanced options
    restoreToOriginalReplicaCount: true/false           # Optional. Default: false
    horizontalPodAutoscalerConfig:                      # Optional. Section to specify HPA related options
      name: {name-of-hpa-resource}                      # Optional. Default: keda-hpa-{scaled-object-name}
      behavior:                                         # Optional. Use to modify HPA's scaling behavior
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
          - type: Percent
            value: 100
            periodSeconds: 15
```

#### 메세지 수 관련 옵션

KEDA SQS 스케일러에서 메세지 수 계산시 ApproximateNumberOfMessages 값에,
옵션에 따라 다른 항목들을 더하여 판단함

- `scaleOnInFlight`이 true면:
  - `ApproximateNumberOfMessagesNotVisible`이 메세지 수 계산에 더해짐 (기본값 true)  

- `scaleOnDelayed`가 true면:
  - `ApproximateNumberOfMessagesDelayed`가 메세지 수 계산에 더해짐 (기본값 false)

- 예시
  - 기본값:  `ApproximateNumberOfMessages` + `ApproximateNumberOfMessagesNotVisible`
  - 둘 다 true인 경우:  `ApproximateNumberOfMessages` + `ApproximateNumberOfMessagesNotVisible` + `ApproximateNumberOfMessagesDelayed`

#### 계산된 메세지 값 조회 방법

HPA를 조회해 현재 pod 수가 어떻게 계산되었는지 확인할 수 있음

- `current`: 현재 실행 중인 컨테이너 수 / 메시지 수

  - m = 1/1000를 뜻함, 5667m = 5.667

  - e.g. 현재 실행 중인 컨테이너가 1개이고, 메세지 수가 12, queueLength가 10일 때 current = 12

    - 12가 10보다 크므로 desire replica 수 증가되어 current = 6로 변함

- `target`: 스케일링 기준이 되는 목표 값 = queueLength

```bash
$ kubectl describe hpa -n inflearn keda-hpa-demo
Name:                                        keda-hpa-demo
Namespace:                                   inflearn
...
Reference:                                   Deployment/demo
Metrics:                                     ( current / target )
  "s0-aws-sqs-test" (target average value):  5667m / 5
Min replicas:                                1
Max replicas:                                10
Deployment pods:                             2 current / 2 desired
```

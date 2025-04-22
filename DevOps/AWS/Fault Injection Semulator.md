AWS Fault Injection Simulator는 AWS에서 오류 주입 실험을 실행하기 위한 서비스로서 부하가 있을 때의 성능 테스트나, 특정 실패 이벤트에 대한 대처를 시뮬레이션해볼 수 있도록 한다.

테스트 결과를 통해 애플리케이션의 성능과 복원력을 개선시켜 애플리케이션이 예상대로 작동하도록 만들 수 있다.

실제 AWS 리소스에 대해 작업을 수행하기 때문에, 아무런 대비 없이 FIS를 돌리는 것은 서버 공격이나 다름없다.
꼭 자동 복구 작업 세팅 후 테스트하기 위해서 사용하자.

### Target으로 사용할 수 있는 서비스 목록

- Amazon CloudWatch
- Amazon EBS
- Amazon EC2
- Amazon ECS
- Amazon EKS
- Amazon RDS
- AWS Systems Manager

### Spot instance interruption test

각 서비스에 대해서 수행할 수 있는 다양한 Action들이 있는데, spot instance로 인한 불안정에 대응하기 위해선 대표적으로 아래 Action을 사용할 수 있다.

> **aws:ec2:send-spot-instance-interruption**
>
> 대상 스팟 인스턴스를 중단합니다. [스팟 인스턴스를 중단하기 2분 전에 대상 스팟 인스턴스에 스팟 인스턴스 중단 알림을](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html#spot-instance-termination-notices) 보냅니다. 중단 시간은 지정된 **durationBeforeInterruption**파라미터에 의해 결정됩니다. 중단 시간으로부터 2분 후에 스팟 인스턴스는 중단 동작에 따라 종료되거나 중지됩니다. AWS FIS에 의해 중지된 스팟 인스턴스는 다시 시작할 때까지 중지된 상태로 유지됩니다.
>
> 작업이 시작된 직후 대상 인스턴스는 [EC2 인스턴스 재조정](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/rebalance-recommendations.html) 권장 사항(instance rebalance recommendation)을 받습니다.  **durationBeforeInterruption**를 지정한경우 재조정 권장 사항과 중단 알림 사이에 지연이 발생할 수 있습니다.
>
> 자세한 정보는 [자습서: 다음을 사용하여 스팟 인스턴스 중단 테스트 AWS FIS](https://docs.aws.amazon.com/ko_kr/fis/latest/userguide/fis-tutorial-spot-interruptions.html)을 참조하세요. *또는 Amazon EC2 콘솔을 사용하여 실험을 [시작하려면 Amazon EC2 사용 설명서의 스팟 인스턴스 중단 시작을](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/initiate-a-spot-instance-interruption.html) 참조하십시오.*

---

durationBeforeInterruption을 길게 잡으면 NTH에서 EC2 instance rebalance recommendation에 대해 어떻게 대응하는지 확인할 수 있다.

### 실험 템플릿 예시

- rebalance recommendation 메시지를 보내고 15분 후에
xquare-cluster의 spot instance를 랜덤으로 하나 종료 (instance rebalance recommendation test)

    ```
    aws fis create-experiment-template \
        --cli-input-json '{
            "description": " EC2 instance rebalance recommendation test",
            "targets": {
                    "SpotInstances-Target-1": {
                            "resourceType": "aws:ec2:spot-instance",
                            "resourceTags": {
                                    "eks:cluster-name": "xquare-cluster"
                            },
                            "selectionMode": "COUNT(1)"
                    }
            },
            "actions": {
                    "spot-instance-interruption": {
                            "actionId": "aws:ec2:send-spot-instance-interruptions",
                            "parameters": {
                                    "durationBeforeInterruption": "PT15M"
                            },
                            "targets": {
                                    "SpotInstances": "SpotInstances-Target-1"
                            }
                    }
            },
            "stopConditions": [
                    {
                            "source": "none"
                    }
            ],
            "roleArn": "arn:aws:iam::471407337433:role/FaultInjectionSimulatorEc2Role",
            "tags": {}
    }'
    ```

- xquare-cluster의 spot instance를 랜덤으로 하나 종료 (spot instance interrption test)

    ```
    aws fis create-experiment-template \
        --cli-input-json '{
            "description": "spot instance interruption test",
            "targets": {
                    "SpotInstances-Target-1": {
                            "resourceType": "aws:ec2:spot-instance",
                            "resourceTags": {
                                    "eks:cluster-name": "xquare-cluster"
                            },
                            "selectionMode": "COUNT(1)"
                    }
            },
            "actions": {
                    "spot-instance-interruption": {
                            "actionId": "aws:ec2:send-spot-instance-interruptions",
                            "parameters": {
                                    "durationBeforeInterruption": "PT2M"
                            },
                            "targets": {
                                    "SpotInstances": "SpotInstances-Target-1"
                            }
                    }
            },
            "stopConditions": [
                    {
                            "source": "none"
                    }
            ],
            "roleArn": "arn:aws:iam::471407337433:role/FaultInjectionSimulatorEc2Role",
            "tags": {}
    }'
    ```

---
참고

- <https://docs.aws.amazon.com/fis/latest/userguide/fis-actions-reference.html>
- <https://docs.aws.amazon.com/ko_kr/fis/latest/userguide/fis-tutorial-spot-interruptions.html>

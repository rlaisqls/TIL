
Node Termination Handler는 EC2 인스턴스가 [EC2 maintenance events](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-instances-status-check_sched.html), [EC2 Spot interruptions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html), [ASG Scale-In](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroupLifecycle.html#as-lifecycle-scale-in), ASG AZ 재조정, and EC2 Instance Termination 등의 이유로 사용할 수 없는 상태가 되었을 때 대응하기 위한 tool이다. 그에 대한 핸들링을 제때 해줌으로써 Pod를 더 빠르게 회복시키고 availability를 높일 수 있다.

## modes

The aws-node-termination-handler(NTH)에는 Instance Metadata Service (IMDS) 모드와 Queue Processor 모드 두가지가 있다.

### IMDS mode

The aws-node-termination-handler [Instance Metadata Service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) Monitor는 각 host에 작은 pod를 하나씩 돌려 `/spot`이나 `/events` 같은 metadata API에 주기적으로 요청을 보내 node를 drain 혹은 cordon 시킨다.

현재 xquare에서 사용하고 있는 mode이다. Queue 모드에 비해서 지원되지 않는 기능이 있다는 단점이 있지만, EC2 metadata를 이용해 돌아가기 때문에 별도의 AWS 리소스를 사용하지 않고 간단하게 구축할 수 있는 것이 장점이다.

### Queue Processor

Queue Processor 모드는 SQS queue에 연결하여 EventBridge에서 온 Event를 받아 처리한다. 아래와 같은 이벤트들을 처리할 수 있다.

- ASG lifecycle 이벤트
- EC2 status change 이벤트
- Spot Interruption Termination 알림 이벤트
- Spot Rebalance Recommendation
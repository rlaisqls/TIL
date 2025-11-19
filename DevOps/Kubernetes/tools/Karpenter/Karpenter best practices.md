### Use Karpenter for workloads with changing capacity needs

Karpenter는 [Auto Scaling Groups](https://aws.amazon.com/blogs/containers/amazon-eks-cluster-multi-zone-auto-scaling-groups/) (ASG)나 [Managed Node Groups](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/managed-node-groups.html) (MNG)보다 Kubernetes 네이티브 API에 더 가까운 스케일링 관리를 제공한다.

ASG와 MNG는 AWS 네이티브 추상화로, EC2 CPU 부하와 같은 AWS 레벨 메트릭을 기반으로 스케일링이 트리거된다.

[Cluster Autoscaler](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/autoscaling.html#cluster-autoscaler)는 Kubernetes 추상화를 AWS 추상화로 연결하지만, 특정 가용 영역에 대한 스케줄링과 같은 일부 유연성을 잃는다.

Karpenter는 AWS 추상화 레이어를 제거하여 유연성을 Kubernetes에 직접 제공한다. Karpenter는 높고 급격한 수요를 겪거나 다양한 컴퓨팅 요구사항을 가진 워크로드를 실행하는 클러스터에 가장 적합하다. MNG와 ASG는 정적이고 일관된 워크로드를 실행하는 클러스터에 적합하다. 요구사항에 따라 동적 및 정적 관리 노드를 혼합하여 사용할 수 있다.

### Consider other autoscaling projects when...

Karpenter에서 아직 개발 중인 기능이 필요한 경우. Karpenter는 비교적 새로운 프로젝트이므로, Karpenter에 아직 포함되지 않은 기능이 필요하다면 당분간 다른 오토스케일링 프로젝트를 고려하는 것이 좋다.

### Run the Karpenter controller on EKS Fargate or on a worker node that belongs to a node group

Karpenter는 Helm 차트를 사용하여 설치된다. Helm 차트는 Karpenter 컨트롤러와 웹훅 파드를 Deployment로 설치하며, 이는 클러스터 스케일링에 컨트롤러를 사용하기 전에 실행되어야 한다.

최소한 하나의 워커 노드를 가진 작은 노드 그룹 하나가 권장된다. 대안으로, karpenter 네임스페이스에 대한 Fargate 프로파일을 생성하여 EKS Fargate에서 이러한 파드를 실행할 수 있다. 이렇게 하면 이 네임스페이스에 배포된 모든 파드가 EKS Fargate에서 실행된다. Karpenter가 관리하는 노드에서 Karpenter를 실행하지 말아야 한다.

### Avoid using custom launch templates with Karpenter

Karpenter는 **커스텀 시작 템플릿 사용을 강력히 권장하지 않는다**. 커스텀 시작 템플릿을 사용하면 멀티 아키텍처 지원, 노드 자동 업그레이드 기능, securityGroup 검색이 방지된다. 시작 템플릿을 사용하면 특정 필드가 Karpenter의 프로비저너 내에서 중복되는 반면 다른 필드는 Karpenter에서 무시되어(예: 서브넷 및 인스턴스 타입) 혼란을 야기할 수 있다.

커스텀 사용자 데이터를 사용하거나 AWS 노드 템플릿에서 커스텀 AMI를 직접 지정하여 시작 템플릿 사용을 피할 수 있는 경우가 많다. 이를 수행하는 방법에 대한 자세한 내용은 Node Templates에서 확인할 수 있다.

### Exclude instance types that do not fit your workload

클러스터에서 실행되는 워크로드에 필요하지 않은 경우 `node.kubernetes.io/instance-type` 키를 사용하여 특정 인스턴스 타입을 제외하는 것을 고려하자.

다음 예시는 대형 Graviton 인스턴스의 프로비저닝을 피하는 방법을 보여준다.

```yaml
- key: node.kubernetes.io/instance-type
    operator: NotIn
    values:
      'm6g.16xlarge'
      'm6gd.16xlarge'
      'r6g.16xlarge'
      'r6gd.16xlarge'
      'c6g.16xlarge'
```

### Enable Interruption Handling when using Spot

Karpenter는 Karpenter 설정의 `aws.interruptionQueue` 값을 통해 활성화되는 [네이티브 중단 처리](https://karpenter.sh/docs/concepts/deprovisioning/#interruption)를 지원한다. 중단 처리는 워크로드에 중단을 야기할 수 있는 다음과 같은 예정된 비자발적 중단 이벤트를 감시한다.

- Spot 중단 경고
- 예약된 변경 건강 이벤트 (유지보수 이벤트)
- 인스턴스 종료 이벤트
- 인스턴스 중지 이벤트

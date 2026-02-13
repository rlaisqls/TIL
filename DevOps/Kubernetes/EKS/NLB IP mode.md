
AWS Load Balancer Controller는 Kubernetes `LoadBalancer` 타입 서비스에 적절한 어노테이션을 통해, Amazon EC2 인스턴스와 AWS Fargate에서 실행되는 Pod에 대한 IP 대상 모드의 Network Load Balancer(NLB)를 지원한다. 이 모드에서는 AWS NLB가 트래픽을 서비스 뒤의 Kubernetes Pod로 직접 타겟팅하므로, 워커 노드를 통한 추가적인 네트워크 홉이 필요 없다.

**설정**

NLB IP 모드는 서비스 객체에 추가된 어노테이션을 기반으로 결정된다. IP 모드의 NLB를 사용하려면 서비스에 다음 어노테이션을 적용한다:

```yaml
metadata:
  name: my-service
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: "nlb-ip"

```

> 기존 서비스 객체의 `service.beta.kubernetes.io/aws-load-balancer-type` 어노테이션을 수정하면 안 된다. 예를 들어 클래식에서 NLB로 기본 AWS 로드 밸런서 유형을 변경해야 하는 경우, Kubernetes 서비스를 먼저 삭제하고 올바른 어노테이션으로 다시 생성해야 한다. 그렇지 않으면 AWS 로드 밸런서 리소스가 유출될 수 있다.

> 기본 로드 밸런서는 인터넷 연결형이다. 내부 로드 밸런서를 생성하려면 서비스에 다음 어노테이션을 적용한다: `service.beta.kubernetes.io/aws-load-balancer-internal: "true"`

**프로토콜**

TCP와 UDP 프로토콜 모두 지원된다. TCP의 경우 IP 모드의 NLB는 클라이언트 소스 IP 주소를 Pod에 전달하지 않는다. 클라이언트 소스 IP 주소가 필요하면 어노테이션을 통해 [NLB 프록시 프로토콜 v2](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#proxy-protocol)를 구성할 수 있다.

프록시 프로토콜 v2를 활성화하려면 서비스에 다음 어노테이션을 적용한다:

```yaml
service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
```

**보안 그룹**

NLB는 현재 관리형 보안 그룹을 지원하지 않는다. 인그레스 접근의 경우 컨트롤러는 엔드포인트 Pod에 해당하는 ENI의 보안 그룹을 해석한다. ENI에 단일 보안 그룹이 있으면 그것이 사용된다. 여러 보안 그룹이 있는 경우 컨트롤러는 Kubernetes 클러스터 ID로 태그된 보안 그룹 하나만 찾으려고 한다. 컨트롤러는 서비스 스펙에 따라 보안 그룹의 인그레스 규칙을 업데이트한다.

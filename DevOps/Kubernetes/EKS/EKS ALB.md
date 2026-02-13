
Kubernetes `ingress`를 생성하면 애플리케이션 트래픽을 로드 밸런싱하는 AWS Application Load Balancer(ALB)가 프로비저닝된다. ALB는 노드에 배포된 Pod나 AWS Fargate Pod와 함께 사용할 수 있다. ALB를 퍼블릭 또는 프라이빗 서브넷에 배포할 수 있다.

애플리케이션 트래픽을 로드 밸런싱하기 전에 다음 요구사항을 충족해야 한다.

**사전 조건**

- 기존 클러스터가 있어야 한다.
- 클러스터에 AWS Load Balancer Controller가 배포되어 있어야 한다.
- 서로 다른 가용 영역에 최소 두 개의 서브넷이 필요하다. AWS Load Balancer Controller는 각 가용 영역에서 하나의 서브넷을 선택한다. 한 가용 영역에 태그가 지정된 서브넷이 여러 개 발견되면 서브넷 ID가 사전순으로 먼저 오는 서브넷을 선택한다. 각 서브넷에는 최소 8개의 사용 가능한 IP 주소가 있어야 한다.
    워커 노드에 여러 보안 그룹이 연결된 경우, 정확히 하나의 보안 그룹에 다음과 같이 태그를 지정해야 한다. my-cluster를 클러스터 이름으로 교체한다.
    - **Key** – `kubernetes.io/cluster/my-cluster`
    - **Value** – `shared or owned`

- 서비스나 인그레스 객체의 어노테이션으로 서브넷 ID를 명시적으로 지정하지 않는 한, 퍼블릭 및 프라이빗 서브넷은 다음 요구사항을 충족해야 한다. 서비스나 인그레스 객체의 어노테이션으로 서브넷 ID를 명시적으로 지정하는 경우, Kubernetes와 AWS Load Balancer Controller는 해당 서브넷을 직접 사용하여 로드 밸런서를 생성하므로 다음 태그가 필요 없다.
  - **프라이빗 서브넷** – Kubernetes와 AWS Load Balancer Controller가 내부 로드 밸런서에 서브넷을 사용할 수 있도록 다음 형식으로 태그를 지정해야 한다. 2020년 3월 26일 이후에 eksctl이나 Amazon EKS AWS CloudFormation 템플릿으로 VPC를 생성한 경우, 서브넷에 자동으로 적절한 태그가 지정된다.
    - **Key** – `kubernetes.io/role/internal-elb`
    - **Value** – `1`
  - **퍼블릭 서브넷** – Kubernetes가 외부 로드 밸런서에 지정된 서브넷만 사용하도록 다음 형식으로 태그를 지정해야 한다. 이렇게 하면 Kubernetes가 각 가용 영역에서 퍼블릭 서브넷을 사전순으로 선택하는 것을 방지한다.
    - **Key** – `kubernetes.io/role/elb`
    - **Value** – `1`

서브넷 역할 태그가 명시적으로 추가되지 않은 경우, Kubernetes 서비스 컨트롤러는 클러스터 VPC 서브넷의 라우트 테이블을 검사하여 서브넷이 프라이빗인지 퍼블릭인지 판단한다. 이 동작에 의존하지 않는 것이 좋으며, 프라이빗 또는 퍼블릭 역할 태그를 명시적으로 추가하는 것을 권장한다. AWS Load Balancer Controller는 라우트 테이블을 검사하지 않으며, 자동 검색이 성공하려면 프라이빗 및 퍼블릭 태그가 있어야 한다.

**고려 사항**

- AWS Load Balancer Controller는 클러스터에 `kubernetes.io/ingress.class: alb` 어노테이션이 있는 Kubernetes 인그레스 리소스가 생성될 때마다 ALB와 필요한 AWS 리소스를 생성한다. 인그레스 리소스는 클러스터 내의 다양한 Pod로 HTTP 또는 HTTPS 트래픽을 라우팅하도록 ALB를 구성한다. 인그레스 객체가 AWS Load Balancer Controller를 사용하도록 하려면 Kubernetes 인그레스 스펙에 다음 어노테이션을 추가한다. [추가 정보](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/spec/)

```yml
annotations:
    kubernetes.io/ingress.class: alb
    # IPv6를 사용하려면
    # alb.ingress.kubernetes.io/ip-address-type: dualstack
```

- AWS Load Balancer Controller는 다음 트래픽 모드를 지원한다:
  - **Instance** – 클러스터 내의 노드를 ALB의 대상으로 등록한다. <u>ALB에 도달하는 트래픽은 서비스의 NodePort로 라우팅된 후 Pod로 프록시된다.</u> 기본 트래픽 모드이다. `alb.ingress.kubernetes.io/target-type: instance` 어노테이션으로 명시적으로 지정할 수도 있다.
  - **IP** – Pod를 ALB의 대상으로 등록한다. ALB에 도달하는 트래픽은 <u>서비스의 Pod로 직접 라우팅된다</u>. 이 트래픽 모드를 사용하려면 `alb.ingress.kubernetes.io/target-type: ip` 어노테이션을 지정해야 한다. 대상 Pod가 Fargate에서 실행되는 경우 IP 대상 유형이 필수이다.

- 컨트롤러가 생성하는 ALB에 태그를 지정하려면 `alb.ingress.kubernetes.io/tags` 어노테이션을 추가한다. AWS Load Balancer Controller가 지원하는 모든 사용 가능한 어노테이션 목록은 GitHub의 [Ingress annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/annotations/)를 참고한다.

- ALB 컨트롤러 버전을 업그레이드하거나 다운그레이드하면 해당 기능에 의존하는 기능에 대한 호환성 문제가 발생할 수 있다. 각 릴리스에서 도입된 변경 사항에 대한 자세한 내용은 GitHub의 [ALB controller 릴리스 노트](https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases)를 참고한다.

- **IngressGroup을 사용하여 여러 서비스 리소스에서 Application Load Balancer를 공유하려면**
    인그레스를 그룹에 추가하려면 Kubernetes 인그레스 리소스 스펙에 다음 어노테이션을 추가한다.
    ```yml
    alb.ingress.kubernetes.io/group.name: my-group
    ```

## (선택 사항) 샘플 애플리케이션 배포

**사전 조건**

- 클러스터 VPC에 최소 하나의 퍼블릭 또는 프라이빗 서브넷이 있어야 한다.
- 클러스터에 AWS Load Balancer Controller가 배포되어 있어야 한다. 버전 2.4.7 이상을 권장한다.

**샘플 애플리케이션 배포 방법**

Amazon EC2 노드, Fargate Pod 또는 둘 다에서 샘플 애플리케이션을 실행할 수 있다.

1. Fargate에 배포하지 않는 경우 이 단계를 건너뛴다. Fargate에 배포하는 경우 Fargate 프로파일을 생성한다. 다음 명령어를 실행하거나 AWS Management Console에서 동일한 이름과 네임스페이스 값을 사용하여 프로파일을 생성할 수 있다. `example values`를 자신의 값으로 교체한다.

```bash
eksctl create fargateprofile \
    --cluster my-cluster \
    --region region-code \
    --name alb-sample-app \
    --namespace game-2048
```

2. 인그레스 객체의 결과로 AWS Load Balancer Controller가 AWS ALB를 생성하는지 확인하기 위해 게임 [2048](https://play2048.co/)을 샘플 애플리케이션으로 배포한다. 배포할 서브넷 유형에 맞는 단계를 완료한다.

  - **퍼블릭**
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/examples/2048/2048_full.yaml
    ```
  - **프라이빗**
    1. 매니페스트를 다운로드한다
      ```bash
      curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/examples/2048/2048_full.yaml
      ```
    2. 파일을 편집하여 `alb.ingress.kubernetes.io/scheme: internet-facing` 줄을 찾는다.
    3. `internet-facing`을 `internal`로 변경하고 파일을 저장한다
    4. 클러스터에 매니페스트를 적용한다.
      ```bash
      kubectl apply -f 2048_full.yaml
      ```

3. 몇 분 후 다음 명령어로 인그레스 리소스가 생성되었는지 확인한다.

  ```bash
  $ kubectl get ingress/ingress-2048 -n game-2048
  NAME           CLASS    HOSTS   ADDRESS                                                                   PORTS   AGE
  ingress-2048   <none>   *       k8s-game2048-ingress2-xxxxxxxxxx-yyyyyyyyyy.region-code.elb.amazonaws.com   80      2m32s
  ```

4. 퍼블릭 서브넷에 배포한 경우 브라우저를 열고 이전 명령어 출력의 ADDRESS URL로 이동하여 샘플 애플리케이션을 확인한다. 아무것도 보이지 않으면 브라우저를 새로고침하고 다시 시도한다. 프라이빗 서브넷에 배포한 경우에는 배스천 호스트 같은 VPC 내의 장치에서 페이지를 확인해야 한다.

5. 샘플 애플리케이션 실험이 끝나면 다음 명령어 중 하나를 실행하여 삭제한다.

- 매니페스트를 직접 적용한 경우(다운로드하지 않은 경우) 다음 명령어를 사용한다.

  ```bash
  kubectl delete -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/examples/2048/2048_full.yaml
  ```

- 매니페스트를 다운로드하고 편집한 경우 다음 명령어를 사용한다.

  ```bash
  kubectl delete -f 2048_full.yaml
  ```


EKS 환경에서 EBS에 데이터를 영속적으로 저장하고 싶다면, AWS에서 제공하는 EBS CSI driver 애드온을 사용할 수 있다.

사전에 IAM OIDC 프로바이더를 활성화하고 EBS CSI driver용 IAM 역할을 생성해야 한다. 가장 쉬운 방법은 eksctl을 사용하는 것이다(일반 AWS CLI나 AWS 콘솔을 사용하는 방법은 공식 문서에 설명되어 있다).

**1. IAM OIDC 프로바이더 활성화**

클러스터에 IAM OIDC 프로바이더가 있어야 한다:

```bash
eksctl utils associate-iam-oidc-provider --region=eu-central-1 --cluster=YourClusterNameHere --approve
```

**2. Amazon EBS CSI driver IAM 역할 생성**

eksctl을 사용하여 IAM 역할을 생성한다:

```bash
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster YourClusterNameHere \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole
```

AWS가 관리형 정책(ARN: `arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy`)을 제공하므로, 암호화된 EBS 드라이브를 사용하는 경우에만 추가 구성이 필요하다.

> 이 명령어는 IAM 역할을 생성하고, IAM 정책을 연결하고, 기존 ebs-csi-controller-sa 서비스 계정에 IAM 역할의 ARN을 어노테이션하는 AWS CloudFormation 스택을 배포한다.

**3. Amazon EBS CSI 애드온 추가**

AWS 계정 ID(`aws sts get-caller-identity --query Account --output text`로 확인)를 사용하여 애드온을 추가한다:

```bash
eksctl create addon --name aws-ebs-csi-driver --cluster YourClusterNameHere --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AmazonEKS_EBS_CSI_DriverRole --force
```

이제 PersistentVolumeClaim이 Bound 상태가 되면서 EBS 볼륨이 생성되고, Tekton Pipeline이 다시 실행될 것이다.

---
참고
- https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/
- https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html

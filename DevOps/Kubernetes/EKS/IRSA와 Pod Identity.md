## IRSA

EKS IRSA는 POD가 특정 IAM Role로 Assume할 때, 토큰을 AWS에 전송하고 AWS는 토큰과 EKS IdP를 통해 해당 IAM Role을 사용할 수 있는지 검증한다. EC2 Instance Profile과 유사하게 Pod 단위의 자격증명을 통해 IAM Role을 사용하는 것이다.

EKS IRSA의 장점으로는 세 가지가 있다.

- 최소 권한 원칙
- 자격 증명의 격리(Credential Isolation)
  - SDK의 Credential Provider Chain를 사용하게 되면 CloudTrail에 node의 역할로 찍힘
    - 누가 어떤 일을 했는지에 대한 분리가 됨
- 감사(Auditability)

IRSA는 OIDC(OpenID Connect) 공급자를 사용하여 자격 증명을 할 수 있다. 이 기능을 사용하면 AWS API 호출을 인증하고 유효한 OIDC JWT 토큰을 받을 수 있다. 이 토큰을 AWS STS AssumeRoleWithWebIdentity에 전달하고 IAM 임시 역할 자격 증명을 받을 수 있다.

IRSA는 eksctl create iamserviceaccount 명령어 한 줄로 설정할 수 있다.

```
eksctl create iamserviceaccount \
  --name my-sa \
  --namespace default \
  --cluster $CLUSTER_NAME \
  --approve \
  --attach-policy-arn $(aws iam list-policies --query 'Policies[?PolicyName==`AmazonS3ReadOnlyAccess`].Arn' --output text)
```

AmazonS3ReadOnlyAccess 정책을 붙인 IRSA를 생성하였다. 이는 Cloudformation으로 자동으로 생성되고 default 네임스페이스에 my-sa 이름으로 IRSA 하나가 생성되었다.

해당 SA에 자동으로 Role이 생성되었는데 이를 확인해 보면 Condition에 sts.amazonaws.com와 system:serviceaccount:default:my-sa 값이 일치해야 한다는 조건이 생겼다. 또한 sts:AssumeRoleWithWebIdentity이 실행된 것도 알 수 있었다.

신규 POD를 만들어 테스트해 보자. 이 POD에는 위에 생성한 SA를 설정했다.

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: eks-iam-test3
spec:
  serviceAccountName: my-sa
  containers:
    - name: my-aws-cli
      image: amazon/aws-cli:latest
      command: ['sleep', '36000']
  restartPolicy: Never
  terminationGracePeriodSeconds: 0
EOF
```

pod-identity-webhook은 mutating webhook을 통해 아래 Env 내용과 볼륨 하나를 추가했다. pod-identity-webhook은 POD를 생성할 수 있는 권한을 가지고 있다.

- ENV -> 사용할 Role과 토큰 값이 설정되었다.
- aws-iam-token 볼륨 ⇒ 86400초인 24시간 동안 유효한 토큰을 사용할 수 있다.

POD 내부에서 명령을 실행해 보면

- get-caller-identity 실행이 가능하다
- AmazonS3ReadOnlyAccess 정책대로 실행된다.

## Pod Identity

IRSA는 정책에 `system:serviceaccount:*:*`가 들어있으면, 토큰만 검증받은 후엔 또 다른 검증없이 모든 SA에게 동일한 권한을 부여할 수 있다.

더불어 OIDC의 엔드포인트는 퍼블릭이기에 보안에 취약할 수 있다. 그래서 SA가 가지고 있는 토큰 값과 Role ARN만 알면 STS 임시자격증명 발급을 요청할 수 있고

```
$ IAM_TOKEN=$(kubectl exec -it eks-iam-test3 -- cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token)
$ eksctl get iamserviceaccount --cluster $CLUSTER_NAME
 NAMESPACE       NAME                            ROLE ARN
 default         my-sa                           arn:aws:iam::**:role/eksctl-myeks-addon-iamserviceaccount-default--Role1-sEMLKoOub24T
$ ROLE_ARN=arn:aws:iam::**:role/eksctl-myeks-addon-iamserviceaccount-default--Role1-sEMLKoOub24T
$ aws sts assume-role-with-web-identity --role-arn $ROLE_ARN --role-session-name mykey --web-identity-token $IAM_TOKEN | jq
```

얻어낸 키, 토큰, 역할로 권한을 쉽게 탈취할 수 있다.

EKS Pod Identity는 위와 같은 문제를 방지하며, 기존의 IRSA보다 더 편하게 사용할 수 있게 발전된 형태로 만들어졌다.

- 신뢰 정책에서 pods.eks.amazonaws.com을 서비스 주체로 지정한다.
- EKS 콘솔 또는 aws cli로 Amazon EKS Pod Identity Agent 추가 기능을 설치한다.
- EKS 콘솔 또는 aws cli로 SA에 Role을 매핑한다.

EKS 콘솔 혹은 aws cli로 addon을 설치해보자.

```
aws eks create-addon --cluster-name $CLUSTER_NAME --addon-name eks-pod-identity-agent
eksctl create addon --cluster $CLUSTER_NAME --name eks-pod-identity-agent --version 1.2.0
```

eks-pod-identity-agent는 데몬셋으로 생성되어 hostNetwork를 사용하고, 링크 로컬 169.254.170.23 주소와 80, 2703 포트를 사용한다.

aws cli로 podidentityassociation를 생성한다.

```
eksctl create podidentityassociation \
--cluster $CLUSTER_NAME \
--namespace default \
--service-account-name s3-sa \
--role-name s3-eks-pod-identity-role \
--permission-policy-arns arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
--region $AWS_REGION
```

신뢰 관계를 보면 AssumeRole과 TagSession이 들어가 있다.

- "sts:AssumeRole",
- "sts:TagSession"

TagSession을 통해 ABAC 설정이 가능하다.

이제 테스트 SA와 POD를 생성해 보자

```
kubectl create sa s3-sa

cat <<EOF | kubectl apply -f -**
apiVersion: v1
kind: Pod
metadata:
  name: eks-pod-identity
spec:
  serviceAccountName: s3-sa
  containers:
    - name: my-aws-cli
      image: amazon/aws-cli:latest
      command: ['sleep', '36000']
  restartPolicy: Never
  terminationGracePeriodSeconds: 0
EOF
```

POD를 생성하면 sa가 podidentityassociation을 통해 AmazonS3ReadOnlyAccess에 연결되어 있기 때문에 아래와 같이 ENV와 토큰 볼륨이 생성된 것을 알 수 있다. 이제 POD에서 S3 조회가 가능하다

POD Identity는 좀 더 편리하게 사용할 수 있지만, 아래와 같은 사항을 확인해주어야 한다.

- SDK, EKS 클러스터 버전 (1.21 이상만 지원)
- 링크 로컬 주소 169.254.170.23가 사용 가능한지
- Node의 IAM Policy에서 Action에 `eks-auth:AssumeRoleForPodIdentity`이 있는지
- 또한 Amazon VPC CNI plugin, AWS Load Balancer Controller, 몇몇 CSI storage drivers에선 pod identity를 아직 지원하지 않아 IRSA를 사용해야 한다.

---

참고

- <https://aws.amazon.com/ko/blogs/containers/diving-into-iam-roles-for-service-accounts/>
- <https://aws.amazon.com/ko/blogs/containers/amazon-eks-pod-identity-a-new-way-for-applications-on-eks-to-obtain-iam-credentials/>

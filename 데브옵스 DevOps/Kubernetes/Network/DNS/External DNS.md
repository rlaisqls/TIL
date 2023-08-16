# External DNS

ExternalDNS는 kubernetes dns(kube-dns)와 상반되는 개념으로 내부 도메인서버가 아닌 Public한 도메인서버(AWS Route53, GCP DNS 등)를 사용하여 쿠버네티스의 리소스를 쿼리할 수 있게 해주는 오픈소스 솔루션이다.

ExternalDNS를 사용하면 public도메인 서버가 무엇이든 상관없이 쿠버네티스 리소스를 통해서 DNS레코드를 동적으로 관리 할 수 있다. 

### ExternalDNS 설치

쿠버네티스 서비스 계정에 IAM 역할을 사용하려면 OIDC 공급자가 필요하다. IAM OIDC 자격 증명 공급자를 생성한다.

```bash
eksctl utils associate-iam-oidc-provider --cluster {cluster name} --approve
```

External DNS용도의 구분된 namespace를 생성한다.

```bash
kubectl create namespace external-dns
```

External DNS가 Route53을 제어할 수 있도록 정책을 생성한다. IAM Policy json 파일을 생성해준다.

```bash
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

생성한 json파일로 IAM Policy를 생성한다.

```bash
aws iam create-policy --policy-name AllowExternalDNSUpdates --policy-document file://{json file name}.
```

`eksctl`을 이용하여 iam service account를 생성한다.

```bash
eksctl create iamserviceaccount \
    --name <service_account_name> \ ### Exteranl DNS service account명 = external-dns
    --namespace <service_account_namespace> \ ### External DNS namespace명 = external-dns
    --cluster <cluster_name> \ ### AWS EKS 클러스터명
    --attach-policy-arn <IAM_policy_ARN> \ ### 앞서 생성한 Policy arn
    --approve \
    --override-existing-serviceaccounts
```

> 클러스터 노드 IAM Role에 Route53 접근권한이 설정되지 않는 경우 배포가 되지 않는다. 적용이 안되었으면 IAM Role 콘솔에서 직접 적용해야한다.

### External DNS 배포

공식 문서를 참고하여 yaml파일을 작성하고 배포한다.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
  namespace: external-dns
  # If you're using Amazon EKS with IAM Roles for Service Accounts, specify the following annotation.
  # Otherwise, you may safely omit it.
  annotations:
    # Substitute your account ID and IAM service role name below.
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT-ID:role/IAM-SERVICE-ROLE-NAME
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
  namespace: external-dns
rules:
- apiGroups: [""]
  resources: ["services","endpoints","pods"]
  verbs: ["get","watch","list"]
- apiGroups: ["extensions","networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get","watch","list"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
  namespace: external-dns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: external-dns
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: external-dns
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: k8s.gcr.io/external-dns/external-dns:v0.7.6
        args:
        - --source=service
        - --source=ingress
        - --domain-filter=external-dns-test.my-org.com # will make ExternalDNS see only the hosted zones matching provided domain, omit to process all available hosted zones
        - --provider=aws
        - --policy=upsert-only # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
        - --aws-zone-type=public # only look at public hosted zones (valid values are public, private or no value for both)
        - --registry=txt
        - --txt-owner-id=my-hostedzone-identifier
      securityContext:
        fsGroup: 65534 # For ExternalDNS to be able to read Kubernetes and AWS token files
```

`eks.amazonaws.com/role-arn`과 `domain-filter`를 정확하게 입력해줘야 한다.

policy는 Route53에서 레코드 업데이트를 제어하는 정책을 뜻한다.

- upsert-only: 생성, 업데이트
- sync: 생성, 업데이트, 삭제
- create-only: 생성

## 서비스 배포

ingress에 `external-dns.alpha.kubernetes.io/hostname`와 `service.beta.kubernetes.io/aws-load-balancer-ssl-cert` annotation을 추가하여 설정해준다.

```yaml
apiVersion: v1
kind: Service
metadata:
   name: test-service
   annotations:
    external-dns.alpha.kubernetes.io/hostname: your.domain.com # 자신의 domain
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:ap-northeast-2:{accountId}:certificate/{} # ssl cert의 arn
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: https
spec:
  selector:
    app: test
  ports:
  - name: http
	protocol: TCP
	port: 80
	targetPort: 8080
  - name: https
	port: 443
	targetPort: 8080
  protocol: TCP
  type: LoadBalancer
```

배포된 external-dns의 로그를 확인해서 레코드가 정상적으로 생성되는지 확인할 수 있다.

```yaml
kubectl logs -f {external-dns pod name} -n external-dns
```

---
참고
- https://github.com/kubernetes-sigs/external-dns#the-latest-release-v08
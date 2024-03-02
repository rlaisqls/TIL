 
EKS 기본 환경 Setting 방법을 알아보자.

쿠버네티스는 kubectl에 대한 인증정보를 kubeconfig라는 yaml파일에 저장한다. EKS 클러스터는 어떻게 접근을 하는지, 어떻게 인증을 받아오는지 알아보자.

### Kubeconfig

EKS 클러스터에 접근 가능한 kubeconfig파일을 생성하는 것은 간단하다. aws command 한 줄이면 인증 정보를 kubeconfig 파일에 저장할 수 있다.

```bash
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
```

kubeconfig 파일 내용을 살펴보자.

```yml
apiVersion: v1
clusters:
- cluster:
    server: <endpoint-url>
    certificate-authority-data: <base64-encoded-ca-cert>
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  # namesapce: "<namespace>"
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws
      args:
        - "eks"
        - "get-token"
        - "--cluster-name"
        - "<cluster-name>"
        # - "--role-arn"
        # - "<role-arn>"
      # env:
        # - name: AWS_PROFILE
        #   value: "<aws-profile>"

```

kubeconfig 파일은 크게 `clusters` / `contexts` / `users`로 구분할 수 있다. clusters는 클러스터의 인증 정보, users는 사용자 eks로는 IAM에 대한 인증 정보를 토큰 값으로 저장하는 방식이다. 그리고 context는 clusters와 users의 조합하는 구간으로 namespace 또한 지정 가능하다.

잘 생성되었는지 테스트 해보자.

```bash
$ kubectl get svc

NAME             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
svc/kubernetes   ClusterIP   10.100.0.1   <none>        443
```

### 수동으로 kubeconfig 파일 생성

kubeconfig 파일을 수동으로 생성하려면 우선 몇 개의 환경변수를 설정해준다. (`******` 부분의 값을 알맞게 변경)

```bash
export region_code=******
export cluster_name=******
export account_id=******
```

클러스터의 엔드포인트를 검색하고 값을 변수에 저장한다.

```bash
export cluster_endpoint=$(aws eks describe-cluster \
    --region $region_code \
    --name $cluster_name \
    --query "cluster.endpoint" \
    --output text)
```

클러스터와 통신하는 데 필요한 Base64 인코딩 인증서 데이터를 검색하고 값을 변수에 저장한다.

```bash
certificate_data=$(aws eks describe-cluster \
    --region $region_code \
    --name $cluster_name \
    --query "cluster.certificateAuthority.data" \
    --output text)
```
  
기본 `~/.kube` 디렉터리가 아직 없으면 생성해줘야한다.

```bash
mkdir -p ~/.kube
```

아래 쉘 스크립트에 값을 적어주고 실행한다.

```bash
#!/bin/bash
read -r -d '' KUBECONFIG <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $certificate_data
    server: $cluster_endpoint
  name: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
contexts:
- context:
    cluster: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
    user: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
  name: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
current-context: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
kind: Config
preferences: {}
users:
- name: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - --region
        - $region_code
        - eks
        - get-token
        - --cluster-name
        - $cluster_name
        # - --role
        # - "arn:aws:iam::$account_id:role/my-role"
      # env:
        # - name: "AWS_PROFILE"
        #   value: "aws-profile"
EOF
echo "${KUBECONFIG}" > ~/.kube/config
```

KUBECONFIG 환경 변수에 파일 경로를 추가한다. (kubectl은 클러스터 구성을 찾아야 하는 위치를 알 수 있도록 함)

```bash
export KUBECONFIG=$KUBECONFIG:~/.kube/config
```

잘 생성되었는지 테스트 해보자.

```bash
$ kubectl get svc

NAME             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
svc/kubernetes   ClusterIP   10.100.0.1   <none>        443
```

---
참고
- https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/create-kubeconfig.html
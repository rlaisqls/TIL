
<img src="https://github.com/rlaisqls/TIL/assets/81006587/94ff313b-6e46-4aa4-81cc-15f4cb2c8e20" height=300px>

kubectl에서 EKS Cluster의 K8s API Server에 접근하거나, Worker Node에서 동작하는 kubelet에서 EKS Cluster의 K8s API Server 접근시에는 **AWS IAM Authenticator**가 이용된다.

<img width="404" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/f5a2ee70-7834-4a27-a609-16e9eb0332d5">
<img width="406" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/75bcdd0e-4444-4d3c-a63d-729d299f5a31">

왼쪽은 kubelet의 kubeconfig이고, 오른쪽은 kubectl의 kubeconfig이다. 두 kubeconfig 모두 user 부분을 확인해보면 `aws eks get-token` 명령어를 수행하는 것을 확인할 수 있다. `aws eks get-token` 명령어는 해당 명령어를 수행하는 Identity가 누구인지 알려주는 AWS STS의 GetCallerIdentity API의 Presigned URL을 생성하고, 생성한 URL을 Encoding하여 Token을 생성한다. 여기서 Identity는 AWS IAM의 User/Role을 의미한다.

Presigned URL은 의미 그대로 미리 할당된 URL을 의미한다. AWS STS의 GetCallerIdentity API를 호출하기 위해서는 AccessKey/SecretAccessKey와 같은 Secret이 필요하지만, Presigned URL을 이용하여 GetCallerIdentity API를 호출하면 Secret없이 호출이 가능하다. Token을 통해서 전달되는 GetCallerIdentity API의 Presigned URL은 AWS IAM Authenticator에게 전달되어 `aws eks get-token` 명령어를 수행한 Identity이 누구인지 파악하는데 이용된다.

```bash
# "aws eks get-token" 명령어 출력 결과 예시
$ aws eks get-token --cluster-name test-eks-cluster
{
	"kind": "ExecCredential",
	"apiVersion": "client.authentication.k8s.io/v1alpha1",
	"spec": {},
	"status": {
		"expirationTimestamp": "2022-04-26T17:46:42Z",
		"token": "k8s-aws-v1.aHR0cHM6Ly9zdHMuYXAtbm9ydGhlYXN0LTIuYW1hem9uYXdzLmNvbS8_QWN0aW9uPUdldENhbGxlcklkZW50aXR5JlZlcnNpb249MjAxMS0wNi0xNSZYLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFSNVFPRVpQVTRRWFg1SDRGJTJGMjAyMjA0MjYlMkZhcC1ub3J0aGVhc3QtMiUyRnN0cyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjIwNDI2VDE3MzI0MlomWC1BbXotRXhwaXJlcz02MCZYLUFtei1TaWduZWRIZWFkZXJzPWhvc3QlM0J4LWs4cy1hd3MtaWQmWC1BbXotU2lnbmF0dXJlPTIxOGQ4MDQ5NTBlZGMxMWRlZmQ0OWMwYTFkNWZkYWNjMzI0Y2M4MzBmZDZmMDZkNTlhN2Q5NzUwMGZhM2U3Mzg"
	}
}

$ base64url decode aHR0cHM6Ly9zdHMuYXAtbm9ydGhlYXN0LTIuYW1hem9uYXdzLmNvbS8_QWN0aW9uPUdldENhbGxlcklkZW50aXR5JlZlcnNpb249MjAxMS0wNi0xNSZYLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFSNVFPRVpQVTRRWFg1SDRGJTJGMjAyMjA0MjYlMkZhcC1ub3J0aGVhc3QtMiUyRnN0cyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjIwNDI2VDE3MzI0MlomWC1BbXotRXhwaXJlcz02MCZYLUFtei1TaWduZWRIZWFkZXJzPWhvc3QlM0J4LWs4cy1hd3MtaWQmWC1BbXotU2lnbmF0dXJlPTIxOGQ4MDQ5NTBlZGMxMWRlZmQ0OWMwYTFkNWZkYWNjMzI0Y2M4MzBmZDZmMDZkNTlhN2Q5NzUwMGZhM2U3Mzg
https://sts.ap-northeast-2.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAR5QOEZPU4QXX5H4F%2F20220426%2Fap-northeast-2%2Fsts%2Faws4_request&X-Amz-Date=20220426T173242Z&X-Amz-Expires=60&X-Amz-SignedHeaders=host%3Bx-k8s-aws-id&X-Amz-Signature=218d804950edc11defd49c0a1d5fdacc324cc830fd6f06d59a7d97500fa3e738
```

token의 "k8s-aws-v1" 뒷부분의 문자열을 base64url로 decoding을 수행하면 GetCallerIdentity API의 Presigned URL을 확인할 수 있다.

GetCallerIdentity API의 Presigned URL에 `x-k8s-aws-id: Cluster 이름` Header와 함께 Get 요청을 수행하면 "aws eks get-token" 명령어를 수행한 Identity이 누구인지 알 수 있다. GetCallerIdentity API의 Presigned URL을 대상으로 Get 요청을 수행하면 "test" User가 "aws eks get-token" 명령어를 수행했다는 사실을 알 수 있다.

AWS IAM Authenticator는 EKS Cluster의 K8s API Server에 인증 Webhook Server로 등록되어 있다. 따라서 kubelet/kubectl이 "aws eks get-token" 명령어를 통해서 생성한 Token은 AWS IAM Authenticator에게 전달된다. 

```bash
$ curl -H "x-k8s-aws-id: test-eks-cluster" "https://sts.ap-northeast-2.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAR5QOEZPU4QXX5H4F%2F20220426%2Fap-northeast-2%2Fsts%2Faws4_request&X-Amz-Date=20220426T173242Z&X-Amz-Expires=60&X-Amz-SignedHeaders=host%3Bx-k8s-aws-id&X-Amz-Signature=218d804950edc11defd49c0a1d5fdacc324cc830fd6f06d59a7d97500fa3e738"
<GetCallerIdentityResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
  <GetCallerIdentityResult>
    <Arn>arn:aws:iam::142021912854:user/test</Arn>
    <UserId>DCDAJXZHJQB4JQK2FDWQ</UserId>
    <Account>142021912854</Account>
  </GetCallerIdentityResult>
  <ResponseMetadata>
    <RequestId>9bdb9ca4-65c5-4659-8ca0-0e0625d14c5d</RequestId>
  </ResponseMetadata>
</GetCallerIdentityResponse>
```

## "aws-auth" ConfigMap

AWS IAM Authenticator는 "aws eks get-token" 명령어를 수행한 Identity를 파악한 다음, 파악한 Identity가 EKS Cluster의 어떤 User/Group과 Mapping 되는지 확인한다. 이후 AWS IAM Authenticator는 Mapping 되는 EKS Cluster의 User/Group을 EKS Cluster의 K8s API Server에게 전달한다.

"aws eks get-token" 명령어을 수행한 Identity와 EKS Cluster의 User/Group과의 Mapping 정보는 kube-system Namespace에 존재하는 aws-auth ConfigMap에 저장되어 있다. mapUser 항목은 "aws eks get-token" 명령어을 수행한 AWS IAM User와 EKS Cluster의 User/Group을 Mapping을 하는데 이용되며, mapRoles 항목은 "aws eks get-token" 명령어를 수행한 AWS IAM Role과 EKS Cluster의 User/Group을 Mapping 하는데 이용한다.

에서 test AWS IAM User는 EKS Cluster의 admin User 또는 system:master Group에 Mapping되는걸 확인할 수 있다. EKS Cluster에서 Node Group 생성시 각 Node Group에서 이용하는 AWS IAM Role이 생성되는데, Node Group의 AWS IAM Role도 [파일 3]의 mapRoles 항목에서 확인할 수 있다.

```yaml
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::132099418825:role/eksctl-test-eks-cluster-nodegrou-NodeInstanceRole-1CR0AFVMLFHSE
      username: system:node:
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::132099418825:role/eksctl-test-eks-cluster-nodegrou-NodeInstanceRole-1FLORRGQWIWD8
      username: system:node:
  mapUsers: |
    - userarn: arn:aws:iam::142627221238:user/test
      username: admin
      groups:
        - system:masters
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
...
```
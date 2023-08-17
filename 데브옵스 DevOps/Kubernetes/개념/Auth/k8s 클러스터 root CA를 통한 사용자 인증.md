# k8s 클러스터 root CA를 통한 사용자 인증

k8s는 기본적으로 root CA 인증서를 스스로 발급해 사용한다. 이 인증서를 이용하면 별도의 Third-party 연동 없이도 User와 Group을 사용할 수 있다. 단, 이 방법은 여러모로 한계점이 많기 때문에 가능하면 사용하지 않는 것이 좋다. 인증서가 유출되었을 때 revoke가 힘들기도 하고, 파일 단위로 인증 정보를 관리하는 것은 매우 비효율적이고 보안에 취약하기 때문이다. 따라서 k8s는 인증서 발급을 통한 사용자 인증은 극히 제한된 경우에만 사용하고 있다. 대표적으로는 관리자 권한을 가져야 하는 `system:master` 그룹의 인증 정보를 생성한다거나 (`/etc/kubernetes/admin.conf`), k8s의 핵심 컴포넌트에 인증서를 발급한다거나 할 때가 이에 해당한다. 

우선, k8s는 기본적으로 마스터 노드의 `/etc/kubernetes/pki` 디렉터리에 root 인증서를 저장해 놓는다. 

위의 `ca.crt`와 `ca.key` 파일이 root 인증서에 해당하는데, 이 root 인증서를 통해 생성된 하위 인증서는 k8s 인증에 사용할 수 있다. k8s는 csr이라는 object를 통해 간접적으로 root CA로부터 하위 인증서를 발급하는 기능을 제공하기 때문에, 이 기능을 사용해서 하위 인증서에 대한 비밀 키를 우선 생성해보자.

```bash
$ openssl genrsa -out rlaisqls.key 2048 
$ openssl req -new -key rlaisqls.key -out rlaisqls.csr -subj "/O=helloworld/CN=rlaisqls"
```

위 명령어에서 눈여겨 봐야 할 부분은 CSR을 생성할 때 `-subj` 옵션으로 넘겨준 O (Organization) 와 CN (Common Name) 의 값이다. 이전에 k8s의 User와 Group은 인증 방법에 따라서 그 단위 또는 대상이 달라진다고 설명했었는데, 인증서를 통해서 인증을 수행할 경우 O가 Group이 되고 CN이 User가 된다. 따라서 위의 CSR로부터 생성된 인증서로 k8s에 인증할 경우, RoleBinding에서는 Group -> helloworld 또는 User -> rlaisqls 와 같은 방식으로 대상을 지정해야 한다.

어쨌든, k8s의 root CA가 위 CSR 파일에 sign 하기 위해 아래의 YAML 파일을 작성한다. CertificateSigningRequest는 CSR에 root CA로 간접적으로 sign할 수 있도록 해주는 k8s object이다. 

```yaml
cat << EOF >> csr.yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: rlaisqls-csr
spec:
  groups:
  - system:authenticated
  request: $(cat rlaisqls.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF
```

위의 YAML 파일에서는 usages 항목에서 client auth를 설정했기 때문에 클라이언트 전용 하위 인증서를 생성한다 (server auth로 설정하면 서버 전용 인증서를 생성할 수도 있다). 또한 groups 항목에서 `system:authenticated`로 설정했기 때문에 k8s의 인증된 사용자로 설정된다. request 항목에는 CSR 파일을 base64로 인코딩한 값이 들어간다.

위 YAML 파일을 통해 k8s에서 CSR 리소스를 생성한다.

```bash
$ kubectl apply -f csr.yaml
certificatesigningrequest.certificates.k8s.io/rlaisqls-csr created
 
$ kubectl get csr
NAME            AGE   REQUESTOR          CONDITION
rlaisqls-csr   5s    kubernetes-admin   Pending
```
CSR의 목록을 확인해 보면 CONDITION 상태가 Pending으로 설정되어 있는데, 이는 아직 k8s 관리자에 의해 승인되지 않았음을 뜻한다. 즉, [CSR을 제출하는 것]과 [이를 승인해 sign하는 것]은 별도의 작업으로 취급된다. k8s 관리자가 이를 승인하는 API를 명시적으로 호출해야만 정상적으로 하위 인증서가 생성된다.

> REQUESTOR는 어떠한 User가 해당 CSR을 제출했는지를 의미한다. 위 예시에서는 kubeadm을 설치하면 자동으로 사용하도록 설정된 kubeconfig의 인증서로 CSR을 제출했으며, 이 인증서의 CN은 kubernetes-admin으로 설정되어 있다.

아래의 명령어를 입력해 CSR을 승인한다.

```bash
$ kubectl certificate approve rlaisqls-csr
certificatesigningrequest.certificates.k8s.io/rlaisqls-csr approved

$ kubectl get csr
NAME            AGE     REQUESTOR          CONDITION
rlaisqls-csr   4m35s   kubernetes-admin   Approved,Issued
```

정상적으로 승인되었으니 하위 인증서를 파일에 저장한 뒤, 해당 인증서로 API 요청을 전송해 본다. kubeconfig에 User를 등록해도 되겠지만, 지금은 임시로 kubectl 옵션에 인증서 파일을 넣어 사용했다.

```bash
$ kubectl get csr rlaisqls-csr -o jsonpath='{.status.certificate}' | base64 -D > rlaisqls.crt
 
$ kubectl get po --client-certificate rlaisqls.crt --client-key rlaisqls.key
Error from server (Forbidden): pods is forbidden: User "rlaisqls" cannot list resource "pods" in API group "" in the namespace "default"
```

> error: You must be logged in to the server (Unauthorized) 에러가 출력되었다면 중간에 뭔가 빼먹었을 가능성이 높다. 이 에러는 k8s에서 해당 credential을 아예 인증하지 못했다는 것을 의미한다.

rlaisqls 이라는 이름의 User가 포드를 list 할 수 없다는 에러가 반환되었다. 위 에러가 발생했다면 정상적으로 인증서 발급이 완료된 것이기 때문에, Role이나 ClusterRole을 `User: rlaisqls` 에 대해서 부여하면 된다. 또는 인증서의 O (Organization) 이름이 helloworld이므로 `Group: helloworld` 처럼 대상을 지정해도 된다.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: service-reader-clusterrole
rules:
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: service-reader-clusterrolebinding
  namespace: default
subjects:
- kind: User # Group 을 사용해도 된다.
  name: rlaisqls # kind: Group 인 경우, helloworld 를 사용해도 된다.
roleRef:
  kind: Role
  name: service-reader-clusterrole
  apiGroup: rbac.authorization.k8s.io
```

위 내용을 rbac.yaml 파일로 저장해 적용한 뒤, 다시 API를 호출해 보면 정상적으로 실행되는 것을 확인할 수 있다.

```bash
$ kubectl apply -f rbac.yaml
role.rbac.authorization.k8s.io/service-reader-clusterrole created
rolebinding.rbac.authorization.k8s.io/service-reader-clusterrolebinding created
 
$ kubectl get svc --client-certificate rlaisqls.crt --client-key rlaisqls.key
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   2d3h
```
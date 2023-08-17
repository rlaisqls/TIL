# Token Webhook

Webhook 서버에 인증 데이터를 전달한 뒤, 클라이언트가 유효한지 인증하여 Third party에 권한을 부여하는 Webhook Token 인증 방법에 대해 알아보자.

1. 사용자는 미리 인증 데이터를 발급받아 놓고, 
2. 사용자가 인증 데이터를 Bearer 헤더에 담아서 REST API 요청을 보내면 
3. API 서버는 클라이언트가 유효한지를 검증하기 위해 Webhook 서버에 인증 데이터를 전달한다. 
4. Webhook 서버는 해당 데이터를 검사한 뒤, 인증 여부를 API 서버에 반환하는 간단한 방식으로 되어 있다

Token Webhook, OIDC 중 어느 방법을 선택하든지에 상관 없이 클라이언트는 HTTP의 Bearer 헤더에 인증 데이터를 담아서 보내기만 하면 된다. 클라이언트는 인증 방법이 무엇인지 알 필요가 없기 때문에 인증 과정은 API 서버에서 Transparent 하게 처리된다.

Webhook 서버 구현 중 하나로 [Guard](https://github.com/kubeguard/guard)라는 오픈소스가 있다. Guard는 [단순한 토큰 파일, Gitlab, Google, Azure, LDAP, EKS] 등을 인증 수단으로 사용할 수 있다. Github Organization을 이용해 클라이언트를 인증하는 방법에 대해 다룬다. 

> 인증 데이터를 생성하기 위해 Github에서 Organization (조직)을 미리 만들어 두어야 한다.

## Guard 설치

kubectl을 사용할 수 있는 환경에서 guard를 다운로드한다. 설치 방법은 kops, Kubespray, kubeadm에 따라 조금씩 다르니 [공식문서](https://appscode.com/products/guard/v0.7.1/welcome/)를 참고하자. 테스트 예시로는 Guard 0.7.1 버전과 kubeadm으로 EC2에 배포된 쿠버네티스 클러스터를 사용했다.

```bash
$ wget -O guard https://github.com/appscode/guard/releases/download/0.7.1/guard-linux-amd64 \
  && chmod +x guard \
  && sudo mv guard /usr/local/bin/
```

공식 문서에 나와있는대로 HTTPS 통신을 위한 인증서를 생성한다. `~/.guard` 디렉터리에 인증서 파일이 생성된다.

```bash
$ guard init ca
Wrote ca certificates in /root/.guard/pki
 
$ guard init server --ips=10.96.10.96
Wrote server certificates in /root/.guard/pki
```

단, `kube init server` 명령어의 `--ips` 옵션을 환경에 맞게 조금씩 수정해야 한다. `--ips` 옵션에는 Guard를 Deploy한 뒤 생성될 Service의 IP를 입력하면 된다. 쉽게 말해서, kube-apiserver에 설정되어 있는 Service의 IP CIDR 에서 적절한 IP를 하나 선택하면 된다. Service의 IP Range는 API 서버의 실행 옵션에서 확인할 수 있다.

```bash
$ ps aux | grep service-cluster-ip-range
root   3442  2.1  7.5 ... --service-cluster-ip-range=10.96.0.0/12
```

위 예시에서는 kubeadm에 의해 `--service-cluster-ip-range` 옵션의 값이 `10.96.0.0/12` 로 설정되었으며, 그 범위에 속하는 `10.96.10.96`을 `--ips` 옵션에 사용했다. 각자의 환경에 맞는 IP를 적당히 선택해 사용하면 된다.

그 다음으로 클라이언트 측의 인증서를 생성한다. 

```bash
$ guard init client {ORGANIZATION_NAME} -o github
Wrote client certificates in  $HOME/.guard/pki
```

`~/.guard/pki` 디렉터리에 키 페어가 정상적으로 생성되어 있는지 확인한다.

```bash
$ ls ~/.guard/pki/
ca.crt  ca.key  ml-kubernetes@github.crt  ml-kubernetes@github.key  server.crt  server.key
```

Guard 서버를 Deploy하기 위한 YAML 파일을 생성한 뒤, 이를 쿠버네티스에 적용한다.

```bash
$ guard get installer \
    --auth-providers=github \
    > installer.yaml
 
$ kubectl apply -f installer.yaml
```

## Kubernetes API 서버에 Token Webhook 옵션 추가하기

API 서버가 Guard 서버를 Token Webhook 인증 서버로서 사용하도록 설정해야 한다. 아래의 명령어를 사용해 Webhook을 위한 설정 파일을 생성한다. 빨간 색으로 강조된 부분은 여러분의 환경에 맞게 적절히 바꿔 사용한다.

```bash
$ guard get webhook-config ml-kubernetes -o github --addr=10.96.10.96:443 > webhook-config.yaml
```

위 명령어로부터 생성된 파일에는 API 서버가 Guard 서버를 Token Webhook 인증 서버로서 사용하기 위한 설정 정보가 저장되어 있다. 이 설정 파일을 API 서버의 `--authentication-token-webhook-config-file` 옵션을 통해 로드하면 쿠버네티스 쪽 설정은 끝이 난다. 그런데, 문제는 이 설정 파일을 API 서버가 로드하려면 설정 파일이 API 서버 컨테이너 내부에 위치해 있어야 한다는 것이다.

kops의 경우에는 위 설정 파일의 내용을 kops edit cluster에 통째로 복사하는 것이 가능한 것 같은데, kubeadm은 그런 방법이 딱히 존재하지 않는다. 따라서, 임시 방편이긴 하지만 kubeadm의 설정 파일에서 API 서버의 컨테이너에 설정 파일을 마운트한 다음, 이 파일을 로드하도록 구성했다. (설정 파일 전체 내용은 여기를 참고). hostPath 부분의 webhook-config.yaml 파일이 위치한 경로만 여러분 환경에 맞게 적절히 수정한다. 

```yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta1
apiServer:
  extraArgs:
    authorization-mode: Node,RBAC
    cloud-provider: aws
    authentication-token-webhook-config-file: /srv/kubernetes/webhook-guard-config
  extraVolumes:
  - name: "guard-config-file"
    hostPath: "/root/webhook-config.yaml"
    mountPath: "/srv/kubernetes/webhook-guard-config"
    readOnly: true
    pathType: File
  timeoutForControlPlane: 4m0s
certificatesDir: /etc/kubernetes/pki
...
```

물론 이 방법은 Single Master라서 가능한 것이며, HA Master로 구성된 클러스터라면 S3나 NFS 등을 통해 설정 파일을 동일하게 배포해야 한다. 또한 kubeadm이 아닌 다른 도구로 쿠버네티스를 설치했다면 해당 도구에 맞는 적절한 방법을 사용해야 한다.

아래의 명령어를 입력해 kubeadm의 kube-apiserver를 다시 배포한다.

```bash
$ kubeadm init phase control-plane apiserver --config master-config.yaml
 
[config] WARNING: Ignored YAML document with GroupVersionKind kubeadm.k8s.io/v1beta1, Kind=ClusterStatus
[control-plane] Creating static Pod manifest for "kube-apiserver"
[controlplane] Adding extra host path mount "guard-config-file" to "kube-apiserver"
```

## Github에서 토근 발급 받기 & API 서버에 인증하기

다음으로는 Github 계정 설정에서 새로운 토큰을 발급받아야 한다. https://github.com/settings/tokens/new 에 접속한 뒤, Note에는 적절한 토큰 이름을 (ex. guard-access-token) 입력하고 `admin:org`의 `read:org` 에 체크해서 PAT를 생성한다.

이 토큰을 이용해 kubeconfig에 새로운 User를 추가한다. 편의를 위해 kubernetes 클러스터 + 새로운 User (Github 계정) 조합으로 새로운 컨텍스트를 만들었다.

```bash
$ kubectl config get-contexts # kubernetes 라는 이름의 클러스터 사용 중
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin
 
$ export TOKEN=f392362f760fd8... # Github 토큰 임시 저장
 
$ kubectl config set-credentials rlaisqls-github --token $TOKEN # 토큰으로 User 등록
User "rlaisqls-github" set.
 
$ # 등록한 User로 새로운 컨텍스트 생성 (--cluster 옵션은 적절한 클러스터 이름 사용)
$ kubectl config set-context github-rlaisqls-context --cluster kubernetes --user rlaisqls-github 
Context "github-rlaisqls-context" created.
```

새로운 컨텍스트로 변경한 뒤 kubectl로 API 요청을 전송해 보면, 권한이 없다는 에러가 반환된다. 

```bash
$ kubectl config get-contexts
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
          github-rlaisqls-context      kubernetes   rlaisqls-github
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin
 
$ kubectl config use-context github-rlaisqls-context
Switched to context "github-rlaisqls-context".
 
$ kubectl get po
Error from server (Forbidden): pods is forbidden: User "rlaisqls" cannot list resource "pods" in API group "" in the namespace "default"
```

권한이 없다는 에러가 출력되는 것이 정상이다. RBAC 권한 부여 (Authorization)에서 오류가 나는 것이기 때문에 제대로 Guard가 동작하고 있음을 뜻한다. [ `error: You must be logged in to the server (Unauthorized)` ] 에러가 출력되지만 않으면 된다.

이제 Github 사용자에게 RBAC로 권한을 부여하기만 하면 되는데, 여기서 한 가지 알아둘 점은 Github 계정의 이름이 User로, Org Team의 이름이 Group으로 치환된다는 점이다. 따라서 RoleBinding에서 Subject를 `User: rlaisqls` 또는 `Group: test-team` 처럼 적어주면 된다 (물론 test-team 이라는 이름의 팀이 존재해야 한다). 만약 RoleBinding에서 Group에 권한을 부여하면 Org의 Team에 속해 있는 모든 사용자에 대해 권한이 동일하게 부여된다.

Github 계정에게 권한을 부여하기 위해, 아래의 내용으로 `github-svc-reader.yaml` 파일을 작성한다.

```bash
$ cat github-svc-reader.yaml
 
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: service-reader-role
rules:
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: service-reader-rolebinding
  namespace: default
subjects:
- kind: User # Group 을 사용해도 됨
  name: rlaisqls # kind: Group인 경우에는 ml-kubernetes-team (team 이름) 사용 가능
roleRef:
  kind: Role
  name: service-reader-role
  apiGroup: rbac.authorization.k8s.io
```

위의 YAML 파일을 적용해 Github 계정에 권한을 부여하고, 다시 API를 호출해 보았다.

```bash
$ # 현재는 Github context이기 때문에, 잠시만 --context로 관리자 권한을 가져온다 (impersonate)
$ kubectl apply -f github-svc-reader.yaml --context kubernetes-admin@kubernetes
role.rbac.authorization.k8s.io/service-reader-role created
rolebinding.rbac.authorization.k8s.io/service-reader-rolebinding created
 
$ kubectl get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   3d7h
```

정상적으로 명령어가 실행되었음을 확인할 수 있다. Github 계정에 권한이 제대로 부여되었다.

## Guard의 동작 원리

클라이언트로부터 API 요청이 발생하면, Token Webhook 서버는 API 서버로부터 [TokenReview] 라는 JSON 데이터를 전달받는다. [TokenReview] 데이터의 예시는 아래와 같다.

```json
{
  "apiVersion": "authentication.k8s.io/v1beta1",
  "kind": "TokenReview",
  "spec": {
    "token": "(BEARERTOKEN)"
  }
}
```

위 데이터 중, `.spec.token` 항목에는 Github에서 생성한 토큰이 들어가 있다. Guard는 이 토큰을 이용해 '클라이언트가 Github 사용자가 맞는지, 클라이언트가 Github의 Org에 소속되어 있는지'를 Github 으로부터 읽어 온다. 인증이 정상적으로 이루어지면 Guard는 아래와 같은 형식의 데이터를 API 서버에게 다시 반환한다.

```json
{
  "apiVersion": "authentication.k8s.io/v1",
  "kind": "TokenReview",
  "status": {
    "authenticated": true,
    "user": {
      "username": "<github-login>",
      "uid": "<github-id>",
      "groups": [
        "<team-1>",
        "<team-2>"
      ]
    }
  }
}
```

username이 User에, groups가 Group에 매칭되어 RoleBinding 등에서 사용된다.

## API 서버의 Token Webhook 옵션 (캐시 TTL)

Github의 Org에 새로운 멤버를 삭제해도 API 서버에서는 즉시 반영되지 않으며, 일정 시간이 지나야만 Github 사용자의 인증이 정상적으로 거부된다. 이는 기본적으로 한 번 인증된 사용자의 인증 확인 여부 데이터를 API 서버 내부에 캐시로 보관하기 때문인데, 캐시의 TTL이 만료되면 다시 Guard에 인증을 요청한다. 기본적으로 이 값은 2분으로 설정되어 있기 때문에, 2분이 지난 뒤에 다시 API 요청을 보내면 Guard에 다시 인증 Webhook 을 전송한다. 따라서 2분마다 API 요청의 응답 시간이 조금 느려질 수 있다. (새로운 사용자 인증에 대해서는 무조건 Guard로 요청을 전송한다)

인증에 대한 캐시 TTL은 API 서버의 실행 옵션에서 `--authentication-token-webhook-cache-ttl` 를 통해 설정할 수 있다. 기본적으로는 2m 으로 설정되어 있다.

---
참고
- https://github.com/kubeguard/guard
- https://appscode.com/products/guard/v0.7.1/welcome/

k8s에서 kubectl과 같은 커맨드를 사용해 API를 요청하는 과정은 크게 3가지로 구성되어 있다. 

1. 'k8s 사용자가 맞느냐'를 판단하는 Authentication
2. 두 번째는 'API를 호출할 수 있는 권한이 있느냐'를 판단하는 Authorization
3. 마지막으로 그 요청이 적절한지를 판단하는 Admission Controller이다. 

Authorization와 Admission Controller는 k8s에 내장되어 있는 기능이기 때문에 사용 방법이 비교적 정해져 있는 반면, 첫 번째 단계인 Authentication은 이렇다 할 정답이 딱히 정해져 있지 않다. 물론 k8s의 자체 인증 기능인 ServiceAccount, 인증서 등을 사용할 수는 있지만, 사내에서 LADP, Google, Github 와 같은 별도의 인증 시스템을 이미 구축해 놓았다면 [기존 인증 시스템 / k8s 인증 시스템] 을 분리해 운영해야 하는 상황도 발생할 수 있다. 그렇게 되면 인증을 위한 관리 포인트 또한 두 곳이 되어 버리기 때문에, 클러스터 매니저의 입장에서 이러한 구조는 그다지 달갑지는 않을 것이다.

k8s는 이러한 불편함을 해결하기 위해 OAuth (Open ID Connect) 로 Third-party에 인증을 위임하는 기능을 제공한다. 즉, 사내에서 별도의 인증 시스템 (LDAP, Google, Github) 을 이미 운영하고 있다면 해당 인증 시스템을 그대로 k8s로 가져올 수 있다. 따라서 Github 계정을 통해 k8s의 API (ex. kubectl) 를 사용할 수 있을 뿐만 아니라, Role 이나 ClusterRole 을 Github 계정에게 부여하는 것 또한 가능해진다. 

그렇지만 k8s가 서드 파티에 연결하는 모든 인터페이스를 제공하는 것은 아니며, 특정 Third-party (ex. Github) 에 연결하기 위한 모듈 또는 서버를 별도로 구축해야 한다. 이번 포스트에서는 User와 Group을 사용하는 방법을 먼저 설명한 뒤, Third-party에 인증을 위임하기 위한 도구로서 Guard, Dex 의 사용 방법을 다룬다.

## User와 Group의 개념

k8s에서 가장 쉽게 사용할 수 있는 인증 기능은 바로 ServiceAccount이다. 그렇지만 ServiceAccount 라는 이름에서도 알 수 있듯이, ServiceAccount는 사람이 아닌 서비스 (Service), 즉 포드가 API를 호출하기 위한 권한을 부여하기 위해서 사용하는 것이 일반적이다. 물론 ServiceAccount를 사람에게 할당하는 것이 이론상으로 불가능한 것은 아니지만, Service Account의 설계 디자인을 조금만 생각해 보면 애초에 k8s 애플리케이션에 권한을 부여하기 위한 용도라는 것을 알 수 있다.

그렇다면 실제 '사람' 이라는 Entity에 대응하는 추상화된 k8s object는 무엇일지 궁금할텐데, 결론부터 말하자면 k8s에서는 사람에 대응하는 object가 없다. k8s에는 오픈스택의 keystone과 같은 컴포넌트가 따로 존재하는 것도 아니기 때문에, 실제 '사람' 을 k8s에서 리소스로 관리하지 않는다. 그 대신, k8s에서는 User와 Group 이라는 이름으로 사용자를 사용할 수 있다.

때문에 k8s 문서에서도 대부분 ServiceAccount 대신 User나 Group으로 설명하고 있다. 아래는 RBAC를 설명하는 k8s 공식 문서인데, RoleBinding의 대상(subject)이 kind: User로 되어 있는 것을 볼 수 있다.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
# This role binding allows "jane" to read pods in the "default" namespace.
# You need to already have a Role named "pod-reader" in that namespace.
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
# You can specify more than one "subject"
- kind: User
  name: jane # "name" is case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  # "roleRef" specifies the binding to a Role / ClusterRole
  kind: Role #this must be Role or ClusterRole
  name: pod-reader # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```

그렇다면 저 'User'는 무엇에 대응하는 개념일까? 공식문서를 살펴보자.

<img width="696" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/9106758e-1c97-4f52-a8b4-520dc8590956">


위 내용을 요약하자면 'User는 k8s object가 아니기 때문에 따로 관리되지는 않으며, 외부 인증 방법에 따라서 달라진다'는 뜻이다. 예를 들어 Github을 k8s 인증 시스템으로 사용한다면 Github 사용자 이름이 User가 되고, Organization 이름이 Group이 된다고 이해하면 쉽다. 따라서 test 라는 Github Organization에 rlaisqls 사용자가 소속되어 있다면 아래와 같이 ClusterRoleBinding을 생성할 수도 있다.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: service-reader-clusterrolebinding
  namespace: default
subjects:
- kind: Group
  name: test
- kind: User
  name: rlaisqls
rolRef:
  kind: ClusterRole
  name: service-reader-clusterrole
  apiGroup: rbac.authorization.k8s.io
```

물론, Github가 아닌 다른 서드 파티를 통해 인증을 진행한다면 User와 Group의 단위가 달라질 수도 있으며, 원한다면 API 서버의 옵션에서 User와 Group의 단위를 직접 설정할 수도 있다.

> Tip : k8s에서는 미리 정의된 몇 가지 종류의 User와 Group이 존재한다. 가장 대표적인 예시는 `system:` 접두어가 붙는 User나 Group 인데, 이는 다양한 용도로 사용될 수 있다. 예를 들어 rlaisqls 이라는 이름의 ServiceAccount는 `system:serviceaccount:<namespace이름>:rlaisqls` 이라는 User와 동일하게 사용할 수 있다. 즉, RoleBinding의 Subject에서 아래와 같이 사용해도 ServiceAccount에 권한이 부여된다.
> ```yaml
> apiVersion: rbac.authorization.k8s.io/v1
> kind: ClusterRoleBinding
> metadata:
>   name: service-reader-clusterrolebinding
>   namespace: default
> subjects:
> - kind: User
>   name: system:serviceaccount:default:rlaisqls
> ```
> <br>그 외에도 `system:serviceaccount`는 모든 ServiceAccount를, `system:serviceaccount:default`는 default 네임스페이스의 모든 ServiceAccount를 의미하는 Group으로 사용될 수도 있다. 사용 가능한 pre-defined User와 Group에 대해서는 k8s 공식 문서를 참고하자.

##  사용자 인증 방법 예시
- [k8s 클러스터 root CA를 통한 사용자 인증](k8s 클러스터 root CA를 통한 사용자 인증.md)
- [Token Webhook with Guard](Token Webhook with Guard.md)
- [OIDC Authentication with Dex](OIDC Authentication with Dex.md)

---
참고
- https://kubernetes.io/docs/reference/access-authn-authz/authentication/
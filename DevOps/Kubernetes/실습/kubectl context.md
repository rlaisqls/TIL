
쿠버네티스 클러스터를 관리하는 cli 도구인 kubectl에는 환경을 바꿔가며 클러스터를 관리할 수 있도록 "context"라는 개념이 존재한다. context 는 kubectl 을 깔면 생성되는 파일인 `~/.kube/config` 파일에서 설정할 수 있다.

```yml
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://localhost:6443
  name: local-cluster
- cluster:
    certificate-authority-data: ~~~~
    server: https://xxx.xxx.xxx.xxx
  name: gcp-cluster

users:
- name: local-user
  user:
    blah blah
- name: gcp-user
  user:
    blah blah

contexts:
- context:
    cluster: gcp-cluster
    user: gcp-user
  name: gcp-context
- context:
    cluster: local-cluster
    user: local-user
  name: local-context

current-context: local-context

kind: Config
preferences: {}
```

- **clusters**
  - 쿠버네티스 클러스터의 정보이다. 내 PC에 설치된 쿠버네티스 클러스터와, GCP에 설치된 쿠버네티스 클러스터가 있음을 볼 수 있다.

- **users**
  - 클러스터에 접근할 유저의 정보이다

- **context**
  - cluster와 user를 조합해서 생성된 값이다. local-context는 local-user 정보로 local-cluster에 접근하는 하나의 set이 되는 것이다

- **current-context**
    - 현재 사용하는 context 를 지정하는 부분이다
    - 현재는 local-context 를 사용하라고 설정되어 있으므로, 터미널에서 kubectl 명령을 입력하면 로컬 쿠버네티스 클러스터를 관리하게 된다

### context 조회 및 변경

```bash
# gcp-context 로 변경
$ kubectl config use-context gcp-context

# context 조회
$ kubectl config get-contexts

CURRENT   NAME            CLUSTER         AUTHINFO     NAMESPACE
*         gcp-context     gcp-cluster     gcp-user
          local-context   local-cluster   local-user
```

출처: https://dev.to/airoasis/argo-cd-seolci-mic-seoljeong-45bd

## ArhoCD, ArgCD CLI 설치

Argo CD를 kubernetes cluster에 설치한다.

```yml
$ kubectl create namespace argocd
$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/ha/install.yaml
```

Argo CD의 CLI를 설치한다.

```yml
$ curl -sSL -o ~/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
$ chmod +x ~/bin/argocd
```

## Argo CD 서비스 노출

Argo CD는 default로 서버를 외부로 노출시키지 않는다. 아래와 같이 서비스타입을 LoadBalancer로 변경하여 외부로 노출시킨다.

```js
$ kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

## admin password 변경

Argo CD는 최초 admin account의 초기 password를 kubernetes의 secret으로 저장해 놓는다. 아래와 같이 최초 password를 확인할 수 있다.

```js
$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

Argo CD CLI를 이용하여 Argo CD에 로그인한다. 우선 생성된 Load Balancer의 주소를 얻는다.

```js
kubectl get svc argocd-server -n argocd
``

그리고 Login 한다. username은 admin 이다

```js
argocd login <ARGOCD_SERVER_DOMAIN>
```

admin 유저의 password를 업데이트 한다.

```js
$ argocd account update-password
```

## webhook

Argo CD는 Git repository를 3분에 한번씩 pollin 하면서 실제 kubernetes cluster 와 다른점을 확인한다. 따라서 배포시에 운이 없다면 최대 3분을 기다려야 Argo CD가 변경된 image를 배포하게 된다. 이렇게 Polling 으로 인한 delay를 없애고 싶다면 Git repository 에 Argo CD로 webhook을 만들어 놓으면 된다.

https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/

webhook 을 만들어 놓았다면 반드시 Argo CD의 load balancer에 Github의 webhook 관련 API를 inbound로 열어줘야 한다.

GitHub 의 IP 주소 관련 내용과 실제 inbound 에 넣줘야 하는 IP를 확인할 수 있는 링크이다.

https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-githubs-ip-addresses

https://api.github.com/meta

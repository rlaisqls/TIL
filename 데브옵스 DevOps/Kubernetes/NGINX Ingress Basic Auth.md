# NGINX Ingress Basic Auth

NGINX Ingress에서 설정을 해주면 어플리케이션 레벨에서, 혹은 Ingress 레벨에서 서비스 인증과정을 거치도록 할 수 있다. ingress를 통해 인증을 설정하는 방법을 두가지 알아보자.

![image](https://user-images.githubusercontent.com/81006587/215693937-ad54131b-6e70-448e-b137-b58d222f7579.png)

# Static User

> https://kubernetes.github.io/ingress-nginx/examples/auth/basic/

Static User는 미리 basic auth로 인증할 유저 리스트를 생성하고 해당 리스트에 포함된 인원만 인증될 수 있게 하는 방법이다. 별다른 추가 작업 없이 사용자 인증을 할 수 있는 장점이 있는 반해 동적으로 사용자를 추가/삭제하지 못한다는 단점이 있다.

#### 1. auth 파일 생성

먼저 `htpasswd`를 통해 basic auth 사용자 파일을 생성한다.

```yml
# htpasswd 설치
sudo apt-get install apache2-utils

# auth 파일에 bar라는 비밀번호를 가진 foo라는 사용자를 생성
$ htpasswd -cb auth foo bar
```

#### 2. auth 파일을 이용한 Secret 생성

생성한 htpasswd를 k8s에 적용할 수 있는 secret으로 만든다.

```yml
# basic-auth라는 secret 생성
$ kubectl create secret generic basic-auth --from-file=auth

$ kubectl get secret basic-auth -o yaml
# apiVersion: v1
# data:
#   auth: Zm9vOiRhcHIxJE9GRzNYeWJwJGNrTDBGSERBa29YWUlsSDkuY3lzVDAK
# kind: Secret
# metadata:
#   name: basic-auth
#   namespace: default
# type: Opaque
```

#### 3. Ingress 생성

서비스의 Ingress 설정시 annotations 프로퍼티에 다음과 같은 설정을 해준다.

```bash
$ kubectl create -f ingress.yml
ingress "external-auth" created

$ kubectl get ing external-auth
NAME            HOSTS                         ADDRESS       PORTS     AGE
external-auth   external-auth-01.sample.com   172.17.4.99   80        13s
```

```yml
# auth-ingress.yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-with-auth
  annotations:
    # 인증 방법 설정: basic auth
    nginx.ingress.kubernetes.io/auth-type: basic
    # basic auth 사용자가 들어있는 secret 설정
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # 인증 요청시 반환할 메세지 설정
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required - foo'
spec:
  rules:
  - host: foo.bar.com
    http:
      paths:
      - path: /
        backend:
          serviceName: http-svc
          servicePort: 80
```

# External Basic Auth

> https://kubernetes.github.io/ingress-nginx/examples/auth/external-auth/

External Basic Auth는 외부 Basic Auth 서비스를 이용하여 인증을 하는 방식이다. 사용자가 직접 개발한 custom authentication 서버에 연동할 수도 있고, 외부 LDAP 서버를 통하여 인증 체계를 구성하는 등 유연하게 사용할 수 있다.

```yml
# ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-url: https://httpbin.org/basic-auth/user/passwd
  creationTimestamp: 2023-01-31T13:50:35Z
  generation: 1
  name: external-auth
  namespace: default
  resourceVersion: "2068378"
  selfLink: /apis/networking/v1/namespaces/default/ingresses/external-auth
  uid: 5c388f1d-8970-11e6-9004-080027d2dc94
spec:
  rules:
  - host: external-auth-01.sample.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service: 
            name: http-svc
            port: 
              number: 80
status:
  loadBalancer:
    ingress:
    - ip: 172.17.4.99
```
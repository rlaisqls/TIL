# Ingress

인그레스(ingress)는 클러스터 내의 서비스에 대한 외부 접근을 관리하는 API 오브젝트이며, 일반적으로 HTTP를 관리한다.

인그레스는 부하 분산, SSL 종료, 명칭 기반의 가상 호스팅을 제공할 수 있다.

인그레스는 클러스터 외부에서 클러스터 내부 서비스로 HTTP와 HTTPS 경로를 노출한다. 트래픽 라우팅은 인그레스 리소스에 정의된 규칙에 의해 컨트롤된다.

<img src="https://user-images.githubusercontent.com/81006587/215076818-103ab531-9dfb-4c88-ad65-b53dca71f236.png" height=300px>

[인그레스](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#ingress-v1-networking-k8s-io)는 외부에서 서비스로 접속이 가능한 URL, 로드 밸런스 트래픽, SSL / TLS 종료 그리고 이름-기반의 가상 호스팅을 제공하도록 구성할 수 있다. 인그레스 컨트롤러는 일반적으로 로드 밸런서를 사용해서 인그레스를 수행할 책임이 있으며, 트래픽을 처리하는데 도움이 되도록 에지 라우터 또는 추가 프런트 엔드를 구성할 수도 있다.

인그레스는 임의의 포트 또는 프로토콜을 노출시키지 않는다. HTTP와 HTTPS 이외의 서비스를 인터넷에 노출하려면 [Service.Type=NodePort](https://kubernetes.io/ko/docs/concepts/services-networking/service/#type-nodeport) 또는 [Service.Type=LoadBalancer](https://kubernetes.io/ko/docs/concepts/services-networking/service/#loadbalancer) 유형의 서비스를 사용해야한다.

## Ingress 리소스 구성하기

최소한의 사양으로 인그레스 컨트롤러를 구성하고싶다면, 아래와 같이 설정할 수 있다.

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx-example
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
```

인그레스에는 `apiVersion`, `kind`, `metadata`, `spec` 필드가 명시되어야 하고, 인그레스 오브젝트의 이름은 유효한 DNS 서브도메인 이름이어야 한다. 인그레스는 [어노테이션](https://github.com/kubernetes/ingress-nginx/blob/main/docs/examples/rewrite/README.md)을 이용해서 인그레스 컨트롤러에 따른 옵션을 구성하기도 한다.

## Fan-out

Fan-out이란, HTTP URI에서 요청된 것을 기반으로 단일 IP 주소에서 여러 서버로 트래픽을 라우팅하는것을 말한다. 인그레스를 사용하면 로드 밸런서의 수를 줄이면서, Fan-out을 구성할 수 있다.

<img src="https://user-images.githubusercontent.com/81006587/215078518-e89405d1-bb53-4738-a992-9bcc7bda2a06.png" height=350px>

Fan-out을 설정하고 싶다면 아래와 같이 하면 된다!

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-fanout-example
spec:
  rules:
  - host: foo.bar.com
    http:
      paths:
      - path: /foo
        pathType: Prefix
        backend:
          service:
            name: service1
            port:
              number: 4200
      - path: /bar
        pathType: Prefix
        backend:
          service:
            name: service2
            port:
              number: 8080
```

---

참고

https://kubernetes.io/ko/docs/concepts/services-networking/ingress/
# ⚓ DNS

두개의 포드와 서비스가 있다고 해보자. 각 포드의 이름은 test와 web이고, 가상 IP를 하나씩 할당받았다.

```

   /-----\           /---------      /-----\                   
   | pod |          《  service       | pod |
   \-----/           \---------      \-----/
  10.244.1.5        10.107.37.188   10.244.1.5
    test             web-service       web

```

서비스가 생성되면, k8s DNS sevice(CoreDNS)는 **해당 서비스를 위한 레코드**를 저장한다. 즉, ip를 직접 명시하지 않고 사용할 수 있는 대체 이름을 지정해준다는 것이다. 우선 클러스터 내부에서 포드는 해당 서비스의 이름으로 접근하여 그 서비스의 위치로 요청을 보낼 수 있다.

```
curl http://web-service
 > Welcome to NGINX!
```

하지만 만약에 두 포드가 다른 네임스페이스에 있다고 해보자. 그런 경우에도 해당 네임스페이스명을 같이 적어주기만 하면 요청을 보낼 수 있다.

```
curl http://web-service.{namespace name}
 > Welcome to NGINX!
```

그리고 모든 서비스는 svc라는 서브 도메인 안에 묶여있다. 그렇기 때문에 아래와 같이 접근하는 것 또한 가능하다.

```
curl http://web-service.{namespace name}.svc
 > Welcome to NGINX!
```

그리고 모든 서비스와 포드는 cluster.local이라는 root 도메인 안에 묶여있다. 이 url이 바로, 10.107.37.188 IP를 가진 web-service 서비스에 대해서 k8s 내부에서 쓸 수 있는 완전한 도메인명이다.

```
curl http://web-service.{namespace name}.svc.cluster.local
 > Welcome to NGINX!
```

## CoreDNS

위에서 서비스를 레코드에 등록하고, 쿼리할 수 있는 기능은 k8s에 내장되어있는 CoreDNS라는 프로그램이다. 기존에는 KubeDNS라는 별도의 프로그램이 사용되었었는데, 메모리나 CPU 점유율 문제로 1.12 버전부터 기본 설정이 변경됐다.


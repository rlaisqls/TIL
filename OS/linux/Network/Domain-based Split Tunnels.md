
VPN을 구성할 때, 특정 도메인에 대해서만 VPN을 활성화하고 싶은 경우가 있을 수 있다. 해당 기능에 대해 TailScale과 Netbird는 아래와 같은 방식으로 제공한다.

### [TailScale](https://tailscale.com/)에서 제공하는 방식 [(문서)](https://tailscale.com/kb/1342/how-app-connectors-work)

1. DNS 쿼리를 로컬 TailScale 서버로 날리도록 한다.
2. 로컬 데몬에서는 8.8.8.8과 같은 도메인 서버에 다시 요청을 날려서, 도메인 쿼리 결과를 기록해놓은 후 결과를 그대로 돌려준다.
3. 기록한 IP에 대해 커넥터로 지정된 호스트에 라우팅하도록 한다.
4. private 네트워크에 성공적으로 통신할 수 있다.

### [Netbird](https://github.com/netbirdio/netbird)에서 제공하는 방식

1. VPN 클라이언트에서 도메인 쿼리 결과를 주기적(기본 60s)으로 불러와 기록해놓는다.
2. 저장된 IP 목록에 해당하는 요청이 발생하면 Netbird의 TURN 서버로 통신하도록 한다.
3. private 네트워크에 성공적으로 통신할 수 있다.

### 직접 시도해본 방식

Netbird의 도메인 라우팅이 안드로이드, iOS 클라이언트에서 비정상적으로 동작하는 문제가 있어 아래와 같은 방법을 시도해보았다.

1. 모든 도메인 쿼리 결과에 대해 자신의 public IP를 반환하는 DNS 서버를 구성한다. ([linux bind](https://blog.rlaisqls.site/til/os/linux/network/bind%EB%A1%9Cdns%EC%84%9C%EB%B2%84%EC%A0%95%EC%9D%98%ED%95%98%EA%B8%B0/)와 같은 툴 사용)
2. Netbird로 클라이언트의 DNS 쿼리 요청이 커스텀 DNS 서버를 향하도록 설정한다.
3. 커스텀 DNS 서버가 항상 public IP를 반환하므로, 트래픽이 DNS 서버 호스트로 들어올 것이다.  
    호스트의 443 포트를 열고 요청이 들어온 도메인의 실제 IP로 포워딩하여 결과를 돌려준다. Nginx와 같은 Reverse Proxy를 사용할 수 있다.
4. private 네트워크에 성공적으로 통신할 수 있다.

Nginx로 설정했을 때 사용한 구성 파일은 다음과 같다.

```conf
events {
    worker_connections 2048;
}

stream {
    resolver 8.8.8.8 valid=300s;
    resolver_timeout 10s;

    map $ssl_preread_server_name $dst {
        hostnames;
        ~^(.+)$        $1:443;
    }

    server {
        listen 443;
        listen [::]:443;
        proxy_pass $dst;
        ssl_preread on;
    }
}
```

여기서 Reverse Proxy로 Nginx를 사용했을 때 문제가 발생했다. 왜냐하면...

- 대상 서버의 변경 없이 요청을 프록시하기 위해 요청의 ssl을 terminate 시키지 않도록 설정했다.
- ssl을 terminate 시키지 않으면서, 즉 HTTPS 요청의 암호화가 해독되지 않은 상태에서 요청 도메인을 읽기 위해선 Nginx의 [ssl preread](http://nginx.org/en/docs/stream/ngx_stream_ssl_preread_module.html) 기능으로 SNI 정보를 읽어 사용해야한다.
- 다중 커넥션을 사용하는 HTTP/1.x와 달리 HTTP/2.0에서는 하나의 커넥션에 여러 요청을 보낸다. 모든 도메인이 같은 IP로 향하므로, 클라이언트에선 `a.example.com`과 `b.example.com`을 같은 커넥션으로 전송한다.
- 하지만 Nginx stream에서는 HTTP/2.0을 지원하지 않는다! 그래서 하나의 커넥션에 여러 요청이 들어왔을 때 요청들을 구분하지 못한다. 따라서 `a.example.com`와 `b.example.com`가 같은 커넥션으로 들어오면, ssl 커넥션시 사용했던 도메인으로 모든 요청을 보내버린다. 따라서 트래픽이 의도한 도메인으로 전달되지 않는 경우가 생긴다!!

[이 곳](https://gist.github.com/kekru/c09dbab5e78bf76402966b13fa72b9d2)에서 이와 관련된 Nginx 사용자들의 논의를 볼 수 있다.

오픈소스 프로젝트인 [`dlundquist/sniproxy`](https://github.com/dlundquist/sniproxy/issues/178)도 비슷한 이슈 때문에 http2.0을 지원하지 못한다고 한다.

특정 도메인에 대한 요청을 프록싱하기 위해선 목적지 IP를 바꾸지 않는 방식으로 구현해야한다는 것을 몸소 느낄 수 있었다.

---
참고

- <https://gist.github.com/kekru/c09dbab5e78bf76402966b13fa72b9d2>
- <https://tecoble.techcourse.co.kr/post/2021-09-20-http2/>
- <https://github.com/dlundquist/sniproxy/issues/178>
- <https://tailscale.com/kb/1381/what-is-quad100>

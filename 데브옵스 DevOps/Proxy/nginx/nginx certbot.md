
nginx에서 https를 적용하기 위해 certbot과 Let's encrypt를 사용해보자.

일단 nginx를 아래와 같이 설정해준다.

```bash
server {
    listen 80;
    server_name your.domain.com;

    location / {
        proxy_pass http://192.168.XXX.XXX;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
    }
}
```

1. certbot 설치

```bash
wget https://dl.eff.org/certbot-auto
```

snapd를 이용하여 설치할 수도 있다.
```bash
# certbot 설치
$ sudo snap install --classic certbot

# certbot 명령을 로컬에서 실행할 수 있도록 snap의 certbot 파일을 로컬의 cerbot과 링크(연결) 시켜준다. -s 옵션은 심볼릭링크를 하겠다는 것.
$ ln -s /snap/bin/certbot /usr/bin/certbot
```

2. cerbot으로 nginx 설정
   
아래 명령을 수행하고, 알맞은 설정값을 입력해준다. domain을 입력하라는 질문에서는 본인이 사용할 Domain을 입력해주면 된다.

```bash
$ sudo certbot --nginx
```

위 명령을 잘 수행하고 아래처럼 뜨면 잘 된 것이다.

```bash
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Your existing certificate has been successfully renewed, and the new certificate
has been installed.

The new certificate covers the following domains: https://domain.com # https가 설정된 도메인을 알려준 것.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Subscribe to the EFF mailing list (email: woorimprog@gmail.com).

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/domain.com/fullchain.pem # 공개키 경로이므로 기억해두자.
   Your key file has been saved at:
   /etc/letsencrypt/live/domain.com/privkey.pem # 비밀키 경로이므로 기억해두자.
   Your certificate will expire on 2021-08-15. To obtain a new or
   tweaked version of this certificate in the future, simply run
   certbot again with the "certonly" option. To non-interactively
   renew *all* of your certificates, run "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

이 과정을 거치면 Certbot은 Let's Encrypt를 통해 자동으로 SSL 인증서를 발급해온다. 

위 출력을 잘보면 https가 적용된 도메인과 공개키와 비밀키의 경로를 알려준다. 정리하자면 아래와 같다.

```bash
1. https가 설정된 도메인
https://domain.com

1. 공개키 경로
/etc/letsencrypt/live/domain.com/fullchain.pem

1. 비밀키 경로
 /etc/letsencrypt/live/domain.com/privkey.pem
```

또한 우리가 작성한 Nginx의 default.conf를 확인해보면 HTTPS를 위한 설정이 자동으로 추가된 것을 볼 수 있다.

```bash
# 443 포트로 접근시 ssl을 적용한 뒤 3000포트로 요청을 전달해주도록 하는 설정.
server {
    server_name your.domain.com;

    location / {
        proxy_pass http://192.168.XXX.XXX:8080;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/your.domain.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/your.domain.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}


# 80 포트로 접근시 443 포트로 리다이렉트 시켜주는 설정
server {
    if ($host = your.domain.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    listen 80;
    server_name your.domain.com;
    return 404; # managed by Certbot
}
```

certbot을 이용하여 ssl인증서를 발급할 경우 3개월 마다 갱신을 해줘야 한다. 아래 명령어로 갱신해줄 수 있다.

```
$ certbot renew
```

인증서의 유효기간이 끝나가면 본인이 certbot을 통해 ssl인증서를 받아올 때 입력했던 이메일로 알림이 오게된다. 해당 메일을 받으면 위 명령을 통해 갱신해주면 된다.

crontab을 써서 3개월 마다 자동 갱신되도록 해줄 수도 있다.

---

도메인 목록 보기

```js
sudo certbot certificates
```

도메인 추가
```
certbot --cert-name (도메인 대표명) -d ~~~~ -d ~~~~
```
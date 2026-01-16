
Nginx를 설치한다. 원하면 이미지로 띄울 수도 있다.

```bash
$ sudo apt update
$ sudo apt install nginx
```

#### 설정 파일 생성

```
$ cd /etc/nginx/conf.d
$ vim default.conf
```

default.conf 파일을 생성하고 아래와 같이 원하는 설정 내용을 적어준다.

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

`server_name`엔 SSL을 적용할 자신의 도메인을 입력해주고, `proxy_pass`에는 프록시 서버가 클라이언트 요청을 전달할 서버의 주소를 적는다.


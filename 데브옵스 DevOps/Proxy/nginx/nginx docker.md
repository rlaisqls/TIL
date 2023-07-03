1. nginx 컨테이너 실행

```jsx
sudo docker run --name nginx -d -p 80:80 nginx
```

1. nginx bash 들어가서 conf 파일 열기

```jsx
docker exec -it nginx bash
vi /etc/nginx/conf.d/default.conf
```

1. 원하는 도메인, 포트 설정해넣기

예시

```jsx
server {
    listen       80;
    listen   [::]:80;

    server_name  domain.aliens-dms.com;

    location / {
        proxy_pass   http://ip:8080;
    }
}
```

1. nginx reload로 적용

```jsx
nginx -s reload
```
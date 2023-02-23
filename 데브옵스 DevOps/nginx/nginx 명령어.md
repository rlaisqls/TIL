# 🍏 nginx 명령어

#### Nginx 시작
```bash
sudo systemctl start nginx
```

#### Nginx 시작 (systemd 없이 Linux 배포를 실행하는 경우)
```bash
sudo service nginx start
```

#### Nginx 중지
```bash
sudo systemctl stop nginx
sudo service nginx stop 
```

#### Nginx 다시 시작
```bash
sudo systemctl restart nginx
sudo service nginx restart 
```

#### Nginx reroad (새 설정을 적용해야할 떄)
```bash
sudo systemctl reload nginx
sudo service nginx reload 
```

#### Nginx 구성 테스트

설정 파일 혹은 실행에 문제가 있는지 테스트하기 위해 사용한다

```bash
sudo nginx -t

# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful
```

#### Nginx 상태 보기
상세한 상태정보를 반환한다.

```bash
sudo systemctl status nginx

#  nginx.service - A high performance web server and a reverse proxy server
#    Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
#    Active: active (running) since Sun 2019-04-21 13:57:01 PDT; 5min ago
#      Docs: man:nginx(8)
#   Process: 4491 ExecStop=/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid (code=exited, status=0/SUCCESS)
#   Process: 4502 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
#   Process: 4492 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
#  Main PID: 4504 (nginx)
#     Tasks: 3 (limit: 2319)
#    CGroup: /system.slice/nginx.service
#            |-4504 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
#            |-4516 nginx: worker process
#            `-4517 nginx: worker process
```
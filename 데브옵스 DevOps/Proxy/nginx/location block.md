# location block

location 블록은 Nginx에서 정의되어 있는 웹사이트의 특정 URL 을 조작하는데 사용되는 블록이다. Server 블록마다 Location 을 지정해줄 수 있으며, Location 을 여러 번 정의할 수 있다.

location은 URI 경로의 일부인 prefix string이거나 정규식 표현이 될 수 있다.

### 예시

```bash
// nginx.conf
server {
    location /images/ {
        root /data;
    }

    location / {
        proxy_pass http://www.example.com;
    }
}
```

위와 같이 server 내부에 표시해준다. 위의 코드는

- 첫 번째 location context와 일치하는 패턴은 /data 디렉토리에서 파일들을 보여주고
- 두 번째 location context와 일치하는 패턴은  www.example.com 도메인으로 요청을 전송하도록 한다.

### 문법

location 문법은 위치 조정 부호와 패턴으로 구성된다.

위치 조정 부호는 특수 기호로 지정하고 패턴은 정규식 문자열을 사용할 수 있다. 부호는 선택사항이고, 넣지 않는 경우엔 해당 문자로 시작하는 url을 뜻하게 된다.

```js
Syntax:	location [ = | ~ | ~* | ^~ ] [pattern] { ... }
location @name { ... }
Default:	—
Context:	server, location
```

```bash
# 모든 요청과 일치
location / {
    [ configuration A ]
}

# 정확하게 일치 
# matches with /images
# does not matches with /images/index.html or /images/
location = /images {
    [ configuration B ]
}

# 지정한 패턴으로 시작
# /static/ 으로 시작하는 요청과 일치
location /static/ {
    [ configuration C ]
}

# 지정한 패턴으로 시작, 패턴이 일치 하면 다른 패턴 탐색 중지(정규식 아님)
# matches with /images or /images/logo.png 
location ^~ /images {
    [ configuration D ]
}

# 정규식 표현 일치 - 대소문자 구분
location ~ \.(gif|jpg|jpeg)$ {
    [ configuration E ]
}

# 정규식 표현 일치 - 대소문자 구분 안함
location ~* \.(gif|jpg|jpeg)$ {
    [ configuration F ]
}
```

### 우선순위

다수의 Location 블록이 정의되어 있을 경우 Location 블록에 정의되어 있는 패턴에 따라 우선순위가 달라진다.

```md
1. = : 정확하게 일치
2. ^~ : 앞부분이 일치
3. ~ : 정규식 대/소문자 일치
4. ~* : 대/소문자를 구분하지 않고 정규식 일치
5. / : 하위 일치
```

---
참고
- http://nginx.org/en/docs/beginners_guide.html
- https://www.digitalocean.com/community/tutorials/nginx-location-directive
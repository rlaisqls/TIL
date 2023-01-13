# 📡 HTTP Options

일반적인 브라우저를 사용하여 통신한 내용을 들여다보면, 본 요청 이전에 Request Method가 OPTIONS인 요청이 있는것을 볼 수 있다.

통신 Type도 XMLHttpRequest (XHR) 가 아닌 preflight으로 되어있다.

이 요청은 무슨 용도의 요청일까?

![image](https://user-images.githubusercontent.com/81006587/212473281-0d417a0d-096b-4f79-99b2-d983e6b656fa.png)

## Preflight: Request Method: OPTIONS

preflight인 OPTIONS 요청은 서버와 브라우저가 통신하기 위한 통신 옵션을 확인하기 위해 사용한다.

서버가 어떤 method, header, content type을 지원하는지를 알 수 있다.

브라우저가 요청할 메서드와 헤더를 허용하는지 미리 확인한 후, 서버가 지원할 경우에 통신한다. 좀 더 효율적으로 통신할 수 있다.

터미널에서 확인해볼 수 있다.

```
curl -X OPTIONS https://API서버 -i
```

라는 요청을 서버에 보내면 다음과 같은 응답이 나온다.

```
HTTP/1.1 204 No Content
...
Access-Control-Allow-Methods: GET,HEAD,PUT,PATCH,POST,DELETE
...
```

본 정보는 없고, 서버에서 허용하는 메소드나 Origin에 대한 정보만 헤더에 담겨서 온다.

다시말해, 먼저 Options요청을 보낸 뒤 응답 정보를 사용 가능한지 파악하고 서버의 "허가"가 떨어지면 실제 요청을 보내도록 요구하는 것이다. 또한 서버는 클라이언트에게 요청에 "인증정보"(쿠키, HTTP 인증)를 함께 보내야 한다고 알려줄 수도 있다.

허용되지 않는 요청의 경우, 405(Method Not Allowed) 에러를 발생시키고 실제 요청은 전송하지 않게된다.

## 발생 조건

preflight은 보안을 위한 절차이며, 아래와 같은 경우에 발생하게 된다.

1. GET, HEAD, POST 요청이 아닌 경우
2. Custom HTTP Header가 존재하는 경우
   - 유저 에이전트가 자동으로 설정 한 헤더 (ex. Connection, User-Agent (en-US), Fetch 명세에서 “forbidden header name”으로 정의한 헤더), “CORS-safelisted request-header”로 정의한 헤더(ex. Accept, Accept-Language, Content-Language, Content-Type) 등등...
3. Content-Type이 `application/x-www-form-urlencoded`, `multipart/form-data, text/plain`이 아닌 경우



<img width="582" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/c523e94f-6131-4eb9-b97d-9d5a14fef346">

## Persistent Connection

site locality란 웹에서 특정 페이지를 보여주기 위해 서버에 연속적으로 이미지 request를 보내는 것 처럼, 서버에 연속적으로 동일한 클라이언트가 여러 요청을 보낼 가능성이 높은 경우를 의미한다.

site localiry가 높은 경우엔, 요청이 처리된 후에도 connection을 유지하는 persistent connection을 통해 통신 효율을 높일 수 있다. (connection을 위한 절차가 생략되므로)

그 외에도 아래와 같은 장점이 있다.

1. 네트워크 혼잡 감소: TCP, SSL/TCP connection request 수가 줄어들기 때문
2. 네트워크 비용 감소: 여러 개의 connection으로 하나의 client요청을 serving 하는 것보다는 한 개의 connection으로 client요청을 serving하는게 더 효율적이다.
3. latency감소: 3-way handshake을 맺으면서 필요한 round-trip이 줄어들기 때문에 그만큼 latency가 감소한다.

## HTTP keep alive

HTTP keep-alive는 위에서 설명한 persistent connection을 맺는 기법 중 하나이다. 하나의 TCP connection을 활용해서 여러개의 HTTP request/response를 주고받을 수 있도록 해준다. 

Keep-Alive 옵션은 HTTP1.0부터 지원한다. 단, HTTP/1.0에서는 무조건 Keep-Alive 헤더를 명시적으로 추가하여 사용해야 했던 것과 달리 HTTP/1.1부터는 Keep-Alive 연결이 기본적으로 활성화되어 있어 별도의 헤더를 추가하지 않아도 연결을 유지할 수 있게 되었다.

## keep-alive 옵션 사용 방법

keep-alive 옵션을 통해 persistent connection을 맺기 위해서는 HTTP header에 아래와 같이 입력해주어야 한다. 만약 서버에서 keep-alive connection을 지원하는 경우에는 동일한 헤더를 response에 담아 보내주고, 지원하지 않으면 헤더에 담아 보내주지 않는다. 만약 서버의 응답에 해당 헤더가 없을 경우 client는 지원하지 않는다고 가정하고 connection을 재사용하지 않는다.

```bash
HTTP/1.1 200 OK
Connection: Keep-Alive
Keep-Alive: timeout=5, max=1000
```

- max (MaxKeepAliveRequests): keep-alive connection을 통해서 주고받을 수 있는 request의 최대 갯수. 이 수보다 더 많은 요청을 주고 받을 경우에는 connection은 close된다.
- timeout (KeepAlivetimeout): 커넥션이 idle한 채로 얼마동안 유지될 것인가를 의미한다. 이 시간이 지날 동안 request가 없을 경우에 connection은 close된다.

keep-alive를 사용할 때는 아래와 같은 사항에 유의해야한다.

- persistent한 connection을 유지하기 위해서는 클라이언트 측에서 모든 요청에 위에 언급한 헤더를 담아 보내야 한다. 만약 한 요청이라도 생략될 경우 서버는 연결을 close한다.
- connection이 언제든 close 될 수 있기 때문에 클라이언트에서 retry 로직을 준비해두어야 한다.
- 정확한 Content-length를 사용해야 한다. 하나의 connection을 계속해서 재사용해야 하는데, 특정 요청의 종료를 판단할 수 없기 때문이다.
- Connection 헤더를 지원하지 않는 proxy에는 사용할 수 없다.

## proxy 문제: blind relays

서버와 클라이언트가 proxy없이 직접 통신할 경우에는 keep-alive 옵션이 정상 동작할 수 있지만, 만약 blind relay, 즉 keep-alive 옵션을 지원하지 않는 proxy는 Connection header를 이해하지 못하고 그냥 extension header로 인식하여 제대로 동작하지 않는다.

<img width="610" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/1d24ac31-8441-4c1d-a62f-628a67c6e6ec">

위 사진을 살펴보자.

- (b)단계에 blind relay proxy가 server측에 HTTP Connection Keep Alive header를 보낼 경우에, 서버는 proxy가 keep-alive를 지원하는 걸로 착각하게 된다.

- 따라서 proxy와 헤더에 입력된 규칙으로 통신을 시도한다. 그리고 proxy는 서버가 보낸 header를 그대로 client에게 전달은 하지만 keep-alive 옵션을 이해하지 못하기 때문에, client서버가 connection을 close하기를 대기한다.

- 하지만 client는 response에서 keep-alive 관련 헤더가 넘어왔기 때문에 persistent connection이 맺어진 줄 알고 close하지 않게된다. 따라서 이 때 proxy가 connection이 close 될 때까지 hang에 걸리게 된다.
  
- client는 동일한 conenction에 request를 보내지만 proxy는 이미 close된 connection이기 때문에 해당 요청을 무시한다.이에 따라 client나 서버가 설정한 timeout이 발생할 때까지 hang이 발생한다.

따라서 `HTTP/1.1`부터는 proxy에서 Persistent Connection 관련 header를 전달하지 않는다. persistent connection을 지원하는 proxy에서는 대안으로 Proxy Connection 헤더를 활용하여 proxy에서 자체적으로 keep-alive를 사용한다. Keep-Alive 연결이 기본적으로 활성화되는 이유가 이 때문이다.

---
참고
- https://flylib.com/books/en/1.2.1.88/1/
- http://www.w3.org/Protocols/rfc2616/rfc2616.txt
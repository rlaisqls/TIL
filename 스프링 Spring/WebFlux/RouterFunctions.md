# ⚡️ RouterFunctions와 WebFlux

**RouterFunctions**로 webFlux를 사용해보자. 기본적인 원리와 방식은 <a href="./@Controller.md">**@Controller**</a>에서 모두 설명하였으며 같은 기능의 코드를 테스트할 것이기 때문에 해당 글을 먼저 보고 오는 것을 추천한다.

우선  GET("/")으로 Flux의 “Hello World"를 반환하는 Routing을 정의한다.

```java
@Component
public class HelloHandler {

    RouterFunction<ServerResponse> routes() {
        return route(GET("/"),
            req -> ok().body(Flux.just("Hello", "World!"), String.class));
    }

}
```

스트림 반환은 아래와 같이 한다.
```java
    public Mono<ServerResponse> stream(ServerRequest req) {

        Stream<Integer> stream = Stream.iterate(0, i -> i + 1);
        
        Flux<Map<String, Integer>> flux = Flux.fromStream(stream)
                .map(i -> Collections.singletonMap("value", i));
        
        return ok()
                .contentType(MediaType.APPLICATION_NDJSON)
                .body(fromPublisher(flux, new ParameterizedTypeReference<Map<String, Integer>>(){}));
    }
```

HelloWebFluxApplication 클래스를 다시 시작하고 /stream에 접속해 보면 무한 JSON Stream이 반환된다.

```java
$ curl -i localhost:8080/stream
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0HTTP/1.1 200 OK
transfer-encoding: chunked
Content-Type: application/x-ndjson

{"value":0}
{"value":1}
{"value":2}
{"value":3}
{"value":4}
{"value":5}
{"value":6}
{"value":7}
{"value":8}
{"value":9}
{"value":10}

...

```

---

POST의 경우는 RequestPredicates.POST를 사용하여 라우팅을 정의하는 것과 응답 본문을 ServerRequest.bodyToMono 또는 ServerRequest.bodyToFlux을 사용하면 된다.

```java
@Component
public class HelloHandler {

    public RouterFunction<ServerResponse> routes() {
        return route(GET("/"), this::hello)
                .andRoute(GET("/stream"), this::stream)
                .andRoute(POST("/echo"), this::echo);
    }

    public Mono<ServerResponse> hello(ServerRequest req) {
        return ok().body(Flux.just("Hello", "World!"), String.class);
    }

    public Mono<ServerResponse> stream(ServerRequest req) {
        Stream<Integer> stream = Stream.iterate(0, i -> i + 1);
        Flux<Map<String, Integer>> flux = Flux.fromStream(stream)
                .map(i -> Collections.singletonMap("value", i));
        return ok().contentType(MediaType.APPLICATION_NDJSON)
                .body(fromPublisher(flux, new ParameterizedTypeReference<Map<String, Integer>>(){}));
    }
    
    public Mono<ServerResponse> echo(ServerRequest req) {
        Mono<String> body = req.bodyToMono(String.class).map(String::toUpperCase);
        return ok().body(body, String.class);
    }
```

POST /stream도 동일하지만 Request Body를 Generics 형태의 Publisher으로 받을 경우는 ServerRequest.bodyToFlux가 아닌 ServerRequest.body 메소드에 BodyInserters와 반대의 개념인 BodyExtractors을 전달한다.

```java
@Component
public class HelloHandler {

    public RouterFunction<ServerResponse> routes() {
        return route(GET("/"), this::hello)
                .andRoute(GET("/stream"), this::stream)
                .andRoute(POST("/echo"), this::echo)
                .andRoute(POST("/stream"), this::postStream);
    }

    public Mono<ServerResponse> hello(ServerRequest req) {
        return ok().body(Flux.just("Hello", "World!"), String.class);
    }

    public Mono<ServerResponse> stream(ServerRequest req) {
        Stream<Integer> stream = Stream.iterate(0, i -> i + 1);
        Flux<Map<String, Integer>> flux = Flux.fromStream(stream)
                .map(i -> Collections.singletonMap("value", i));
        return ok().contentType(MediaType.APPLICATION_NDJSON)
                .body(fromPublisher(flux, new ParameterizedTypeReference<Map<String, Integer>>(){}));
    }
    
    public Mono<ServerResponse> echo(ServerRequest req) {
        Mono<String> body = req.bodyToMono(String.class).map(String::toUpperCase);
        return ok().body(body, String.class);
    }

    public Mono<ServerResponse> postStream(ServerRequest req) {
        Flux<Map<String, Integer>> body = req.body(toFlux( // BodyExtractors.toFlux을 static import해야 한다.
                new ParameterizedTypeReference<Map<String, Integer>>(){}
        ));
        
        return ok().contentType(MediaType.TEXT_EVENT_STREAM)
                .body(fromPublisher(body.map(m -> Collections.singletonMap("double", m.get("value") * 2)),
                        new ParameterizedTypeReference<Map<String, Integer>>(){}));
    }
}
```

> RequestPredicates.GET와 RequestPredicates.POST는 @GetMapping, @PostMapping에 대응되고, HTTP 메소드가 없는@RequestMapping에 대응하는 것은RequestPredicates.path이다.<br>그리고 이것들은 Functional Interface이므로, 람다 식을 통해 요청 매칭 규칙을 선택적으로 변형할 수 있다.

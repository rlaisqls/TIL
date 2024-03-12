
**@Controller**로 webFlux를 사용해보자.

### 프로젝트 생성

스프링부트 프로젝트를 생성하여 `build.gradle`에 Dependencies를 설정한다. 필요한 의존성과, webflux 의존성을 설정해준다.

```groovy
implementation 'org.springframework.boot:spring-boot-starter-webflux'
```

### Flux 반환 유형

`Flux`는 Reactive Streams의 Publisher를 구현한 N개 요소의 스트림을 표현하는 Reactor 클래스이다. 기본적으로 text/plain으로 응답이 반환되지만, **Server-Sent Event**나 **JSON Stream**으로 반환할 수도 있다.

Flux의 반환 유형은 **클라이언트가 헤더에 응답 유형을 어떻게 설정하느냐에 따라** 달라진다.

아래같은 코드가 있다고 해보자.

```java
@RestController
public class HelloController {

    @GetMapping("/")
    Flux<String> hello() {
        return Flux.just("Hello", "World");
    }
}
```
 
일반적으로 요청을 보내면 `text/plain`으로 반환이 온다.

```c
//text/plain
$ curl -i localhost:8080
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    10    0    10    0     0    909      0 --:--:-- --:--:-- --:--:--  1000HTTP/1.1 200 OK
transfer-encoding: chunked
Content-Type: text/plain;charset=UTF-8

HelloWorld
```

Accept 헤더에 `text/event-stream`를 지정하면 Server-Sent Event, `application/stream+json`를 지정하면 JSON Stream으로 반환된다. (하지만 위 컨트롤러 코드에서는 단순 문자열을 반환했기 때문에, JSON과 plain text의 차이가 없다.)

```c
//text/event-stream
$ curl -i localhost:8080 -H 'Accept: text/event-stream'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    24    0    24    0     0   1846      0 --:--:-- --:--:-- --:--:--  2000HTTP/1.1 200 OK
transfer-encoding: chunked
Content-Type: text/event-stream;charset=UTF-8

data:Hello

data:World
```

```c
//application/stream+json
$ curl -i localhost:8080 -H 'Accept: application/stream+json'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    10    0    10    0     0    714      0 --:--:-- --:--:-- --:--:--   769HTTP/1.1 200 OK
transfer-encoding: chunked
Content-Type: application/stream+json;charset=UTF-8

HelloWorld
```

### 무한 Stream

Flux 반환을 `java.util.stream.Stream`형으로 주는 것도 가능하다. 다음은 stream 메소드를 작성하여, 무한 Stream을 작성하고, 그 중에 10건을 Flux로 변환하여 반환해 보자.

```java
@RestController
public class HelloController {

    @GetMapping("/")
    Flux<String> hello() {
        return Flux.just("Hello", "World");
    }

    @GetMapping("/stream")
    Flux<Map<String, Integer>> stream() {
        Stream<Integer> stream = Stream.iterate(0, i -> i + 1); // Java8의 무한Stream
        return Flux.fromStream(stream.limit(10))
                .map(i -> Collections.singletonMap("value", i));
    }
}
```

`/stream`에 대한 세 가지 응답은 각각와 아래와 같다.

#### 일반 JSON

```c
$ curl -i localhost:8080/stream
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   121    0   121    0     0  11000      0 --:--:-- --:--:-- --:--:-- 12100HTTP/1.1 200 OK
transfer-encoding: chunked
Content-Type: application/json

[{"value":0},{"value":1},{"value":2},{"value":3},{"value":4},{"value":5},{"value":6},{"value":7},{"value":8},{"value":9}]
```

#### Server-Sent Event

```c
$ curl -i localhost:8080/stream -H 'Accept: text/event-stream'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   180    0   180    0     0  12000      0 --:--:-- --:--:-- --:--:-- 12000HTTP/1.1 200 OK
transfer-encoding: chunked
Content-Type: text/event-stream;charset=UTF-8

data:{"value":0}

data:{"value":1}

data:{"value":2}

data:{"value":3}

data:{"value":4}

data:{"value":5}

data:{"value":6}

data:{"value":7}

data:{"value":8}

data:{"value":9}
```

### JSON Stream

```c
$ curl -i localhost:8080/stream -H 'Accept: application/stream+json'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   120    0   120    0     0   7500      0 --:--:-- --:--:-- --:--:--  7500HTTP/1.1 200 OK
transfer-encoding: chunked
Content-Type: application/stream+json

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
````

`application/json`과 `application/stream+json`의 차이를 볼 수 있다.

만약 코드에서 limit을 붙이지 않고 코드를 아래와 같이 작성한다면 무한 Stream을 받을 수도 있다. (단 `application/json`의 경우에는 응답이 반환되지 않을 것이다.)

```c
    @GetMapping("/stream")
    Flux<Map<String, Integer>> stream() {
        Stream<Integer> stream = Stream.iterate(0, i -> i + 1); // Java8의 무한Stream
        return Flux.fromStream(stream)
                .map(i -> Collections.singletonMap("value", i));
    }
```

### 요청인자를 비동기로

요청을 받는 것 또한 비동기적으로 처리할 수 있다.

`@RequestBody`으로 요청 본문으로 받아 대문자로 변환하는 map의 결과 Mono를 그대로 반환하는 메소드를 추가해보자. 일반적으로 String으로 요청을 받는다면 NonBlocking으로 동기화 처리되지만, Mono에 감싸서 받으면 **`chain/compose`로 비동기처리**할 수 있게 된다.

Mono는 **1개 또는 0개의 요소**를 가지도록 한다.

```java
@RestController
public class HelloController {

    @GetMapping("/")
    Flux<String> hello() {
        return Flux.just("Hello", "World");
    }

    @GetMapping("/stream")
    Flux<Map<String, Integer>> stream() {
        Stream<Integer> stream = Stream.iterate(0, i -> i + 1);
        return Flux.fromStream(stream).zipWith(Flux.interval(Duration.ofSeconds(1)))
                .map(tuple -> Collections.singletonMap("value", tuple.getT1() /* 튜플의 첫 번째 요소 = Stream<Integer> 요소 */));
    }

    @PostMapping("/echo")
    Mono<String> echo(@RequestBody Mono<String> body) {
        return body.map(String::toUpperCase);
    }
}
```

```c
$  curl -i localhost:8080/echo -H 'Content-Type: application/json' -d rlaisqls
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    14  100     7  100     7   1166   1166 --:--:-- --:--:-- --:--:--  2800HTTP/1.1 200 OK
Content-Type: text/plain;charset=UTF-8
Content-Length: 7

RLAISQLS
```

1건만 처리해야 한다면 Mono를 사용하는 것이 명시적이지만, **여러 건수의 Stream을 처리**하고 싶다면 `Flux`로 해야 한다.

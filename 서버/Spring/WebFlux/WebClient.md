
외부 서비스와 HTTP로 통신해야 하는 경우 가장 흔한 방법은 RestTemplate을 사용하는 것이다. RestTemplate은 Spring 애플리케이션에서 가장 일반적인 웹 클라이언트지만 블로킹 API이므로 리액티브 기반의 애플리케이션에서 성능을 떨어트리는 원인이 될 수 있다. 

대신 Spring5에서 추가된 WebClient를 사용하면 reactive 기반의 비동기-논블로킹 통신을 구현할 수 있다.

```kotlin
    webClient
        .get()
        .uri("/users/" + userId)
        .retrieve();
```

## 기본 요청 방법

http method는 webClient의 get, post, put, head 등의 메서드로 지정해준다.

<img width="644" alt="image" src="https://user-images.githubusercontent.com/81006587/230880942-31f0a097-5eb3-41f5-840c-198d91b20e62.png">

### query parameter

query parameter는 uri builder로 지정해준다.

```kotlin
webClient.post()
    .uri {
        it.path("https://example.com")
        .queryParam("code", code)
        .queryParam("email", email)
        .build()
    }
    .retrieve()
```

### body

```kotlin
webClient.mutate()
    .baseUrl("https://some.com/api")
    .build()
    .post()
    .uri("/login")
    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
    .accept(MediaType.APPLICATION_JSON)
    .body(BodyInserters.fromFormData("id", idValue)
        .with("pwd", pwdValue)
    )
    .retrieve()
    .bodyToMono(SomeData.class);
```

```kotlin
webClient.mutate()
    .baseUrl("https://some.com/api")
    .build()
    .post()
    .uri("/login")
    .contentType(MediaType.APPLICATION_JSON)
    .accept(MediaType.APPLICATION_JSON)
    .bodyValue(loginInfo)
    .retrieve()
    .bodyToMono(SomeData.class);
```

### 응답 값이 없는 경우

응답 값이 없는 요청은 `bodyToMono`에 `Void.class`를 넣어준다.

```kotlin
webClient.mutate()
    .baseUrl("https://some.com/api")
    .build()
    .delete()
    .uri("/resource/{ID}", id)
    .retrieve()
    .bodyToMono(Void.class)
```

## mutate

`WebClient`는 기존 설정값을 상속해서 사용할 수 있는 `mutate()` 함수를 제공하고 있다. `mutate()`를 통해 `builder()`를 다시 생성하여 추가적인 옵션을 설정하여 재사용이 가능하기 때문에 `@Bean`으로 등록한 `WebClient`는 각 Component에서 의존주입하여 mutate()를 통해 사용하는 것이 좋다.

```kotlin
val a = WebClient
    .builder()
    .baseUrl("https://some.com")
    .build();

val b = a.mutate()
    .defaultHeader("user-agent", "WebClient")
    .build();

val c = b.mutate()
    .defaultHeader(HttpHeaders.AUTHORIZATION, token)
    .build();
```

WebClient c는 a와 b에 설정된 baseUrl, user-agent 헤더를 모두 가지고 있다.

`@Bean`으로 등록된 WebClient 는 다음과 같이 사용할 수 있다.

```kotlin
@Service
class SomeService(
    private val webClient: WebClient
) : SomeInterface {

    public Mono<SomeData> getSomething() {
        return webClient.mutate()
            .build()
            .get()
            .uri("/resource")
            .retrieve()
            .bodyToMono(SomeData.class)
    }
}
```

## retrieve() vs exchange()

HTTP 호출 결과를 가져오는 두 가지 방법으로 `retrieve()`와 `exchange()`가 존재한다. retrieve를 이용하면 **ResponseBody를 바로 처리** 할 수 있고, `exchange`를 이용하면 **세세한 컨트롤**이 가능하다. 하지만 exchange를 이용하게 되면 Response 컨텐츠에 대한 모든 처리를 직접 하면서 발생할 수 있는 `memory leak` 가능성 때문에 Spring에서는 가급적 retrieve를 사용하기를 권고하고 있다.

### retrieve

```kotlin
webClient.get()
    .uri("/persons/{id}", id)
    .accept(MediaType.APPLICATION_JSON) 
    .retrieve() 
    .bodyToMono(Person.class);
```
### exchange

```kotlin
webClient.get()
    .uri("/persons/{id}", id)
    .accept(MediaType.APPLICATION_JSON)
    .exchange()
    .flatMap(response -> response.bodyToMono(Person.class))
```

### 4xx and 5xx 처리

HTTP 응답 코드가 4xx 또는 5xx로 내려올 경우 WebClient 에서는 WebClientResponseException이 발생하게 된다. 이 때 각 상태코드에 따라 임의의 처리를 하거나 Exception을 wrapping하고 싶을 때는 `onStatus()` 함수를 사용하여 해결할 수 있다.

```kotlin
webClient.mutate()
    .baseUrl("https://some.com")
    .build()
    .get()
    .uri("/resource")
    .accept(MediaType.APPLICATION_JSON)
    .retrieve()
    .onStatus(HttpStatus::is4xxClientError) { Mono.error(ForbiddenException) }
    .bodyToMono(SomeData.class)
```

## Synchronous Use

WebClient 는 Reactive Stream 기반이므로 리턴값을 Mono 또는 Flux 로 전달받게 된다. Spring WebFlux를 이미 사용하고 있다면 문제가 없지만 Spring MVC를 사용하는 상황에서 WebClient를 활용하고자 한다면 Mono나 Flux를 객체로 변환하거나 Java Stream 으로 변환해야 할 필요가 있다.

이럴 경우를 대비해서 `Mono.block()`이나 `Flux.blockFirst()`와 같은 blocking 함수가 존재하지만 `block()`을 이용해서 객체로 변환하면 Reactive Pipeline 을 사용하는 장점이 없어지고 모든 호출이 main 쓰레드에서 호출되기 때문에 Spring 측에서는 `block()`은 테스트 용도 외에는 가급적 사용하지 말라고 권고하고 있다.

대신 완벽한 Reactive 호출은 아니지만 Lazy Subscribe 를 통한 Stream 또는 Iterable 로 변환 시킬 수 있는 `Flux.toStream()`, `Flux.toIterable()` 함수를 제공하고 있다.

```kotlin
val res = webClient.mutate()
    .baseUrl("https://some.com/api")
    .build()
    .get()
    .uri("/resource")
    .accept(MediaType.APPLICATION_JSON)
    .retrieve()
    .bodyToFlux(SomeData.class)
    .toStream()
    .collect(Collectors.toList())
```

```kotlin
val res = webClient.mutate()
    .baseUrl("https://some.com/api")
    .build()
    .get()
    .uri("/resource/{ID}", id)
    .accept(MediaType.APPLICATION_JSON)
    .retrieve()
    .bodyToMono(SomeData.class)
    .flux()
    .toStream()
    .findFirst()
    .orElse(defaultValue);
```
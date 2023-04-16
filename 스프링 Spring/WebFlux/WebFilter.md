# WebFilter

WebFilter는 Spring WebMVC의 Filter에 대응되는 클래스이다. WebFilter는 Spring Web package에 있는 클래스이고, WebFlux를 사용할 때만 동작한다. 

## RequestContextWebFilter

```kotlin
import org.springframework.web.server.ServerWebExchange
import org.springframework.web.server.WebFilter
import org.springframework.web.server.WebFilterChain
import reactor.core.publisher.Mono

class RequestContextWebFilter(
    private val requestContext: RequestContext,
    private val requestContextModelFactory: RequestContextModelFactory,
    private val instantGenerator: DateTimeGenerator,
) : WebFilter {
    override fun filter(
        exchange: ServerWebExchange,
        chain: WebFilterChain
    ): Mono<Void> {
        val request = exchange.request
        requestContext.setContext(
            requestContextModelFactory.create(
                requestId = request.id,
                requestHeaders = request.headers.toMap(),
                requestMethod = request.method?.name.toString(),
                requestPath = request.path.value(),
                userId = request.queryParams.getFirst("userId")?.toString() ?: "null",
                requestQueryParams = request.queryParams.toSingleValueMap().toMap(),
                requestInstant = instantGenerator.now(),
            )
        )
        return chain.filter(exchange)
    }
}
```

위와 같이 WebFilter를 작성할 수 있다. WebFilter는 `reactor-http-nio-$N`라는 id의 thread에서 실행된다. (N은 랜덤 숫자이다)

**filter 함수를 호출한 thread**와 **filter 함수가 return한 Mono를 subscribe하는 thread**는 다를 수도 있다.

## BasicAuthenticationWebFilter

```kotlin
class BasicAuthenticationWebFilter(
    private val authenticationService: AuthenticationService,
) : WebFilter {

    companion object {
        const val allowedAuthScheme = "basic"
        private val base64Decoder = Base64.getDecoder()
    }

    override fun filter(exchange: ServerWebExchange, chain: WebFilterChain): Mono<Void> {
        val request = exchange.request
        val (authenticationScheme, encodedCredential) = request
            .headers.getFirst(RequestHeaderKeys.authorization)
            ?.split(" ", limit = 2)
            ?: throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authorization header not found.")
        if (authenticationScheme.lowercase() != allowedAuthScheme)
            throw ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "$authenticationScheme is not allowed. Use $allowedAuthScheme."
            )
        return chain.filter(exchange)
            .doOnSubscribe { authenticationService.authenticate(decodeOrThrow(encodedCredential)) }
    }

    private fun decodeOrThrow(s: String) =
        base64Decoder
            .runCatching { decode(s).decodeToString() }
            .getOrElse { t ->
                if (t is IllegalArgumentException)
                    throw ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Invalid credential. base64 decoding failed."
                    ).initCause(t)
                else
                    throw ResponseStatusException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "Server error occurred."
                    ).initCause(t)
            }
}
```

[RFC7235](https://datatracker.ietf.org/doc/html/rfc7235#section-4.2) (HTTP/1.1 Authentication), [RFC7617](https://datatracker.ietf.org/doc/html/rfc7617) (Basic HTTP Authentication Scheme) Spec에 따라 간단히 구현한 Authentication WebFilter이다.

코드는 WebFilter 개념 중점으로 보면 좋을 것 같다. 특별히 설명할 부분은 없다. authenticate() 등이 blocking call일 경우에만 주의하자.

## WebFilter Order

이제 2개의 WebFilter가 생겼다. WebFilter를 2개 이상 사용할 경우 순서가 생길 것이다. 이 순서는 때때로 중요하다. (RequestContext → Logging과 같이 불가피하게 순서 의존적일 때)

가장 좋은 방법은 순서 독립적으로 WebFilter를 구현하는 것이고, 대안은 WebFilter의 순서를 지정하는 것이다. WebFilter를 하나로 뭉쳐서 구현할 수도 있지만, 코드의 재사용성과 유연성이 떨어진다.

순서는 Spring @Order 어노테이션으로 지정할 수 있다. 이 Order는 하나의 Config 파일에서 확인할 수 있도록 작성하는 것이 좋다.

```kotlin
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.core.annotation.Order

@Configuration
class WebFilterConfig {
    @Order(100)
    @Bean
    fun requestContextWebFilter() =
        RequestContextWebFilter(
            requestContext(),
            requestContextModelFactory(),
            dateTimeGenerator(),
        )
    @Order(200)
    @Bean
    fun authenticationWebFilter(authenticationService: AuthenticationService) =
        AuthenticationWebFilter(requestContext(), authenticationService)
    @Bean
    fun requestContext(): ThreadLocalRequestContext =
        ThreadLocalRequestContext()
    @Bean
    fun requestContextModelFactory() =
        RequestContextModelFactory()
    @Bean
    fun dateTimeGenerator() =
        DateTimeGenerator()
}
```

Order는 `lower is higher`이다.

## WebFlux Decorator classes

WebFlux에는 대표적으로 3개의 Decorator 클래스가 있다.

- ServerWebExchangeDecorator
- ServerHttpRequestDecorator
- ServerHttpResponseDecorator

세개의 클래스를 활용하여 로깅을 구현하는 예제를 살펴보자.

### ServerWebExchangeDecorator

```kotlin
class LoggingWebFilter(
    private val requestContext: RequestContext,
    private val dateTimeGenerator: DateTimeGenerator,
) : WebFilter {

    companion object : InsideLoggerProvider()

    override fun filter(exchange: ServerWebExchange, chain: WebFilterChain): Mono<Void> =
        chain.filter(loggingDecoratedExchange(exchange, request, response))
            .doOnError { t ->
                val context = requestContext.getContextOrThrow()
                    .apply { responseTime = dateTimeGenerator.now() }
                log.error(t, LoggingType.errorResponseType, context)
        }
    }

    private fun loggingDecoratedExchange(exchange: ServerWebExchange): ServerWebExchange =
        object : ServerWebExchangeDecorator(exchange) {

            override fun getRequest(): ServerHttpRequest = 
                LoggingDecoratedRequest(exchange.request, requestContext.getContext())

            override fun getResponse(): ServerHttpResponse = 
                LoggingDecoratedResponse(
                    exchange.response,
                    requestContext.getContext(),
                    dateTimeGenerator,
                )
        }
}
```

### ServerHttpRequestDecorator

```kotlin
class LoggingDecoratedRequest(
    delegate: ServerHttpRequest,
    private val contextOrNull: RequestContextModel?,
) : ServerHttpRequestDecorator(delegate) {

    override fun getBody(): Flux<DataBuffer> =
        super.getBody().doOnNext { dataBuffer ->
            val body = DataBufferUtil.readDataBuffer(dataBuffer)
            contextOrNull?.requestPayload = body
            logRequest()
        }
}
```

### ServerHttpResponseDecorator

```kotlin
class LoggingDecoratedResponse(
    delegate: ServerHttpResponse,
    private val contextOrNull: RequestContextModel?,
) : ServerHttpResponseDecorator(delegate) {
    
    companion object : InsideLoggerProvider()

    override fun writeWith(body: Publisher<out DataBuffer>): Mono<Void> =
        super.writeWith(
            Mono.from(body).doOnNext { dataBuffer ->
                contextOrNull?.responsePayload = DataBufferUtil.readDataBuffer(dataBuffer)
                statusCode?.name?.let { contextOrNull?.statusCode = it }
            }
        )
}
```

### DataBufferUtil

```kotlin
object DataBufferUtil {
    
    fun readDataBuffer(dataBuffer: DataBuffer): String {

        val baos = ByteArrayOutputStream()
        return Channels.newChannel(baos)
            .runCatching { write(dataBuffer.asByteBuffer().asReadOnlyBuffer()) }
            .map { baos.toString() }
            .onFailure { t -> if (t is IOException) t.printStackTrace() }
            .getOrThrow()
        // Closing a ByteArrayOutputStream has no effect.
    }
}
```

### Conclusion

WebFlux에서 사용하기 위한 WebFilter와 Decorator의 예제 코드들을 살펴보았다. use case로서 request context와 authentication을 살펴보았다. WebFlux Logging을 구현하기 위해 존재하는 challenge도 간략하게 살펴보았다.
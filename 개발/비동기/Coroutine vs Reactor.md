# Coroutine vs Reactor

코틀린 코루틴과 리액티브 스트림의 구현체 중 하나인 Reactor의 차이점은 무엇이 있을까?

아래와 같이 사용자의 정보를 받아 환영 메세지를 생성한 후 반환하는 메서드가 있을때, 이 메서드를 호출하는 코드를 각 방식으로 작성해보자.

```kotlin
fun generateWelcome(
    usernameOrIp: String,
    userProfile: UserProfile?, // 프로필 정보
    block: Block?, // 차단 여부
): WelcomeMessage =
    when {
        block != null -> WelcomeMessage(
            "You are blocked. Reason: ${block.reason}",
            WARNING
        )
        else -> WelcomeMessage(
            "Hello ${userProfile?.fullName ?: usernameOrIp}",
            INFO
        )
    }
```

호출 코드는, 대략적으로 이러한 흐름을 가져야한다.

1. usernameOrIp를 인자로 받는다.
2. 인자를 사용해 UserProfile을 조회한다.
3. 인자를 사용해 block(차단 여부)를 조회한다.
4. 조회 정보를 넣어 generateWelcome 메서드를 호출한다.

구조를 알아보기 쉽게 명령형 방식으로 작성하자면 아래와 같이 짤 수 있다.

```kotlin
class WelcomeService {
    fun welcome(usernameOrIp: String): WelcomeMessage {
        val userProfile: UserProfile? = findUserProfile(usernameOrIp)
        val block: Block? = findBlock(usernameOrIp)
        return generateWelcome(usernameOrIp, userProfile, block)
    }
}
```

## Reactive Streams(Reactor) Code

```kotlin
fun welcome(usernameOrIp: String): Mono<WelcomeMessage> {
    return userProfileRepository.findById(usernameOrIp)
        .zipWith(blockRepository.findById(usernameOrIp))
        .map { tuple ->
            generateWelcome(usernameOrIp, tuple.t1, tuple.t2)
        }
}
```

`reactive repository`인 `userProfileRepository`와 `blockRepository`는 결과값을 `Mono`에 감싸서 반환하고, 두 reactive stream은 `zip` 연산자를 통해 연결되고 있다. 

괜찮은 코드인 것 같지만 이 코드는 정상적으로 작동하지 않을 수 있다. `zip` 연산자는 인자가 비어있을 때 리액티브 스트림 후속 과정을 실행하지 않고 취소한다. 그래서 사용자 프로파일이나 차단 여부 정보 중 한 가지라도 없는 경우에는 `generateWelcome()`이 실행되지 않는다. 

위에서 명령형 방식으로 짰던 코드에서는 변수 타입을 명시적으로 nullable Type(`?`)으로 지정해서 프로그래머가 인식하고 처리할 수 있도록 했는데, Reactor를 사용하면 그러한 이점이 사라진다. 항상 프로그래머가 그 가능성을 고려하여 코드를 짜야한다. null인 경우를 고려하여 코드를 수정한 코드는 아래와 같다.

```kotlin
fun welcome(usernameOrIp: String): Mono<WelcomeMessage> {
    return userProfileRepository.findById(usernameOrIp)
        .map { Optional.of(it) }
        .defaultIfEmpty(Optional.empty())
        .zipWith(
            blockRepository.findById(usernameOrIp)
                .map { Optional.of(it) }
                .defaultIfEmpty(Optional.empty())
        )
        .map { tuple ->
            generateWelcome(
                usernameOrIp, tuple.t1.orElse(null), tuple.t2.orElse(null)
            )
        }
}
```

로직이 한눈에 파악하기 어려워졌다. 코드가 수행하고자 하는 목적이 잘 드러나지 않아서, 유지보수하기에 굉장히 어려울 것이다.

그리고 위의 코드에서도 마찬가지였는데, 도메인과 관련 없는 reactor에 의존한 용어(tuple)가 코드에 섞이는 것도 문제가 된다. 이 코드를 이해하기 위해선 reactor의 구조와 용어를 숙지하는 과정이 필요할 것이다.

## Coroutine Code

```kotlin
suspend fun welcome(usernameOrIp: String): WelcomeMessage {
    val userProfile = userProfileRepository.findById(usernameOrIp).awaitFirstOrNull()
    val block = blockRepository.findById(usernameOrIp).awaitFirstOrNull()
    return generateWelcome(usernameOrIp, userProfile, block)
}
```

코틀린 코루틴 코드는 suspend, awaitFirstOrNull()외에는 명령형 코드와 거의 같다. 그냥 `reactive repository`를 호출해서 사용하기만 한다.

가독성이 굉장히 좋아졌고 간단해졌다.

## Kotlin Coroutine + Reactor Code

`kotlinx-coroutines-reactor`를 사용하면 코틀린 코루틴과 스프링 리액터 및 웹플럭스(WebFlux)를 함께 사용할 수 있다.

```kotlin
@RestController
class WelcomeController(
    private val welcomeService: WelcomeService
) {
    @GetMapping("/welcome")
    suspend fun welcome(@RequestParam ip: String) =
        welcomeService.welcome(ip)
}
```

스프링 웹플럭스는 suspend 함수 결과를 받아서 반환하는 기능을 지원하고 있어서 컨트롤러에서 suspend 함수를 사용할 수 있다.
따라서 Reactor 기반으로 작성된 코드를 코틀린 코루틴 코드로 대체할 수 있다.

그리고 코틀린 코루틴은 리액터 타입인 Mono를 지원하고 있기 때문에 다음과 같이 섞어쓸 수 있다.

```kotlin
fun welcome(usernameOrIp: String): Mono<WelcomeMessage> {
    return mono {
        val userProfile = userProfileRepository.findById(usernameOrIp).awaitFirstOrNull()
        val block = blockRepository.findById(usernameOrIp).awaitFirstOrNull()
        generateWelcome(usernameOrIp, userProfile, block)
    }
}
```

참고

https://nexocode.com/blog/posts/reactive-streams-vs-coroutines/
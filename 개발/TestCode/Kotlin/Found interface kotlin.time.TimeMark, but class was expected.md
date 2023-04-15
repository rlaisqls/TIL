## Found interface kotlin.time.TimeMark, but class was expected

나는 프로젝트에서 `java 17`과 `jvm plugin` 1.6.21, `kotest` 5.1.0를 사용하고 있었다. 기존에는 api를 Spring MVC 기반으로 개발했는데 PDF 변환 등 무거운 작업을 할때 Thread가 완전히 blocking되어 사용자 요청 처리가 지연되는 것을 우려해서, coroutine과 WebFlux로 마이그레이션을 진행하고 있었다. 그래서 kotest에도 coroutine 설정을 해주었다.

그랬더니 테스트를 돌릴떄 에러가 발생했다.

```log
java.lang.IncompatibleClassChangeError: Found interface kotlin.time.TimeMark, but class was expected
	at io.kotest.engine.spec.interceptor.SpecFinishedInterceptor.intercept-0E7RQCE(SpecFinishedInterceptor.kt:37)
	at io.kotest.engine.spec.interceptor.SpecFinishedInterceptor$intercept$1.invokeSuspend(SpecFinishedInterceptor.kt)
	at kotlin.coroutines.jvm.internal.BaseContinuationImpl.resumeWith(ContinuationImpl.kt:33)
```

`TimeMark`가 클래스일거라고 예상했지만, 인터페이스를 찾았다고 한다. 

<img width="887" alt="image" src="https://user-images.githubusercontent.com/81006587/232176349-8b607adf-535d-4c9f-a838-039adde0a849.png">

```kotlin
// kotlin-stdlib-1.6.21의 TimeMark
@kotlin.SinceKotlin @kotlin.time.ExperimentalTime public abstract class TimeMark public constructor() {
    public abstract fun elapsedNow(): kotlin.time.Duration

    public final fun hasNotPassedNow(): kotlin.Boolean { /* compiled code */ }

    public final fun hasPassedNow(): kotlin.Boolean { /* compiled code */ }

    public open operator fun minus(duration: kotlin.time.Duration): kotlin.time.TimeMark { /* compiled code */ }

    public open operator fun plus(duration: kotlin.time.Duration): kotlin.time.TimeMark { /* compiled code */ }
}
```

```kotlin
/// kotlin-stdlib-1.7.10의 TimeMark
@kotlin.SinceKotlin @kotlin.time.ExperimentalTime public interface TimeMark {
    public abstract fun elapsedNow(): kotlin.time.Duration

    public open fun hasNotPassedNow(): kotlin.Boolean { /* compiled code */ }

    public open fun hasPassedNow(): kotlin.Boolean { /* compiled code */ }

    public open operator fun minus(duration: kotlin.time.Duration): kotlin.time.TimeMark { /* compiled code */ }

    public open operator fun plus(duration: kotlin.time.Duration): kotlin.time.TimeMark { /* compiled code */ }
}
```

찾아보니 `kotlin-stdlib-1.6.x`의 TimeMark는 abstract class였고, `kotlin-stdlib-1.7.x`에서는 interface가 되어있었다.

이 변경사항에 대한 것은 kotlin 공식 릴리즈 문서에서도 확인할 수 있었다.

- https://blog.jetbrains.com/kotlin/2022/06/kotlin-1-7-0-released/
- https://kotlinlang.org/docs/whatsnew17.html#time-marks-based-on-inline-classes-for-default-time-source

## kotest의 대응

<img width="417" alt="image" src="https://user-images.githubusercontent.com/81006587/232177195-9102a439-2627-46a8-a6b1-ed1b14d7df6f.png">

<img width="821" alt="image" src="https://user-images.githubusercontent.com/81006587/232177109-3616e884-1b59-4759-8d2f-12f2541fbc9f.png">

kotest 5.3.1 이상 버전에서는 Kotlin 1.6에서 1.7로 넘어가면서 생긴 TimeMark의 변화에 대응하기 위해서, TimeMark와 비슷한 기능을 하는 Compat을 만들어서 사용하고 있는 것을 볼 수 있다.

프로젝트에서도 kotest를 5.4.0으로 변경하면서 문제를 해결헀다.

---

참고
- https://github.com/kotest/kotest/issues/2960
- https://github.com/kotest/kotest/issues/2990
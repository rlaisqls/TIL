# ✅ Kotest

코틀린에서는 아래와 형태와 같은 DSL(Domain Specific Language) 스타일의 중괄호를 활용한 코드 스타일을 제공한다. 코틀린 내부에서 제공하는 Standard library 대부분도 DSL을 이용해 작성된 것을 볼 수 있다.
- [Type safe builders](https://play.kotlinlang.org/byExample/09_Kotlin_JS/06_HtmlBuilder?_gl=1*scn3we*_ga*MTExMjE5OTk1NC4xNjExNjY4NzEx*_ga_J6T75801PF*MTYyNDM2NTA0Mi4xMDguMC4xNjI0MzY1MDQyLjA.&amp;_ga=2.54260653.40338281.1624343617-1112199954.1611668711)
- [Kotlin Standard Library](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin.collections/-list/#kotlin.collections.List)
- [Kotlin Scope Functions (let, also, apply, run ..)](https://github.com/rlaisqls/TIL/blob/main/%EC%96%B8%EC%96%B4%E2%80%85Language/Kotlin/%EB%B2%94%EC%9C%84%E2%80%85%EC%A7%80%EC%A0%95%E2%80%85%ED%95%A8%EC%88%98.md)


하지만 기존에 사용하던 Junit과 AssertJ, Mockito를 사용하면 Mocking이나 Assertion 과정에서 코틀린 DSL 을 활용할 수 없다.

기존에 JAVA에서 사용하던 `Junit`, `Assertion`, `Mockito` 등의 테스트 프레임워크 대신에, Kotest나 Mockk와 같은 도구들을 사용하면 아래처럼 코틀린 DSL과 Infix를 사용해 코틀린 스타일의 테스트 코드를 작성할 수 있다.

<img height=300px src="https://user-images.githubusercontent.com/81006587/210187709-882eb2a4-5b0a-4355-8dab-a0eaaa68b875.png"/>


---

## Kotest

<img src="https://user-images.githubusercontent.com/81006587/210192326-5f4eae32-985e-4914-9f32-c33b5928ada3.png" height=300px>

[Kotest](https://github.com/kotest/kotest)는 코틀린 진영에서 가장 많이 사용되는 테스트 프레임워크아다. 코틀린 DSL을 활용해 테스트 코드를 작성할 수 있으며 아래와 같은 기능들을 포함하고 있다.

- 다양한 테스트 레이아웃(String Spec, Describe Spec, Behavior Spec 등) 제공
- Kotlin DSL 스타일의 Assertion 기능 제공

Kotest를 사용하기 위해서는 아래와 같은 설정 / 의존성 추가가 필요하다.
```kotlin
test {
    useJUnitPlatform()
}

dependencies {
    testImplementation("io.kotest:kotest-runner-junit5:${Versions.KOTEST}")
    testImplementation("io.kotest:kotest-assertions-core:${Versions.KOTEST}")
}
```

Kotest는 테스트를 위한 많은 레이아웃을 제공한다.

- Annotation Spec
- Behavior Spec
- Describe Spec
- Fun Spec
- …

**Kotest Annotation Spec**

기존 Junit 방식과 가장 유사한 방식이다. 별 다른 장점이 없는 레이아웃이지만 Junit에서 Kotest로의 마이그레이션이 필요한 상황이라면 나쁘지 않은 선택이 될 수 있다.


```kotlin
internal class CalculatorAnnotationSpec: AnnotationSpec() {
    private val sut = Calculator()

    @Test
    fun `1과 2를 더하면 3이 반환된다`() {
        val result = sut.calculate("1 + 2")
        result shouldBe 3
    }

    @Test
    fun `식을 입력하면, 해당하는 결과값이 반환된다`() {
        calculations.forAll { (expression, answer) ->
            val result = sut.calculate(expression)
            result shouldBe answer
        }
    }

    @Test
    fun `입력값이 null 이거나 빈 공백 문자일 경우 IllegalArgumentException 예외를 던진다`() {
        blanks.forAll {
            shouldThrow<IllegalArgumentException> {
                sut.calculate(it)
            }
        }
    }

    @Test
    fun `사칙연산 기호 이외에 다른 문자가 연산자로 들어오는 경우 IllegalArgumentException 예외를 던진다 `() {
        invalidInputs.forAll {
            shouldThrow<IllegalArgumentException> {
                sut.calculate(it)
            }
        }
    }

    companion object {
        private val calculations = listOf(
            "1 + 3 * 5" to 20.0,
            "2 - 8 / 3 - 3" to -5.0,
            "1 + 2 + 3 + 4 + 5" to 15.0
        )
        private val blanks = listOf("", " ", "      ")
        private val invalidInputs = listOf("1 & 2", "1 + 5 % 1")
    }
}
```

**Kotest Behavior Spec**

기존 스프링 기반 프로젝트에서 작성하던 Given, When, Then 패턴을 Kotest Behavior Spec을 활용해 간결하게 정의할 수 있다.

```kotlin
internal class CalculatorBehaviorSpec : BehaviorSpec({
    val sut = Calculator()

    given("calculate") {
        val expression = "1 + 2"
        `when`("1과 2를 더하면") {
            val result = sut.calculate(expression)
            then("3이 반환된다") {
                result shouldBe 3
            }
        }

        `when`("수식을 입력하면") {
            then("해당하는 결과값이 반환된다") {
                calculations.forAll { (expression, answer) ->
                    val result = sut.calculate(expression)

                    result shouldBe answer
                }
            }
        }

        `when`("입력값이 null이거나 빈 값인 경우") {
            then("IllegalArgumentException 예외를 던진다") {
                blanks.forAll {
                    shouldThrow<IllegalArgumentException> {
                        sut.calculate(it)
                    }
                }
            }
        }

        `when`("사칙연산 기호 이외에 다른 연산자가 들어오는 경우") {
            then("IllegalArgumentException 예외를 던진다") {
                invalidInputs.forAll {
                    shouldThrow<IllegalArgumentException> {
                        sut.calculate(it)
                    }
                }
            }
        }
    }
}) {
    companion object {
        private val calculations = listOf(
            "1 + 3 * 5" to 20.0,
            "2 - 8 / 3 - 3" to -5.0,
            "1 + 2 + 3 + 4 + 5" to 15.0
        )
        private val blanks = listOf("", " ", "      ")
        private val invalidInputs = listOf("1 & 2", "1 + 5 % 1")
    }
}
```

**Kotest Describe Spec**

Kotest는 Describe Spec을 통해 DCI(Describe, Context, It) 패턴 형태의 레이아웃도 제공한다.

```kotlin

internal class CalculatorDescribeSpec : DescribeSpec({
    val sut = Calculator()

    describe("calculate") {
        context("식이 주어지면") {
            it("해당 식에 대한 결과값이 반환된다") {
                calculations.forAll { (expression, data) ->
                    val result = sut.calculate(expression)

                    result shouldBe data
                }
            }
        }

        context("0으로 나누는 경우") {
            it("Infinity를 반환한다") {
                val result = sut.calculate("1 / 0")

                result shouldBe Double.POSITIVE_INFINITY
            }
        }

        context("입력값이 null이거나 공백인 경우") {
            it("IllegalArgumentException 예외를 던진다") {
                blanks.forAll {
                    shouldThrow<IllegalArgumentException> {
                        sut.calculate(it)
                    }
                }
            }
        }

        context("사칙연산 기호 이외에 다른 문자가 연산자로 들어오는 경우") {
            it("IllegalArgumentException 예외를 던진다") {
                invalidInputs.forAll {
                    shouldThrow<IllegalArgumentException> {
                        sut.calculate(it)
                    }
                }
            }
        }
    }
}) {
    companion object {
        val calculations = listOf(
            "1 + 3 * 5" to 20.0,
            "2 - 8 / 3 - 3" to -5.0,
            "1 + 2 + 3 + 4 + 5" to 15.0
        )
        val blanks = listOf("", " ", "      ")
        val invalidInputs = listOf("1 & 2", "1 + 5 % 1")
    }
}
```

위와 같은 여러 레이아웃 중 프로젝트 상황에 가장 잘 맞는 레이아웃을 골라 사용하면 된다.

상황에 따라 [kotest 플러그인](https://kotest.io/docs/intellij/intellij-plugin.html)을 깔아야 test 실행 버튼이 나타날 수도 있다. 

---

## Kotest with @SpringBootTest

`@SpringBootTest`와 같은 통합 테스트에서도 Kotest의 테스트 레이아웃을 사용할 수 있다.

사용을 위해서는 아래와 같은 spring extension 의존성의 추가가 필요하다.

```kotlin
dependencies {
    testImplementation("io.kotest:kotest-extensions-spring:${Versions.KOTEST}")
}
```

```kotlin
@SpringBootTest
internal class CalculatorSpringBootSpec : DescribeSpec() {
    override fun extensions() = listOf(SpringExtension)

    @Autowired
    private lateinit var calculatorService: CalculatorService

    init {
        this.describe("calculate") {
            context("식이 주어지면") {
                it("해당 식에 대한 결과값이 반환된다") {
                    calculations.forAll { (expression, data) ->
                        val result = calculatorService.calculate(expression)

                        result shouldBe data
                    }
                }
            }
        }
    }

    companion object {
        private val calculations = listOf(
            "1 + 3 * 5" to 20.0,
            "2 - 8 / 3 - 3" to -5.0,
            "1 + 2 + 3 + 4 + 5" to 15.0
        )
    }
}
```

## Kotest Isolation Mode

Kotest는 테스트 간 격리에 대한 설정을 제공하고 있다.

- SingleInstance – Default
- InstancePerTest
- InstancePerLeaf

Kotest에서는 테스트 간 격리 레벨에 대해 디폴트로 SingleInstance를 설정하고 있는데, 이 경우 Mocking 등의 이유로 테스트 간 충돌이 발생할 수 있다. 따라서 테스트간 완전한 격리를 위해서는 아래와 같이 IsolationMode를 InstancePerLeaf로 지정해 사용해야 합니다.

```kotlin
internal class CalculatorDescribeSpec : DescribeSpec({
    isolationMode = IsolationMode.InstancePerLeaf
    // ...
})
```
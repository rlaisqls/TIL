
https://kotest.io/docs/framework/testing-styles.html

Kotest는 10가지 다른 스타일의 테스트 레이아웃을 제공한다. 그중 일부는, 다른 테스트 프레임워크와 비슷한 구조로 만들어지기도 했다.

스타일 간에 기능적인 차이는 없다. 스레드, 태그 등 모두 동일한 유형의 구성을 허용하지만, 이는 단순히 테스트를 구성하는 방법에 대한 선호도의 문제이다.

코테스트를 사용하려면 테스트 스타일 중 하나를 확장하는 클래스 파일을 만들어야 한다. 그런 다음 원하는 Spec (추상)클래스를 상속받고 init {} 블록 안에서 테스트 케이스를 작성하면 된다.

|테스트 스타일|유사한 테스트 프레임워크|
|-|-|
|Fun Spec|ScalaTest|
|String Spec|A Kotest original|
|Should Spec|A Kotest original|
|Describe Spec|Javascript frameworks과 RSpec|
|Behavior Spec|BDD frameworks|
|Word Spec|ScalaTest|
|Free Spec|ScalaTest|
|Feature Spec|Cucumber|
|Expect Spec|A Kotest original|
|Annotation Spec|JUnit|

---

## Fun Spec

FunSpec 테스트는 String으로 이름을 지정한다음 테스트 자체를 람다로 호출하여 테스트를 생성할 수 있다.

내용은 별다른 형식 없이 그냥 자유롭게 작성하고, 이름만 저런 식으로 지정해줄 수 있는 형식인 것 같다.

```kotlin
class MyTests : FunSpec({
    test("String length should return the length of the string") {
        "sammy".length shouldBe 5
        "".length shouldBe 0
    }
})
```

## String Spec

Fun Spec과 똑같은 방식이지만, `test()`로 묶어줄 필요 없이 바로 string과 람다를 써서 작성하는 Spec이다.

```kotlin
class MyTests : StringSpec({
    "strings.length should return size of string" {
        "hello".length shouldBe 5
    }
})
```

추가설정은 이런 식으로 할 수 있다.

```kotlin
class MyTests : StringSpec({
    "strings.length should return size of string".config(enabled = false, invocations = 3) {
        "hello".length shouldBe 5
    }
})
```

## Should Spec

ShouldSpec은 funSpec에서 `test`만 `should`로 바뀐 것이다.

```kotlin
class MyTests : ShouldSpec({
    should("return the length of the string") {
        "sammy".length shouldBe 5
        "".length shouldBe 0
    }
})
```

## Describe Spec

Describe Spec은 DCI 패턴으로 테스트코드를 작성할 수 있는 Spec이다.

describe에는 도메인 혹은 함수명, 어떻게 되는지를 각각 적으면 된다.

```kotlin
class MyTests : DescribeSpec({

    describe("score") {
        it("start as zero") {
            // test here
        }
        describe("with a strike") {
            it("adds ten") {
                // test here
            }
            it("carries strike to the next frame") {
                // test here
            }
        }

        describe("for the opposite team") {
            it("Should negate one score") {
                // test here
            }
        }
    }
})
```

Docs에 예시는 위와 같이 되어있지만, Describe Spec으로는 보통 중간에 context를 껴서 이런식으로 작성하는 경우가 많다.

JUnit5로 DCI 패턴을 쓰려면 [이렇게](https://johngrib.github.io/wiki/junit5-nested/) 해야하는데, Kotest를 쓰면 중첩테스트가 되니까 그냥 할 수 있다.

```kotlin
    describe("PASSWORD_EXP") {
        context("영어 대소문자, 영어, 특수문자가 포함된 8-30자의 문자열이 주어지면"){
            val string = "Password!1"
            it("참이 반환된다") {
                Pattern.matches(RegexUtil.PASSWORD_EXP, string) shouldBe true
            }
        }
    }
```

## Behavior Spec

우리가 보통 아는 `given`, `when`, `then` 패턴이다.

하지만 when이 Kotlin의 예약어이기 때문에 Behavior Spec을 사용할떄 backtick(`)으로 감싸서 사용해야한다. 그게 마음에 들지 않는 경우 Given, When, Then을 쓸 수도 있다.

```kotlin
class MyTests : BehaviorSpec({
    given("a broomstick") {
        `when`("I sit on it") {
            then("I should be able to fly") {
                // test code
            }
        }
        `when`("I throw it away") {
            then("it should come back") {
                // test code
            }
        }
    }
})
```


## Word Spec

WordSpec은 context 문자열 뒤에 테스트를 키워드 should를 사용하여 테스트를 작성한다.

```kotlin
class MyTests : WordSpec({
    "String.length" should {
        "return the length of the string" {
            "sammy".length shouldBe 5
            "".length shouldBe 0
        }
    }
})
```

또한 다른 수준의 중첩을 추가할 수 있는 When 키워드를 지원한다.

여기에서도 역시 when은 backtick(`) 또는 대문자 변형을 사용해야 한다.

```kotlin
class MyTests : WordSpec({
    "Hello" When {
        "asked for length" should {
            "return 5" {
                "Hello".length shouldBe 5
            }
        }
        "appended to Bob" should {
            "return Hello Bob" {
                "Hello " + "Bob" shouldBe "Hello Bob"
            }
        }
    }
})
```

## Free Spec

Free Spec에서는 키워드 `-`(빼기)를 사용하여 임의의 깊이 수준을 중첩할 수 있다.

```kotlin
class MyTests : FreeSpec({
    "String.length" - {
        "should return the length of the string" {
            "sammy".length shouldBe 5
            "".length shouldBe 0
        }
    }
    "containers can be nested as deep as you want" - {
        "and so we nest another container" - {
            "yet another container" - {
                "finally a real test" {
                    1 + 1 shouldBe 2
                }
            }
        }
    }
})
```

## Feature Spec

FeatureSpec은 feature, scenario를 사용한다. ([cucumber](https://cucumber.io/docs/gherkin/reference/)와 비슷하다)

```kotlin
class MyTests : FeatureSpec({
    feature("the can of coke") {
        scenario("should be fizzy when I shake it") {
            // test here
        }
        scenario("and should be tasty") {
            // test here
        }
    }
})
```

## Expect Spec

ExpectSpec은 FunSpec, ShouldSpec과 비슷하며, `expect` 키워드를 사용한다.

```kotlin
class MyTests : ExpectSpec({
    expect("my test") {
        // test here
    }
})
```

context 블록에 중첩하여 작성할 수도 있다.

```kotlin
class MyTests : ExpectSpec({
    context("a calculator") {
        expect("simple addition") {
            // test here
        }
        expect("integer overflow") {
            // test here
        }
    }
})
```

## Annotation Spec

JUnit과 동일한 방식이다. 별다른 이점은 없지만, 기존 형식을 그대로 가져올 수 있어 더 빠른 마이그레이션이 가능하다.

```kotlin
class  AnnotationSpecExample : AnnotationSpec () { 

    @BeforeEach fun beforeTest () {
         println ( " 각 테스트 전 " ) 
    } 
    @Test fun test1 () {
         1 shouldBe 1 
    } 
    @Test fun test2 () {
         3 shouldBe 3 
    } 
}
```
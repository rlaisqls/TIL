
Kotlin에서는 코틀린은 원시 타입(primitive type)과 래퍼 타입(wrapper type)을 따로 구분하지 않고, Null일 수 있는 타입과, Null이 불가능한 타입으로 나누어 사용한다.

널이 될 수 있는지 여부를 타입 시스템을 통해 확실히 구분함으로써 컴파일러가 여러 가지 오류를 컴파일 시 미리 감지해서 실행 시점에 발생할 수 있는 예외의 가능성을 줄일 수 있다.

또, null 처리를 위한 다양한 연산자를 지원한다.

<br>

---

### NULL이 될 수 있는 타입 `? !!`

코틀린의 모든 타입은 기본적으로 널이 될 수 없는 타입이다. 

타입 옆에 물음표(`?`)를 붙이면 널이 될 수 있음을 뜻한다.

느낌표 2개(`!!`)를 변수 뒤에 붙이면 NULL이 될 수 있는 타입의 변수이지만, 현재는 NULL이 아님을 나타낼 수 있다.

```kotlin
var a:Int? = null 
var b:Int? = 10
var c:Int = b!!
```
<br>

### 안전한 메서드 호출 `?.`

`?.`은 null 검사와 메서드 호출을 한 번의 연산으로 수행한다.

```kotlin
foo?.bar()
```

foo가 null이면 bar() 메서드 호출이 무시되고 null이 결과 값이 된다.<br>
foo가 null이 아니면 bar() 메서드를 정상 실행하고 결과값을 얻어온다.

<br>

### 엘비스 연산자 `?:`

null 대신 사용할 디폴트 값을 지정할때, 3항 연산자 대신 사용할 수 있는 연산자이다.

```kotlin
fun foo(s: String?) {
    val t: String = s ?: ""
}
```

우항에 return, throw 등의 연산을 넣을 수도 있다.

<br>

### 안전한 캐스트 `as?`

자바 타입 캐스트와 마찬가지로 대상 값을 as로 지정한 타입으로 바꿀 수 없다면 ClassCastException이 발생한다.
그래서 자바에서는 보통 is를 통해 미리 as로 변환 가능한 타입인지 검사해 본다.

as? 연산자는 어떤 값을 지정한 타입으로 캐스트하고, 변환할 수 없으면 null을 반환한다.

```kotlin
foo as? Type
```

foo is Type이면 foo는 Type으로 변환하고<br>
foo !is Type이면 null을 반환한다.

<br>

### `let{}`

let 함수를 안전한 호출 연산자와 함께 사용하면 원하는 식을 평가해서 결과가 널인지 검사한 다음에 그 결과를 변수에 넣는 작업을 간단한 식을 사용해 한꺼번에 처리할 수 있다.

```kotlin
fun sendEmailTo(email: String) {
    println("Sending email to $email")
}

fun main(args: Array<String>) {
    var email: String? = "yole@example.com"
//    sendEmailTo(email) -> error
    email?.let { sendEmailTo(it) }
}
```

코틀린을 사용할 때 변수를 선언하려면 아래와 같이 한다.

```kotlin
val 변수명: 타입
var 변수명: 타입
```

String을 써서 문자열 데이터를 집어넣는다면 아래와 같이 할 수 있다.

```kotlin
val name1: String = "kimeunbin"
val name2: String = "kimeunbin"
```

근데 val과 var의 차이는 무엇일까?

### val

`val`이 붙은 변수는 읽을 수만 있고 수정할 수는 없는 변수가 된다. 자바로 치면 final 키워드가 붙은 변수와 비슷하다.

```kotlin
fun main(args: Array<String>)
{
    val a: String = "aaa"
    a = "bbb" //에러가 난다! Val cannot be reassigned
}
```

### var

`val`가 붙은 변수는 읽기/쓰기가 모두 가능하다. 

```kotlin
fun main(args: Array<String>)
{
    var a: String = "aaa"
    a = "bbb"
    println(a)
}
```

성공적으로 재할당 되는 것을 볼 수 있다!
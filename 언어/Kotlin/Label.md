
Kotlin은 loop에 label을 지정해 break, continue 스코프를 정할 수 있다.

label은 @ 식별자를 통해 지정할 수 있고, @abc, fooBar@ 처럼 사용할 수 있다.

아래는 내부 for문에서 break 한 경우 -> 바깥의 for문 까지 종료 시키는 예제와, continue의 next iteration을 바깥 for문으로 지정하는 예제이다.

```java
fun labelReturnJump() {
    loop@ for (i in 1..10) { // label 지정 
        for (j in 1..10) {
            if (i + j > 12) {
                break@loop // label을 통해 break  
            }
        }
    }
}

fun labelContinue() {
    loop@ for (i in 1..10) {
        for (j in 1..10) {
            if (j > 2) {
                continue@loop
            }
        }
    }
}
```

## Return Labels

Label을 쓰지 않고 Lambda를 사용하는 경우 아래와 같은 문제가 있다. 아래의 코드에서 return은 foo 메소드 자체를 끝내버린다.

```java
fun foo() {
    listOf(1, 2, 3, 4, 5).forEach {
        if (it == 3) return // non-local return directly to the caller of foo()
        print(it)
    }
    println("this point is unreachable")
}
```

따라서 코틀린에서 람다의 경우 레이블을 이용해서 아래처럼 람다식만 종료시켜야한다.

```java
fun fooLabmdaReturn () {
    var ints = listOf<Int>(1, 2, 3, 4, 5)
    ints.forEach lambda@ {
        if (it == 1) return@lambda
        println(it)
    }
    println("this point is unreachable")
}
```

## 암시적 Label

매번 이렇게 작성하는 것은 귀찮으니 연산자 이름을 레이블로 활용하는 암시적 레이블도 지원한다.

```java
fun fooLambdaReturn() {
    var ints = listOf<Int>(1, 2, 3, 4, 5)
    ints.forEach{
        if (it == 1) return@forEach
        println(it)
    }
    println("this point is unreachable")
}

fun fooReturnLabelWithValue(): List<String> {
    var ints = listOf<Int>(1, 2, 3, 4, 5)
    return ints.map {
        if (it == 0) {
            return@map "zero"
        }
        "number $it"
    }
}
```

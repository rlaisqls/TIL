
코틀린에서 아래와 같은 방식으로 컬렉션을 사용할 수 있다.

```kotlin
val set = hashSetOf(1, 7, 53)
val list = arrayListOf(1, 7, 53)
val map = hashMapOf(1 to "one", 7 to "seven", 53 to "fifty-three")
```

자바의 컬렉션(`Set`,`List`,`Map`)과 동일한 구조이기 때문에 서로  호환된다.

코틀린의 컬렉션은 자바보다 더 많은 기능을 지원한다.

```kotlin
fun main(args: Array<String>) {
    val strings = listOf("first", "second", "fourteenth")
    println(strings.last()) // 리스트의 마지막 원소를 가져온다. 
    val numbers = setOf(1, 14, 2)
    println(numbers.max()) // 컬렉션에서 최댓값을 가져온다. 
}
```

### 불변 리스트

코틀린과 자바의 컬렉션은 서로 호환되지만 코틀린의 `List`가 자바의 `List`와 같은것은 아니다.

코틀린의 `List`는 한번 정의되면 그 이후로는 변경이 불가능한 불변(immutable) 리스트이며 `add`같은 메서드가 존재하지 않는다.

```kotlin
fun main(args:Array<String>){

    //list는 데이터를 읽는 메서드만 가지고있다.

    val list = listOf(1,2,3,"String")

    println(list.size)

    if(list.contains(1)){
        println(true)
    }else{
        println(false)
    }

    println(list.indexOf(2))

    println(list[2])
}
```

자바의 `list`처럼 읽기, 쓰기를 모두 사용하려면 `mutableList`로 선언해야한다.

참고로 kotlin에서도 ArrayList와 List의 개념은 동일하다.

```kotlin
public fun <T> listOf(vararg elements: T): List<T> = if (elements.size > 0) elements.asList() else emptyList()

public fun <T> mutableListOf(vararg elements: T): MutableList<T> =
    if (elements.size == 0) ArrayList() else ArrayList(ArrayAsCollection(elements, isVarargs = true))
```

`mutableListOf()`나 `listOf()`를 호출하면 ArrayList의 생성자를 호출해서 반환하는 것을 볼 수 있다.
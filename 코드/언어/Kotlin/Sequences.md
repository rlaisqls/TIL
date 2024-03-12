
Sequences는 Collections와 비슷하게 Iterable한 자료구조이다. 하지만 `Eager evaluation`으로 동작하는 Collections와 다르게 Sequences는 `Lazy evaluation`으로 동작한다.

### Lazy evaluation과 Eager evaluation의 차이

Lazy evaluation은 지금 하지 않아도 되는 연산은 최대한 뒤로 미루고, 어쩔 수 없이 연산이 필요한 순간에 연산을 수행하는 방식이다.

```kotlin
val fruits = listOf("apple", "banana", "kiwi", "cherry")

fruits
    .filter {
        println("checking the length of $it")
        it.length > 5
    }
    .map {
        println("mapping to the length of $it")
        "${it.length}"
    }
    .take(1)
```

```
//실행결과
checking the length of apple
checking the length of banana
checking the length of kiwi
checking the length of cherry
mapping to the length of banana
mapping to the length of cherry
```

Collections를 사용하면 `Eager evaluation`이기 떄문에 함수를 호출한대로 모든 과정을 수행한다.

실행결과를 보면 1개의 원소만 반환하지만 모두 순회하며 필터링, 매핑하는 모습을 볼 수 있다. 

```kotlin
val fruits = listOf("apple", "banana", "kiwi", "cherry")

fruits
    .asSequence()
    .filter {
        println("checking the length of $it")
        it.length > 5
    }
    .map {
        println("mapping to the length of $it")
        "${it.length}"
    }
    .take(1)
    .toList()
```

```
//실행결과
checking the length of apple
checking the length of banana
mapping to the length of banana
```

하지만 Sequence로 변환 후 사용하면 `Lazy evaluation`이기 떄문에 모든 과정을 수행하지 않고, 결과물 반환에 필요한 작업만 수행한다.

`.take(1)`로 설정되어있기 때문에 `filter()` 조건의 맞는 한개의 원소를 찾자마자 `map()`으로 넘어가 반환하는 것을 볼 수 있다.

심지어 마지막에 `.toList()`를 안 붙여주면 아무것도 실행되지 않는다.

이처럼, `Lazy evaluation`은 꼭 필요할 떄에만 연산하며, kotlin의 Sequence가 이러한 특성을 가진다.

### 결론

원소가 너무 많은 경우에는 Sequences로 연산하는 것이 성능에 큰 향상을 줄 수 있겠지만, 작은 배열에서는 그냥 Collections를 사용하는게 오히려 좋을 수도 있지 않을까 싶다.
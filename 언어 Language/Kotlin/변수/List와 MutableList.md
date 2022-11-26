# List와 MutableList

List는 수정이 불가능한 리스트이고, MutableList는 수정이 가능한 리스트이다.

내부 코드는 어떤 차이가 있을까?

```kotlin
public interface Collection<out E> : Iterable<E> {

    public val size: Int

    public fun isEmpty(): Boolean

    public operator fun contains(element: @UnsafeVariance E): Boolean

    override fun iterator(): Iterator<E>

    public fun containsAll(elements: Collection<@UnsafeVariance E>): Boolean

}

public interface MutableCollection<E> : Collection<E>, MutableIterable<E> {

    override fun iterator(): MutableIterator<E>

    public fun add(element: E): Boolean

    public fun remove(element: E): Boolean

    public fun addAll(elements: Collection<E>): Boolean

    public fun removeAll(elements: Collection<E>): Boolean

    public fun retainAll(elements: Collection<E>): Boolean

    public fun clear(): Unit

}
```

`Collection`은 공변이고 `MutableCollection`은 불공변이다.

공변은 Write가 안되는 대신에, 하위 클래스를 포함할 수 있다. 이러한 특성을 고려하여 개발하면 좋을 것 같다.


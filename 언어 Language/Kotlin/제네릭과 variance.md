
프로그래밍 언어들에서 제공해주는 기능 중 하나인 `제네릭`은 클래스나 인터페이스 혹은 함수 등에서 동일한 코드로 여러 타입을 지원해주기 위해 존재한다. 한가지 타입에 대한 템플릿이 아니라 **여러가지 타입**을 사용할 수 있는 클래스와 같은 코드를 간단하게 작성할 수 있다.

## 예시

```kotlin
class Wrapper<T>(var value: T)

fun main(vararg args: String) {
    val intWrapper = Wrapper(1)
    val strWrapper = Wrapper<String>("1")
    val doubleWrapper = Wrapper<Double>(0.1)
}
```

`Wrapper`라는 클래스는 꺽쇠안에 `T`라는 형식 인자(Type paraameter)를 가진다. 그곳에는 `Int`, `String`, `Double`등 여러 형식이 저장될 수 있다.

```kotlin
fun <T : Comparable<T>> greaterThan(lhs: T, rhs: T): Boolean {
    return lhs > rhs
}
```

함수에 제네릭을 적용한 예시이다. `Comparable` 을 구현한 형식 인자만 `>` 연산자를 사용할 수 있기 때문에 꺽쇠 안의 T의 선언에 `Comparable<T>` 를 구현했다는 것을 표시해주었다.

흔하게 사용되는 Kotlin의 컬렉션들인 `List`, `MutableList`, `Set`, `MutableSet`, `Map`등도 초기화될 때 제네릭으로 타입을 넣는다. 혹은 타입 추론이 될 수도 있다. (ex: listOf(1,2)가 자동으로 List<Int>로 추론됨)

# Invariance

제네릭을 사용할 때 가장 헷갈리는 부분은 variance이다. 자바에선 와일드 카드(Wild card)라고 불리는 기능과 비슷하다.

자바에서 `String`은 `Object`의 subType이다. 그러나 `List<String>`은 `List<Object>`의 subType이 아니다. 

```kotlin
val strs: MutableList<String> = mutableListOf()

//val objs: MutableList<Object> = strs 에러발생
```
    
두번째 줄과 같은 코드는 에러 발생으로 인해 실행될 수 없다. 만약 `MutableList<String>` 이 `MutableList<Object>`의 subType이면 2번째 줄이 에러가 발생하지 않아야 한다. 

이렇게 형식 인자들끼리는 sub type 관계를 만족하더라도 제네릭을 사용하는 클래스와 인터페이스에서는 subType 관계가 유지되지 않는 것이 **Invariance**(불공변)이다. 기본적으로 코틀린의 모든 제네릭에서의 형식 인자는 Invariance이 된다.

## Invariance의 한계

Invariance는 컴파일 타임 에러를 잡아주고 런타임에 에러를 내지않는 안전한 방법이다. 그러나, 안전하다고 보장된 상황에서도 컴파일 에러를 내 개발자를 불편하게 할 수도 있다.

```java
interface Collection<E> ... {
  void addAll(Collection<E> items);
}
void copyAll(Collection<Object> to, Collection<String> from) {
  to.addAll(from);
  //addAll은 Invariance여서 to의 addAll에 from을 전달할 수 없다!
}
```

to는 `Collection<Object>`고 from은 `Collection<String>`이다. String을 Object로 취급하여, `String`만 사용할 수 있는 메서드나 속성을 사용하지 않을 것이라면 이 코드는 문제될게 없다. 하지만 이 코드는 컴파일 에러가 발생한다.

## Java Wildcard, Covariance, Contravariance

이를 해결하기위해 자바에서는 Wildcard가 등장한다. 제네릭 형식 인자 선언에 `? extends E`와 같은 문법을 통해 `E`나 `E`의 subType의 제네릭 형식을 전달받아 사용할 수 있다.

```java
interface Collection<E> ... {
  void addAll(Collection<? extends E> items);
}
```

만약 Collection의 코드가 이런 형식으로 되어있다고 가정해보자.

items엔 E일수도 있고 E의 sub type일 수도 있는 아이템들이 들어있을 것이다.  여기서 어떤 아이템을 꺼내든(읽든) 그것은 E라는 형식안에 담길 수 있다.

그러나 `items`에 어떤 값을 추가하려면 `items`의 형식 인자인 ?가 어떤 것인지를 알아야한다. 하지만 그 인자가 무엇인지 정확히 알 수 없기 떄문에 값을 추가할 수 없다. 예를 들어 `items`가 `Collection<? extends Object>`라면 `items`에서 우리는 어떤 아이템을 꺼내서 그것을 `Object` 타입 안에 담을 수 있다. 그러나 `Object`를 `items`에 넣을 수는 없다. 왜냐하면 **전달된 `items`가 `Collection<String>`일 수도 있고 `Collection<Object>`일 수도 있기 때문**이다.

읽기만 가능하고 쓰기는 불가능한 `? extends E 는` 코틀린에서의 out과 비슷한 의미로 사용되고 이런 것들을 **covariance**(공변)이라 부른다.

반대로 읽기는 불가능하고 쓰기만 가능한, 자바에선 `? super E` 로 사용되고 코틀린에선 `in` 으로 사용되는 **contravariance**(반공변)이 있다.

**contravariance**에서는 `E`와 같거나 `E의 상위타입`만 `?` 자리에 들어올 수 있다. items이 `Collection<? super E>` 라면, `items`에서 어떤 변수를 꺼내도 `E`에 담을 수 있을 지 보장할 수 없지만(읽기 불가) `E`의 상위 타입 아무거나 `items`에 넣을 수 있기 때문에 **covariance와 반대**된다고 생가하면 된다.

## 정리

|정리|설명|java|kotlin|
|-|-|-|-|
|Invariance(불공변)|제네릭으로 선언한 타입과 일치하는 클래스만 삽입할 수 있다.|`<T>`|`<T>`|
|Covariance(공변)|**특정 클래스를 상속받은 하위클래스들**을 리스트로 선언할 수 있다.<br>하지만 해당 리스트의 타입을 특정할 수 없기 때문에 **Write가 불가능**하다.|`<? extends T>`|`<out T>`|
|Contravariance(반공변)|**특정 클래스의 상위 클래스들**을 리스트로 선언할 수 있다.<br>하지만 꺼낼 인스턴스가 어떤 타입인지 알 수 없기 때문에 Read가 불가능하다.|`<? super T>`|`<in T>`|


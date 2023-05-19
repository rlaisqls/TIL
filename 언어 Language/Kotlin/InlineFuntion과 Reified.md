# Inline-Funtions과 Reified

`inline` 키워드는 자바에서는 제공하지 않는 코틀린만의 키워드이다.

코틀린 공식문서의 [inline function](https://kotlinlang.org/docs/inline-functions.html)을 보면, 코틀린에서 고차함수(High order functions, 함수를 인자로 전달하거나 함수를 리턴)를 사용하면 패널티가 발생한다고 나와있다.

패널티란 추가적인 메모리 할당 및 함수호출로 Runtime overhead가 발생한다는 것으로, 람다를 사용하면 각 함수는 객체로 변환되어 메모리 할당과 가상 호출 단계를 거치는데 여기서 런타임 오버헤드가 발생한다.

inline functions는 내부적으로 함수 내용을 호출되는 위치에 복사하며, Runtime overhead를 줄여준다.

## 객체로 변환되는 오버헤드란?

아래와 같은 고차함수(함수를 인자로 전달하거나 함수를 리턴하는 함수)를 컴파일 하면 자바 파일이 생성된다.

```kotlin
fun doSomethingElse(lambda: () -> Unit) {
    println("Doing something else")
    lambda()
}
```

컴파일된 자바 코드는 Functional Interface인 Function 객체를 파라미터로 받고 invoke 메서드를 실행한다.

그러면 이제 위에서 선언한 메소드를 이용해 또 다른 메서드를 만들어보자.

doSomethingElse를 실행 하기전 출력문을 실행 후 함수를 호출하며 파라미터로 { println("Inside lambda") } 람다식을 넣었다.

```kotlin
fun doSomething() {
    println("Before lambda")
    
    doSomethingElse {
        println("Inside lambda")
    }
    
    println("After lambda")
}
```

위 코드를 자바로 컴파일 하면 아래와 같이 된다.

```java
public static final void doSomething() {
    System.out.println("Before lambda");
    
    doSomethingElse(new Function() {
        public final void invoke() {
            System.out.println("Inside lambda");
        }
    });
    
    System.out.println("After lambda");
}
```

이 코드의 문제점은 파라미터로 매번 새로운(`new Function()`)객체를 만들어 넣어준다는 것이다. 이렇게 의미없이 객체로 변환되는 코드가 바로 **객체로 변환되는 오버헤드이자 패널티**이다.

## Inline-Funtions 으로 오버헤드 해결하기

메소드 앞에 `inline`를 붙이면 이렇게 된다.

```java
inline fun doSomethingElse(lambda: () -> Unit) {
   println("Doing something else")
   lambda()
}

public static final void doSomething() {
    System.out.println("Before lambda");
    System.out.println("Doing something else");
    System.out.println("Inside lambda");
    System.out.println("After lambda");
}
```

위 자바 컴파일 코드를 보면 새로운 객체를 생성하는 부분이 사라지고
- `System.out.println("Doing something else");`
- `System.out.println("Inside lambda");`
두 코드로 변경된 것을 알 수있다.

## Reified

범용성 좋은 메소드를 만들기 위해 generics <T> 를 사용할 때가 있다.

이떄 inline과 함께 refied 키워드를 사용하면 Generics를 사용하는 메소드 까지 처리할 수 있다.

```kotlin
fun <T> doSomething(someValue: T)
```

이러한 class Type `T` 객체는 원래 타입에 대한 정보가 런타임에서 `Type Erase` 되어버려 알 수 없어져서, 실행하면 에러가 난다.

따라서 Class를 함께 넘겨 type을 확인하고 casting 하는 과정을 거치곤한다.

```kotlin
  // runtime에서도 타입을 알 수 있게 Class<T> 넘김
fun <T> doSomething(someValue: T, Class<T> type) { 
    // T의 타입을 파라미터를 통해 알기에 OK
    println("Doing something with value: $someValue")  
    // T::class 가 어떤 class인지 몰라서 Error
    println("Doing something with type: ${T::class.simpleName}") 
}
```

인라인(inline) 함수와 reified 키워드를 함께 사용하면 T type에 대해서 런타임에 접근할 수 있게 해준다.

따라서 타입을 유지하기 위해서 Class와 같은 추가 파라미터를 넘길 필요가 없어진다.

```kotlin
//reified로 런타임시 T의 타입을 유추 할 수있게됨
inline fun <reified T> doSomething(someValue: T) {
  // OK
  println("Doing something with value: $someValue")              
  // T::class 가 reified로 인해 타입을 알 수 있게되어 OK
  println("Doing something with type: ${T::class.simpleName}")    
}
```

inline keyword는 1~3줄 정도 길이의 함수에 사용하는 것이 효과적일 수 있다.

## noinline

인자 앞에 noinline 키워드를 붙이면 해당 인자는 inline에서 제외된다. 따라서 noinline 키워드가 붙은 인자는 다른 함수의 인자로 전달하는 것이 가능하다.

```kotlin
inline fun doSomething(action1: () -> Unit, noinline action2: () -> Unit) {
    action1()
    anotherFunc(action2)
}

fun anotherFunc(action: () -> Unit) {
    action()
}

fun main() {
    doSomething({
        println("1")
    }, {
        println("2")
    })
}
```


## cross inline

crossinline은 lambda 가 non-local return 을 허용하지 않아야 한다는 것을 이야기한다. inline 되는 higher order function 에서 lambda 를 소비하는 것이 아니라 다른 곳으로 전달할 때 마킹을 해준다.

```kotlin
inline fun foo(crossinline f: () -> Unit) {
    /**
     * 다른 고차함수에서 func를 호출시엔 crossinline 을 표시해주어야 함.
     */
    bar { f() }
}

fun bar(f: () -> Unit) {
    f()
}
```
 
예제를 보면 f lambda 는 바로 소비되지 않고, boo 로 한번 더 전달이 된다.

전달이 되지 않는다면 inline 함수이기 때문에 non-local return 이 허용되지만, 한번 더 전달되므로 non-local return을 할 수 없게 되고, 이것을 명시적으로 알리기 위해(함수 사용자 & compiler) crossinline 으로 마킹해준다.
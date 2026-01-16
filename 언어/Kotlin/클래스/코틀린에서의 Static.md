
코틀린에는 static 키워드가 없다. 자바와 같이 정적 변수 혹은 메서드를 사용하려면 다른 방법을 사용해야한다.

### 클래스 외 필드 선언

```java
package foo.bar;

class Foo {

    public static final String BAR = "bar";

    public static void baz() {
        // Do something
    }
}
```

자바에서 static을 사용해서 위와 같이 작성해야할떄, 코틀린에선 이렇게 사용할 수 있다.

```kotlin
package foo.bar

const val BAR = "bar"

fun baz() {
    // Do something
}
```

위와 같이 Foo.kt 파일에 정의한 속성 및 함수는 **자바**에서 각각 FooKt.BAR 및 FooKt.baz()로 접근할 수 있다. Top level에 속성이나 함수 선언이 있으면 뒤에 kt라는 접미사가 자동으로 추가되기 때문이다.

단, 이러한 규칙을 무시하고 자신이 원하는 이름으로 생성되도록 하려면 파일의 맨 첫 줄에 `@file:JvmName(name: String)`을 사용하면 된다.

만약 원한다면, 파일 내에 함수/필드 + 클래스를 정의할 수도 있다.

```kotlin
package foo.bar

const val BAR = "bar"

fun baz() {
    // Do something
}

// Foo 클래스 선언
class Foo {
    ...
}
```

하지만, 이렇게 할 경우에도 **자바**에서 Foo.kt 파일에 정의한 속성 및 함수에 접근하려면  각각 FooKt.BAR 및 FooKt.baz()로 접근해야한다.

### companion object

companion object를 사용하면 위에서 나열했던 문제 없이 자바에서 정적 변수/메서드를 사용했던 것과 동일하게 사용할 수 있다.

```kotlin
class Foo {

    companion object {

        const val BAR = "bar"

        fun baz() {
            // Do something
        }
    }
}
```

companion object 내에 선언된 속성과 함수는 {클래스 이름}.{필드/함수 이름} 형태로 바로 호출할 수 있다. 즉, 위의 Foo클래스 내 companion object에 선언된 baz() 함수는 다음과 같이 호출 가능하다.
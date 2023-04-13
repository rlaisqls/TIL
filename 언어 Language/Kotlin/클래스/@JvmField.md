# @JvmField

`@JvmField`는 get/set을 생성하지 말라는 의미이다.

다음 코틀린 코드에서 프로퍼티 var barSize는 getter/setter를 생성한다.

```kotlin
class Bar {
    var barSize = 0
}
```

자바로 변환해보면 getter/setter가 생성된 것을 볼 수 있다.

```java
public final class Bar {
   private int barSize;
   public final int getBarSize() {
      return this.barSize;
   }
   public final void setBarSize(int var1) {
      this.barSize = var1;
   }
}
```

이번엔 `@JvmField`를 붙여보자

```kotlin
class Bar {
   @JvmField
   var barSize = 0
}
```

자바로 변환해보면 getter/setter가 생성되지 않은 것을 볼 수 있다.

```java
public final class Bar {
   @JvmField
   public int barSize;
}
```
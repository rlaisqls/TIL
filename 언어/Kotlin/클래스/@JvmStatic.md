
함수와 프로퍼티에 static 하게 접근할 수 있도록 추가적인 메서드 또는 getter / setter 를 생성한다.

다음 Bar 클래스는 barSize라는 변수를 companion object에 선언함으로써, 전역변수를 만들었다.

```kotlin
class Bar {
    companion object {
        var barSize : Int = 0
    }
}
```

자바로 변환해보면 Bar클래스에 barSize는 선언되었지만 getter/setter는 Bar.Companion 클래스에 등록된 것을 볼 수 있다.

```java
public final class Bar {
   private static int barSize;
   public static final class Companion {
      public final int getBarSize() {
         return Bar.barSize;
      }
      public final void setBarSize(int var1) {
         Bar.barSize = var1;
      }
   }
}
```

자바에서 get/set 함수에 접근하려면 다음처럼 Companion을 꼭 써줘야 한다.

```java
Bar.Companion.getBarSize();
Bar.Companion.setBarSize(10);
```

static과 companion object가 다르다고 하는 이유가 바로 이것이다. kotlin만 사용할때는 다른 것이 없지만, java와 kotlin을 같이 사용하는 경우에는 이 부분에서 차이가 생긴다.

companion object를 static처럼 사용하려면 `@JvmStatic`을 사용해야한다.

```kotlin
class Bar {
    companion object {
        @JvmStatic var barSize : Int = 0
    }
}
```

자바로 변환해보면 Bar클래스에 barSize가 선언되었고, Bar클래스와 Bar.Companion 클래스에 get/set함수가 모두 생성된 것을 볼 수 있다.

```java
public final class Bar {
   private static int barSize;
   public static final int getBarSize() {
      return barSize;
   }

   public static final void setBarSize(int var0) {
      barSize = var0;
   }

   public static final class Companion {
      public final int getBarSize() {
         return Bar.barSize;
      }
      public final void setBarSize(int var1) {
         Bar.barSize = var1;
      }
   }
}
```

자바에서 위 코드를 접근하면 Bar.Companion 도 가능하지만 Bar.getBarSize 처럼 바로 접근도 된다.

```java
Bar.getBarSize();
Bar.setBarSize(10);
Bar.Companion.getBarSize();
Bar.Companion.setBarSize(10);
```

@JvmStatic를 사용하면 클래스도 마찬가지로 `Companion` 키워드 없이 접근할 수 있다.

정리하자면, @JvmStatic는 Companion에 등록된 변수를 자바의 static처럼 선언하기 위한 annotation이다.
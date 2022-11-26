# Sealed Class/interface

### Sealed Classe 와 Enum Classe 의 공통점

Sealed Classe와 Enum Class는 모두 하나의 클래스로 여러 가지 상태를 열거할 때 사용한다.
예를 들어, API 통신 결과를 핸들링하고 싶을 때 사용하는데 sealed class 경우 아래와 같이 소스코드를 작성한다.

예를 들어, sealed class를 사용하면  다음과 같이 API 통신 결과를 핸들링 하기 위해 사용할 수 있다.

```kotlin
sealed class Resource<T>(val data: T? = null, val message: String? = null) {
	class Success<T>(data: T) : Resource<T>(data)
    class Loading<T>(data: T? = null) : Resource<T>(data)
    class Error<T>(message: String, data: T? = null) : Resource<T>(message, data)
}
```

### Sealed Class 와 Enum Class 의 차이점

Sealed Class 는 위의 소스코드에서 정의한 것 처럼 class 를 포함해 자식 클래스를 세 가지로 분류한다.
- Object 
    상태를 특정하는 변수가 필요하지 않은 경우 메모리 관리를 위해 singleton 기법으로 하나의 객체만을 생성하기 위한 object class
- Class
    Sealed class 에서 정의한 변수를 사용할 수 있는 일반적인 class
- Data class
    Sealed class 에서 정의한 변수 이외에 특정한 상태를 표현하기 위한 변수를 새로 정의할 수 있는 data class

Enum Class에서는 그냥 Object 타입의 요소만 추가할 수 있지만, Sealed Cless를 사용하면 더 다양하게 활용할 수 있다.

```kotlin
sealed class HttpError(val code: Int) {
	data class Unauthorized(val reason: String) : HttpError(401)
    object NotFound : HttpError(404)
}
```

```kotlin
enum class HttpErrorEnum(val code: Int) {
	Unauthorized(401),
    NotFound(404)
}
```

```java
@Metadata("")
public abstract class HttpError {
   private final int code;

   public final int getCode() {
      return this.code;
   }

   private HttpError(int code) {
      this.code = code;
   }

   // $FF: synthetic method
   public HttpError(int code, DefaultConstructorMarker $constructor_marker) {
      this(code);
   }

   @Metadata("")
   public static final class Unauthorized extends HttpError {
      @NotNull
      private final String reason;

      @NotNull
      public final String getReason() {
         return this.reason;
      }

      public Unauthorized(@NotNull String reason) {
         Intrinsics.checkNotNullParameter(reason, "reason");
         super(401, (DefaultConstructorMarker)null);
         this.reason = reason;
      }

      @NotNull
      public final String component1() {
         return this.reason;
      }

      @NotNull
      public final Unauthorized copy(@NotNull String reason) {
         Intrinsics.checkNotNullParameter(reason, "reason");
         return new Unauthorized(reason);
      }

      // $FF: synthetic method
      public static Unauthorized copy$default(Unauthorized var0, String var1, int var2, Object var3) {
         if ((var2 & 1) != 0) {
            var1 = var0.reason;
         }

         return var0.copy(var1);
      }

      @NotNull
      public String toString() {
         return "Unauthorized(reason=" + this.reason + ")";
      }

      public int hashCode() {
         String var10000 = this.reason;
         return var10000 != null ? var10000.hashCode() : 0;
      }

      public boolean equals(@Nullable Object var1) {
         if (this != var1) {
            if (var1 instanceof Unauthorized) {
               Unauthorized var2 = (Unauthorized)var1;
               if (Intrinsics.areEqual(this.reason, var2.reason)) {
                  return true;
               }
            }

            return false;
         } else {
            return true;
         }
      }
   }

   @Metadata(
      mv = {1, 6, 0},
      k = 1,
      d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\bÆ\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002¢\u0006\u0002\u0010\u0002¨\u0006\u0003"},
      d2 = {"Lcom/example/helloworld/domain/HttpError$NotFound;", "Lcom/example/helloworld/domain/HttpError;", "()V", "helloworld-application"}
   )
   public static final class NotFound extends HttpError {
      @NotNull
      public static final NotFound INSTANCE;

      private NotFound() {
         super(404, (DefaultConstructorMarker)null);
      }

      static {
         NotFound var0 = new NotFound();
         INSTANCE = var0;
      }
   }
}

```
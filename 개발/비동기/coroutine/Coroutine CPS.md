# Coroutine CPS(Continuation-Passing-Style)

Kotlin coroutines are managed at the JVM level using the concept of **"continuations."** Continuations are a programming technique that allows suspending the execution of a function at a certain point and resuming it later from where it left off. Coroutines build upon this concept to provide a high-level and efficient way to write asynchronous code.

## Continuation

When a code with suspend is converted to bytecode, a parameter is added to the end of the function to convert it into handing over an object called Continuation.

```kotlin
// suspend fun createPost(token: Token, item: Item): Post { … }
     ↓
// Java/JVM 
Object createPost(Token token, Item item, Continuation<Post> cont) { … }
```

When such a suspend function is called from the coroutine, the execution information at that time is cached by making it a `Continuation` object, and when the execution is resumed (Resume), the execution is resumed based on the stored execution information.

```kotlin
/**
 * Interface representing a continuation after a suspension point that returns a value of type `T`.
 */
@SinceKotlin("1.3")
public interface Continuation<in T> {
    /**
     * The context of the coroutine that corresponds to this continuation.
     */
    public val context: CoroutineContext

    /**
     * Resumes the execution of the corresponding coroutine passing a successful or failed [result] as the
     * return value of the last suspension point.
     */
    public fun resumeWith(result: Result<T>)
}
```

Continuation is just a geneeric callback that any suspending function actually uses behind the scenes. You can't see it, every time you call the suspend function, it's actually called back.

## Labels

It also performs labeling for recognized callback points. The Kotlin compiler checks and labels the suspension points, as they require suspension points when resuming.

```kotlin
    suspen fun postItem(item: Item) {
    // LABEL 0
       val token = requestToken()
    // LABEL 1
       val post = createPost(token, item)
    // LABEL 2
        processPost(post)
    }
```

```kotlin
fun postItem(item: Item, cont: Continuation) {
    
    val sm = cont as? ThisSM ?: object : ThisSM {
        fun resume(…) {
            postItem(null, this)
        }
    }

    switch (sm.label) {
        case 0:
            sm.item = item
            sm.label = 1
            requestToken(sm)
        case 1:
            createPost(token, item, sm)
        …
    }
}
```

`sm` on the above code means `state machine`, the state (the result of the operations done so far) when each function is called.

This `state machine` is eventually **Continuation**, and Corutin operates internally as Continuation passes in a form with some information value. This style is called as **continuation-passing style (CPS)**.

Each suspend function takes Continuation (sm in the code above) as the last parameter, so :

- if `requestToken(sm)` is completed, `resume()` is called in `sm(continuation)`.
- The `createPost(token, item, sm)` is called again, and even when it is completed, the form of calling `resume()` to `sm(continuation)` is repeated.
  
So what is `resume()` for? In the code above, `resume()` is what eventually calls itself. (`postItem(…)` Inside the postItem(…) is being recalled.)

- For example, when the operation of suspend function `requestToken(sm)` is finished, `postItem(…)` again through `resume()` is called, which increases the Label value by one so that another case is called. In this case, internally, it is as if the suspend function is called and then the next case, and then the next case.

## Decompile the code

```kotlin
fun main(): Unit {
    GlobalScope.launch {
        val userData = fetchUserData()
        val userCache = cacheUserData(userData)
        updateTextView(userCache)
    }
}

suspend fun fetchUserData() = "user_name"

suspend fun cacheUserData(user: String) = user

fun updateTextView(user: String) = user

```

Let's make the above code into Kotlin's byte code, then decompose it into Java code.

<img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/43e93bf8-b0e6-47c8-bcf7-259486484487" height="400px"/>

```kotlin
public final class Example_nomagic_01Kt {
   public static final void main() {
      BuildersKt.launch$default((CoroutineScope)GlobalScope.INSTANCE, (CoroutineContext)null, (CoroutineStart)null, (Function2)(new Function2((Continuation)null) {
         int label;

         @Nullable
         public final Object invokeSuspend(@NotNull Object $result) {
            Object var10000;
            label17: {
               Object var4 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
               switch(this.label) {
               case 0:
                  ResultKt.throwOnFailure($result);
                  this.label = 1;
                  var10000 = Example_nomagic_01Kt.fetchUserData(this);
                  if (var10000 == var4) {
                     return var4;
                  }
                  break;
               case 1:
                  ResultKt.throwOnFailure($result);
                  var10000 = $result;
                  break;
               case 2:
                  ResultKt.throwOnFailure($result);
                  var10000 = $result;
                  break label17;
               default:
                  throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
               }

               String userData = (String)var10000;
               this.label = 2;
               var10000 = Example_nomagic_01Kt.cacheUserData(userData, this);
               if (var10000 == var4) {
                  return var4;
               }
            }

            String userCache = (String)var10000;
            Example_nomagic_01Kt.updateTextView(userCache);
            return Unit.INSTANCE;
         }

         @NotNull
         public final Continuation create(@Nullable Object value, @NotNull Continuation completion) {
            Intrinsics.checkNotNullParameter(completion, "completion");
            Function2 var3 = new <anonymous constructor>(completion);
            return var3;
         }

         public final Object invoke(Object var1, Object var2) {
            return ((<undefinedtype>)this.create(var1, (Continuation)var2)).invokeSuspend(Unit.INSTANCE);
         }
      }), 3, (Object)null);
   }

   // $FF: synthetic method
   public static void main(String[] var0) {
      main();
   }

   @Nullable
   public static final Object fetchUserData(@NotNull Continuation $completion) {
      return "user_name";
   }

   @Nullable
   public static final Object cacheUserData(@NotNull String user, @NotNull Continuation $completion) {
      return user;
   }

   @NotNull
   public static final String updateTextView(@NotNull String user) {
      Intrinsics.checkNotNullParameter(user, "user");
      return user;
   }
}
```

It can be seen that functions that were suspend functions were changed to general functions and Continuation was included as the last parameter.

---

reference
- https://www.youtube.com/watch?v=YrrUCSi72E8&t=110s
- https://kotlinlang.org/spec/asynchronous-programming-with-coroutines.html#suspending-functions

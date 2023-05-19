# Integration

```kotlin
interface Service {
    fun savePost(token: Token, item: Item): Call<Post>
}

suspend fun createPost(token: Token, item: Item): Post = 
    serviceInstance.savePost(token, item).await()
```

Let's say you want to use Coroutine with code that used futur (which corresponds to several libraries such as reactor). We are going to call 'savePost' which returns the future 'Call<Post>' from 'createPost'.

If so, we need the conversion code as below.

```kotlin
suspend fun <T> Call<T>.await(): T {
    ...
}
```

How to implement it?

---

Any kind of synchronous future has a method to install callback. For example retrofit, there's in queue. 

```kotlin
suspend fun <T> Call<T>.await(): T {
    enqueue(object : Callback<T> {
        override fun onResponse(call: Call<T>, response: Response<T>) {
            // todo
        }
        override fun onFailure(call: Call<T>, t: Throwable) {
            // tode
        }
    })
}
```

But every callback having defferent futures call is a different way. Then make different name of each function, implementation and using will complicated.

Standard library in coroutine provides a function all suspendCorouine. That's exactly the building block that were using to implement all those ways for all dfferent kinds of future.

```kotlin
suspend fun <T> Call<T>.await(): T = suspendCoroutine { cont ->
    enqueue(object : Callback<T>) {
        override fun onResponse(call: Call<T>, response: Response<T>) {
            if (response.isSuccessful)
                cont.resume(response.body()!!)
            else
                cont.resumeWithException(ErrorResponse(response))
        }
        override fun onFailure(call: Call<T>, t: Throwable) {
            cont.resumeWithException(t)
        }
    }
}
```

let's take a closer look at what's at that is.

## suspendCoroutine

```kotlin
/**
 * Obtains the current continuation instance inside suspend functions and suspends
 * the currently running coroutine.
 *
 * In this function both [Continuation.resume] and [Continuation.resumeWithException] can be used either synchronously in
 * the same stack-frame where the suspension function is run or asynchronously later in the same thread or
 * from a different thread of execution. Subsequent invocation of any resume function will produce an [IllegalStateException].
 */
@SinceKotlin("1.3")
@InlineOnly
public suspend inline fun <T> suspendCoroutine(crossinline block: (Continuation<T>) -> Unit): T {
    contract { callsInPlace(block, InvocationKind.EXACTLY_ONCE) }
    return suspendCoroutineUninterceptedOrReturn { c: Continuation<T> ->
        val safe = SafeContinuation(c.intercepted())
        block(safe)
        safe.getOrThrow()
    }
}
```

Inside of it is just regular lambda that doesn't have a suspend modifier. so it is kind of reverse separation to coroutine builder. so when you launch a croutine by regular function and you want turn into suspending lambda, can use this.

This atually inspired by the operator that named call with current continuation in the Lisp FEM language called scheme.

---
reference
- https://www.youtube.com/watch?v=YrrUCSi72E8&t=110s
- https://en.wikipedia.org/wiki/Call-with-current-continuation
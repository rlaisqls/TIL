# Coroutine Dispatcher

Coroutines always execute in some context represented by a value of the [CoroutineContext](Coroutine%E2%80%85Scope%2C%E2%80%85Context.md) type, defined in the Kotlin standard library.

The coroutine context is a set of various elements. The main elements are the Job of the coroutine, which we've seen before, and its dispatcher, which is covered in this section.

The coroutine context includes a coroutine dispatcher **that determines what thread or threads the corresponding coroutine uses for its execution.** The coroutine dispatcher can confine coroutine execution to a specific thread, dispatch it to a thread pool, or let it run unconfined.

It is declared as base class to be extended by all coroutine dispatcher implementations.

<details>
<summary>Coroutine Dispatcher's code</summary>

(Actually, this below code and java doc has a many information. The contents to be discussed below are described, I think read this is very useful to additional understanding.)

**java doc**

Base class to be extended by all coroutine dispatcher implementations.

The following standard implementations are provided by `kotlinx.coroutines` as properties on the [Dispatchers] object:

- [Dispatchers.Default] is used by all standard builders if no dispatcher or any other [ContinuationInterceptor] is specified in their context. It uses a common pool of shared background threads.
This is an appropriate choice for compute-intensive coroutines that consume CPU resources.
- [Dispatchers.IO] : uses a shared pool of on-demand created threads and is designed for offloading of IO-intensive `_blocking_` operations (like file I/O and blocking socket I/O).
- [Dispatchers.Unconfined] &mdash; starts coroutine execution in the current call-frame until the first suspension, where upon the coroutine builder function returns. The coroutine will later resume in whatever thread used by the corresponding suspending function, without confining it to any specific thread or pool. The `Unconfined` dispatcher should not normally be used in code**.
- Private thread pools can be created with [newSingleThreadContext] and [newFixedThreadPoolContext].
- An arbitrary [Executor][java.util.concurrent.Executor] can be converted to a dispatcher with the [asCoroutineDispatcher] extension function.
- This class ensures that debugging facilities in [newCoroutineContext] function work properly.

**code**

```kotlin
public abstract class CoroutineDispatcher :
    AbstractCoroutineContextElement(ContinuationInterceptor), ContinuationInterceptor {

    /** @suppress */
    @ExperimentalStdlibApi
    public companion object Key : AbstractCoroutineContextKey<ContinuationInterceptor, CoroutineDispatcher>(
        ContinuationInterceptor,
        { it as? CoroutineDispatcher })

    /**
     * Returns `true` if the execution of the coroutine should be performed with [dispatch] method.
     * The default behavior for most dispatchers is to return `true`.
     *
     * If this method returns `false`, the coroutine is resumed immediately in the current thread,
     * potentially forming an event-loop to prevent stack overflows.
     * The event loop is an advanced topic and its implications can be found in [Dispatchers.Unconfined] documentation.
     *
     * The [context] parameter represents the context of the coroutine that is being dispatched,
     * or [EmptyCoroutineContext] if a non-coroutine-specific [Runnable] is dispatched instead.
     *
     * A dispatcher can override this method to provide a performance optimization and avoid paying a cost of an unnecessary dispatch.
     * E.g. [MainCoroutineDispatcher.immediate] checks whether we are already in the required UI thread in this method and avoids
     * an additional dispatch when it is not required.
     *
     * While this approach can be more efficient, it is not chosen by default to provide a consistent dispatching behaviour
     * so that users won't observe unexpected and non-consistent order of events by default.
     *
     * Coroutine builders like [launch][CoroutineScope.launch] and [async][CoroutineScope.async] accept an optional [CoroutineStart]
     * parameter that allows one to optionally choose the [undispatched][CoroutineStart.UNDISPATCHED] behavior to start coroutine immediately,
     * but to be resumed only in the provided dispatcher.
     *
     * This method should generally be exception-safe. An exception thrown from this method
     * may leave the coroutines that use this dispatcher in the inconsistent and hard to debug state.
     *
     * @see dispatch
     * @see Dispatchers.Unconfined
     */
    public open fun isDispatchNeeded(context: CoroutineContext): Boolean = true

    /**
     * Creates a view of the current dispatcher that limits the parallelism to the given [value][parallelism].
     * The resulting view uses the original dispatcher for execution, but with the guarantee that
     * no more than [parallelism] coroutines are executed at the same time.
     *
     * This method does not impose restrictions on the number of views or the total sum of parallelism values,
     * each view controls its own parallelism independently with the guarantee that the effective parallelism
     * of all views cannot exceed the actual parallelism of the original dispatcher.
     *
     * ### Limitations
     *
     * The default implementation of `limitedParallelism` does not support direct dispatchers,
     * such as executing the given runnable in place during [dispatch] calls.
     * Any dispatcher that may return `false` from [isDispatchNeeded] is considered direct.
     * For direct dispatchers, it is recommended to override this method
     * and provide a domain-specific implementation or to throw an [UnsupportedOperationException].
     *
     * ### Example of usage
     * ```
     * private val backgroundDispatcher = newFixedThreadPoolContext(4, "App Background")
     * // At most 2 threads will be processing images as it is really slow and CPU-intensive
     * private val imageProcessingDispatcher = backgroundDispatcher.limitedParallelism(2)
     * // At most 3 threads will be processing JSON to avoid image processing starvation
     * private val jsonProcessingDispatcher = backgroundDispatcher.limitedParallelism(3)
     * // At most 1 thread will be doing IO
     * private val fileWriterDispatcher = backgroundDispatcher.limitedParallelism(1)
     * ```
     * Note how in this example the application has an executor with 4 threads, but the total sum of all limits
     * is 6. Still, at most 4 coroutines can be executed simultaneously as each view limits only its own parallelism.
     *
     * Note that this example was structured in such a way that it illustrates the parallelism guarantees.
     * In practice, it is usually better to use [Dispatchers.IO] or [Dispatchers.Default] instead of creating a
     * `backgroundDispatcher`. It is both possible and advised to call `limitedParallelism` on them.
     */
    @ExperimentalCoroutinesApi
    public open fun limitedParallelism(parallelism: Int): CoroutineDispatcher {
        parallelism.checkParallelism()
        return LimitedDispatcher(this, parallelism)
    }

    /**
     * Requests execution of a runnable [block].
     * The dispatcher guarantees that [block] will eventually execute, typically by dispatching it to a thread pool,
     * using a dedicated thread, or just executing the block in place.
     * The [context] parameter represents the context of the coroutine that is being dispatched,
     * or [EmptyCoroutineContext] if a non-coroutine-specific [Runnable] is dispatched instead.
     * Implementations may use [context] for additional context-specific information,
     * such as priority, whether the dispatched coroutine can be invoked in place,
     * coroutine name, and additional diagnostic elements.
     *
     * This method should guarantee that the given [block] will be eventually invoked,
     * otherwise the system may reach a deadlock state and never leave it.
     * The cancellation mechanism is transparent for [CoroutineDispatcher] and is managed by [block] internals.
     *
     * This method should generally be exception-safe. An exception thrown from this method
     * may leave the coroutines that use this dispatcher in an inconsistent and hard-to-debug state.
     *
     * This method must not immediately call [block]. Doing so may result in `StackOverflowError`
     * when `dispatch` is invoked repeatedly, for example when [yield] is called in a loop.
     * In order to execute a block in place, it is required to return `false` from [isDispatchNeeded]
     * and delegate the `dispatch` implementation to `Dispatchers.Unconfined.dispatch` in such cases.
     * To support this, the coroutines machinery ensures in-place execution and forms an event-loop to
     * avoid unbound recursion.
     *
     * @see isDispatchNeeded
     * @see Dispatchers.Unconfined
     */
    public abstract fun dispatch(context: CoroutineContext, block: Runnable)

    /**
     * Dispatches execution of a runnable `block` onto another thread in the given `context`
     * with a hint for the dispatcher that the current dispatch is triggered by a [yield] call, so that the execution of this
     * continuation may be delayed in favor of already dispatched coroutines.
     *
     * Though the `yield` marker may be passed as a part of [context], this
     * is a separate method for performance reasons.
     *
     * @suppress **This an internal API and should not be used from general code.**
     */
    @InternalCoroutinesApi
    public open fun dispatchYield(context: CoroutineContext, block: Runnable): Unit = dispatch(context, block)

    /**
     * Returns a continuation that wraps the provided [continuation], thus intercepting all resumptions.
     *
     * This method should generally be exception-safe. An exception thrown from this method
     * may leave the coroutines that use this dispatcher in the inconsistent and hard to debug state.
     */
    public final override fun <T> interceptContinuation(continuation: Continuation<T>): Continuation<T> =
        DispatchedContinuation(this, continuation)

    public final override fun releaseInterceptedContinuation(continuation: Continuation<*>) {
        /*
         * Unconditional cast is safe here: we only return DispatchedContinuation from `interceptContinuation`,
         * any ClassCastException can only indicate compiler bug
         */
        val dispatched = continuation as DispatchedContinuation<*>
        dispatched.release()
    }

    /**
     * @suppress **Error**: Operator '+' on two CoroutineDispatcher objects is meaningless.
     * CoroutineDispatcher is a coroutine context element and `+` is a set-sum operator for coroutine contexts.
     * The dispatcher to the right of `+` just replaces the dispatcher to the left.
     */
    @Suppress("DeprecatedCallableAddReplaceWith")
    @Deprecated(
        message = "Operator '+' on two CoroutineDispatcher objects is meaningless. " +
            "CoroutineDispatcher is a coroutine context element and `+` is a set-sum operator for coroutine contexts. " +
            "The dispatcher to the right of `+` just replaces the dispatcher to the left.",
        level = DeprecationLevel.ERROR
    )
    public operator fun plus(other: CoroutineDispatcher): CoroutineDispatcher = other

    /** @suppress for nicer debugging */
    override fun toString(): String = "$classSimpleName@$hexAddress"
}
```

</details>

---

Try the below example

```kotlin
fun main() = runBlocking<Unit> {
    launch { // context of the parent, main runBlocking coroutine
        println("main runBlocking      : I'm working in thread ${Thread.currentThread().name}")
    }
    launch(Dispatchers.Unconfined) { // not confined -- will work with main thread
        println("Unconfined            : I'm working in thread ${Thread.currentThread().name}")
    }
    launch(Dispatchers.Default) { // will get dispatched to DefaultDispatcher 
        println("Default               : I'm working in thread ${Thread.currentThread().name}")
    }
    launch(newSingleThreadContext("MyOwnThread")) { // will get its own new thread
        println("newSingleThreadContext: I'm working in thread ${Thread.currentThread().name}")
    }    
}
```

It produces the following output (maybe in different order):

```kotlin
Unconfined            : I'm working in thread main
Default               : I'm working in thread DefaultDispatcher-worker-1
newSingleThreadContext: I'm working in thread MyOwnThread
main runBlocking      : I'm working in thread main
```

- When `launch { ... }` is used without parameters, it inherits the context (and thus dispatcher) from the `CoroutineScope` it is being launched from. In this case, it inherits the context of the main `runBlocking` coroutine which runs in the main thread.

- `Dispatchers.Unconfined` is a special dispatcher that also appears to run in the main thread, but it is, in fact, a different mechanism that is explained later.

- The default dispatcher is used when no other dispatcher is explicitly specified in the scope. It is represented by `Dispatchers.Default` and uses a shared background pool of threads.

- `newSingleThreadContext` creates a thread for the coroutine to run. A dedicated thread is a very expensive resource. In a real application it must be either released, when no longer needed, using the close function, or stored in a top-level variable and reused throughout the application.

## Unconfined vs confined dispatcher

The `Dispatchers.Unconfined` coroutine dispatcher starts a coroutine in the caller thread, but only until the first suspension point. The unconfined dispatcher is appropriate for coroutines which neither consume CPU time nor update any shared data confined to a specific thread.

On the other side, the dispatcher is inherited from the outer CoroutineScope by default. The default dispatcher for the runBlocking coroutine, in particular, is confined to the invoker thread, so inheriting it has the effect of confining execution to this thread with predictable FIFO scheduling.

```kotlin
launch(Dispatchers.Unconfined) { // not confined -- will work with main thread
    println("Unconfined      : I'm working in thread ${Thread.currentThread().name}")
    delay(500)
    println("Unconfined      : After delay in thread ${Thread.currentThread().name}")
}
launch { // context of the parent, main runBlocking coroutine
    println("main runBlocking: I'm working in thread ${Thread.currentThread().name}")
    delay(1000)
    println("main runBlocking: After delay in thread ${Thread.currentThread().name}")
}
```

Produces the output:

```kotlin
Unconfined      : I'm working in thread main
main runBlocking: I'm working in thread main
Unconfined      : After delay in thread kotlinx.coroutines.DefaultExecutor
main runBlocking: After delay in thread main
```

So, the coroutine with the context inherited from `runBlocking {...}` continues to execute in the main thread, while the unconfined one resumes in the default executor thread that the delay function is using.

> The unconfined dispatcher is an advanced mechanism that can be helpful in certain corner cases where <u>dispatching of a coroutine for its execution later is not needed or produces undesirable side-effects</u>, because some operation in a coroutine must be performed right away. The unconfined dispatcher should not be used in general code.

## Debugging coroutines and threads

Coroutines can suspend on one thread and resume on another thread. Even with a single-threaded dispatcher it might be hard to figure out what the coroutine was doing, where, and when if you don't have special tooling.

### Debugging with IDEA

The Coroutine Debugger of the Kotlin plugin simplifies debugging coroutines in IntelliJ IDEA.

> Debugging works for versions 1.3.8 or later of kotlinx-coroutines-core.

The Debug tool window contains the Coroutines tab. In this tab, you can find information about both currently running and suspended coroutines. The coroutines are grouped by the dispatcher they are running on.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/fd2f2ff4-07e6-4465-942d-b06005ac9ad7)

With the coroutine debugger, you can:
- Check the state of each coroutine.
- See the values of local and captured variables for both running and suspended coroutines.
- See a full coroutine creation stack, as well as a call stack inside the coroutine. The stack includes all frames with variable values, even those that would be lost during standard debugging.
- Get a full report that contains the state of each coroutine and its stack. To obtain it, right-click inside the Coroutines tab, and then click **Get Coroutines Dump.**
- To start coroutine debugging, you just need to set breakpoints and run the application in debug mode.

Learn more about coroutines debugging in the [official tutorial](https://kotlinlang.org/docs/tutorials/coroutines/debug-coroutines-with-idea.html).

## Jumping between threads
Run the following code with the -Dkotlinx.coroutines.debug JVM option (see debug):

```kotlin
newSingleThreadContext("Ctx1").use { ctx1 ->
    newSingleThreadContext("Ctx2").use { ctx2 ->
        runBlocking(ctx1) {
            log("Started in ctx1")
            withContext(ctx2) {
                log("Working in ctx2")
            }
            log("Back to ctx1")
        }
    }
}
```

It demonstrates several new techniques. One is using runBlocking with an explicitly specified context, and the other one is using the withContext function to change the context of a coroutine while still staying in the same coroutine, as you can see in the output below:

```kotlin
[Ctx1 @coroutine#1] Started in ctx1
[Ctx2 @coroutine#1] Working in ctx2
[Ctx1 @coroutine#1] Back to ctx1
```

Note that this example also uses the use function from the Kotlin standard library to release threads created with newSingleThreadContext when they are no longer needed.

## Chilren of a coroutine

When a coroutine is launched in the CoroutineScope of another coroutine, it inherits its context via CoroutineScope.coroutineContext and the Job of the new coroutine becomes a child of the parent coroutine's job. When the parent coroutine is cancelled, all its children are recursively cancelled, too.

However, this parent-child relation can be explictly overriden in one of two ways:

1. When a different scope is explicitly specified when launching a coroutine (for example, `GlobalScope.launch`),  then is does no inherit a `Job` from the parent scope.
2. When a different `Job` object is passed as the context for the new coroutine (as shown in the example below), then is overrides the `Job` of the parent scope.

In both cases, the launched coroutine is not tied to the scope it was launched fron and operates independently.

## Combining context elements

Sometimes we need to define multiple elements for a coroutine context. We can use the + operator for that. For example, we can launch a coroutine with an explicitly specified dispatcher and an explicitly specified name at the same time:

```kotlin
launch(Dispatchers.Default + CoroutineName("test")) {
    println("I'm working in thread ${Thread.currentThread().name}")
}
```

The output of this code with the `-Dkotlinx.coroutines.debug` JVM option is:

```kotlin
I'm working in thread DefaultDispatcher-worker-1 @test#2
```

## Thread-local data

Sometimes it is convenient to have an ability to pass some thread-local data to or between coroutines. However, since they are not bound to any particular thread, this will likely lead to boilerplate if done manually.

For **ThreadLocal, the asContextElement** extension function is here for the rescue. It creates an additional context element which keeps the value of the given ThreadLocal and restores it every time the coroutine switches its context.

```kotlin
threadLocal.set("main")
println("Pre-main, current thread: ${Thread.currentThread()}, thread local value: '${threadLocal.get()}'")
val job = launch(Dispatchers.Default + threadLocal.asContextElement(value = "launch")) {
    println("Launch start, current thread: ${Thread.currentThread()}, thread local value: '${threadLocal.get()}'")
    yield()
    println("After yield, current thread: ${Thread.currentThread()}, thread local value: '${threadLocal.get()}'")
}
job.join()
println("Post-main, current thread: ${Thread.currentThread()}, thread local value: '${threadLocal.get()}'")
```

In this example we launch a new coroutine in a background thread pool using Dispatchers.Default, so it works on a different thread from the thread pool, but it still has the value of the thread local variable that we specified using threadLocal.asContextElement(value = "launch"), no matter which thread the coroutine is executed on. Thus, the output (with debug) is:

```kotlin
Pre-main, current thread: Thread[main @coroutine#1,5,main], thread local value: 'main'
Launch start, current thread: Thread[DefaultDispatcher-worker-1 @coroutine#2,5,main], thread local value: 'launch'
After yield, current thread: Thread[DefaultDispatcher-worker-2 @coroutine#2,5,main], thread local value: 'launch'
Post-main, current thread: Thread[main @coroutine#1,5,main], thread local value: 'main'
```

It's easy to forget to set the corresponding context element. The thread-local variable accessed from the coroutine may then have an unexpected value, if the thread running the coroutine is different. To avoid such situations, it is recommended to use the ensurePresent method and fail-fast on improper usages.

ThreadLocal has first-class support and can be used with any primitive `kotlinx.coroutines` provides. It has one key limitation, though: when a thread-local is mutated, a new value is not propagated to the coroutine caller (because a context element cannot track all ThreadLocal object accesses), and the updated value is lost on the next suspension. Use `withContext` to update the value of the thread-local in a coroutine, see `asContextElement` for more details.

Alternatively, a value can be stored in a mutable box like `class Counter(var i: Int)`, which is, in turn, stored in a thread-local variable. However, in this case you are fully responsible to synchronize potentially concurrent modifications to the variable in this mutable box.

For advanced usage, for example for integration with logging MDC, transactional contexts or any other libraries which internally use thread-locals for passing data, see the documentation of the `ThreadContextElement` interface that should be implemented.

---
reference

- https://kotlinlang.org/docs/coroutine-context-and-dispatchers.html
- https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-coroutine-dispatcher/
- https://github.com/Kotlin/kotlinx.coroutines/blob/master/kotlinx-coroutines-core/jvm/test/guide
- https://medium.com/@lucianoalmeida1/an-overview-on-kotlin-coroutines-d55e123e137b
# Coroutine Scope

To launch a coroutine, we need to use a coroutine builder like launch or async. These builder functions are actually extensions of the `CoroutineScope` interface. So, whenever we want to launch a coroutine, we need to start it in some scope.

```kotlin
public interface CoroutineScope {
    /**
     * The context of this scope.
     * Context is encapsulated by the scope and used for implementation of coroutine builders that are extensions on the scope.
     * Accessing this property in general code is not recommended for any purposes except accessing the [Job] instance for advanced usages.
     *
     * By convention, should contain an instance of a [job][Job] to enforce structured concurrency.
     */
    public val coroutineContext: CoroutineContext
}

public fun CoroutineScope.launch(
    context: CoroutineContext = EmptyCoroutineContext,
    start: CoroutineStart = CoroutineStart.DEFAULT,
    block: suspend CoroutineScope.() -> Unit
): Job {
    val newContext = newCoroutineContext(context)
    val coroutine = if (start.isLazy)
        LazyStandaloneCoroutine(newContext, block) else
        StandaloneCoroutine(newContext, active = true)
    coroutine.start(start, coroutine, block)
    return coroutine
}
```

The scope **creates relationships between coroutines inside it and allows us to manage the lifecycles of these coroutines.** To manage the lifecycle, it can manage memory to prevent leak also. There are several scopes provided by the `kotlinx.coroutines` library that we can use when launching a coroutine. 

Manual implementation of this interface is not recommended, implementation by delegation should be preferred instead. By convention, the context of a scope should contain an instance of a job to enforce the discipline of structured concurrency with propagation of cancellation.

Every coroutine builder (like launch, async, and others) and every scoping function (like coroutineScope and withContext) provides its own scope with its own [Job instance](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-job/index.html) into the inner block of code it runs. By convention, they all wait for all the coroutines inside their block to complete before completing themselves, thus enforcing the structured concurrency. It's important to prevent memory leak.

There’s also a way to create a custom scope. Let’s have a look

## Coroutine Context

One of the simplest ways to run a coroutine is to use GlobalScope:

```kotlin
GlobalScope.launch {
    delay(500L)
    println("Coroutine launched from GlobalScope")
}
```

The lifecycle of this scope is <u>tied to the lifecycle of the whole application</u>. This means that the scope will stop running either after all of its coroutines have been completed or when the application is stopped.

It’s worth mentioning that coroutines launched using GlobalScope do not keep the process alive. They behave similarly to daemon threads. So, even when the application stops, some active coroutines will still be running. This can easily create resource or memory leaks.

## runBlocking

Another scope that comes right out of the box is runBlocking. From the name, we might guess that it creates a scope and runs a coroutine in a blocking way. This means it blocks the current thread until all childrens’ coroutines complete their executions.

It is not recommended to use this scope because threads are expensive and will depreciate all the benefits of coroutines.

The most suitable place for using runBlocking is the very top level of the application, which is the main function. Using it in main will ensure that the app will wait until all child jobs inside runBlocking complete.

Another place where this scope fits nicely is in tests that access suspending functions.

## CoroutineScope

For all the cases when we don’t need thread blocking, we can use coroutineScope. Similarly to runBlocking, it will wait for its children to complete. But unlike runBlocking, **this scope doesn’t block the current thread but only suspends** it because coroutineScope is a suspending function.

## Custom Coroutine Scope

There might be cases when we need to have some specific behavior of the scope to get a different approach in managing the coroutines. To achieve that, we can implement the CoroutineScope interface and implement our custom scope for coroutine handling.

# Coroutine Context

Now, let’s take a look at the role of CoroutineContext here. **The context is a holder of data that is needed for the coroutine**. Basically, it’s an indexed set of elements where each element in the set has a unique key.

The important elements of the coroutine context are the [**Job of the coroutine and the Dispatcher**](Coroutine%E2%80%85Dispatcher.md).

Kotlin provides an easy way to add these elements to the coroutine context using the `+` operator:

```kotlin
launch(Dispatchers.Default + Job()) {
    println("Coroutine works in thread ${Thread.currentThread().name}")
}
```

## Job in the Context

```kotlin
interface Job : CoroutineContext.Element
```

A Job of a coroutine is to handle the launched coroutine. For example, it can be used to wait for coroutine completion explicitly.

Since Job is a part of the coroutine context, it can be accessed using the coroutineContext(Job) expression.

Jobs can be arranged into parent-child hierarchies where cancellation of a parent leads to immediate cancellation of all its children recursively. Failure of a child with an exception other than CancellationException immediately cancels its parent and, consequently, all its other children. This behavior can be customized using [SupervisorJob](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-supervisor-job.html).

The most basic instances of Job interface are created like this:

- **Coroutine job** is created with launch coroutine builder. It runs a specified block of code and completes on completion of this block.
- **CompletableJob** is created with a `Job()` factory function. It is completed by calling CompletableJob.complete.

## Coroutine Context and Dispatchers

Another important element of the context is Dispatcher. It determines what threads the coroutine will use for its execution.

Kotlin provides several implementations of CoroutineDispatcher that we can pass to the CoroutineContext:

- `Dispatchers.Default` uses a shared thread pool on the JVM. By default, the number of threads is equal to the number of CPUs available on the machine.
- `Dispatchers.IO` is designed to offload blocking IO operations to a shared thread pool.
- `Dispatchers.Main` is present only on platforms that have main threads, such as Android and iOS.
- `Dispatchers.Unconfined` doesn’t change the thread and launches the coroutine in the caller thread. The important thing here is that after suspension, it resumes the coroutine in the thread that was determined by the suspending function.


## Switching the Context

Sometimes, we must change the context during coroutine execution while staying in the same coroutine. We can do this **using the withContext function**. It will call the specified suspending block with a given coroutine context. The outer coroutine suspends until this block completes and returns the result:

```kotlin
newSingleThreadContext("Context 1").use { ctx1 ->
    newSingleThreadContext("Context 2").use { ctx2 ->
        runBlocking(ctx1) {
            println("Coroutine started in thread from ${Thread.currentThread().name}")
            withContext(ctx2) {
                println("Coroutine works in thread from ${Thread.currentThread().name}")
            }
            println("Coroutine switched back to thread from ${Thread.currentThread().name}")
        }
    }
}
```

The context of the withContext block will be the merged contexts of the coroutine and the context passed to withContext.

## Children of a Coroutine

When we launch a coroutine inside another coroutine, it inherits the outer coroutine’s context, and the job of the new coroutine becomes a child job of the parent coroutine’s job. Cancellation of the parent coroutine leads to cancellation of the child coroutine as well.

We can override this parent-child relationship using one of two ways:

- Explicitly specify a different scope when launching a new coroutine
- Pass a different Job object to the context of the new coroutine

In both cases, the new coroutine will not be bound to the scope of the parent coroutine. It will execute independently, meaning that canceling the parent coroutine won’t affect the new coroutine.

---
참고
- https://www.baeldung.com/kotlin/coroutines-scope-vs-context
- https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-coroutine-scope/
- https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-coroutine-scope/coroutine-context.html
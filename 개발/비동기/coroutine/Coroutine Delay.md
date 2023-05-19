# Coroutine Delay

아래와 같은 timeout(혹은 delay)가 내부적으로 어떻게 동작하는지 알아보자.

```kotlin
GlobalScope.launch {
    withTimeout(10) {
        ...
    }
}
```

일단 `withTimeout`의 코드를 살펴보자면 아래와 같다.

가장 아랫부분을 보면 time이 실제로 track되는 것은 CoroutineDispatcher의 구현이라고 적혀있다.

> Implementation note: how the time is tracked exactly is an implementation detail of the context's [CoroutineDispatcher].

```kotlin
/**
 * Runs a given suspending [block] of code inside a coroutine with a specified [timeout][timeMillis] and throws
 * a [TimeoutCancellationException] if the timeout was exceeded.
 *
 * The code that is executing inside the [block] is cancelled on timeout and the active or next invocation of
 * the cancellable suspending function inside the block throws a [TimeoutCancellationException].
 *
 * The sibling function that does not throw an exception on timeout is [withTimeoutOrNull].
 * Note that the timeout action can be specified for a [select] invocation with [onTimeout][SelectBuilder.onTimeout] clause.
 *
 * **The timeout event is asynchronous with respect to the code running in the block** and may happen at any time,
 * even right before the return from inside of the timeout [block]. Keep this in mind if you open or acquire some
 * resource inside the [block] that needs closing or release outside of the block.
 * See the
 * [Asynchronous timeout and resources][https://kotlinlang.org/docs/reference/coroutines/cancellation-and-timeouts.html#asynchronous-timeout-and-resources]
 * section of the coroutines guide for details.
 *
 * > Implementation note: how the time is tracked exactly is an implementation detail of the context's [CoroutineDispatcher].
 *
 * @param timeMillis timeout time in milliseconds.
 */
public suspend fun <T> withTimeout(timeMillis: Long, block: suspend CoroutineScope.() -> T): T {
    contract {
        callsInPlace(block, InvocationKind.EXACTLY_ONCE)
    }
    if (timeMillis <= 0L) throw TimeoutCancellationException("Timed out immediately")
    return suspendCoroutineUninterceptedOrReturn { uCont ->
        setupTimeout(TimeoutCoroutine(timeMillis, uCont), block)
    }
}
```

<details>
<summary>TimeoutCoroutine</summary>

```kotlin
private class TimeoutCoroutine<U, in T: U>(
    @JvmField val time: Long,
    uCont: Continuation<U> // unintercepted continuation
) : ScopeCoroutine<T>(uCont.context, uCont), Runnable {

    // 이 run은 runnable에서 상속받은 메서드이고, cancel하기 위해 사용된다.
    override fun run() {
        cancelCoroutine(TimeoutCancellationException(time, this))
    }

    override fun nameString(): String =
        "${super.nameString()}(timeMillis=$time)"
}

public open class JobSupport constructor(active: Boolean) : Job, ChildJob, ParentJob, SelectClause0 {
    final override val key: CoroutineContext.Key<*> get() = Job

    ...
    public fun cancelCoroutine(cause: Throwable?): Boolean = cancelImpl(cause)

    // TimeoutCoroutine에서 run을 호출하면, 여기로 와서 적절히 cancel된다.
    // cause is Throwable or ParentJob when cancelChild was invoked
    // returns true is exception was handled, false otherwise
    internal fun cancelImpl(cause: Any?): Boolean {
        var finalState: Any? = COMPLETING_ALREADY
        if (onCancelComplete) {
            // make sure it is completing, if cancelMakeCompleting returns state it means it had make it
            // completing and had recorded exception
            finalState = cancelMakeCompleting(cause)
            if (finalState === COMPLETING_WAITING_CHILDREN) return true
        }
        if (finalState === COMPLETING_ALREADY) {
            finalState = makeCancelling(cause)
        }
        return when {
            finalState === COMPLETING_ALREADY -> true
            finalState === COMPLETING_WAITING_CHILDREN -> true
            finalState === TOO_LATE_TO_CANCEL -> false
            else -> {
                afterCompletion(finalState)
                true
            }
        }
    }
    ...
}
```

</details>

```kotlin
private fun <U, T: U> setupTimeout(
    coroutine: TimeoutCoroutine<U, T>,
    block: suspend CoroutineScope.() -> T
): Any? {
    
    // schedule cancellation of this coroutine on time
    val cont = coroutine.uCont
    val context = cont.context
    coroutine.disposeOnCompletion(context.delay.invokeOnTimeout(coroutine.time, coroutine, coroutine.context)) // <--

    // restart the block using a new coroutine with a new job,
    // however, start it undispatched, because we already are in the proper context
    return coroutine.startUndispatchedOrReturnIgnoreTimeout(coroutine, block)
}
```

`context.delay`를 가져와서 `invokeOnTimeout`를 호출한다. 그리고 block을 restart해서 새로운 job을 가지도록 만든다. (delay 후 다시 시작되어야하기 떄문)

```kotlin
/** Returns [Delay] implementation of the given context */
internal val CoroutineContext.delay: Delay get() = get(ContinuationInterceptor) as? Delay ?: DefaultDelay

internal actual val DefaultDelay: Delay = initializeDefaultDelay()

private fun initializeDefaultDelay(): Delay {
    // Opt-out flag
    if (!defaultMainDelayOptIn) return DefaultExecutor
    val main = Dispatchers.Main
    /*
     * When we already are working with UI and Main threads, it makes
     * no sense to create a separate thread with timer that cannot be controller
     * by the UI runtime.
     */
    return if (main.isMissing() || main !is Delay) DefaultExecutor else main // <--
}
```

`CoroutineContext.delay`는 기본적으로 `DefaultExecutor`라는 object를 가져온다.

## DefaultExecuter

```kotlin
internal actual object DefaultExecutor : EventLoopImplBase(), Runnable {

    override fun run() {
        // TreadLocalEventLoop에 등록되어 동작한다.
        // TreadLocalEventLoop는 @ThreadLocal이 달려있고, object로 선언되어있어 모든 스레드마다 각 1개씩 생성된다.
        // eventLoop로 등록되므로 일정 주기마다 실행된다. (@InternalCoroutinesApi)
        ThreadLocalEventLoop.setEventLoop(this) 
        ...
    }

    // timeout일때 block을 run 시켜준다.
    override fun invokeOnTimeout(timeMillis: Long, block: Runnable, context: CoroutineContext): DisposableHandle =
        scheduleInvokeOnTimeout(timeMillis, block)

    protected fun scheduleInvokeOnTimeout(timeMillis: Long, block: Runnable): DisposableHandle {
        val timeNanos = delayToNanos(timeMillis)
        return if (timeNanos < MAX_DELAY_NS) {
            val now = nanoTime()
            DelayedRunnableTask(now + timeNanos, block).also { task ->
                schedule(now, task)
            }
        } else {
            NonDisposableHandle
        }
    }

    // 이 부분은 delayedQueue가 있는지 확인하고, task를 받았을때 스케줄링해주는 함수이다.
    // 위를 보면 알겠지만 DelayedRunnableTask에 람다로 들어간다.
    public fun schedule(now: Long, delayedTask: DelayedTask) {
        when (scheduleImpl(now, delayedTask)) {
            SCHEDULE_OK -> if (shouldUnpark(delayedTask)) unpark()
            SCHEDULE_COMPLETED -> reschedule(now, delayedTask)
            SCHEDULE_DISPOSED -> {} // do nothing -- task was already disposed
            else -> error("unexpected result")
        }
    }
    private fun scheduleImpl(now: Long, delayedTask: DelayedTask): Int {
        if (isCompleted) return SCHEDULE_COMPLETED
        val delayedQueue = _delayed.value ?: run {
            _delayed.compareAndSet(null, DelayedTaskQueue(now))
            _delayed.value!!
        }
        return delayedTask.scheduleTask(now, delayedQueue, this)
    }
    ...
}
```

## DelayedRunnableTask와 DelayedTask

```kotlin

private class DelayedRunnableTask(
    nanoTime: Long,
    private val block: Runnable
) : DelayedTask(nanoTime) { // <--
    override fun run() { block.run() }
    override fun toString(): String = super.toString() + block.toString()
}
```

```kotlin
    internal abstract class DelayedTask(
        /**
         * This field can be only modified in [scheduleTask] before putting this DelayedTask
         * into heap to avoid overflow and corruption of heap data structure.
         */
        @JvmField var nanoTime: Long
    ) : Runnable, Comparable<DelayedTask>, DisposableHandle, ThreadSafeHeapNode {
        @Volatile
        private var _heap: Any? = null // null | ThreadSafeHeap | DISPOSED_TASK

        override var heap: ThreadSafeHeap<*>?
            get() = _heap as? ThreadSafeHeap<*>
            set(value) {
                require(_heap !== DISPOSED_TASK) // this can never happen, it is always checked before adding/removing
                _heap = value
            }

        override var index: Int = -1

        // EventLoop#DefaultExecutor()에서 DelayedTask(DisposableHandle)를 반환하면 이 메서드를 통해 비교되고 실행된다.
        override fun compareTo(other: DelayedTask): Int {
            val dTime = nanoTime - other.nanoTime
            return when {
                dTime > 0 -> 1
                dTime < 0 -> -1
                else -> 0
            }
        }

        fun timeToExecute(now: Long): Boolean = now - nanoTime >= 0L

        // 실제로 스케줄링 하는 부분
        @Synchronized
        fun scheduleTask(now: Long, delayed: DelayedTaskQueue, eventLoop: EventLoopImplBase): Int {
            if (_heap === DISPOSED_TASK) return SCHEDULE_DISPOSED // don't add -- was already disposed
            delayed.addLastIf(this) { firstTask ->
                if (eventLoop.isCompleted) return SCHEDULE_COMPLETED // non-local return from scheduleTask
                /**
                 * We are about to add new task and we have to make sure that [DelayedTaskQueue]
                 * invariant is maintained. The code in this lambda is additionally executed under
                 * the lock of [DelayedTaskQueue] and working with [DelayedTaskQueue.timeNow] here is thread-safe.
                 */
                if (firstTask == null) {
                    /**
                     * When adding the first delayed task we simply update queue's [DelayedTaskQueue.timeNow] to
                     * the current now time even if that means "going backwards in time". This makes the structure
                     * self-correcting in spite of wild jumps in `nanoTime()` measurements once all delayed tasks
                     * are removed from the delayed queue for execution.
                     */
                    delayed.timeNow = now
                } else {
                    /**
                     * Carefully update [DelayedTaskQueue.timeNow] so that it does not sweep past first's tasks time
                     * and only goes forward in time. We cannot let it go backwards in time or invariant can be
                     * violated for tasks that were already scheduled.
                     */
                    val firstTime = firstTask.nanoTime
                    // compute min(now, firstTime) using a wrap-safe check
                    val minTime = if (firstTime - now >= 0) now else firstTime
                    // update timeNow only when going forward in time
                    if (minTime - delayed.timeNow > 0) delayed.timeNow = minTime
                }
                /**
                 * Here [DelayedTaskQueue.timeNow] was already modified and we have to double-check that newly added
                 * task does not violate [DelayedTaskQueue] invariant because of that. Note also that this scheduleTask
                 * function can be called to reschedule from one queue to another and this might be another reason
                 * where new task's time might now violate invariant.
                 * We correct invariant violation (if any) by simply changing this task's time to now.
                 */
                if (nanoTime - delayed.timeNow < 0) nanoTime = delayed.timeNow
                true
            }
            return SCHEDULE_OK
        }
    }
```

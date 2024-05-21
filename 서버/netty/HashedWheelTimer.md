
Timers are important for failure recovery, rate based flow control, scheduling algorithms, controlling packet lifetime in networks. And Efficient timer algorithms are required to reduce the overall interrupt overhead

- Timer maintenance high if 
  - Processor interrupted every clock tick 
  - Fine granularity timers are used
  - outstanding timers is high

## Model & Performance Measure

Therefore, we will look at several ways of implementing timers. And we're going to look at Hashed WheelTimer's approach. First, define the features and methods that the timer should have, and how it compares performance.

**Routines in the model**
  - Client Invoked :
    The interface provided by the timer facility is as follows:
    ```js
    START_TIMER(Interval, Timer_ID, Expiry_Action)
    Start a timer lasting Interval, identified by Timer_ID, and when expired, perform Expiry_Action

    STOP_TIMER(Timer_ID)
    Stop the timer identified by Timer_ID, and clean it up
    ```
  Now for all the schemes we will assume we have some source of clock ticks, probably hardware, but this could also be some other software interface. Whatever resolution these clock ticks are (every second, every millisecond, or every microsecond) are the “atomic”, individisble clock ticks we will construct our timer from. For our calculations we will assume the granularity of our timer is T clock ticks.<br>Then to evaluate our timer implementation we will also consider two more operations:

  - Timer tick invoked :
    ```js
    PER_TICK_BOOKKEEPING
    For every T clock ticks we will have to check for expired timers. This is how much work we have to do when we check for expired timers.

    EXPIRY_PROCESSING
    This is the routine that does the Expiry_Action from the START_TIMER call.
    ```
  
- **Performance Measure**
    - Space : Memory used by the data structures
    - Latency : Time required to begin and end any of the routines mentioned above

## Several ways of implementing timers

### 1. Straightforward

<img width="145" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/dffdfb4e-1e80-4368-9fc4-43d99399b2f8">

The first approach is the most straightforward. `START_TIMER` allocates a timer struct that stores the expiry action and the interval of the timer. `PER_TICK_BOOKKEEPING` goes through all the timers and decrements the interval by one tick, and if the timer has counted down to zero, it calls the expiry action.

It’s fast for all operations except `PER_TICK_BOOKKEEPING` and to quote the paper is only appropriate if

- There are only a few outstanding timers.
- Most timers are stopped within a few ticks of the clock.
- `PER_TICK_BOOKKEEPING` is done with suitable performance by special-purpose hardware.

- START_TIMER = O(1)
- STOP_TIMER = O(1)
- PER_TICK_BOOKKEEPING = O(n)

### 2. Ordered List / Timer Queues

<img width="113" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/7cfb26ae-e6b6-4b6a-b0d9-a8bc8af447f1">

Instead of having `PER_TICK_BOOKKEEPING` operate on every timer, this scheme has it operate on **just one**. 

It stores the absolute expiry time for timers instead of how much remaining time it has left. It then keeps the timers in a sorted list, ordered by their expiry time, with the lowest in the front, so the head of the list is the timer that will expire first.

Now `START_TIMER` has to perform possibly O(n) work to insert the timer into the sorted list, but `PER_TICK_BOOKKEEPING` is vastly improved. On each tick, the timer only increments the current time, and compares it with the head of the list. If the timer is expired, it calls `EXPIRY_PROCESSING` and removes it from the list, continuing until the head of the list is an unexpired timer.

This is the best performance we can get. We only do constant work per tick, and then the necessary work when timers are expired.

- START_TIMER = O(n)
- STOP_TIMER = O(1)
- PER_TICK_BOOKKEEPING = O(1)

### 3. Tree-based Algorithms

<img width="238" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/fb0f1f2f-0146-4e8b-8510-bd5528cb17cb">

There is a great deal of similarity between trying to manage which timer has the smallest expiration time and sorting. The difference between timers and classical sorting is that we don’t know all of the elements to start with, as more will come at some later point. The authors call this modified version, “dyanmic sorting.”

Using that lens, we can view the ordered list in number 2 as simply insertion sort, which takes `O(n)` work per item. However this isn’t the best and we can do better, usually via quicksort or merge sort. Quicksort doesn’t necessarily translate well to the problem, but the authors suggest using a balanced binary search tree in place of a list and using that to keep track of the timers. In this case our `START_TIMER` costs only `O(log(n))` and everything else is the same.

- START_TIMER = O(log n)
- STOP_TIMER = O(1)
- PER_TICK_BOOKKEEPING = O(1)

### 4. Simple Timing Wheel

In the simulation of digital circuits, it is often sufficient to consider event scheduling at time instants that are multiples of the clock interval, say `c`. Then, after the program processes an event, it increments the clock variable by `c` until it finds any outstanding events at the current time. It then executes the events.

The idea is that given we are at time `t` we’ll have a timing wheel that consists of an array of lists. The array is of size `N` and each index `i` in the array holds a list of timers that will expire at time `t + i`. This allows us to schedule events up to `N` clock ticks away. For events beyond that, the timing wheel also has an overflow list of timers that expire at a time later than `t + N - 1`.

`START_TIMER` will add the timer either to the appropriate list in the array, or into the overflow list. In the common case, `PER_TICK_BOOKKEEPING` increments the current time index, checks the current time index in the array for expired timers and performs the expiry action as necessary. Every `N` clock ticks, `PER_TICK_BOOKKEEPING` will need to reset the current time index to 0 and “rotate” the timing wheel, moving items from the overflow list into the appropriate list in the array.

The downside to this approach is that as we approach `N` clock ticks, right before we’ll need to perform a rotation, it’s more and more likely that timers will be added to the overflow list. One known solution at the time was to rotate the timing wheel half way through, every `N/2` ticks. This reduces the severity of the problem, but doesn’t quite do away with it.v

<img width="302" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/533a422a-bf69-4f90-9753-e3f07dfb0752">

Simple Timing Wheel is the simple implementation of that idea.

- Keep a large timing wheel
- A curser in the timing wheel moves one location every time unit (just like a seconds hand in the clock)
- If the timer interval is within a rotation from the current curser position then put the timer in the corresponding location
- Requires exponential amount of memory

We create a timing wheel consisting of an array of `N` slots. The array is a circular buffer indexed by the current time `i by i mod N`. `START_TIMER` for a timer with interval j gets placed into the list located at index `(i + j) mod N`.

`PER_TICK_BOOKKEEPING` only has to increment the current time i and inspect the list at index i mod N and perform expiry actions as necessary. This is ideal in that START_TIMER does only O(1) work and `PER_TICK_BOOKKEEPING` does only `O(1)` extra work, besides the necessary work of handling expiry actions of expired timers.

- START_TIMER = O(1)
- STOP_TIMER = O(1)
- PER_TICK_BOOKKEEPING = O(1)

The downside to this solution is that we can only provide timers of a max interval `N`. And if we decide to grow `N`, then we in turn must grow the size of our timing wheel, meaning that if our clock resolution is one millisecond, and we wish to have a max interval of one hour, we’ll need a 3.6 million element timing wheel. This can quickly become prohibitively expensive in terms of memory usage.
  
### 5. Hashed Timing Wheel

we have a fixed amount of memory to store these timers, instead of having a memory slot for each possible timer expiration date, we can have each slot represent many possible expiration dates. Then to figure out which expiration dates correspond to which slots, we use a hash function to hopefully evenly distribute our expiration dates over all slots.

This is in fact what `Hashed Timing Wheel` does. Using a power of 2 array size, and a bit mask, The lower bits, lb, index into the array at point `(i + lb) mod N` where `i` is the current time and N is the array size. Then the higher order bits are stored into the list at that index.

<img width="350" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/d083c275-0b07-4793-9fc9-dd19e31a7746">

> In Figure 9, let the table size be 256 and the timer be a 32 bit timer. The remainder on division is the last 8 bits. Let the value of the last 8 bits be 20. Then the timer index is 10 `(Curent Time Pointer) + 20 (remainder) = 30`. The 24 high order bits are then inserted into a list that is pointed to by the 30th element. <br> [Hashed and Hierarchical Timing Wheels: Data Structures or the Efficient Implementation of a Timer Facility, 1987](http://www.cs.columbia.edu/~nahum/w6998/papers/sosp87-timing-wheels.pdf)

<img width="383" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/60ded9bb-ff9d-4ce0-8e24-ba5e4ccc97ee">

<br>

- Say wheel has 8 ticks
- Timer value = 17
- Make 2 rounds of wheel + 1 more tick
- Schedule the timer in the bucket “1” 
- Keep the # rounds with the timer
- At the expiry processing if the `# rounds > 0` then reinsert the timer

- Sorted Lists in each bucket
    - The list in each bucket can be insertion sorted
    - Hence `START_TIMER` takes `O(n)` time in the worst case
    - If `n < WheelSize` then average `O(1)`
- Unsorted list in each bucket
    - List can be kept unsorted to avoid worst case `O(n)` latency for START_TIMER
    - However worst case `PER_TICK_BOOKKEEPING = O(n)`
    - Again, if `n < WheelSize then average O(1)`

<br>

Hashed Timing Wheel data structure is better as it holds lock only on that sec value of the list. But to efficiently define timers that can specify a larger time, a hierarchical structure can be used.

<img width="510" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/c8550a3e-5c1d-4543-8969-974473b94436">

<br>

- START_TIMER = O(m) where m is the number of wheels. The bucket value on each wheel needs to be calculated
- STOP_TIMER = O(1)
- PER_TICK_BOOKKEEPING = O(1) on avg.

<br>

## Comparison

||START_TIMER|STOP_TIMER|PER_TICK|
|-|-|-|-|
|Straight Fwd|O(1)|O(1)|O(n)|
|Sequential List|O(n)|O(1)|O(1)|
|Tree Based|O(log(n))|O(1)|O(1)|
|Simple Wheel|O(1)|O(1)|O(1)|
|Hashed Wheel (sorted)|O(n) worst case<br>O(1) avg|O(1)|O(1)|
|Hashed Wheel (unsorted)|O(1)|O(1)|O(n) worst case<br>O(1) avg|
|Hierarchical Wheels|O(m)|O(1)|O(1)|

# HashedWheelTimer

`HashedWheelTimer` is a Class which effecient timer implementation of netty, a timer optimized for approximeted I/O timeout scheduling.

As described with 'approximated', this timer does not execute the scheduled TimerTask on time. HashedWheelTimer, on every tick, will check if there are any TimerTasks behind the schedule and execute them.

When adding a new task, hold a lock on the list and add it.
For every tick, the Timeout manager hold a lock and scan through the List, decrement toExpire time for the tasks and expire tasks what need to expire.

Based on explaination in front, 

- HashedWheelTimer maintains a data structure called 'wheel'. To put simply, a wheel is a hash table of TimerTasks whose hash function is 'dead line of the task'. When we add a new task, we compute taskToExpire mod 60, go to that key, hold the lock, take the list out and add tuple (counter, task) to the list where the counter is the timeToExpire / 60.

- For every sec, we go the key for that second and hold the lock on the list and scan through the list, expire all the task which have counter 0 and decrease the counter of rest of the task tuples.

It's wheel is maintain of inner class `HashedWheelBucket`'s array. `HashedWheelBucket` is a linked list of `HashedWheelTimeout` that contains information about each added timeout.

```java
    private static HashedWheelBucket[] createWheel(int ticksPerWheel) {
        //ticksPerWheel may not be greater than 2^30
        checkInRange(ticksPerWheel, 1, 1073741824, "ticksPerWheel");

        ticksPerWheel = normalizeTicksPerWheel(ticksPerWheel);
        HashedWheelBucket[] wheel = new HashedWheelBucket[ticksPerWheel];
        for (int i = 0; i < wheel.length; i ++) {
            wheel[i] = new HashedWheelBucket();
        }
        return wheel;
    }
```

You can increase or decrease the accuracy of the execution timing by specifying smaller or larger tick duration in the constructor. In most network applications, I/O timeout does not need to be accurate. Therefore, the default tick duration is 100 milliseconds and you will not need to try different configurations in most cases.

And **HashedWheelTimer creates a new thread whenever it is instantiated and started**. Therefore, you should make sure to create only one instance and share it across your application. One of the common mistakes, that makes your application unresponsive, is to create a new instance for every connection.

```java
    public HashedWheelTimer(
            ThreadFactory threadFactory,
            long tickDuration, TimeUnit unit, int ticksPerWheel, boolean leakDetection,
            long maxPendingTimeouts, Executor taskExecutor) {
        
        ...
        workerThread = threadFactory.newThread(worker);
        ...
    }
```

The generated worker thread acts as a timer by moving the cursor and checking each timeout.

```java
    private final class Worker implements Runnable {
        ...
       @Override
        public void run() {
            // Initialize the startTime.
            startTime = System.nanoTime();
            if (startTime == 0) {
                // We use 0 as an indicator for the uninitialized value here, so make sure it's not 0 when initialized.
                startTime = 1;
            }

            // Notify the other threads waiting for the initialization at start().
            startTimeInitialized.countDown();

            do {
                final long deadline = waitForNextTick();
                if (deadline > 0) {
                    int idx = (int) (tick & mask);
                    processCancelledTasks();
                    HashedWheelBucket bucket =
                            wheel[idx];
                    transferTimeoutsToBuckets();
                    bucket.expireTimeouts(deadline);
                    tick++;
                }
            } while (WORKER_STATE_UPDATER.get(HashedWheelTimer.this) == WORKER_STATE_STARTED);

            // Fill the unprocessedTimeouts so we can return them from stop() method.
            for (HashedWheelBucket bucket: wheel) {
                bucket.clearTimeouts(unprocessedTimeouts);
            }
            for (;;) {
                HashedWheelTimeout timeout = timeouts.poll();
                if (timeout == null) {
                    break;
                }
                if (!timeout.isCancelled()) {
                    unprocessedTimeouts.add(timeout);
                }
            }
            processCancelledTasks();
        }
        ...
    }
```

```java
        public void expireTimeouts(long deadline) {
            HashedWheelTimeout timeout = head;

            // process all timeouts
            while (timeout != null) {
                HashedWheelTimeout next = timeout.next;
                if (timeout.remainingRounds <= 0) {
                    next = remove(timeout);
                    if (timeout.deadline <= deadline) {
                        timeout.expire();
                    } else {
                        // The timeout was placed into a wrong slot. This should never happen.
                        throw new IllegalStateException(String.format(
                                "timeout.deadline (%d) > deadline (%d)", timeout.deadline, deadline));
                    }
                } else if (timeout.isCancelled()) {
                    next = remove(timeout);
                } else {
                    timeout.remainingRounds --;
                }
                timeout = next;
            }
        }
```

---
reference

- https://www.cse.wustl.edu/~cdgill/courses/cs6874/TimingWheels.ppt
- https://cseweb.ucsd.edu/users/varghese/PAPERS/twheel.ps.Z
- https://medium.com/@raghavan99o/hashed-timing-wheel-2192b5ec8082
- http://www.cs.columbia.edu/~nahum/w6998/papers/sosp87-timing-wheels.pdf
- https://paulcavallaro.com/blog/hashed-and-hierarchical-timing-wheels/
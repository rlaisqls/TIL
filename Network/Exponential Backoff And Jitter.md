
### Introducing OCC
Optimistic concurrency control(OCC) is a time-honored way for multiple writers to safely modify a single object without losing writes. OCC has three nice properties: it will always make progress as long as the underlying store is available, it’s easy to understand, and it’s easy to implement.

while OCC is guaranteed to make progress, it can stil perform quite poorly under high contention. The simplest of this contiention cases is when a whole log of clients start at the same time, and try to update the same database row. With one client guarenteed to succeed every round, the time to complete all the updates grows linearly with contention.

With N clients contending, the total amount of work done by the system increases with N2.

![image](https://github.com/rlaisqls/TIL/assets/81006587/cb23c3d2-cc47-4d84-9271-7a817818d349)

### Adding Backoff

The problem here is that N clients compete in the first rount, N-1 in the second round, and so on. Having every client compete in every roun dis wateful. Slowing clients down may hel, and the classic way to slow clients down is capped exponential backoff. Capped exponential backoff means that clients multiply their backoff by a constant after each attempt, up to some maximum value. In our case, after each unsuccessful attempt, clients sleep for:

```c
sleep = min(cap, base * 2 ** attempt)
```

Running the simulation again shows that backoff helps a small amount, but doesn't solve the problem. Client work has only been reduced slightly.

![image](https://github.com/rlaisqls/TIL/assets/81006587/16cd8173-d354-4626-8896-163814323794)

The best way to see the problem is to look at the times these exponentially backed-off calls happen.

![image](https://github.com/rlaisqls/TIL/assets/81006587/5235d62a-6fa6-40f6-a826-50a45c1ebf7c)

The obvious that the exponential backoff is working, in that the calls are happening less and less frequently. The problem also stands out: there are still clusters of calls. Instead of reducing the number of clients competing in every round, we've just introduced times when no client is competing. Contention hasn't been reduced much, although the natural variance in network delay has introduced some spreading.

### Adding Jitter

The solution isn't to remove backoff. It's to add jitter. Initially, jitter may apper to be a counter-intuitive idea: trying to improve the performancd of a system by adding randomness. The time series above makes a great case for jitter - we want to spread out the spikes to an approximately constant rate. Adding jitter is a small change to the sleep function.

```c
sleep = random_between(0, min(cap, base * ** attempt))
```

The time series looks a whole lot better. The gaps are gone, and beyond the initial spike, there's an approximately constant rate of calls. It's also had a great effect on the total number of calls.

![image](https://github.com/rlaisqls/TIL/assets/81006587/19ae5986-3024-4122-a4a6-a2641fae7368)

In the case with 100 contending clients, we've reduced our call count by more than half. We've also significantly improved the time to completion, when compared to un-jittered exponential backoff.

![image](https://github.com/rlaisqls/TIL/assets/81006587/7e64a0ca-c7da-4c63-8d6e-1e0b16496021)

There are a few ways to implement the timed backoff loops. Let's call the algorithm above "Full Jitter", and consider two alternatives. The first alternative is "Equal Jitter", where we always keep some of the back off and jitter by a smaller amount:

```c
tmp = min(cap, base * 2 ** attempt)
sleep = temp / 2 + random_between(0, tmp / 2)
```

Ter intuition behind this one is that it prevents very short sleeps, always keeping some of the slow down from the backoff. A second alternative is "Decorrelated Jitter", which is similar to "Full Jitter", but we also increase the maximum jitter based on the last random value.

```c
sleep = min(cap, random_bwtween(base, sleep * 3))
```

Which approach do you think is best?

Looking at the amount of client work, the number of calls is approximately the same for “Full” and “Equal” jitter, and higher for “Decorrelated”. Both cut down work substantially relative to both the no-jitter approaches.

![image](https://github.com/rlaisqls/TIL/assets/81006587/5fe5e0a3-d198-4731-9db9-7943f50a7d34)

The no-jitter exponential backoff approach is the clear loser. It not only takes more work, but also takes more time than the jittered approaches. In fact, it takes so much more time we have to leave it off the graph to get a good comparison of the other methods.

![image](https://github.com/rlaisqls/TIL/assets/81006587/4d5cd304-2511-4997-b997-eed15f8f6243)


Of the jittered approaches, “Equal Jitter” is the loser. It does slightly more work than “Full Jitter”, and takes much longer. The decision between “Decorrelated Jitter” and “Full Jitter” is less clear. The “Full Jitter” approach uses less work, but slightly more time. Both approaches, though, present a substantial decrease in client work and server load.

It’s worth noting that none of these approaches fundamentally change the N2 nature of the work to be done, but do substantially reduce work at reasonable levels of contention. The return on implementation complexity of using jittered backoff is huge, and it should be considered a standard approach for remote clients.

---
reference
- https://github.com/aws-samples/aws-arch-backoff-simulator/blob/master/src/backoff_simulator.py

> https://doc.rust-lang.org/std/sync/struct.Condvar.html

- 구조체 Condvar는 Condition Variable의 약자로, 이벤트가 발생할 때까지 스레드를 차단하여 CPU 시간을 소비하지 않도록 하기 위해 사용한다. 조건 변수는 일반적으로 boolean predicate, 뮤텍스와 함께 사용된다. 
- 스레드를 차단해야 한다고 판단하기 전에 뮤텍스 내에서 항상 조건을 검증한다.
- 이 모듈의 함수는 현재 실행 중인 스레드를 차단한다. 동일한 조건 변수에 여러 뮤텍스를 사용하려고 시도하면 런타임 패닉이 발생할 수 있다.

## 예제

```rust
use std::sync::{Arc, Mutex, Condvar};
use std::thread;

let pair = Arc::new((Mutex::new(false), Condvar::new()));
let pair2 = Arc::clone(&pair);

// Inside of our lock, spawn a new thread, and then wait for it to start.
thread::spawn(move|| {
    let (lock, cvar) = &*pair2;
    let mut started = lock.lock().unwrap();
    *started = true;
    // We notify the condvar that the value has changed.
    cvar.notify_one();
});

// Wait for the thread to start up.
let (lock, cvar) = &*pair;
let mut started = lock.lock().unwrap();
while !*started {
    started = cvar.wait(started).unwrap();
}
```

## 함수

### `new()`

```rust
pub const fn new() -> Condvar
```

새로운 Condvar를 생성한다.

### `wait()`

```rust
pub fn wait<'a, T>(
    &self,
    guard: MutexGuard<'a, T>
) -> LockResult<MutexGuard<'a, T>>
```

현재 조건 변수가 알림을 받을 때까지 현재 스레드를 블록한다.

이 함수는 뮤텍스를 잠그고 현재 스레드를 차단한다. 뮤텍스가 해제된 후 `notify_one` 또는 `notify_all`를 호출하면 스레드를 깨울 수 있다. 함수 호출이 반환되면 지정된 락이 다시 획득된다.

스레드가 락을 다시 획득할 때 뮤텍스가 손상되어있는 경우 오류를 반환한다.

**예제**

```rust
use std::sync::{Arc, Mutex, Condvar};
use std::thread;

let pair = Arc::new((Mutex::new(false), Condvar::new()));
let pair2 = Arc::clone(&pair);

thread::spawn(move|| {
    let (lock, cvar) = &*pair2;
    let mut started = lock.lock().unwrap();
    *started = true;
    // 값이 변경되었음을 조건 변수에 알린다.
    cvar.notify_one();
});

// 스레드가 시작되기를 기다린다.
let (lock, cvar) = &*pair;
let mut started = lock.lock().unwrap();
// 내부의 값이 `false`인 동안 기다린다.
while !*started {
    started = cvar.wait(started).unwrap();
}
```

### `wait_while()`

```rust
pub fn wait_while<'a, T, F>(
    &self,
    guard: MutexGuard<'a, T>,
    condition: F
) -> LockResult<MutexGuard<'a, T>>
where
    F: FnMut(&mut T) -> bool,
```

현재 스레드가 알림을 받아 조건을 검증했을 때 그 결과가 false일 때까지 현재 스레드를 차단한다. 다시말해, 스레드를 차단했다가 알림을 받아 조건을 검증한 결과가 false일 때 차단을 해제한다.

이 함수도 `wait()`과 동일하게 뮤텍스를 잠그고 현재 스레드를 차단한다.

**예제**
```rust
use std::sync::{Arc, Mutex, Condvar};
use std::thread;

let pair = Arc::new((Mutex::new(true), Condvar::new()));
let pair2 = Arc::clone(&pair);

thread::spawn(move|| {
    let (lock, cvar) = &*pair2;
    let mut pending = lock.lock().unwrap();
    *pending = false;
    // 값이 변경되었음을 조건 변수에 알린다.
    cvar.notify_one();
});

// 스레드가 시작되기를 기다란다.
let (lock, cvar) = &*pair;
// 내부의 값이 `true`인 동안 기다린다.
let _guard = cvar.wait_while(lock.lock().unwrap(), |pending| { *pending }).unwrap();
```

### `wait_timeout()`

```rust
pub fn wait_timeout<'a, T>(
    &self,
    guard: MutexGuard<'a, T>,
    dur: Duration
) -> LockResult<(MutexGuard<'a, T>, WaitTimeoutResult)>
```

이 조건 변수에 대한 알림을 기다리되, dur 파라미터로 지정한 기간만큼 차단한 후 타임아웃을 해제한다. 선점(preemption) 또는 플랫폼 간의 차이 등으로 인해 대기 시간이 정확히 dur이 되지 않을 수 있기 때문에, 정확한 기간이 보장되어야 하는 경우에는 적절하지 않다.

반환된 WaitTimeoutResult 값은 타임아웃이 경과했는지 여부를 나타낸다.

### `notify_one()`

하나의 차단된 스레드를 깨운다.

만약 이 조건 변수에 차단된 스레드가 있다면, 해당 스레드는 wait 또는 wait_timeout 호출로부터 깨어날 것이다.

```rust
use std::sync::{Arc, Mutex, Condvar};
use std::thread;

let pair = Arc::new((Mutex::new(false), Condvar::new()));
let pair2 = Arc::clone(&pair);

thread::spawn(move|| {
    let (lock, cvar) = &*pair2;
    let mut started = lock.lock().unwrap();
    *started = true;
    // 값이 변경되었음을 알린다.
    cvar.notify_one();
});

// 스레드가 시작될 때까지 기다린다.
let (lock, cvar) = &*pair;
let mut started = lock.lock().unwrap();
// Mutex<bool> 내부의 값이 `false`인 동안 기다린다.
while !*started {
    started = cvar.wait(started).unwrap();
}
```

### `notify_all()`

이 condvar에 대기 중인 모든 차단된 스레드를 깨운다.

이 메서드는 조건 변수에 대기 중인 현재 모든 대기 스레드가 깨어나도록 보장한다.

```rust
use std::sync::{Arc, Mutex, Condvar};
use std::thread;

let pair = Arc::new((Mutex::new(false), Condvar::new()));
let pair2 = Arc::clone(&pair);

thread::spawn(move|| {
    let (lock, cvar) = &*pair2;
    let mut started = lock.lock().unwrap();
    *started = true;
    // 값이 변경되었음을 알린다.
    cvar.notify_all();
});

// 스레드가 시작될 때까지 기다린다.
let (lock, cvar) = &*pair;
let mut started = lock.lock().unwrap();
// Mutex<bool> 내부의 값이 `false`인 동안 기다린다.
while !*started {
    started = cvar.wait(started).unwrap();
}
```

---
참고
- https://doc.rust-lang.org/std/sync/struct.Condvar.html

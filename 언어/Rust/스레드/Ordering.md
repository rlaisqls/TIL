> <https://doc.rust-lang.org/std/sync/atomic/enum.Ordering.html>

- `Ordering`은 원자적 연산(atomic operation)이 다른 스레드에서 어떤 순서로 관찰되는지를 지정하는 열거형이다. `std::sync::atomic` 모듈의 `AtomicUsize`, `AtomicBool` 등 원자적 타입의 `load`, `store`, `compare_exchange` 같은 메서드에 인자로 전달한다.
- 컴파일러와 CPU는 실제 실행 결과가 같다면 명령어의 순서를 재배열(reorder)할 수 있는데, 이는 싱글 스레드에서는 문제가 없지만 여러 스레드가 메모리를 공유하는 상황에서는 한 스레드의 변경 사항이 다른 스레드에 어떤 순서로 보이는지가 프로그램의 정확성에 직접적인 영향을 준다.
- `Ordering`은 이러한 재배열을 어느 정도까지 허용할지를 결정하며, 값이 엄격할수록(강한 순서를 요구할수록) 안전성은 높아지지만 성능은 낮아진다.

## 종류

### `Relaxed`

```rust
Ordering::Relaxed
```

- 가장 느슨한 순서로, 해당 연산의 원자성(atomicity)만 보장하고 다른 메모리 연산과의 순서 관계는 전혀 보장하지 않는다.
- 단순히 값을 증가시키는 카운터처럼, 값 자체의 정확성만 필요하고 다른 메모리 접근과의 선후 관계가 중요하지 않을 때 사용한다.

```rust
use std::sync::atomic::{AtomicUsize, Ordering};

static COUNTER: AtomicUsize = AtomicUsize::new(0);

COUNTER.fetch_add(1, Ordering::Relaxed);
```

### `Release`

```rust
Ordering::Release
```

- store류 연산(`store`, `fetch_add` 등)에 사용하며, 이 연산 이전에 있었던 모든 메모리 쓰기가 다른 스레드에서 이 값을 `Acquire`로 읽었을 때 반드시 함께 보이도록 보장한다.
- 즉 "이 지점 이전의 작업을 여기서 확정 짓는다"는 의미로, 뮤텍스의 `unlock`처럼 임계 구역에서의 변경 사항을 공개할 때 사용한다.

### `Acquire`

```rust
Ordering::Acquire
```

- load류 연산(`load`, `compare_exchange`의 성공 분기 등)에 사용하며, 다른 스레드가 `Release`로 저장하기 이전에 수행한 모든 메모리 쓰기가 이 연산 이후에는 반드시 보이도록 보장한다.
- 뮤텍스의 `lock`처럼 다른 스레드가 공개한 변경 사항을 안전하게 관찰해야 할 때 사용한다.
- `Release`/`Acquire`는 항상 쌍으로 사용되어 "happens-before" 관계를 형성한다.

```rust
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;

let ready = Arc::new(AtomicBool::new(false));
let ready2 = Arc::clone(&ready);

thread::spawn(move || {
    // 준비 작업 수행...
    ready2.store(true, Ordering::Release);
});

// ready가 true가 될 때까지 대기
while !ready.load(Ordering::Acquire) {}
// 여기서는 다른 스레드의 준비 작업 결과를 안전하게 관찰할 수 있다.
```

### `AcqRel`

```rust
Ordering::AcqRel
```

- `fetch_add`, `compare_exchange`처럼 하나의 연산이 값을 읽고(load) 쓰는(store) 동작을 동시에 수행할 때 사용한다.
- 읽기 부분에는 `Acquire`, 쓰기 부분에는 `Release`의 의미를 함께 적용한다.

### `SeqCst`

```rust
Ordering::SeqCst
```

- 순차적 일관성(Sequentially Consistent)을 보장하는 가장 강력한 순서로, `Acquire`/`Release`의 성질을 모두 포함하는 것에 더해 모든 스레드가 `SeqCst` 연산들의 전역적으로 동일한 순서를 관찰하도록 보장한다.
- 가장 이해하기 쉽고 안전하지만 성능 비용이 가장 크므로, 정말 전역적인 순서가 필요한 경우가 아니라면 `Acquire`/`Release` 조합으로 충분한 경우가 많다.

---
참고

- <https://doc.rust-lang.org/std/sync/atomic/enum.Ordering.html>
- <https://doc.rust-lang.org/nomicon/atomics.html>

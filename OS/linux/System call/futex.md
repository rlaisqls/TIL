futex(Fast Userspace muTEX)는 리눅스에서 제공하는 저수준 동기화 메커니즘이다. 사용자 공간에서 빠르게 락을 처리하고, 경합이 발생할 때만 커널로 진입하여 효율적인 동기화를 제공한다.

```c
#include <linux/futex.h>
#include <sys/syscall.h>

int futex(int *uaddr, int futex_op, int val,
          const struct timespec *timeout,
          int *uaddr2, int val3);
```

- `uaddr`: 동기화에 사용할 메모리 주소 (보통 32비트 정수)
- `futex_op`: 수행할 연산 (FUTEX_WAIT, FUTEX_WAKE 등)
- `val`: 연산에 따라 다른 의미 (WAIT에서는 기대값, WAKE에서는 깨울 쓰레드 수)

## 주요 연산

### FUTEX_WAIT

```c
futex(addr, FUTEX_WAIT, expected_val, timeout, NULL, 0);
```

1. `*addr`의 값이 `expected_val`과 같은지 확인
2. **같으면**: 해당 쓰레드를 대기 상태로 전환 (sleep)
3. **다르면**: 즉시 `EAGAIN` 반환

### FUTEX_WAKE

```c
futex(addr, FUTEX_WAKE, num_to_wake, NULL, NULL, 0);
```

- `addr`에서 대기 중인 쓰레드 중 `num_to_wake`개를 깨움

## EAGAIN 에러

`FUTEX_WAIT` 호출 시 `EAGAIN`이 반환되는 것은 기다리려던 조건이 이미 변경되었으니 다시 확인하라는 의미이다.

```
┌─────────────────────────────────────────────────────────┐
│  Thread A                    Thread B                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. *addr 값 확인: 0                                     │
│                              2. *addr = 1로 변경         │
│                              3. FUTEX_WAKE 호출          │
│  4. futex(WAIT, expected=0)                             │
│     → 커널 진입                                          │
│     → *addr 확인: 1 (≠ 0)                               │
│     → EAGAIN 반환                                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

올바르게 처리하기 위해선 재시도 로직을 적절히 추가해야한다.

```c
// 올바른 구현: EAGAIN 시 조건 재확인 후 재시도
while (should_wait()) {
    int ret = futex(&lock, FUTEX_WAIT, expected, NULL, NULL, 0);
    if (ret == -1) {
        if (errno == EAGAIN) {
            // 값이 이미 바뀜 → 조건 다시 확인
            continue;
        }
        if (errno == EINTR) {
            // 시그널에 의해 중단됨 → 재시도
            continue;
        }
        // 다른 에러는 처리
        handle_error();
    }
}
```

```c
// 잘못된 구현: EAGAIN 무시
int ret = futex(&lock, FUTEX_WAIT, expected, NULL, NULL, 0);
if (ret == -1) {
    return;  // EAGAIN이어도 그냥 종료 → 버그
}
```

## futex 변형

| 연산 | 설명 |
|------|------|
| `FUTEX_WAIT` | 값이 일치하면 대기 |
| `FUTEX_WAKE` | 대기 중인 쓰레드 깨움 |
| `FUTEX_WAIT_PRIVATE` | 프로세스 내부 전용 (더 빠름) |
| `FUTEX_WAKE_PRIVATE` | 프로세스 내부 전용 (더 빠름) |
| `FUTEX_WAIT_BITSET` | 비트마스크로 선택적 대기 |
| `FUTEX_WAKE_BITSET` | 비트마스크로 선택적 깨움 |

## 고수준 동기화와의 관계

futex는 직접 사용하기보다 고수준 동기화 기능의 기반이 된다:

```
┌─────────────────────────────────────────────────────────┐
│  Application                                            │
├─────────────────────────────────────────────────────────┤
│  pthread_mutex, std::mutex, Go sync.Mutex               │
├─────────────────────────────────────────────────────────┤
│  glibc / runtime                                        │
├─────────────────────────────────────────────────────────┤
│  futex syscall                                          │
├─────────────────────────────────────────────────────────┤
│  Linux Kernel                                           │
└─────────────────────────────────────────────────────────┘
```

## strace로 futex 관찰

```bash
strace -e trace=futex ./program
```

출력 예시:

```
futex(0x7f..., FUTEX_WAIT_PRIVATE, 0, NULL) = 0
futex(0x7f..., FUTEX_WAKE_PRIVATE, 1) = 1
futex(0x7f..., FUTEX_WAIT_BITSET_PRIVATE, 0, NULL, FUTEX_BITSET_MATCH_ANY) = -1 EAGAIN
```

## 실제 버그 사례

멀티쓰레드 프로그램에서 EAGAIN을 잘못 처리하면 다음과 같은 문제가 발생할 수 있다:

```
정상 동작:
  Thread 1: EAGAIN → 조건 재확인 → 작업 계속 → 완료

버그 있는 동작:
  Thread 1: EAGAIN → "작업 없음"으로 오해 → 조기 종료 → 작업 누락
```

이런 버그는 간헐적으로 발생하고 재현이 어려워 디버깅이 까다롭다.

## 참고

- <https://wariua.github.io/man-pages-ko/futex%287%29/>
- <https://man7.org/linux/man-pages/man2/futex.2.html>
- <https://man7.org/linux/man-pages/man7/futex.7.html>
- <https://lwn.net/Articles/360699/>

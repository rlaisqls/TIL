# TAS(Test and set)

TAS은 메모리 위치를 write하고, 그것의 이전 값을 atomic으로 (thread safe)하게 반환하는 명령어이다.

한 프로세스가 TAS를 performing하고 있다면, 다른 프로세스는 그 프로세스의 작용이 끝나기 전에 TAS를 실행할 수 없다. 

## 동작

동작 내용
- 주어진 불리언 값의 현재 값을 반환하고, 그 불리언 값을 true 로 덮어쓴다.
반환 정보
- true : 플래그가 원래 true 일 때.
- false : 플래그가 원래 false 일 때. ( flag = true 명령도 동시에 일어남)

중간에 문맥교환이 발생한다면 결과 값은 달라질 수 있지만, 간단한 예제코드로 살며보자면 아래와 같다.

```c
bool flag = false;
testAndSet(flag); // false
testAndSet(flag); // true
testAndSet(flag); // true
flag = false;
testAndSet(flag); // false
```

<img width="617" alt="image" src="https://user-images.githubusercontent.com/81006587/233374728-449a0e92-746e-4b41-bf60-ebbf04b110c2.png">


## 하드웨어적 구현 방법

두개의 CPU가 있다. 그리고 두 CPU가 공유할 수 있는 공간인 [DPRAM](https://en.wikipedia.org/wiki/DPRAM)이 있다.

CPU1이 TAS를 발행하면, DPRAM이 `internal note`라는걸 내부에 만들어놓고 메모리 주소를 저장해놓는다.

이때 나머지 CPU2가 같은 메모리에 TAS를 발행하면 DPRAM은 `internal note`를 체크해본다. 그곳에 뭔가 있다는걸 확인하면 `BUSY` interrrupt를 발행해서 CPU2가 기다린 후에 retry하도록 한다. 이것이 바로 interrupt mechanism를 사용해서 busy waiting과 spinlock을 구현하는 방법이다. 

CPU2가 메모리공간에 접근을 시도하든 그렇지 않든, DPRAM은 CPU 1이 제공하는 `test`를 수행한다 그 test가 성공하면 DPRAM은 메모리 주소를 CPU1이 줬던 값으로 바꾸고, `internal note`를 지워서 다른 CPU나 프로세스가 접근할 수 있도록 한다.

## 소프트웨어적 구현 방법

TAS 명령어는 bool과 함께 사용될 때 함수가 atomic하게 실행되어야 한다는 점을 제외하고, 아래 코드와 같은 로직을 사용한다.

```c
function TestAndSet(boolean_ref lock) {
    boolean initial = lock;
    lock = true;
    return initial;
}
```

여기서 설정되는 값과 테스트하는 값은 고정적이고 불변적이며 테스트 결과에 관계없이 값이 업데이트되는 반면, 위에서 봤던 DPRAM TAS의 경우 메모리는 테스트가 성공할 때만 설정되며, 설정할 값과 테스트 조건은 CPU에 의해 지정된다.

여기서는 설정할 값이 1만 될 수 있도록 했지만 0과 1이 메모리 위치에 대한 유일한 유효한 값으로 간주되고 "값이 0이 아니다"가 유일하게 허용되는 테스트인 경우, 이는 DPRAM 하드웨어에 대해 설명된 경우와 동일하다. 그러한 관점에서, 이것은 정확하게 "테스트 앤 세트"라고 불릴 수 있다.

중요한 점은 테스트 앤 세트의 일반적인 의도와 원칙이다: 값은 테스트되고 하나의 atomic한 연산에서 설정되므로 다른 프로그램 스레드나 프로세스는 그것이 test한 다음 set되기 전에 대상 메모리 위치를 변경할 수 없다. (메모리 값은 무조건 특정 값을 하나만 가지기 때문이다.)

## SpinLock

test_and_set 의 성질을 활용하여 SpinLock을 구현할 수 있다.

## 상호배제

TAS를 이용해서 상호배제를 구현할 수도 있다.

```c
volatile int lock = 0;

void critical() {
    // Spin lock: loop forever until we get the lock; we know the lock was
    // successfully obtained after exiting this while loop because the 
    // test_and_set() function locks the lock and returns the previous lock 
    // value. If the previous lock value was 1 then the lock was **already**
    // locked by another thread or process. Once the previous lock value
    // was 0, however, then it indicates the lock was **not** locked before we
    // locked it, but now it **is** locked because we locked it, indicating
    // we own the lock.
    while (test_and_set(&lock) == 1);  
    critical section  // only one process can be in this section at a time
    lock = 0;  // release lock when finished with the critical section
}
```

**진행 흐름**
- 가장 먼저 TestAndSet을 실행하는 프로세스가 `while(TestAndSet(&lock));` 루프에서 `lock = ture`로 바꾸고 `false`를 반환받아 while문을 빠져나오며 임계 구역에 진입한다.
- 다른 프로세스는 `lock = false`가 될때까지 while루프를 빠져나오지 못하고 계속 대기하게 된다.
- 임계구역에 진입했던 프로세스가 임계구역을 빠져나오면서 `lock = false`를 수행하여 lock을 풀어주면 대기하던 다른 프로세스가 임계구역에 진입하게 된다.

---

참고

- https://en.wikipedia.org/wiki/Test-and-set
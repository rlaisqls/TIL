GIL(Global Interpreter Lock)은 CPython 인터프리터에서 한 번에 하나의 스레드만 Python 바이트코드를 실행할 수 있도록 강제하는 뮤텍스이다.

## 레퍼런스 카운팅과 GIL

CPython은 객체의 메모리 관리를 레퍼런스 카운팅으로 한다. 모든 객체에 참조 횟수(`ob_refcnt`)가 있고, 이 값이 0이 되면 메모리를 해제한다.

```c
// CPython 내부의 참조 카운트 조작
Py_INCREF(op);  // ob_refcnt++
Py_DECREF(op);  // ob_refcnt--, 0이면 해제
```

여러 스레드가 동시에 이 카운터를 수정하면 race condition이 발생한다. 예를 들어 두 스레드가 동시에 `Py_DECREF`를 호출하면, 카운터가 1인 객체를 두 번 해제하거나 아예 해제하지 못하는 상황이 생길 수 있다.

이를 해결하는 방법은 두 가지이다.

- **객체별 fine-grained 락**: 모든 객체마다 개별 락을 건다. 오버헤드가 크고 데드락 위험이 있다. 실제로 1999년 Greg Stein이 CPython에서 GIL을 제거하고 fine-grained 락을 적용하는 패치를 만들었지만, 싱글스레드 성능이 40% 이상 떨어져서 채택되지 않았다.
- **인터프리터 전체 락(GIL)**: 인터프리터에 락을 하나만 둔다. 단순하고 싱글스레드 성능 저하가 없다.

CPython은 후자를 택했다.

## GIL의 동작

Python 스레드는 일정량의 바이트코드를 실행한 뒤 GIL을 해제하고 다른 스레드에 실행 기회를 넘긴다. Python 3.2 이전에는 `sys.setcheckinterval()`로 바이트코드 명령어 수 기준으로 전환했고, 3.2부터는 시간 기반(기본 5ms)으로 변경되었다.

```python
import sys
sys.getswitchinterval()  # 기본값: 0.005 (5ms)
sys.setswitchinterval(0.001)  # 1ms로 변경
```

I/O 작업(네트워크, 파일, sleep 등)을 할 때는 GIL을 해제한다. 따라서 I/O-bound 멀티스레딩은 GIL의 영향을 거의 받지 않는다. C 확장 모듈도 `Py_BEGIN_ALLOW_THREADS` 매크로로 GIL을 명시적으로 해제하고 작업할 수 있어서, numpy 같은 라이브러리는 실제로 멀티코어를 활용한다.

```c
// C 확장에서 GIL 해제
Py_BEGIN_ALLOW_THREADS
// GIL 없이 실행되는 CPU-intensive 코드
heavy_computation();
Py_END_ALLOW_THREADS
```

## CPU-bound에서의 영향

GIL은 뮤텍스이므로, Python 바이트코드를 실행하려면 반드시 GIL을 획득해야 한다. GIL은 하나뿐이기 때문에 스레드가 아무리 많아도 GIL을 잡고 있는 스레드 하나만 Python 코드를 실행할 수 있고, 나머지 스레드는 전부 GIL이 풀릴 때까지 대기한다. 결국 CPU-bound 작업에서는 스레드들이 번갈아가며 순차 실행하는 것과 같아서, 코어가 여러 개 있어도 실제 병렬 실행이 이루어지지 않는다.

```python
import threading, time

def count():
    n = 0
    for _ in range(50_000_000):
        n += 1

# 싱글스레드
start = time.time()
count()
count()
print(f"sequential: {time.time() - start:.2f}s")

# 멀티스레드 - GIL 때문에 더 빨라지지 않음
start = time.time()
t1 = threading.Thread(target=count)
t2 = threading.Thread(target=count)
t1.start(); t2.start()
t1.join(); t2.join()
print(f"threaded: {time.time() - start:.2f}s")
```

오히려 스레드 간 GIL 경합과 컨텍스트 스위칭 비용 때문에 멀티스레드가 더 느릴 수 있다.

## 우회 방법

**`multiprocessing`**

프로세스를 분리하면 각각 독립된 인터프리터와 GIL을 가진다.

```python
from multiprocessing import Pool

def heavy(n):
    return sum(range(n))

with Pool(4) as p:
    results = p.map(heavy, [10**7] * 4)
```

프로세스 간 데이터 교환은 pickle 직렬화를 거치므로 IPC 오버헤드가 있다. 작업 단위가 충분히 클 때 효과적이다.

**C 확장에서 GIL 해제**

연산 집중 부분을 C, Cython, Rust 등으로 작성하고 GIL을 해제한다. numpy, scikit-learn 같은 라이브러리가 이 방식으로 멀티코어를 활용한다.

**`asyncio`**

I/O-bound 작업은 코루틴으로 동시성을 확보한다. GIL과 직접적인 관계는 없지만, I/O 대기 시간을 효율적으로 활용하는 대안이다.

## 다른 Python 구현체의 GIL

- **PyPy**: GIL이 있다. STM(Software Transactional Memory) 기반 제거 시도가 있었지만 실용화되지 않았다.
- **Jython**: GIL이 없다. JVM의 스레딩 모델을 그대로 사용한다.
- **IronPython**: GIL이 없다. .NET CLR 위에서 동작한다.
- **RustPython**: GIL이 있다.

## Free-threaded CPython (PEP 703)

CPython 3.13부터 GIL을 제거한 실험적 빌드가 도입되었다.

```bash
# free-threaded 빌드 (3.13+)
./configure --disable-gil
make
```

GIL 없이 레퍼런스 카운팅의 안전성을 보장하기 위해 biased reference counting, deferred reference counting 등의 기법을 사용한다. 싱글스레드 성능 저하를 최소화하면서 멀티스레드 병렬 실행을 가능하게 하는 것이 목표이다.

다만 기존 C 확장 모듈들이 GIL 존재를 전제로 작성되어 있어서, 생태계 전체가 thread-safe하게 업데이트되기까지는 시간이 걸린다. CPython 3.13에서는 실험적 기능이며, 점진적으로 안정화될 예정이다.

---
참고

- https://docs.python.org/3/glossary.html#term-global-interpreter-lock
- https://peps.python.org/pep-0703/
- https://docs.python.org/3/howto/free-threading-python.html

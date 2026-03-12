Python은 언어 명세와 구현체가 분리되어 있다. 문법과 동작을 정의한 것이 명세이고, 이를 실행하는 인터프리터는 여러 개 존재한다. 터미널에서 `python`을 실행하면 시스템에 설치된 구현체가 동작하는데, 별도 설정이 없다면 CPython이다.

```bash
$ python -c "import platform; print(platform.python_implementation())"
CPython
```

## CPython

C로 작성된 레퍼런스 구현체. `python.org`에서 배포하는 바이너리가 이것이다.

소스코드를 바이트코드(`.pyc`)로 컴파일한 뒤 CPython VM이 한 명령어씩 해석하며 실행한다.

- 언어 명세의 기준. 새 문법이나 기능은 CPython에 먼저 구현된다.
- C 확장 API(`Python.h`)를 제공한다. numpy, pandas, TensorFlow 등은 이 API로 C/C++ 코드를 호출한다.
- 메모리 관리에 레퍼런스 카운팅 + 순환 참조 GC를 사용한다.
- [GIL](./GIL.md)이 있어서 멀티스레드 Python 코드의 병렬 실행이 제한된다.

순수 Python 코드의 실행 속도는 느리지만, C 확장 생태계가 압도적으로 넓어서 사실상 표준이다.

## PyPy

RPython으로 작성된 Python 인터프리터. 핵심은 **JIT 컴파일러**이다.

- CPython: 소스 → 바이트코드 → VM이 해석 실행
- PyPy: 소스 → 바이트코드 → VM이 해석 실행 → hot path를 기계어로 JIT 컴파일

반복 연산이 많은 순수 Python 코드에서 CPython 대비 4~10배 빠르다. JIT 워밍업이 필요하므로 짧은 스크립트에서는 오히려 느릴 수 있다. 자체 GC를 사용하여 메모리 효율이 좋은 경우가 많고, GIL은 있다.

가장 큰 약점은 **C 확장 호환성**이다. CPython C API에 의존하는 라이브러리를 `cpyext` 호환 레이어로 지원하지만, 느리거나 동작하지 않는 경우가 있다.

순수 Python 코드가 대부분이고 C 확장 의존이 적은 서버 애플리케이션에서 드롭인 교체로 쓸 만하다.

**RPython**

RPython(Restricted Python)은 정적 타입 추론이 가능하도록 제약을 건 Python 부분집합이다. 변수마다 타입이 하나로 고정되어야 하고, 리스트도 동일 타입 원소만 허용하며, `*args`/`**kwargs`, `exec`, `eval`을 쓸 수 없다.

```python
# 유효한 RPython - x는 항상 int
def factorial(x):
    result = 1
    while x > 1:
        result *= x
        x -= 1
    return result

# 유효하지 않은 RPython - x가 int일 수도 str일 수도 있음
def ambiguous(x):
    if some_condition():
        x = 1
    else:
        x = "hello"
    return x
```

이 제약 덕분에 RPython 툴체인이 코드를 C로 변환하고 네이티브 바이너리로 컴파일할 수 있다. 인터프리터 코드에 JIT 힌트(`jit_merge_point`, `promote` 등)를 달아두면 툴체인이 **JIT 컴파일러를 자동 생성**한다. PyPy 개발자가 JIT을 직접 구현한 게 아니라, 인터프리터를 RPython으로 작성하면 JIT이 따라오는 구조이다. Python 외에도 Ruby, Prolog, Smalltalk 등의 실험적 인터프리터가 RPython으로 만들어졌다.

**JIT이 빠른 이유**

CPython의 인터프리터 루프는 바이트코드를 한 명령어씩 읽고, 피연산자 타입을 확인하고, 타입에 맞는 연산 함수를 호출하는 과정을 매번 반복한다. `n += 1`이 루프 안에서 1억 번 실행되면, n이 항상 int라는 사실과 무관하게 1억 번 모두 타입 체크와 함수 디스패치를 거친다. 각 바이트코드 실행이 독립적이라 이전 실행의 정보를 재활용할 수 없다.

JIT은 런타임에 수집한 타입 정보를 기반으로 특수화된 기계어를 생성한다.

- **타입 특수화**: "이 변수는 항상 int였다"는 관찰을 바탕으로 int 전용 덧셈 기계어를 생성한다. 범용 디스패치가 정적 타입 수준 연산으로 축소되는 것이다. 타입이 바뀌면 컴파일된 코드를 폐기하고 재생성한다(guard + deoptimization).
- **인라이닝**: 함수 호출을 제거하고 호출 대상 코드를 호출 지점에 삽입한다.
- **루프 최적화**: 루프 내 불변 연산을 외부로 이동하거나, 불필요한 박싱/언박싱을 제거한다.

AOT 컴파일러는 런타임 정보가 없어 모든 가능한 타입 조합을 고려해야 하지만, JIT은 실제 관찰된 타입만 대상으로 하므로 더 공격적인 최적화가 가능하다.

CPython에 같은 방식을 적용하려면 코드 생성기, 레지스터 할당기, 가드/디옵티마이제이션 메커니즘 같은 인프라가 필요한데, CPython은 단순성과 유지보수성을 우선했다. 다만 3.11부터 **Specializing Adaptive Interpreter**를 도입하여 바이트코드 수준에서 제한적인 타입 특수화를 시도하고 있다. `BINARY_ADD`가 반복적으로 int에 대해 호출되면 `BINARY_ADD_INT`로 교체하는 식이다.

## Jython

Java로 작성된 구현체. Python 코드를 JVM 바이트코드로 컴파일하여 실행한다. Java 클래스를 Python에서 직접 import할 수 있고, JVM 스레딩을 그대로 쓰기 때문에 GIL이 없다. C 확장은 지원하지 않는다.

**Python 2.7까지만 지원**하며 사실상 개발이 중단됐다.

## IronPython

C#으로 작성된 구현체. .NET CLR 위에서 동작한다. .NET 라이브러리를 Python에서 직접 사용할 수 있고, .NET 스레딩 모델을 쓰므로 GIL이 없다. C 확장은 미지원.

IronPython 3이 Python 3을 지원하지만 개발 진행이 느리다. .NET 환경에서 스크립팅이 필요할 때 쓰인다.

## RustPython

Rust로 작성된 인터프리터. WebAssembly로 컴파일할 수 있어서 브라우저에서 Python을 실행할 수 있고, Rust 프로젝트에 인터프리터를 임베딩할 수 있다. GreptimeDB, Ruff 등이 실제로 RustPython을 활용한다.

JIT이 없어서(실험적 JIT 크레이트는 존재) 성능은 CPython과 비슷하거나 느리다. C 확장을 지원하지 않고, CPython 완전 호환도 아직 아니다. 범용 인터프리터보다는 WASM이나 Rust 앱 임베딩 용도에 가치가 있다.

## MicroPython / CircuitPython

마이크로컨트롤러용 Python 구현체이다.

**MicroPython**은 C로 작성되어 256KB ROM, 16KB RAM 정도의 환경에서 동작한다. ESP32, Raspberry Pi Pico 같은 보드에서 사용하며, Python 3 핵심 문법을 지원하되 표준 라이브러리 일부만 포함한다. 하드웨어 제어용 모듈(`machine`, `network` 등)을 제공한다.

**CircuitPython**은 MicroPython 포크로, Adafruit가 주도한다. 교육과 입문에 초점을 맞추어 USB 드라이브 방식의 코드 배포와 더 간단한 하드웨어 API를 제공한다.

## Cython

Python 구현체가 아니라 **Python과 C를 섞어 쓸 수 있는 컴파일 언어**이다. Python 문법에 C 타입 선언을 추가한 `.pyx` 파일을 C로 변환하고 컴파일하여 CPython 확장 모듈을 생성한다.

```python
# example.pyx
def fib(int n):
    cdef int a = 0, b = 1, i
    for i in range(n):
        a, b = b, a + b
    return a
```

성능이 중요한 부분만 Cython으로 작성하면 순수 Python 대비 수십 배의 성능 향상을 얻을 수 있다.

---
참고

- <https://docs.python.org/3/reference/>
- <https://www.pypy.org/>
- <https://micropython.org/>
- <https://rustpython.github.io/>
- <https://cython.org/>

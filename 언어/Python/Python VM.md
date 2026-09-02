PVM(Python Virtual Machine)은 컴파일된 바이트코드를 한 명령어씩 해석해서 실행하는 인터프리터 루프이다. `python` 실행 파일을 돌렸을 때 실제로 코드를 실행하는 주체가 이것이다.

**실행 흐름**

1. 소스코드(`.py`)를 파서가 AST(Abstract Syntax Tree)로 변환한다.
2. 컴파일러가 AST를 **바이트코드**로 변환한다. `__pycache__`에 `.pyc`로 캐싱되어, 소스가 바뀌지 않으면 재컴파일을 건너뛴다.
3. **PVM**이 바이트코드를 프레임 단위로 한 명령어씩 실행한다.

```
소스코드(.py) → AST → 바이트코드(.pyc) → PVM 실행
```

CPython 기준으로 이 인터프리터 루프는 `Python/ceval.c`의 `_PyEval_EvalFrameDefault` 함수에 구현되어 있다. 거대한 `switch`문(또는 이를 대체하는 computed goto)으로, 바이트코드 명령어(opcode)마다 분기해서 처리한다.

`dis` 모듈로 함수가 어떤 바이트코드로 컴파일되는지 확인할 수 있다.

```python
import dis

def add(a, b):
    return a + b

dis.dis(add)
```

```
  1           0 RESUME                   0

  2           2 LOAD_FAST                0 (a)
              4 LOAD_FAST                1 (b)
              6 BINARY_OP                0 (+)
             10 RETURN_VALUE
```

PVM은 스택 기반 머신이다. `LOAD_FAST`가 지역 변수를 스택에 push하고, `BINARY_OP`가 스택 top 두 값을 pop해서 연산한 뒤 결과를 다시 push하는 식으로 동작한다. 레지스터 기반 VM(예: Lua)과 달리 모든 연산이 스택을 경유한다.

## Frame

함수가 호출될 때마다 PVM은 **프레임 객체**를 하나 생성한다. 프레임은 다음을 담는다.

- 바이트코드와 현재 실행 위치(명령어 포인터)
- 값 스택(연산에 쓰이는 스택)
- 지역/전역/빌트인 네임스페이스에 대한 참조

함수 호출은 새 프레임을 만들어 콜 스택에 쌓고, 함수가 반환되면 해당 프레임을 버리는 것과 같다. `traceback` 모듈이 예외 발생 시 보여주는 호출 스택이 바로 이 프레임 체인이다.

```python
import sys
sys._getframe()          # 현재 프레임 객체
sys._getframe().f_lineno # 현재 실행 중인 라인 번호
```

## 타입 체크, 디스패치 비용

PVM은 매 바이트코드 실행마다 피연산자 타입을 확인하고 그에 맞는 연산 함수를 호출한다. 예를 들어 `BINARY_OP`(`+`)는 피연산자가 int인지 str인지 list인지에 따라 다른 C 함수(`long_add`, `unicode_concat` 등)로 분기한다. 이 범용 디스패치가 반복문에서 매번 되풀이되는 것이 CPython이 느린 주된 이유이다.

```python
n = 0
for _ in range(10**8):
    n += 1  # 매 반복마다 n의 타입을 확인하고 int 덧셈 함수를 찾아 호출
```

Python 3.11부터 도입된 **Specializing Adaptive Interpreter**(PEP 659)는 이 비용을 줄이려 한다. 같은 바이트코드가 반복적으로 같은 타입에 대해 실행되면, 범용 `BINARY_OP`를 `BINARY_OP_ADD_INT` 같은 특수화된 버전으로 교체해서 타입 체크를 생략한다. 타입이 바뀌면 다시 범용 버전으로 되돌아간다(deoptimization).

## 다른 구현체의 VM

- **PyPy**: 바이트코드를 VM이 해석 실행하는 것은 동일하지만, hot path를 감지하면 기계어로 JIT 컴파일한다. 자세한 내용은 [Python 구현체](<./Python 구현체.md>) 참고.
- **Jython**: Python 바이트코드 대신 JVM 바이트코드로 컴파일해서 JVM 위에서 실행한다. 즉 PVM이 아니라 JVM이 실행 주체이다.

---
참고

- <https://docs.python.org/3/library/dis.html>
- <https://docs.python.org/3/glossary.html#term-bytecode>
- <https://peps.python.org/pep-0659/> (Specializing Adaptive Interpreter)

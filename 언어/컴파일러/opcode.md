opcode는 가상머신이 실행하는 명령어 하나를 가리키는 코드다. 명령어 집합을 어떻게 설계하느냐가 가상머신의 성능과 컴파일러의 복잡도를 함께 결정한다.

설계에서 정해야 할 것은 크게 셋이다. 피연산자를 어디에 두는가(스택이냐 레지스터냐), 명령어를 어떻게 인코딩하는가, 명령어를 몇 개나 둘 것인가.

## 스택 머신과 레지스터 머신

피연산자의 위치가 갈림길이다.

**스택 머신**은 피연산자를 암묵적으로 스택 top에서 가져온다. [중간언어](./중간언어.md)의 후위표현이 그대로 명령어가 된다.

```
a + b * c

LOAD_NAME  a
LOAD_NAME  b
LOAD_NAME  c
BINARY_OP  *      ← 스택에서 둘 pop, 결과 push
BINARY_OP  +
```

`BINARY_OP`는 피연산자가 어디 있는지 말하지 않는다. 항상 스택 top 둘이다. 그래서 명령어가 짧고 코드 생성이 단순하다. 구문트리를 후위순회하면서 노드마다 명령 하나를 뱉으면 끝이고, 레지스터를 어떻게 배분할지 고민할 필요가 없다.

**레지스터 머신**은 피연산자와 결과를 명령어 안에 명시한다. 3-주소 코드가 그대로 명령어가 된다.

```
MUL  R1, b, c
ADD  R0, a, R1
```

명령어 수가 5개에서 2개로 줄었다. 스택 머신에서 필요했던 `LOAD`/`PUSH`가 사라졌기 때문이다. 대신 명령어 하나가 길어지고, **레지스터 할당**이라는 어려운 문제가 컴파일러 쪽으로 넘어온다.

| | 스택 머신 | 레지스터 머신 |
|---|---|---|
| 피연산자 지정 | 암묵적 (스택 top) | 명시적 (레지스터 번호) |
| 명령어 길이 | 짧다 | 길다 |
| 명령어 개수 | 많다 | 적다 |
| 코드 생성 | 후위순회로 끝 | 레지스터 할당 필요 |
| 디스패치 횟수 | 많다 | 적다 |
| 예 | CPython, JVM, WebAssembly | Lua 5.x, Dalvik, LLVM |

명령어 개수가 적다는 것은 디스패치 횟수가 적다는 뜻이다. 인터프리터 루프에서 명령 하나를 처리할 때마다 "다음 명령을 읽고 분기한다"는 고정 비용이 드는데, 이게 인터프리터 실행 시간의 상당 부분을 차지한다. 레지스터 머신이 빠른 주된 이유다. 이 고정 비용은 명령어를 아무리 잘 설계해도 사라지지 않는다. computed goto, 명령어 합치기(superinstruction), 특수화가 전부 이 비용을 깎으려는 시도이고, 근본적인 해결은 JIT로 넘어가는 것이다.

그럼에도 스택 머신이 널리 쓰이는 이유는 이식성과 단순성 때문이다. 레지스터 개수를 가정하지 않아도 되고, 검증하기 쉽고(스택 깊이만 추적하면 된다), 코드가 조밀하다. JVM과 WebAssembly가 스택 머신인 것은 바이너리를 배포하고 검증해야 하는 환경이기 때문이다.

## 인코딩

명령어를 바이트로 어떻게 배치할지의 문제다. CPython은 명령어 하나가 정확히 2바이트다.

```c
typedef union {
    uint16_t cache;
    struct {
        uint8_t code;   // opcode
        uint8_t arg;    // oparg
    } op;
    _Py_BackoffCounter counter;
} _Py_CODEUNIT;
```

고정 길이라서 명령어 경계를 계산할 필요가 없다. 점프 대상을 명령어 단위로 셀 수 있고, 다음 명령 주소가 항상 `+2`다.

문제는 `arg`가 1바이트뿐이라는 것이다. 지역변수가 256개를 넘으면 `LOAD_FAST`의 인자가 표현되지 않는다. 해법이 `EXTENDED_ARG`다.

```python
# 지역변수 300개짜리 함수를 컴파일하면
EXTENDED_ARG   1
STORE_FAST   256      ← 실제로는 (1 << 8) | 0
```

앞선 `EXTENDED_ARG`의 인자를 8비트 왼쪽으로 밀어 다음 명령의 인자에 얹는다. 최대 세 번까지 이어 붙여 32비트 인자를 만들 수 있다. 실제로 지역변수 300개 함수를 컴파일하면 `EXTENDED_ARG`가 45번 등장한다. 드문 경우를 위해 명령어 폭을 늘리는 대신, 드문 경우에만 명령을 하나 더 쓰는 선택이다.

인자가 필요 없는 명령도 2바이트를 차지한다. `HAVE_ARGUMENT`(3.14 기준 43) 미만의 opcode는 인자를 쓰지 않지만 자리는 그대로 둔다. 고정 길이를 유지하는 대가다.

명령어마다 **스택 효과**도 정해진다. 스택 깊이가 몇 칸 변하는지다.

```
LOAD_FAST        +1
STORE_FAST       -1
BINARY_OP        -1     (둘 pop, 하나 push)
UNARY_NEGATIVE    0     (하나 pop, 하나 push)
POP_TOP          -1
```

컴파일러는 이 값을 더해가며 함수에 필요한 최대 스택 깊이를 계산하고, 그 크기만큼 프레임을 잡는다. 실행 중에 스택이 넘칠 걱정을 하지 않아도 되는 이유다.

## 개수를 늘리는 이유

명령어를 몇 개나 둘 것인가. 최소 집합으로도 언어는 돌아간다. 산술, 비교, 분기, 호출, 변수 접근, 자료구조 생성 정도면 30개 안쪽으로 완결된 언어를 만들 수 있다.

CPython main(3.16.0a0)의 opcode는 243개다. 그런데 이 숫자를 나눠 보면 성격이 완전히 다른 셋으로 갈린다.

```
기본        119개   (id < 129)
특수화       90개   (129 ≤ id < 233)
계측         34개   (id ≥ 233)
```

언어 명세가 만든 것은 119개뿐이고, 나머지 124개는 언어와 무관하다.

특수화 90개는 성능을 위한 것이다. `BINARY_OP` 하나로 충분한 자리에 이런 변종들이 있다.

```
BINARY_OP_ADD_INT
BINARY_OP_ADD_FLOAT
BINARY_OP_ADD_UNICODE
BINARY_OP_MULTIPLY_INT
BINARY_OP_MULTIPLY_FLOAT
...
```

동적 타입 언어에서 `a + b`는 매번 두 피연산자의 타입을 확인하고 알맞은 연산을 찾아야 한다. 실행 중에 "이 자리는 늘 정수더라"가 관찰되면 타입 검사만 남긴 전용 명령으로 바꿔치기한다. 그 구조는 [인라인 캐싱과 특수화](./인라인%20캐싱과%20특수화.md)에 정리했다. 명령어 집합을 언어 명세가 아니라 실행 프로파일이 결정한 부분이다.

계측 34개는 관측을 위한 것이다. `INSTRUMENTED_FOR_ITER` 같은 명령들로, 디버거나 프로파일러가 붙었을 때만 원래 명령을 대체한다. 관측 비용을 평소에는 0으로 만들기 위해 명령어를 통째로 복제한 셈이다.

여기서 끝이 아니다. Tier 2에서는 명령어를 더 잘게 쪼갠 **마이크로 연산(uop)**을 JIT 컴파일 단위로 쓰고, 그 종류가 653개다. 실행이 잦은 구간을 uop 열로 펼친 뒤 최적화하고 기계어로 컴파일하기 위한 것이다.

언어가 커서 명령어가 많은 게 아니라, 최적화 층이 쌓여서 많아졌다. 그리고 이렇게 늘린 명령어는 되돌리기 어렵다. 바이트코드가 파일로 저장되거나(`.pyc`, `.class`) 네트워크로 배포되면 호환성 문제가 되기 때문이다. CPython이 `.pyc`에 매직 넘버를 두고 버전이 다르면 무시하는 것도 명령어 집합이 계속 바뀌기 때문이고, `BINARY_OP_ADD_INT`가 파이썬 언어가 아니라 CPython 구현의 일부인 이상 바이트코드 수준의 호환성은 사실상 포기된 것이다.

## 정의를 생성한다

명령어가 이 정도로 많아지면 인터프리터 루프를 손으로 유지할 수 없다. CPython은 명령어를 DSL로 정의하고 실행 코드를 생성한다.

```c
macro(UNARY_NEGATIVE) = _UNARY_NEGATIVE + POP_TOP;

op(_UNARY_NEGATIVE, (value -- res, v)) {
    PyObject *res_o = PyNumber_Negative(PyStackRef_AsPyObjectBorrow(value));
    if (res_o == NULL) {
        ERROR_NO_POP();
    }
    res = PyStackRef_FromPyObjectSteal(res_o);
    v = value;
    DEAD(value);
}
```

`(value -- res, v)`가 스택 효과 선언이다. `--` 왼쪽이 입력, 오른쪽이 출력이고, 이 표기에서 스택 효과가 자동으로 계산된다. `macro(...)`는 여러 uop을 묶어 하나의 명령으로 만드는 선언이다.

`Python/bytecodes.c` 6,690줄이 이런 정의의 모음이고, 여기서 `Python/generated_cases.c.h` 13,895줄이 생성된다. opcode ID 헤더도 마찬가지로 생성물이다.

```
Python/bytecodes.c  (6,690줄, 사람이 쓴다)
        │  Tools/cases_generator/
        ├─→ Python/generated_cases.c.h  (13,895줄)  ← ceval 루프의 case들
        ├─→ Include/opcode_ids.h                    ← opcode 번호
        └─→ 스택 효과 테이블, uop 정의 …
```

[렉서 생성기](./Lexer와%20DFA.md)나 [파서 생성기](./LR%20파싱.md)와 같은 구조다. 사람은 명세를 쓰고 기계가 실행 코드를 만든다. 명령어 하나를 추가할 때 손으로 고쳐야 할 곳이 열 군데씩 생기는 문제를, 명세를 단일 출처로 만들어 해결한 것이다. 대신 `generated_cases.c.h`를 읽어서는 아무것도 알 수 없어서 DSL과 생성기를 먼저 이해해야 하고, 디버거가 가리키는 줄 번호도 생성 파일 기준이다.

---
참고

- [인라인 캐싱과 특수화](./인라인%20캐싱과%20특수화.md)
- [클로저와 셀](./클로저와%20셀.md)
- [중간언어](./중간언어.md)
- [Lexer와 DFA](./Lexer와%20DFA.md)
- [LR 파싱](./LR%20파싱.md)
- [Python VM](../Python/Python%20VM.md)
- [Java Bytecode](../Java/JVM/Java%20Bytecode.md)
- <https://docs.python.org/3/library/dis.html>
- <https://www.lua.org/doc/jucs05.pdf>
- <https://craftinginterpreters.com/a-virtual-machine.html>
- <https://github.com/python/cpython/blob/main/InternalDocs/interpreter.md>
- <https://github.com/python/cpython/blob/main/Python/bytecodes.c>
- <https://github.com/python/cpython/blob/main/Include/opcode_ids.h>
- <https://github.com/python/cpython/blob/main/Include/internal/pycore_structs.h>

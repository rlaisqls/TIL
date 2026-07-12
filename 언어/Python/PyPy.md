> PyPy gives itself the goal to try to be extremely compatible with all the quirks of the Python language. We don't change the Python language to make things easier to compile and we support the introspection and debugging features of Python. We try very hard to have no opinions on language design. The CPython core developers come up with the semantics, we somehow deal with them.<br>
> PyPy는 Python 언어의 모든 특성을 극도로 잘 이해하려고 노력하는 것을 목표로 삼고 있습니다. 컴파일하기 쉽게 만들기 위해 파이썬 언어를 바꾸지 않으며, 파이썬의 내면 및 디버깅 기능을 지원합니다. 우리는 언어 디자인에 대해 의견을 갖지 않으려고 매우 노력합니다. CPython 핵심 개발자들이 의미론을 만들고, 우리는 어떻게든 그걸 다룹니다.

PyPy는 meta-tracing JIT를 쓰는 Python 구현체이다.

## Architecture

PyPy는 크게 다섯 층으로 나뉜다.

- **[RPython](https://rpython.readthedocs.io/en/latest/rpython.html#language)**
  - 인터프리터를 작성하는 언어이다.
  - Python의 제한된 서브셋으로, 정적 타입 추론이 가능하도록 제약을 건다(변수 타입 고정, `exec`/`eval` 금지 등등)
  - [Getting Started with RPython](https://rpython.readthedocs.io/en/latest/getting-started.html), [RPython By Example](https://mssun.github.io/rpython-by-example/index.html)

- **Translation**
  - RPython 코드를 C로 바꾸는 툴체인이다.

    - `flowspace`: 코드를 흐름 그래프(flow graph)로 변환
    - `annotator`: 각 변수의 타입을 추론
    - `rtyper`: 추론된 타입을 저수준 타입으로 변환

  - 이 파이프라인을 거쳐야 최종적으로 C 코드가 나온다. 즉 "RPython 전용 C 컴파일러"에 가깝다.

- **PyPy 인터프리터 본체**
  - `pypy/interpreter`가 코어이고, 내장 모듈은 `pypy/module/*`, 순수 Python으로 짠 라이브러리는 `lib_pypy`에 있다. 내부적으로 세 부분으로 나뉜다.

    - 바이트코드 컴파일러: 소스 → 토크나이저 → 파서 → AST → 바이트코드
    - 바이트코드 평가기: 바이트코드를 해석 실행
    - 표준 객체 공간(Object Space): Python 객체의 생성/조작 담당

  - 객체 공간을 갈아끼우면 같은 평가기 위에서 완전히 다른 동작(트레이싱, 디버깅 전용 의미론 등)을 구현할 수 있다는 게 이 구조의 핵심 유연성이다.

- **JIT 컴파일러**
  - tracing JIT that traces the interpreter written in RPython, 즉 사용자 프로그램이 아니라 RPython으로 짠 인터프리터 자체를 추적한다.
  - 구성 요소
    - `metainterp`: 추적기, 트레이스 기록 담당
    - 옵티마이저: 기록된 트레이스를 최적화
    - 머신 코드 생성 백엔드: 최종 기계어 생성

- **가비지 컬렉터**
  - RPython에는 CPython의 `Py_INCREF`/`Py_DECREF` 같은 참조 카운팅이 없다.
  - 번역 과정에서 GC 코드가 자동으로 삽입된다, 기본 로직은 [`rpython/memory/gc/incminimark.py`](https://github.com/pypy/pypy/blob/main/rpython/memory/gc/incminimark.py)에 구현되어있다. (세대별 증분 [mark-sweep](https://www.geeksforgeeks.org/java/mark-and-sweep-garbage-collection-algorithm/)).

---
참고

- <https://pypy.org/posts/2025/01/musings-tracing.html>
- ["Runtime Feedback in a Meta-Tracing JIT for Efficient Dynamic Languages"](https://dl.acm.org/doi/epdf/10.1145/2069172.2069181)
- <https://doc.pypy.org/architecture.html>

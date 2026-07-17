Dunder는 **d**ouble **under**score의 줄임말로, 이름 앞뒤에 밑줄 두 개가 붙은 식별자(`__init__`, `__call__`, `__dict__` 등)를 말한다. Python이 언어 차원에서 특별하게 취급하는 이름들이며, 크게 두 부류로 나뉜다.

- **dunder method** (special method, magic method): 인터프리터가 특정 문법·내장 함수를 만나면 암묵적으로 호출하는 메서드. `a + b` → `__add__`, `len(x)` → `__len__`, `x()` → `__call__` 등.
- **dunder attribute**: 객체·클래스·모듈의 메타데이터를 담는 속성. `__dict__`, `__class__`, `__name__` 등.

`__*__` 형태의 이름은 언어가 예약한 네임스페이스다. 문서화되지 않은 dunder 이름을 직접 만들어 쓰면 향후 Python 버전에서 의미가 부여되어 충돌할 수 있으므로, 새 dunder를 정의하는 것은 피해야 한다.

## Dunder method

인터프리터는 문법 요소를 dunder method 호출로 번역한다.

```python
a + b        # type(a).__add__(a, b)
a[k]         # type(a).__getitem__(a, k)
a(x)         # type(a).__call__(a, x)
len(a)       # type(a).__len__(a)
str(a)       # type(a).__str__(a)
with a: ...  # type(a).__enter__(a) / type(a).__exit__(a, ...)
for x in a:  # type(a).__iter__(a) → __next__
```

연산자의 dispatch 순서(`__add__`/`__radd__`, `NotImplemented`, 서브클래스 우선 규칙)는 [연산자 규칙](./연산자%20규칙.md) 참고.

일반 속성과 달리, 암묵적 호출에서 dunder method는 **인스턴스가 아니라 타입에서 조회**된다. 인스턴스에 같은 이름을 붙여도 무시된다.

```python
class Foo:
    pass

f = Foo()
f.__len__ = lambda: 3

# 동작하지 않음
len(f) # TypeError: object of type 'Foo' has no len()

# 명시적 호출은 일반 속성 조회라서 동작함
f.__len__()  # 3 
```

이 조회는 타입의 `__getattribute__`·`__getattr__`도 우회한다. 이유는 두 가지가 있다.

- **성능**: `a + b`마다 인스턴스 `__dict__`를 탐색하는 비용을 피한다.
- **메타클래스 일관성**: 클래스도 객체이다. `repr(Foo)`가 인스턴스 기준으로 조회된다면 `Foo.__repr__`(인스턴스용으로 정의한 메서드)이 호출되어버린다. `repr(Foo)`는 `type(Foo).__repr__`를 사용한다. 즉, 메타클래스의 메서드를 쓴다.

### CPython의 slot 구현

CPython에서 타입은 C 구조체 `PyTypeObject`로 표현되고, dunder method는 이 구조체의 **slot**(함수 포인터 필드)에 매핑된다.

```c
// Include/cpython/object.h (일부)
typedef struct _typeobject {
    ...
    reprfunc tp_repr;        // __repr__
    ternaryfunc tp_call;     // __call__
    hashfunc tp_hash;        // __hash__
    getattrofunc tp_getattro; // __getattribute__
    ...
} PyTypeObject;
```

`a(x)` 같은 암묵적 호출은 Python 레벨의 속성 조회 없이 `type(a)->tp_call`을 바로 실행한다. 클래스에 `__call__`을 정의하면 타입 생성 시 `tp_call` 슬롯이 채워지고, 반대로 C로 구현된 타입의 슬롯은 `__call__`이라는 Python 메서드로 노출된다.

`callable(x)`가 인스턴스가 아니라 `type(x)`의 `tp_call` 존재 여부를 보는 것도 이 구조 때문이다. [Weak Reference](./Weak%20Reference.md)의 `ProxyType`/`CallableProxyType`이 둘로 나뉜 이유가 바로 이것이다 — 프록시 타입이 하나라면 `callable()` 결과를 원본과 일치시킬 수 없다.

## 주요 dunder attribute

**객체**

- `__class__`: 객체의 타입. `type(obj)`와 같다.
- `__dict__`: 객체의 쓰기 가능한 속성을 담는 dict. `obj.x = 1`은 `obj.__dict__["x"] = 1`이다.
- `__weakref__`: 이 객체를 가리키는 weak reference 리스트의 헤드. [Weak Reference](./Weak%20Reference.md) 참고.

**클래스**

- `__name__`: 클래스 이름.
- `__bases__`: 직계 부모 클래스 tuple.
- `__mro__`: method resolution order. 속성 조회 시 탐색하는 클래스 순서.
- `__slots__`: 인스턴스가 가질 수 있는 속성을 고정해 `__dict__` 생성을 막는다. 인스턴스당 메모리를 줄이지만, `__weakref__`를 포함하지 않으면 weak reference도 막힌다.
- `__doc__`: docstring.
- `__module__`: 클래스가 정의된 모듈 이름.

**함수**

- `__name__`, `__qualname__`: 함수 이름 / 중첩 경로를 포함한 이름 (`Foo.method`).
- `__defaults__`, `__kwdefaults__`: 기본 인자 값.
- `__code__`: 컴파일된 코드 객체. 바이트코드(`co_code`), 지역 변수 이름 등을 담는다.
- `__closure__`: 클로저가 캡처한 cell 객체들.
- `__wrapped__`: `functools.wraps`가 남기는 원본 함수 참조.

**모듈**

- `__name__`: 모듈 이름. 직접 실행하면 `"__main__"`이 되는 그 값이다.
- `__file__`: 모듈 파일 경로.
- `__all__`: `from m import *`가 가져갈 이름 목록.

---
참고

- <https://docs.python.org/3/reference/datamodel.html#special-method-names>
- <https://docs.python.org/3/reference/datamodel.html#special-method-lookup>
- <https://docs.python.org/3/reference/expressions.html#private-name-mangling>
- <https://docs.python.org/3/c-api/typeobj.html>

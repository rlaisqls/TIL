Weak reference(약한 참조)는 객체를 참조하되, reference count를 증가시키지 않는 참조 방식이다. `weakref` 모듈로 사용한다.

CPython은 [레퍼런스 카운팅](../GIL.md)으로 메모리를 관리한다. 일반 참조(strong reference)는 ref count를 올리므로, 참조가 남아있는 한 객체가 해제되지 않는다. 이게 문제가 되는 경우가 있다.

- **캐시**: 캐시가 객체를 잡고 있으면 원본이 필요 없어져도 메모리에서 안 사라진다.
- **순환 참조**: observer 패턴 등에서 상호 참조 시 메모리 누수가 발생할 수 있다.
- **대형 객체 매핑**: 객체→메타데이터 매핑에서 키가 객체의 수명을 연장하는 것을 방지해야 한다.

weak reference는 ref count에 영향을 주지 않으므로, 다른 곳에서 strong reference가 모두 사라지면 객체가 정상적으로 GC된다.

## 기본 사용

```python
import weakref


class Foo:
    pass


obj = Foo()
ref = weakref.ref(obj)

print(ref())  # <__main__.Foo object at 0x...>
del obj
print(ref())  # None — 원본이 GC되면 None을 반환한다
```

`weakref.ref()`는 callable 객체를 반환한다. 호출하면 원본 객체 또는 `None`을 돌려준다.

콜백을 등록하면 객체가 소멸될 때 호출된다.

```python
def on_finalize(ref):
    print("객체가 소멸됨")


ref = weakref.ref(obj, on_finalize)
```

## 주요 도구

**`weakref.ref(obj, callback=None)`**

가장 기본적인 weak reference이다. 위에서 설명한 대로 동작한다.

**`weakref.proxy(obj, callback=None)`**

`ref()`와 달리 호출 없이 원본 객체처럼 직접 사용할 수 있는 프록시 객체를 반환한다. 내부적으로 매직 메서드를 오버라이드해서 모든 연산을 referent에 위임한다.

```python
import weakref


class Foo:
    def __init__(self, value):
        self.value = value


obj = Foo(42)

ref = weakref.ref(obj)
print(ref().value)  # 42 — 호출해야 객체를 얻음

proxy = weakref.proxy(obj)
print(proxy.value)  # 42 — 바로 접근 가능
```

객체가 소멸된 후 `ref()`는 `None`을 반환하지만, `proxy`는 `ReferenceError`를 발생시킨다. 소멸 여부를 명시적으로 확인할 수 없으므로 일반적으로 `ref()`가 더 안전하다. proxy는 기존 코드에 weak reference를 투명하게 끼워넣어야 할 때 유용하다.

```python
del obj
print(ref())  # None
print(proxy.value)  # ReferenceError: weakly-referenced object no longer exists
```

**`WeakValueDictionary`**

value가 weak reference인 dict이다. value 객체가 GC되면 해당 항목이 자동으로 제거된다. 캐시 구현에 적합하다.

```python
import weakref


class Image:
    def __init__(self, name):
        self.name = name


cache = weakref.WeakValueDictionary()


def get_image(name):
    img = cache.get(name)
    if img is None:
        img = Image(name)
        cache[name] = img
    return img
```

`Image` 객체를 외부에서 더 이상 참조하지 않으면 cache에서도 자동으로 사라진다.

**`WeakKeyDictionary`**

key가 weak reference인 dict이다. key 객체가 GC되면 항목이 제거된다. `__hash__`가 구현된 객체만 키로 쓸 수 있다.

객체에 메타데이터를 붙이되, 그 매핑이 객체 수명을 연장하지 않게 할 때 유용하다.

**`WeakSet`**

원소가 weak reference인 set이다. 원소 객체가 GC되면 자동으로 set에서 빠진다.

**`finalize(obj, func, *args, **kwargs)`**

`weakref.ref`의 콜백보다 안전한 소멸자 등록 방식이다. 프로그램 종료 시에도 호출이 보장되며, `atexit`과 연동된다.

```python
weakref.finalize(obj, print, "cleanup:", obj.name)
```

## 제약

모든 객체가 weak reference를 지원하는 건 아니다. CPython의 모든 객체는 C 구조체로 표현되는데, weak reference를 지원하려면 이 구조체에 `PyObject **tp_weaklist` 포인터 슬롯(8바이트)이 필요하고, 타입 정의에서 `tp_weaklistoffset`이 0이 아닌 값으로 설정되어야 한다. `int`, `str`, `tuple`, `list`, `dict` 같은 built-in 타입은 이 슬롯을 의도적으로 포함하지 않는다.

**메모리 오버헤드**

이 타입들은 런타임에서 가장 빈번하게 할당되는 타입이다. CPython의 `int` 객체는 28바이트인데, `tp_weaklist` 슬롯 8바이트를 추가하면 객체당 약 28%의 메모리 증가가 발생한다. Python 프로세스 하나에서 수백만 개의 int·str이 동시에 존재하는 건 흔한 일이므로, 이 오버헤드는 무시할 수 없다. `list`(56바이트)와 `dict`(64바이트)도 상대 비율은 작지만 절대 수가 많아 총 비용이 크다.

**identity의 불안정성**

CPython은 성능을 위해 이 타입들에 여러 내부 최적화를 적용한다.

- **small int caching**: -5~256 범위의 정수는 인터프리터 시작 시 미리 할당해 싱글턴으로 재사용한다.
- **string interning**: 식별자로 쓰이는 문자열(`sys.intern()` 포함)은 동일 객체를 공유한다.
- **tuple interning**: 빈 tuple `()`은 싱글턴이며, CPython 3.12부터는 상수 tuple도 인턴된다.
- **free list**: `list`, `dict`, `tuple` 등은 해제 시 메모리를 OS에 반환하지 않고 free list에 보관했다가 다음 할당에 재사용한다. 동일한 메모리 주소에 전혀 다른 객체가 들어올 수 있다.

이런 최적화 때문에 이 타입들의 object identity(`id()`)는 값의 논리적 생명주기와 일치하지 않는다. weak reference는 특정 객체의 생존 여부를 추적하는 메커니즘인데, 캐싱과 재사용으로 인해 "객체의 소멸"이라는 개념 자체가 모호해진다.

**우회 방법**

서브클래싱하면 사용자 정의 클래스가 되므로 `__weakref__` 슬롯이 자동 생성된다.

```python
import weakref


class WeakableDict(dict):
    pass


d = WeakableDict(a=1)
ref = weakref.ref(d)  # 정상 동작
```

다만 이 경우 CPython의 free list, key-sharing dict 등의 최적화가 적용되지 않을 수 있다.

사용자 정의 클래스는 기본적으로 weak reference를 지원한다. 단, `__slots__`를 쓰는 경우 `__weakref__`를 명시적으로 포함해야 한다.

```python
class SlottedClass:
    __slots__ = ("value", "__weakref__")
```

`__weakref__`가 빠지면 `TypeError: cannot create weak reference to 'SlottedClass' object`가 발생한다.

## CPython 내부 구현

CPython에서 weak reference가 가능한 객체는 내부에 `__weakref__` 필드를 가진다. 이 필드는 해당 객체를 가리키는 weak reference들의 연결 리스트 헤드이다.

weak reference 객체 자체는 `PyWeakReference` 구조체로 표현된다.

```c
// Include/cpython/weakrefobject.h
typedef struct _PyWeakReference PyWeakReference;

struct _PyWeakReference {
    PyObject_HEAD
    PyObject *wr_object;   // 참조 대상 객체 (referent)
    PyObject *wr_callback; // 소멸 시 호출할 콜백 (없으면 NULL)
    Py_hash_t hash;        // wr_object의 해시값 캐시
    PyWeakReference *wr_prev;  // 이중 연결 리스트 — 이전 weak ref
    PyWeakReference *wr_next;  // 이중 연결 리스트 — 다음 weak ref
};
```

`wr_prev`/`wr_next`로 동일 객체를 가리키는 모든 weak reference가 이중 연결 리스트로 연결된다. 객체의 `tp_weaklistoffset`이 가리키는 위치에 이 리스트의 헤드 포인터가 저장된다.

객체가 해제될 때 `tp_dealloc`에서 `PyObject_ClearWeakRefs()`를 호출한다.

```c
// Objects/weakrefobject.c (간략화)
void PyObject_ClearWeakRefs(PyObject *object) {
    PyWeakReference **list = GET_WEAKREFS_LISTPTR(object);
    PyWeakReference *current = *list;

    while (current != NULL) {
        PyWeakReference *next = current->wr_next;
        // referent를 Py_None으로 설정 — 이후 ref() 호출 시 None 반환
        current->wr_object = Py_None;

        if (current->wr_callback != NULL) {
            // 콜백을 수집해서 일괄 호출
            PyObject *callback = current->wr_callback;
            current->wr_callback = NULL;
            PyObject_CALL(callback, current);
        }

        // 리스트에서 제거
        current->wr_prev = NULL;
        current->wr_next = NULL;
        current = next;
    }
    *list = NULL;
}
```

이 과정은 GC 사이클과 무관하게 ref count가 0이 되는 시점에 즉시 실행된다. 콜백 호출 순서는 리스트 순서를 따르며, 콜백이 없는 weak reference는 `wr_object`만 `Py_None`으로 바뀌고 별도 처리 없이 넘어간다.

---
참고

- <https://docs.python.org/3/library/weakref.html>
- <https://docs.python.org/3/extending/newtypes.html#weak-reference-support>
- <https://peps.python.org/pep-0205/>

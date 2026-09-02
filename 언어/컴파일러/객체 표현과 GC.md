객체 표현은 언어의 값을 메모리에 어떤 모양으로 담을지를 정하는 설계이고, 값의 수명을 누가 어떻게 끝낼지가 그 설계에 딸려 나온다. 값의 종류가 닫혀 있는지 열려 있는지가 두 선택을 함께 결정한다.

정적 타입 언어는 정수를 기계 워드 하나로 담는다. 컴파일 시점에 이게 정수라는 걸 알기 때문에 타입 정보를 실행 중에 들고 다닐 필요가 없다. 동적 타입 언어는 그럴 수 없다. 값이 어디로 흘러가든 자기가 무엇인지 스스로 알고 있어야 한다.

CPython은 모든 값을 힙 객체로 만들고 `PyObject *` 하나로 가리킨다. 아래는 main(3.16.0a0) 기준이고 측정은 3.14.6에서 했다.

## 모든 값이 객체다

객체의 머리는 참조 카운트와 타입 포인터다.

```c
struct _object {
    _Py_ANONYMOUS union {
        int64_t ob_refcnt_full;
        struct {
            uint32_t ob_refcnt;
            uint16_t ob_overflow;
            uint16_t ob_flags;
        };
    };
    PyTypeObject *ob_type;
};
```

이 머리가 붙는 대가는 크다. 같은 정수 하나를 담는 비용을 재 보면 이렇다.

```
C의 int64                 8 bytes
Python의 int 1           28 bytes
Python의 int 2^30        32 bytes
Python의 int 2^100       40 bytes
Python의 float           24 bytes
```

파이썬 정수는 임의 정밀도라 크기가 값에 따라 늘어난다. `2^100`도 그냥 담긴다. 대신 작은 정수 하나에 28바이트를 쓴다.

컨테이너에서 차이가 더 벌어진다. 리스트는 값이 아니라 포인터를 담기 때문이다.

```
C의 int[3]                12 bytes
Python의 list [1,2,3]     88 bytes  (원소 객체 84 bytes 별도)
```

`list[3]`의 88바이트는 포인터 세 개를 담는 배열의 비용이고, 가리켜지는 정수 객체 세 개가 따로 힙에 있다. 배열 하나를 순회하는 일이 포인터 추적 세 번이 되므로 지역성도 나쁘다.

같은 값을 반복해서 만드는 낭비를 줄이려고 자주 쓰는 객체는 미리 만들어 둔다.

```python
a, b = int("256"), int("256")
a is b        # True

a, b = int("257"), int("257")
a is b        # False
```

−5부터 256까지의 정수는 인터프리터가 하나씩만 갖고 돌려 쓴다. 이 범위 밖은 매번 새로 할당된다.

`None`, `True`, 작은 정수처럼 프로세스 내내 사라지지 않는 객체는 참조 카운트를 아예 갱신하지 않는다. 불멸(immortal) 객체로 표시하고 특수한 카운트 값을 박아 둔다.

```python
sys.getrefcount(0)        # 3221225472  (0xC0000000)
sys.getrefcount(None)     # 3221225472
sys.getrefcount(999999)   # 3
```

이 값이 보이면 증감을 건너뛴다. 모든 스레드가 공유하는 객체의 카운트를 계속 만지는 비용을 없애기 위한 것이다.

## 타입이 열려 있다는 것

`ob_type`이 가리키는 `PyTypeObject`는 연산마다 함수 포인터를 담고 있다.

```c
binaryfunc   nb_add;          /* a + b */
inquiry      nb_bool;         /* if a: */
ssizeargfunc sq_item;         /* a[i] */
binaryfunc   mp_subscript;    /* a[k] */
getattrofunc tp_getattro;     /* a.x */
richcmpfunc  tp_richcompare;  /* a < b */
```

`a + b`를 실행한다는 것은 `a`의 타입에서 `nb_add`를 찾아 부른다는 뜻이다. 파이썬 쪽에서는 이 슬롯이 던더 메서드로 보인다.

```python
int.__add__     # <slot wrapper '__add__' of 'int' objects>
str.__add__     # <slot wrapper '__add__' of 'str' objects>
```

`slot wrapper`라는 표시가 C 함수 포인터를 파이썬에서 볼 수 있게 감싼 것이라는 뜻이다. 사용자가 정의한 타입도 같은 자리를 채운다.

```python
class V:
    def __init__(self, x): self.x = x
    def __add__(self, o): return V(self.x + o.x)

V(1) + V(2)     # V.__add__ 가 불린다
```

진리값 판정도 하드코딩된 규칙이 아니라 슬롯이다.

```python
class Empty:
    def __bool__(self): return False

if not Empty():   # Empty.__bool__ 이 불린다
```

값의 종류가 고정된 구현이라면 `+`는 타입 스위치 한 번으로 끝나고 새 타입을 넣을 수 없다. 슬롯 방식은 사용자 정의 타입과 연산자 오버로딩을 허용하는 대신 모든 연산이 슬롯 조회를 거친다. 이 조회 비용이 [특수화](./인라인%20캐싱과%20특수화.md)가 존재하는 이유이고, `BINARY_OP_ADD_INT` 같은 전용 명령이 하는 일도 결국 이 조회를 건너뛰는 것이다.

## 참조 카운팅과 그 구멍

참조 카운트가 0이 되는 순간 객체를 회수한다. 회수 시점이 결정적이라 파일이나 소켓을 언제 닫을지 예측할 수 있다.

```python
t = T()      # refcount 1
u = t        # refcount 2
del u        # refcount 1
del t        # refcount 0 → 즉시 소멸
```

문제는 서로를 가리키는 객체다.

```python
a, b = C(), C()
a.other = b
b.other = a
del a, b      # 아무 일도 일어나지 않는다
```

바깥에서 접근할 수 없게 됐는데도 서로가 서로를 붙들고 있어 카운트가 0이 되지 않는다. 그래서 참조 카운팅 위에 순환을 찾아내는 수집기를 따로 얹는다(`Python/gc.c` 2,176줄).

```python
gc.collect()   # 2  (앞의 두 객체가 회수된다)
```

수집기는 힙 전체를 훑지 않고 컨테이너만 본다. 순환을 만들 수 있는 것은 다른 객체를 담을 수 있는 객체뿐이기 때문이다.

```python
gc.is_tracked(1)       # False
gc.is_tracked("s")     # False
gc.is_tracked([])      # True
gc.is_tracked({})      # True
gc.is_tracked((1,))    # False   내용이 전부 불변이면 추적에서 빠진다
```

추적 대상은 세 세대로 나뉜다. 갓 만든 객체가 0세대에 들어가고, 수집에서 살아남으면 다음 세대로 승격된다.

```python
gc.get_threshold()   # (2000, 10, 10)
```

0세대는 할당이 회수보다 2,000개 많아지면 수집하고, 1세대는 0세대 수집이 10번 일어나면, 2세대는 1세대 수집이 10번 일어나면 수집한다. 대부분의 객체가 금방 죽는다는 관찰에 기대어 어린 세대를 자주, 늙은 세대를 드물게 본다. [Go](../Go/GC.md)나 JVM의 세대 구분과 같은 발상이지만, 그쪽이 추적 수집으로 살아있는 객체를 전부 찾는 반면 여기서는 참조 카운팅이 대부분을 이미 처리하고 남은 순환만 맡는다.

카운팅을 주로 쓰는 선택은 스레드와 부딪힌다. 여러 스레드가 같은 객체의 카운트를 동시에 만지면 경쟁이 생기고, 그것을 락 하나로 막은 것이 GIL이다. GIL을 없애는 빌드(`Py_GIL_DISABLED`)는 카운트를 스레드 로컬과 공유용으로 쪼갠다.

```c
uintptr_t   ob_tid;           // 소유 스레드 id
uint32_t    ob_ref_local;     // 로컬 참조 카운트
Py_ssize_t  ob_ref_shared;    // 공유(원자적) 참조 카운트
```

객체를 만든 스레드가 혼자 쓰는 동안에는 `ob_ref_local`을 원자 연산 없이 올리고 내린다. 다른 스레드가 끼어들 때만 `ob_ref_shared`로 넘어간다. 수집기도 따로 필요해서 `Python/gc_free_threading.c`가 2,913줄로 별도 구현되어 있다.

객체 머리가 커지고 카운트가 둘로 늘어난다는 점에서, 참조 카운팅을 유지하면서 병렬성을 얻는 대가가 다시 객체 표현으로 돌아온 셈이다.

---
참고

- [인라인 캐싱과 특수화](./인라인%20캐싱과%20특수화.md)
- [opcode](./opcode.md)
- [트리 순회와 바이트코드](./트리%20순회와%20바이트코드.md)
- [GC](../Go/GC.md)
- [Heap 영역 구조와 GC](../Java/JVM/Heap%20영역%20구조와%20GC.md)
- [Python VM](../Python/Python%20VM.md)
- <https://docs.python.org/3/library/gc.html>
- <https://docs.python.org/3/c-api/typeobj.html>
- <https://peps.python.org/pep-0683/>
- <https://peps.python.org/pep-0703/>
- <https://github.com/python/cpython/blob/main/Include/object.h>
- <https://github.com/python/cpython/blob/main/Python/gc.c>
- <https://github.com/python/cpython/blob/main/Python/gc_free_threading.c>

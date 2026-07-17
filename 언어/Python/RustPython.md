[RustPython](https://github.com/RustPython/RustPython)은 Rust로 작성된 Python 인터프리터이다.

## Detect list mutation during sort even when list length is unchanged [#7432](https://github.com/RustPython/RustPython/pull/7432)

CPython은 `list.sort()` 도중 비교 함수가 리스트 자체를 변경하면 예외를 던진다.

```python
class Evil:
    def __init__(self, v):
        self.v = v
    def __lt__(self, other):
        L.append(3)
        L.pop()
        return self.v < other.v

L = [Evil(3), Evil(1), Evil(2)]
L.sort()  # CPython: ValueError: list modified during sort
```

RustPython의 기존 구현은 정렬을 위해 내부 `Vec`을 임시로 꺼내둔 뒤, 정렬이 끝나고 원래 자리에 남아있는 원소가 있는지로 변경 여부를 판단했다.

```rust
if !elements.is_empty() {
    return Err(vm.new_value_error("list modified during sort"));
}
```

이 체크는 **길이**만 본다. `L.append(3); L.pop()`처럼 길이가 원래대로 돌아오는 변경, 혹은 `clear()`처럼 `mem::take()`로 capacity까지 0으로 리셋해버리는 변경은 감지하지 못하고 통과시킨다.

CPython은 이 문제를 `allocated` 필드에 `-1` 같은 불가능한 값을 심어두는 sentinel 방식으로 해결한다. RustPython에도 같은 아이디어를 카운터로 옮겨 적용했다.

```rust
// PyList에 필드 추가
mutation_counter: AtomicU32,

// 리스트를 mutable하게 빌리는 모든 진입점에서 카운터 증가
pub fn borrow_vec_mut(&self) -> PyRwLockWriteGuard<'_, Vec<PyObjectRef>> {
    let guard = self.elements.write();
    self.mutation_counter.fetch_add(1, Ordering::Relaxed);
    guard
}
```

정렬 전후로 write lock을 잡은 상태에서 카운터를 스냅샷/비교한다.

```rust
// 정렬 시작 — write lock 아래서 스냅샷
let (mut elements, version_before) = {
    let mut guard = self.elements.write();
    let version_before = self.mutation_counter.load(Ordering::Relaxed);
    (core::mem::take(guard.deref_mut()), version_before)
};

// 정렬 종료 — 다시 write lock을 잡고 비교
let mutated = {
    let mut guard = self.elements.write();
    let mutated = self.mutation_counter.load(Ordering::Relaxed) != version_before;
    core::mem::swap(guard.deref_mut(), &mut elements);
    mutated
};
```

리뷰 과정에서 처음엔 카운터를 write lock 획득 전에 증가시켰는데, 그 사이 다른 스레드의 변경이 스냅샷에 반영되지 않을 수 있다는 지적을 받아 lock을 잡은 뒤 증가시키는 순서로 고쳤다. 고

## Fix subclass right-op dispatch for Python classes [#7462](https://github.com/RustPython/RustPython/pull/7462)

서브클래스 우선 규칙에 따르면 `B(A)`가 `__radd__`류를 오버라이드하지 않고 그냥 상속만 받았다면, 부모의 정방향 메서드가 그대로 우선해야 한다.

```python
class A:
    def __floordiv__(self, other): return "A.__floordiv__"
    def __rfloordiv__(self, other): return "A.__rfloordiv__"

class B(A):
    pass

A() // B()
# 기대: "A.__floordiv__" (B가 __rfloordiv__를 오버라이드하지 않았으므로)
# 실제: "A.__rfloordiv__"
```

CPython은 이걸 `tp_as_number` 슬롯 함수 포인터가 좌항과 우항에서 같은지 비교해서 판단한다. 상속만 받았으면 슬롯 포인터가 부모 것 그대로라 동일하고, 오버라이드했으면 포인터가 달라진다. 이 구조는 단일 슬롯 구조라 가능한 트릭인데, RustPython은 정방향/역방향 연산이 애초에 서로 다른 슬롯 함수로 분리되어 있다. 그래서 `left(A)`와 `right(B)`를 비교하면 오버라이드 여부와 무관하게 **항상 다르다고** 나온다.

```rust
// 좌항 슬롯과 우항 슬롯을 비교 — 애초에 다른 함수라 의미가 없다
if slot_bb.map(|x| x as usize) != slot_a.map(|x| x as usize) {
    slot_b = slot_bb;
}
```

비교 대상을 `left(A)` vs `left(B)`로 바꾸고, 포인터가 같아도 실제로 Python 메서드 레벨에서 오버라이드했는지를 별도로 확인하는 헬퍼를 추가했다.

```rust
fn method_is_overloaded(
    class_a: &Py<PyType>,
    class_b: &Py<PyType>,
    rop_name: Option<&'static PyStrInterned>,
    vm: &VirtualMachine,
) -> PyResult<bool> {
    let Some(rop_name) = rop_name else { return Ok(false); };
    class_a.get_attr(rop_name).map_or(Ok(true), |method_a| {
        vm.identical_or_equal(&method_a, &method_b).map(|eq| !eq)
    })
}
```

`op_slot.right_method_name()`으로 연산자 슬롯을 `__radd__` 같은 dunder 이름에 매핑해서 `method_is_overloaded`에 넘긴다. 리뷰에서는 이 함수가 처음에 예외를 `unwrap_or`로 삼키던 걸 지적받아 `PyResult<bool>`로 바꿔 상위로 전파하도록 고쳤다.

## Fix weakref proxy number protocol delegation [#7410](https://github.com/RustPython/RustPython/pull/7410)

weakref.proxy는 원본 객체의 모든 연산을 그대로 proxy 해야하는데, 숫자 프로토콜은 `boolean` 슬롯 하나만 구현되어 있었다.

```python
import weakref
obj = 42  # 예시일 뿐, 실제로는 __weakref__ 지원 객체
proxy = weakref.proxy(obj)
proxy + 5       # TypeError
int(proxy)      # TypeError
5 + proxy       # TypeError
```

```rust
// AS_NUMBER에 boolean 슬롯만 있고 나머지는 전부 NOT_IMPLEMENTED
static AS_NUMBER: LazyLock<PyNumberMethods> = LazyLock::new(|| PyNumberMethods {
    boolean: Some(|number, vm| {
        let zelf = number.obj.downcast_ref::<PyWeakProxy>().unwrap();
        zelf.try_upgrade(vm)?.is_true(vm)
    }),
    ..PyNumberMethods::NOT_IMPLEMENTED
});
```

referent를 안전하게 꺼내는 `proxy_upgrade`와, 그걸로 단항/이항 연산을 감싸는 `proxy_unary_op`/`proxy_binary_op` 헬퍼를 추가하고 나머지 슬롯을 채웠다.

```rust
int: Some(|number, vm| {
    let obj = proxy_upgrade(number.obj, vm)?;
    obj.try_int(vm).map(Into::into)
}),
floor_divide: proxy_binary_slot!(_floordiv),
matrix_multiply: proxy_binary_slot!(_matmul),
```

처음엔 슬롯을 직접 호출했는데, 이러면 `5 + proxy`처럼 반사 연산이 필요한 경우 서브타입 우선순위 규칙(위 PR과 같은 규칙)이 깨진다는 지적을 받았다. `vm.binary_op1` 같은 VM 디스패치 함수를 거치도록 바꿔서, 위임된 연산도 일반 연산과 동일한 우선순위 규칙을 타게 했다. 단항 연산 쪽은 반대로 슬롯이 없을 때 에러 대신 `Ok(None)`을 반환하게 해서 `int()` → `__index__` 같은 폴백 체인이 끊기지 않도록 했다.

## Add strict parameter to map() builtin [#7405](https://github.com/RustPython/RustPython/pull/7405)

`zip()`의 `strict=True`(입력 이터러블 길이가 다르면 `ValueError`)와 동일한 옵션을 `map()`에도 넣는 CPython 변경을 RustPython에 반영했다.

```rust
pub struct PyMap {
    mapper: PyObjectRef,
    iterators: Vec<PyIter>,
    #[pytraverse(skip)]
    strict: PyAtomic<bool>,   // 추가된 필드
}

#[derive(FromArgs)]
pub struct PyMapNewArgs {
    #[pyarg(named, optional)]
    strict: OptionalArg<bool>,
}
```

`next()`에서 이터레이터 중 하나가 먼저 소진되면, strict 모드일 때 나머지 이터레이터들도 이번 스텝에서 값을 반환하는지 확인해서 길이가 실제로 다른 경우에만 에러를 낸다.

```rust
if zelf.strict.load(atomic::Ordering::Acquire) {
    if idx > 0 {
        return Err(vm.new_value_error(format!(
            "map() argument {} is shorter than argument{}{}",
            idx + 1, plural, idx,
        )));
    }
    for (idx, iterator) in zelf.iterators[1..].iter().enumerate() {
        if let PyIterReturn::Return(_) = iterator.next(vm)? {
            return Err(vm.new_value_error(/* ... */));
        }
    }
}
```

`pickle`로 직렬화할 때 strict 상태가 유실되지 않도록 `__reduce__`/`__setstate__`도 같이 갱신했다. 구현 스타일은 이미 strict를 지원하던 `zip()` 쪽 이터레이터 로직을 그대로 따라갔다.

---
참고

- <https://github.com/RustPython/RustPython/pull/7432>
- <https://github.com/RustPython/RustPython/pull/7462>
- <https://github.com/RustPython/RustPython/pull/7410>
- <https://github.com/RustPython/RustPython/pull/7405>

Python의 정렬은 `sorted()`와 `list.sort()`로 수행한다. 정렬 기준을 지정하는 방식이 Python 2와 3에서 다르다.

## cmp

Python 2 스타일의 비교 함수. 두 원소를 받아서 비교 결과를 반환한다. Python 3에서는 제거되었다.

```python
# 두 원소를 받아서 음수, 0, 양수 반환
def compare(a, b):
    return a - b

sorted([3, 1, 2], cmp=compare)  # Python 2에서만 동작
```

## key

Python 3 스타일의 키 함수. 각 원소를 받아서 비교용 값을 반환한다.

```python
sorted([3, 1, 2], key=lambda x: -x)
```

Python 3에서 `cmp`가 제거되고 `key`만 남은 이유:

- **성능**: key는 원소당 1번만 호출(O(n)), cmp는 비교마다 호출(O(n log n))
- **단순함**: key 함수가 이해하기 더 쉬움

## cmp_to_key

Python 3에서 cmp 스타일 비교 함수를 사용하려면 `functools.cmp_to_key`로 변환해야 한다.

```python
from functools import cmp_to_key

def compare(a, b):
    return a - b

sorted([3, 1, 2], key=cmp_to_key(compare))
```

내부적으로 래퍼 클래스를 만들어 `__lt__`, `__gt__`, `__eq__` 등을 구현한다.

```python
class CmpToKey:
    def __init__(self, obj):
        self.obj = obj
    def __lt__(self, other):
        return cmp_func(self.obj, other.obj) < 0
    def __gt__(self, other):
        return cmp_func(self.obj, other.obj) > 0
    # ...
```

## CPython의 C 구현

CPython은 `_functools` C 확장 모듈에 `cmp_to_key`의 네이티브 구현을 제공한다. 정렬 중 래퍼의 비교 메서드가 O(n log n)번 호출되기 때문에, C 구현으로 Python 메서드 디스패치 오버헤드를 줄인다.

```python
# functools.py
try:
    from _functools import cmp_to_key  # C 구현 우선 사용
except ImportError:
    pass  # 순수 Python 구현으로 fallback
```

C 모듈 import가 실패하는 경우 (예: `--without-extensions` 빌드, WASM 환경, RustPython 같은 대안 구현) 순수 Python 버전이 사용된다.

Powersort는 자연 병합 정렬에서 run을 합치는 순서를 정하는 규칙이다. run을 찾고, 스택에 쌓고, galloping으로 병합하는 건 Timsort와 똑같고 "지금 병합할지 말지" 판단하는 부분만 다르다. Munro와 Wild가 2018년 논문 *Nearly-Optimal Mergesorts*에서 제안했고 CPython 3.11부터 `list.sort()`가 이걸 쓴다([bpo-34561](https://bugs.python.org/issue34561)).

## 병합 순서

자연 병합 정렬은 입력을 이미 정렬된 구간(run)으로 자르고 이웃한 run끼리 합친다. 한 번 합칠 때 드는 비용이 두 run 길이의 합이라서 순서를 잘못 잡으면 느려진다.

길이 1000인 run에 길이 1인 run 1000개를 하나씩 붙이면 매번 1000개 넘게 옮겨야 하니 O(N²)이다. 크기가 비슷한 것끼리 합쳐서 병합 트리가 균형을 이뤄야 O(N log N)이 나온다.

가장 싼 순서를 정확히 구하는 건 run 길이를 가중치로 둔 최적 이진 탐색 트리 문제랑 같다. run을 다 본 다음에야 풀 수 있고 계산도 무겁다. 그래서 Timsort도 Powersort도 왼쪽부터 한 번 훑으면서 적당히 좋은 순서를 고른다.

## Timsort의 규칙

스택 맨 위 세 run 길이를 X, Y, Z(Z가 맨 위)라고 하면, 아래 조건이 깨질 때마다 병합한다.

```
|X| > |Y| + |Z|
|Y| > |Z|
```

보통은 잘 돌지만 맨 위 세 개만 보기 때문에 스택 아래쪽에서는 조건이 깨질 수 있다. 2015년에 KeY 프로젝트가 형식 검증을 돌리다 이 버그를 찾았고 Java와 Python 구현이 둘 다 해당됐다. 최적 비용과 얼마나 차이 나는지에 대한 보장도 약하고, 길이 비교를 이리저리 엮은 규칙이라 왜 그 순서가 되는지 설명하기도 어렵다.

## Powersort의 규칙

run을 찾는 방법은 Timsort와 같다. 짧은 run은 삽입 정렬로 `minrun`까지 늘린다.

차이는 이웃한 두 run 사이 경계마다 power라는 값을 매긴다는 점이다. 전체 길이를 n이라고 하고 배열을 [0, 1) 구간으로 놓으면 두 run A, B의 중점은 이렇게 된다.

```
a = (A 시작 + |A|/2) / n
b = (B 시작 + |B|/2) / n
```

이 구간을 1/2, 1/4, 1/8로 계속 반씩 자를 때 a와 b가 처음으로 서로 다른 칸에 들어가는 깊이가 power다. 이진수로 쓰면 a와 b의 소수점 아래 비트가 처음 달라지는 자리다. 큰 run이 걸쳐 있어서 두 중점이 멀면 일찍 갈라지니까 power가 작고, 작은 run 두 개가 붙어 있으면 늦게 갈라지니까 power가 크다. 이상적인 균형 이진 트리를 그렸을 때 그 경계가 놓일 깊이라고 보면 된다.

CPython `Objects/listobject.c`의 `powerloop`는 나눗셈 없이 시프트만으로 이 값을 구한다.

```c
a = 2 * s1 + n1;      /* 2 * A의 중점 (n 단위) */
b = a + n1 + n2;      /* 2 * B의 중점 */
for (;;) {
    ++result;
    if (a >= n) {         /* 두 비트 모두 1 */
        a -= n; b -= n;
    }
    else if (b >= n) {    /* a는 0, b는 1 → 여기서 갈라짐 */
        break;
    }
    a <<= 1; b <<= 1;     /* 둘 다 0 → 다음 비트로 */
}
```

병합 규칙은 간단하다. 새 run이 들어오면 새 경계의 power p를 구하고, 스택에 남은 경계 중 power가 p보다 큰 것부터 병합한다. power가 크다는 건 트리에서 더 깊다는 뜻이니 먼저 합쳐야 한다. 그다음 새 run을 올리고, 입력을 다 읽으면 남은 run을 위에서부터 합친다.

이렇게 하면 스택에 남는 power는 아래에서 위로 갈수록 커지기만 하므로 스택 높이가 O(log n)을 넘지 않는다.

## 예시

run 길이가 5, 3, 4, 2, 6이고 n = 20인 경우다.

| 경계 | A\|B | B\|C | C\|D | D\|E |
|---|---|---|---|---|
| power | 2 | 1 | 3 | 2 |

```
                [20]            power 1  (B|C)
              /      \
           [8]        [12]      power 2  (A|B, D|E)
          /   \      /    \
         A     B   [6]     E    power 3  (C|D)
         5     3   /  \    6
                  C    D
                  4    2
```

1. A를 넣는다.
2. B가 들어온다. A|B = 2인데 비교할 경계가 없으니 쌓기만 한다.
3. C가 들어온다. B|C = 1이고 A|B(2)가 더 크니 A와 B를 합친다(8).
4. D가 들어온다. C|D = 3이고 (AB)|C는 1이라 그냥 쌓는다.
5. E가 들어온다. D|E = 2이고 C|D(3)가 더 크니 C와 D를 합친다(6). (AB)|(CD)는 1이라 여기서 멈춘다.
6. 입력이 끝나서 남은 걸 위에서부터 합친다. (CD)와 E로 12, 마지막으로 (AB)와 (CDE)로 20.

AB, CD, (CD)E, 전체 순서로 합쳐지고 위 트리 모양과 같다.

## 장점

run 길이 비율의 엔트로피를 H라고 하면 어떤 순서로 합쳐도 H·N보다는 비용이 든다. Powersort는 H·N + O(N) 안에서 끝나서 최적과의 차이가 선형 항뿐이다. 논문 제목의 nearly-optimal이 이 뜻이다. run이 몇 개 안 되는 입력이면 H가 작아서 거의 O(N)에 끝난다.

판단도 싸다. 경계마다 power를 한 번만 구하면 되고, 지켜야 할 조건이 "스택의 power가 위로 갈수록 커진다" 하나라서 Timsort처럼 조건이 몰래 깨질 일이 없다. 구현을 바꾸기도 쉽다. CPython 패치도 `merge_collapse` 근처만 고쳤다.

## 외부 Timsort crate를 Powersort로 바꾼 사례

Rust로 구현한 Python `list.sort()`가 외부 `rust-timsort` crate를 쓰고 있었는데, 무작위 float 100만 개를 정렬하는 데 약 16분이 걸렸다. 무작위 입력에서 O(N²)로 퇴화하고 있었다.

CPython 3.11의 Powersort를 `sorting.rs`로 옮기고 `str`, `int`, `float`만 들어 있는 리스트는 타입별 비교 함수를 쓰게 했더니 0.78초로 줄었다. 약 1,230배다.

## 직접 돌려보기

알고리즘 확인용 최소 구현이다. 병합 자체는 `sorted`로 대신했다.

```python
def power(s1, n1, n2, n):
    a = 2*s1 + n1; b = a + n1 + n2; r = 0
    while True:
        r += 1
        if a >= n: a -= n; b -= n
        elif b >= n: break
        a <<= 1; b <<= 1
    return r

def runs(xs):
    i = 0
    while i < len(xs):
        j = i + 1
        while j < len(xs) and xs[j-1] <= xs[j]: j += 1
        yield i, j - i; i = j

def powersort(xs, log=None):
    n = len(xs); stack = []  # (start, len, 오른쪽 경계의 power)
    def merge():
        s2, n2, _ = stack.pop(); s1, n1, p = stack.pop()
        xs[s1:s2+n2] = sorted(xs[s1:s2+n2])
        if log is not None: log.append((n1, n2))
        stack.append((s1, n1+n2, p))
    for s, l in runs(xs):
        if stack:
            p = power(stack[-1][0], stack[-1][1], l, n)
            while len(stack) > 1 and stack[-2][2] > p: merge()
            stack[-1] = (*stack[-1][:2], p)
        stack.append((s, l, 0))
    while len(stack) > 1: merge()
    return xs

L = [5, 3, 4, 2, 6]
blocks = [list(range(b, b+l)) for b, l in zip([80, 60, 40, 20, 0], L)]
log = []
assert powersort(sum(blocks, []), log) == sorted(sum(blocks, []))
print(log)  # [(5, 3), (4, 2), (6, 6), (8, 12)]
```

---
참고

- https://arxiv.org/abs/1805.04154 (Munro & Wild, *Nearly-Optimal Mergesorts: Fast, Practical Sorting Methods That Optimally Adapt to Existing Runs*, ESA 2018)
- https://github.com/python/cpython/blob/main/Objects/listsort.txt
- https://github.com/python/cpython/issues/78742
- http://envisage-project.eu/proving-android-java-and-python-sorting-algorithm-is-broken-and-how-to-fix-it/

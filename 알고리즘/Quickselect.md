
Quickselect는 정렬되지 않은 배열에서 k번째로 작은 원소를 평균 `O(n)`에 찾는 알고리즘이다. 퀵소트의 파티션을 그대로 쓰되, 양쪽을 다 재귀하지 않고 k가 속한 쪽만 따라간다.

## 동작

파티션은 피벗을 하나 골라서 작은 원소는 왼쪽, 큰 원소는 오른쪽으로 보낸다. 피벗은 정렬된 최종 위치에 놓인다. 피벗 위치가 k면 끝이고, 아니면 k가 있는 쪽으로 재귀한다.

```
[3, 7, 2, 8, 1, 5, 4]에서 3번째로 작은 원소 (k=2, 0-indexed)를 찾자.

피벗 4 → 파티션 → [3, 2, 1, 4, 7, 8, 5]
                             ↑ 피벗 위치 = 3

k=2 < 3이니까 왼쪽 [3, 2, 1]만 본다.

피벗 1 → 파티션 → [1, 2, 3]
                    ↑ 피벗 위치 = 0

k=2 > 0이니까 오른쪽 [2, 3]만 본다.

피벗 3 → 파티션 → [2, 3]
                      ↑ 피벗 위치 = 1

k=0 < 1이니까 왼쪽 [2]. 답은 2.
```

퀵소트였으면 매 단계에서 양쪽을 다 재귀했을 것이다. Quickselect는 한쪽을 버린다.

```cpp
int quickselect(vector<int>& a, int lo, int hi, int k) {
    if (lo == hi) return a[lo];

    int pivot = a[hi], i = lo;
    for (int j = lo; j < hi; j++)
        if (a[j] < pivot) swap(a[i++], a[j]);
    swap(a[i], a[hi]);

    if (k == i) return a[i];
    if (k < i)  return quickselect(a, lo, i - 1, k);
    return quickselect(a, i + 1, hi, k);
}
```

## 복잡도

피벗이 대략 중앙에 떨어진다고 하면, 매 단계마다 문제 크기가 절반으로 줄어든다.

```
n + n/2 + n/4 + n/8 + ... = 2n
```

등비급수이므로 평균 `O(n)`이다. 퀵소트는 양쪽을 다 처리해서 `O(n log n)`인데, 한쪽을 버리는 것만으로 `log n` 팩터가 사라진다.

최악은 매번 피벗이 끝값으로 잡힐 때다. `n + (n-1) + (n-2) + ... = O(n²)`. 퀵소트의 최악과 같다.

## Median of Medians

최악 O(n²)을 피하려면 피벗을 잘 골라야 한다. Blum, Floyd, Pratt, Rivest, Tarjan(1973)이 제안한 방법은 이렇다.

배열을 5개씩 묶고, 각 그룹의 중앙값을 구한다. 5개짜리 그룹의 중앙값은 상수 시간에 구할 수 있으니 이 단계는 O(n)이다. 그 중앙값들(n/5개)의 중앙값을 다시 재귀적으로 구해서 피벗으로 쓴다.

이 피벗이 왜 괜찮을까? 중앙값들 중 절반(n/10개)은 이 피벗보다 작다. 각 그룹에서 중앙값보다 작은 원소가 2개씩 더 있으므로, 피벗보다 확실히 작은 원소가 최소 3n/10개다. 반대쪽도 마찬가지. 따라서 파티션 후 큰 쪽이 최대 7n/10이다.

```
T(n) = T(n/5) + T(7n/10) + O(n)
```

`1/5 + 7/10 = 9/10 < 1`이므로 `O(n)`이다.

상수가 커서 실무에서는 거의 안 쓴다. C++ `nth_element`는 Introselect를 쓰는데, 평소에는 랜덤 피벗 Quickselect로 돌다가 재귀가 너무 깊어지면 Median of Medians로 전환하는 방식이다.

## 활용

[KD-tree](https://blog.rlaisqls.com/til/%EC%95%8C%EA%B3%A0%EB%A6%AC%EC%A6%98/%EC%9E%90%EB%A3%8C%EA%B5%AC%EC%A1%B0/KD-tree/) 구성에서 각 레벨의 중앙값을 찾을 때 `nth_element`를 쓴다. 전체 정렬이 아니라 중앙값 하나만 제자리에 놓으면 되니까 O(n)이면 충분하다. k = n/2로 호출하면 정렬 없이 중앙값을 구할 수 있고, Top-K 문제에서도 k번째를 찾은 뒤 왼쪽에 모인 k개를 취하면 된다.

---
참고

- <https://en.wikipedia.org/wiki/Quickselect>
- <https://en.wikipedia.org/wiki/Median_of_medians>
- <https://en.cppreference.com/w/cpp/algorithm/nth_element>

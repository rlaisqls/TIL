
Quicksort는 피벗을 기준으로 배열을 둘로 나누고, 각각을 재귀적으로 정렬하는 알고리즘이다. (평균 `O(n log n)`, 최악 `O(n²)`)

## 파티션

피벗을 하나 고르고, 배열을 순회하면서 피벗보다 작은 원소를 왼쪽으로 모은다. 순회가 끝나면 피벗을 중간에 넣는다. 피벗은 최종 정렬 위치에 놓인다.

```
[3, 7, 2, 8, 1, 5, 4]  피벗 = 4

j=0: a[0]=3 < 4 → swap(a[0], a[0]), i=1   [3, 7, 2, 8, 1, 5, 4]
j=1: a[1]=7 ≥ 4 → 넘김                     [3, 7, 2, 8, 1, 5, 4]
j=2: a[2]=2 < 4 → swap(a[1], a[2]), i=2   [3, 2, 7, 8, 1, 5, 4]
j=3: a[3]=8 ≥ 4 → 넘김                     [3, 2, 7, 8, 1, 5, 4]
j=4: a[4]=1 < 4 → swap(a[2], a[4]), i=3   [3, 2, 1, 8, 7, 5, 4]
j=5: a[5]=5 ≥ 4 → 넘김                     [3, 2, 1, 8, 7, 5, 4]

피벗을 i 위치에: swap(a[3], a[6])          [3, 2, 1, 4, 7, 5, 8]
                          ↑
                     피벗 확정 위치
```

4의 왼쪽에는 4보다 작은 {3, 2, 1}이, 오른쪽에는 큰 {7, 5, 8}이 있다. 4는 이미 올바른 위치다. 왼쪽과 오른쪽을 각각 재귀하면 전체가 정렬된다.

이것이 Lomuto 파티션이다. 포인터 하나(i)로 "작은 쪽의 끝"을 추적한다.

```cpp
void quicksort(vector<int>& a, int lo, int hi) {
    if (lo >= hi) return;

    int pivot = a[hi], i = lo;
    for (int j = lo; j < hi; j++)
        if (a[j] < pivot) swap(a[i++], a[j]);
    swap(a[i], a[hi]);

    quicksort(a, lo, i - 1);
    quicksort(a, i + 1, hi);
}
```

[Quickselect](https://blog.rlaisqls.com/til/%EC%95%8C%EA%B3%A0%EB%A6%AC%EC%A6%98/Quickselect/)는 여기서 재귀를 한쪽만 하는 변형이다.

## Hoare 파티션

Lomuto보다 오래된 원조 파티션이다. 양쪽 끝에서 포인터 두 개가 안쪽으로 이동하면서, 왼쪽에서 피벗 이상인 원소와 오른쪽에서 피벗 이하인 원소를 찾아 교환한다.

```
[3, 7, 2, 8, 1, 5, 4]  피벗 = 3 (첫 원소)

i →                ← j
[3, 7, 2, 8, 1, 5, 4]

i가 오른쪽으로: a[1]=7 ≥ 3 → 멈춤 (i=1)
j가 왼쪽으로:   a[4]=1 ≤ 3 → 멈춤 (j=4)
swap(a[1], a[4]):  [3, 1, 2, 8, 7, 5, 4]

i가 오른쪽으로: a[3]=8 ≥ 3 → 멈춤 (i=3)
j가 왼쪽으로:   a[2]=2 ≤ 3 → 멈춤 (j=2)
i > j → 파티션 끝. 분할 지점 = j = 2

[3, 1, 2 | 8, 7, 5, 4]
  ≤ 3        ≥ 3
```

Lomuto와 달리 피벗이 제자리에 놓이는 게 아니라, 배열이 "피벗 이하"와 "피벗 이상"으로 나뉜다. swap 횟수가 Lomuto의 약 1/3이라 실무에서 더 빠르다. 이미 정렬된 배열에서도 Lomuto보다 swap이 적다.

```cpp
void quicksort_hoare(vector<int>& a, int lo, int hi) {
    if (lo >= hi) return;

    int pivot = a[lo + (hi - lo) / 2];
    int i = lo - 1, j = hi + 1;
    while (true) {
        while (a[i] < pivot) i++;
        while (a[j] > pivot) j--;
        if (i >= j) break;
        swap(a[i], a[j]);
    }

    quicksort_hoare(a, lo, j);
    quicksort_hoare(a, j + 1, hi);
}
```

## 복잡도

파티션은 O(n)이다. 피벗이 중앙 근처에 떨어지면 양쪽 크기가 대략 n/2씩이고, 재귀 깊이가 O(log n)이 된다. 각 레벨에서 파티션되는 원소의 총합은 항상 n이므로(레벨 0에서 n개, 레벨 1에서 n/2 + n/2 = n개, ...) 레벨당 O(n), 레벨이 O(log n)개라 전체 O(n log n)이다.

최악은 피벗이 매번 최솟값이나 최댓값일 때다. 한쪽에 n-1개가 몰리고, 재귀 깊이가 O(n)이 되어 O(n²)이다. 이미 정렬된 배열에서 첫 번째나 마지막 원소를 피벗으로 고르면 이 상황이 된다.

## 피벗 선택

최악을 피하는 전략들이 있다.

**랜덤 피벗**: 피벗을 랜덤으로 고른다. 적대적 입력에 대해서도 기대 복잡도가 O(n log n)이다. 가장 간단하고 실무에서 흔히 쓴다.

**Median-of-three**: 첫 번째, 중간, 마지막 원소 중 중앙값을 피벗으로 쓴다. 이미 정렬된 배열에서 최악이 되는 걸 막아준다. 많은 표준 라이브러리 구현이 이 방식을 쓴다.

## Introsort

실무의 정렬 함수(C++ `std::sort`, Rust의 `sort_unstable`)는 Quicksort 단독이 아니라 Introsort를 쓴다. Median-of-three 피벗의 Quicksort로 시작하되, 재귀 깊이가 2·log n을 넘으면 Heapsort로 전환해서 최악 O(n log n)을 보장한다. 파티션 후 원소가 16개 이하로 줄어들면 Insertion sort로 마무리한다. 작은 배열에서는 캐시 효율과 분기 예측 때문에 Insertion sort가 더 빠르기 때문이다.

---
참고

- <https://en.wikipedia.org/wiki/Quicksort>
- <https://en.wikipedia.org/wiki/Introsort>
- <https://en.cppreference.com/w/cpp/algorithm/sort>


KD-tree(K-Dimensional tree)는 k차원 공간의 점들을 축을 번갈아가며 이진 분할하는 트리 자료구조이다. 2차원이면 루트에서 x축 기준으로 중앙값을 잡아 왼쪽/오른쪽으로 나누고, 다음 레벨에서는 y축 기준으로 나누고, 다시 x축으로 돌아오는 식이다. n개의 점이 주어지면, 현재 축의 중앙값을 노드로 선택하고 나머지를 왼쪽/오른쪽 서브트리로 재귀 분할한다. 균형 트리가 되므로 높이는 `O(log n)`이다.

## 최근접 이웃 탐색

1. 루트에서 시작해 쿼리 점이 속하는 쪽의 서브트리를 먼저 재귀 탐색한다.
2. 돌아오면서 현재 노드와의 거리를 계산하고, 현재까지의 최소 거리를 갱신한다.
3. 반대쪽 서브트리의 분할 경계까지의 거리가 현재 최소 거리보다 작으면, 반대쪽도 탐색한다. 크면 통째로 건너뛴다(가지치기).

이 가지치기 덕분에 2~3차원에서는 평균 O(log n)에 탐색이 가능하다. 지도 위에서 가장 가까운 음식점을 찾는다거나, 게임에서 가장 가까운 적 유닛을 찾는 것 같은 저차원 공간 문제에 적합하다.

```cpp
// 2D KD-tree
struct Node {
    double pt[2];
    Node *left, *right;
    int axis;
};

Node* build(vector<array<double,2>>& pts, int depth, int lo, int hi) {
    if (lo >= hi) return nullptr;
    int axis = depth % 2;
    int mid = (lo + hi) / 2;
    nth_element(pts.begin()+lo, pts.begin()+mid, pts.begin()+hi,
        [axis](auto& a, auto& b){ return a[axis] < b[axis]; });
    Node* node = new Node{pts[mid][0], pts[mid][1], nullptr, nullptr, axis};
    node->left  = build(pts, depth+1, lo, mid);
    node->right = build(pts, depth+1, mid+1, hi);
    return node;
}

// 최근접 이웃 탐색
double best_dist;
const double* best_pt;

void nn_search(Node* node, const double query[2]) { if (!node) return;

    double dist = 0;
    for (int i = 0; i < 2; i++)
        dist += (query[i] - node->pt[i]) * (query[i] - node->pt[i]);
    if (dist < best_dist) {
        best_dist = dist;
        best_pt = node->pt;
    }

    double diff = query[node->axis] - node->pt[node->axis];
    // 쿼리가 속하는 쪽 먼저
    Node* near = diff <= 0 ? node->left : node->right;
    Node* far  = diff <= 0 ? node->right : node->left;

    nn_search(near, query);
    // 분할면까지의 거리가 현재 최소보다 작으면 반대쪽도 탐색
    if (diff * diff < best_dist)
        nn_search(far, query);
}
```

## 고차원에서의 한계

고차원 공간에서는 기하학적 직관이 깨진다.

- **거리 집중 현상**: 차원이 높아질수록 모든 점 쌍 간의 거리가 비슷해진다. d차원에서 n개의 점을 균일 분포로 뽑을 때, 최근접 거리 D_min과 최원접 거리 D_max에 대해 (D_max − D_min) / D_min → 0 (d → ∞)이 성립한다. "가장 가까운 점"과 "가장 먼 점"의 상대적 차이가 사라지는 것이다. 직관적으로 보면, 차원이 하나 추가될 때마다 각 차원에서의 거리 기여분이 합산되는데, 중심극한정리에 의해 이 합이 평균 주위로 집중되기 때문이다.

- **부피 집중**: d차원 단위 초구(hypersphere)의 부피 대부분은 표면 근처에 집중된다. 반지름 r인 구의 부피는 rᵈ에 비례하므로, 예를 들어 100차원에서 반지름 0.99인 구의 부피는 반지름 1인 구의 0.99¹⁰⁰ ≈ 0.366, 즉 36.6%에 불과하다. 1000차원이면 0.99¹⁰⁰⁰ ≈ 0.00004로 거의 0이다. 점들이 중심 근처에는 거의 없고 껍데기에 몰려있으니, 구 형태의 범위 탐색이 의미를 잃는다.

- **프루닝 실패**: KD-tree가 빠른 이유는 거리 d 이내의 영역에 점이 적기 때문이다. 고차원에서는 이 영역에 거의 모든 점이 포함되어 버린다. 가지치기 조건 `diff² < best_dist`를 생각해 보면, 한 축에서의 거리 차이가 전체 유클리드 거리에서 차지하는 비중이 1/d로 줄어들기 때문에 거의 항상 조건을 만족하게 된다. 768차원이면 각 축의 기여분은 1/768 수준이라, 분할면 반대쪽을 건너뛸 수 있는 경우가 거의 없다.

Friedman, Bentley, Finkel(1977)의 원래 분석에 따르면 KD-tree의 탐색 비용은 O(2^d · log n)이다. 고정 차원에서는 O(log n)이지만 2^d라는 상수가 숨어 있다. brute force는 O(d · n)이므로, 2^d · log n ≈ d · n이 되는 지점에서 역전이 일어난다. n = 100만이면 d ≈ 16~17, n = 1만이면 d ≈ 12~13 근처다.

Weber, Schek, Blott(1998, VLDB)는 KD-tree를 포함한 파티셔닝 기반 인덱스가 약 10차원을 넘으면 순차 탐색에 밀린다는 것을 실험적으로 보였고, scikit-learn은 `algorithm='auto'`에서 D > 15이면 brute force로 전환한다. 임베딩 벡터처럼 수백~수천 차원인 경우에는 [ANN](https://blog.rlaisqls.com/til/AI/Vector%20Search/Approximate%20Nearest%20Neighbor/)을 사용한다.

---
참고

- <https://dl.acm.org/doi/10.1145/355744.355745>
- <https://dl.acm.org/doi/10.5555/645924.671192>
- <https://link.springer.com/chapter/10.1007/3-540-49257-7_15>

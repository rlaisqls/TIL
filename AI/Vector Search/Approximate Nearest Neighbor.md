
Approximate Nearest Neighbor(ANN)는 고차원 벡터 공간에서 정확한 최근접 이웃 대신 근사적으로 가까운 이웃을 찾는 탐색 방식이다.

'왜 근사가 필요한지'를 이해하려면 저차원에서 정확한 탐색이 어떻게 동작하는지부터 봐야 한다.

2차원 평면에서 가장 가까운 두 점을 찾는 문제는 `O(n log n)`에 풀 수 있다. x좌표 기준으로 정렬한 뒤 [스위핑](https://blog.rlaisqls.com/til/%EC%95%8C%EA%B3%A0%EB%A6%AC%EC%A6%98/%EA%B0%80%EC%9E%A5-%EA%B0%80%EA%B9%8C%EC%9A%B4-%EB%91%90-%EC%A0%90/)하면서, 현재 최소 거리 d 이내의 strip에 있는 점만 비교하는 식이다. 분할정복 방식도 같은 원리로, strip 안에서 비교할 점이 상수 개(최대 6~7개)로 제한되기 때문에 효율적이다.

이걸 일반 k차원으로 확장한 것이 [KD-tree](https://blog.rlaisqls.com/til/%EC%95%8C%EA%B3%A0%EB%A6%AC%EC%A6%98/%EC%9E%90%EB%A3%8C%EA%B5%AC%EC%A1%B0/KD-tree/)다. 축을 번갈아가며 공간을 이진 분할하고, 탐색 시 분할면 반대쪽을 가지치기해서 2~3차원에서는 O(log n)에 최근접 이웃을 찾을 수 있다.

하지만 고차원에서는 이 가지치기가 작동하지 않는다. 차원이 높아질수록 모든 점 쌍 간의 거리가 비슷해지고(거리 집중 현상), 한 축의 거리 차이가 전체 유클리드 거리에서 차지하는 비중이 1/d로 줄어들어 분할면 반대쪽을 건너뛸 수 있는 경우가 거의 없어진다. 실험적으로 약 20차원을 넘으면 brute force보다 느려진다.

임베딩 벡터는 보통 768차원(BERT), 1536차원(OpenAI ada-002), 3072차원(OpenAI text-embedding-3-large) 수준이므로 정확한 최근접 탐색은 사실상 불가능하다. 그래서 정확도를 약간 포기하는 대신 속도를 확보하는 ANN을 사용한다.

## ANN 접근법

전체를 다 보지 않고 탐색 범위를 줄인다는 원리는 저차원 알고리즘과 같지만, 그 방법이 기하학적 분할에서 해싱, 그래프, 클러스터링 등으로 바뀐다.

**IVF (Inverted File Index)**

벡터를 k-means 등으로 클러스터링한 뒤, 각 클러스터의 centroid를 인덱스로 관리한다. 쿼리가 들어오면 가장 가까운 nprobe개의 클러스터만 탐색한다.

동작 과정을 구체적으로 보면 이렇다. 먼저 학습(train) 단계에서 전체 벡터 중 일부를 샘플링하여 k-means를 돌린다. k개의 centroid가 만들어지면, 각 벡터를 가장 가까운 centroid의 리스트(inverted list)에 할당한다. "inverted"라는 이름은 정보검색의 역색인에서 따온 것으로, centroid → 벡터 목록이라는 역방향 매핑을 의미한다.

탐색 시에는 쿼리 벡터와 k개의 centroid 간 거리를 계산해 가장 가까운 nprobe개를 고른 다음, 해당 리스트에 속한 벡터들만 순차 비교한다. k=4096이고 nprobe=16이면 전체의 약 0.4%만 보는 셈이다.

```cpp
// IVF 탐색 의사코드
struct IVFIndex {

    int nlist;                              // 클러스터 수
    vector<vector<float>> centroids;        // nlist개의 centroid
    vector<vector<int>> invlists;           // centroid별 벡터 ID 목록
    vector<vector<float>> vectors;          // 원본 벡터

    // 쿼리에 가장 가까운 k개 벡터 반환
    vector<int> search(const vector<float>& query, int k, int nprobe) {
        // 1. 쿼리와 모든 centroid 간 거리 계산, 가장 가까운 nprobe개 선택
        auto nearest = top_k_centroids(query, nprobe);

        // 2. 선택된 클러스터의 inverted list에 속한 벡터만 비교
        priority_queue<pair<float,int>> pq; // (거리, ID)
        for (int ci : nearest) {
            for (int vid : invlists[ci]) {
                float dist = l2_distance(query, vectors[vid]);
                pq.push({dist, vid});
                if (pq.size() > k) pq.pop();
            }
        }
        // nlist=4096, nprobe=16이면 전체의 ~0.4%만 탐색
        return extract_ids(pq);
    }
};
```

nprobe를 늘리면 recall이 올라가지만 속도가 떨어진다. nprobe=nlist로 설정하면 brute force와 동일해진다. 보통 nprobe를 nlist의 1~5% 범위에서 설정하고, recall-latency 그래프를 그려서 적절한 지점을 찾는다.

클러스터 수 nlist는 데이터 크기의 제곱근 근처(예: 100만 건이면 1024)가 경험적 출발점이다. 클러스터가 너무 많으면 학습이 오래 걸리고 각 리스트가 작아져서 통계적으로 불안정해진다. 너무 적으면 리스트가 커서 탐색이 느리다.

**LSH (Locality-Sensitive Hashing)**

가까운 벡터가 같은 bucket에 해싱될 확률이 높도록 해시 함수를 설계한다. 일반적인 해시 함수는 입력이 조금만 달라도 완전히 다른 값을 내놓지만, LSH는 그 반대를 추구한다.

코사인 유사도 기반 LSH(SimHash)를 예로 들면, 랜덤 초평면(random hyperplane) 하나가 공간을 둘로 나눈다. 벡터가 초평면의 법선 벡터와 내적했을 때 양수면 1, 음수면 0으로 해싱한다. 초평면을 b개 사용하면 b비트 해시 코드가 만들어진다.

```cpp
// SimHash: 코사인 유사도 기반 LSH
struct SimHash {
    int num_planes, dim;
    vector<vector<float>> planes; // 랜덤 초평면 법선 벡터들

    SimHash(int d, int b) : dim(d), num_planes(b), planes(b, vector<float>(d)) {
        mt19937 rng(42);
        normal_distribution<float> dist(0, 1);
        for (auto& plane : planes)
            for (auto& v : plane) v = dist(rng);
    }

    // 벡터를 b비트 해시 코드로 변환
    uint64_t hash(const vector<float>& vec) {
        uint64_t code = 0;
        for (int i = 0; i < num_planes; i++) {
            float dot = inner_product(vec.begin(), vec.end(),
                                      planes[i].begin(), 0.0f);
            if (dot > 0) code |= (1ULL << i);
        }
        return code;
    }
    // 두 해시 코드의 해밍 거리가 작을수록 원본 벡터가 유사
};
```

두 벡터의 사잇각이 θ일 때, 하나의 랜덤 초평면에서 같은 쪽에 있을 확률은 1 − θ/π이다. 즉 가까운 벡터일수록(θ가 작을수록) 같은 해시값을 가질 확률이 높다. 이것이 LSH의 수학적 보장이다.

한 테이블로는 recall이 낮으므로, 서로 다른 랜덤 초평면 집합으로 L개의 해시 테이블을 만든다. 쿼리 시 L개 테이블에서 같은 bucket에 있는 후보들의 합집합을 모아 정확한 거리를 계산한다.

유클리드 거리 기반 LSH(E2LSH)도 있다. 랜덤 방향으로 벡터를 투영한 뒤 일정 폭 w로 양자화하는 방식인데, h(v) = ⌊(a · v + b) / w⌋ 형태다. 여기서 a는 가우시안 랜덤 벡터, b는 [0, w) 균일 분포 랜덤 값이다.

LSH는 이론적으로 근사 비율에 대한 보장을 제공한다는 것이 강점이다. 하지만 실무에서는 높은 recall을 얻으려면 테이블 수 L을 크게 잡아야 해서 메모리가 많이 들고, 같은 recall에서 HNSW나 IVF 대비 속도가 느린 경우가 많아 최근에는 주로 특수한 상황(바이너리 코드, 스트리밍 데이터 등)에서 사용된다.

**PQ (Product Quantization)**

PQ는 탐색 알고리즘이라기보다 벡터 압축 기법이다. 고차원 벡터를 작은 코드로 압축하면서도 거리 계산을 근사할 수 있게 해준다.

핵심 아이디어는 벡터를 m개의 sub-vector로 쪼개고, 각각을 독립적으로 양자화하는 것이다. 768차원 벡터를 m=8로 나누면 96차원짜리 sub-vector 8개가 된다. 각 sub-space에서 k-means로 k*=256개의 centroid(코드워드)를 학습하면, 하나의 sub-vector는 8비트(0~255)로 표현된다. 전체 벡터는 8바이트, 원래 768×4=3072바이트 대비 384배 압축이다.

원본 벡터(768차원, 3072 bytes)를 8개의 96차원 sub-vector로 나눈 뒤, 각 sub-vector를 256개 centroid 중 하나의 인덱스(1 byte)로 매핑한다. 결과적으로 전체 벡터가 8 bytes의 PQ 코드로 압축된다.

거리 계산도 효율적이다. 쿼리 벡터가 주어지면, 먼저 쿼리의 각 sub-vector와 256개 코드워드 간의 거리를 미리 계산해서 lookup table을 만든다(ADC, Asymmetric Distance Computation). 이 테이블 크기는 m × 256이다. 이후 DB의 각 PQ 코드에 대해, 코드 값으로 테이블을 참조해 m번 더하면 근사 거리가 나온다.

```cpp
// ADC (Asymmetric Distance Computation) 거리 계산
struct PQIndex {
    int m;           // sub-vector 개수 (e.g. 8)
    int dsub;        // sub-vector 차원 (e.g. 96)
    // codebook[j][c]: j번째 sub-space의 c번째 코드워드 (dsub차원)
    vector<vector<vector<float>>> codebook; // [m][256][dsub]
    vector<vector<uint8_t>> codes;          // DB 벡터들의 PQ 코드 [n][m]

    // 쿼리와 DB 벡터 간 근사 거리 계산
    float approx_distance(const vector<float>& query, int db_idx) {
        // 1. lookup table 구성: 쿼리의 각 sub-vector와 256개 코드워드 간 거리
        float dist_table[8][256]; // m × 256
        for (int j = 0; j < m; j++) {
            const float* qsub = &query[j * dsub];
            for (int c = 0; c < 256; c++) {
                float d = 0;
                for (int k = 0; k < dsub; k++)
                    d += (qsub[k] - codebook[j][c][k]) * (qsub[k] - codebook[j][c][k]);
                dist_table[j][c] = d;
            }
        }
        // 2. PQ 코드로 테이블 참조 → m번의 덧셈으로 거리 근사
        float dist = 0;
        for (int j = 0; j < m; j++)
            dist += dist_table[j][codes[db_idx][j]];
        return dist;
    }
    // 원본: 768번 곱셈-덧셈 → PQ: 8번 테이블 참조 + 덧셈
};
```

원본 벡터 간 거리 계산이 768번의 곱셈-덧셈이라면, PQ는 8번의 테이블 참조와 덧셈으로 끝난다.

OPQ(Optimized PQ)는 PQ 전에 회전 행렬을 적용해서 sub-space 간의 상관관계를 줄이는 최적화이다. sub-vector들이 독립이라는 PQ의 가정에 더 잘 맞게 되어 양자화 오차가 줄어든다.

**[HNSW](../HNSW.md) (Hierarchical Navigable Small World)**

그래프 기반 접근이다. 모든 벡터를 노드로 하고, 가까운 벡터끼리 간선으로 연결한 그래프 위에서 그리디 탐색을 수행한다.

NSW(Navigable Small World)부터 이해하면 쉽다. 모든 노드가 하나의 레이어에 있고, 각 노드는 가까운 이웃 M개와 연결된다. 쿼리가 들어오면 임의의 진입점에서 시작해, 현재 노드의 이웃 중 쿼리에 더 가까운 노드로 이동하기를 반복한다. 더 가까운 이웃이 없으면 멈추고 그 노드를 결과로 반환한다.

NSW의 문제는 그래프가 커지면 진입점에서 목표까지의 hop 수가 많아진다는 것이다. HNSW는 skip list의 아이디어를 빌려 이를 해결한다. 여러 층의 그래프를 만들어서, 상위 층은 노드가 적고(장거리 연결), 하위 층은 노드가 많다(단거리 정밀 연결).

1. 삽입 시 각 노드의 최대 층을 지수분포 ⌊−ln(uniform(0,1)) × mL⌋로 결정한다. mL = 1/ln(M)이 기본값이다. 대부분의 노드는 layer 0에만 존재하고, 극소수가 상위 층까지 올라간다.
2. 탐색 시 최상위 층의 진입점에서 시작해 그리디하게 가장 가까운 노드를 찾아 내려간다. 상위 층에서는 노드가 sparse하므로 한 hop이 큰 거리를 이동한다. Layer 0에 도달하면 ef개의 후보를 유지하며 beam search를 수행한다.

이 계층 구조 덕분에 탐색 복잡도가 O(log n)에 가까워진다. KD-tree와 달리 축 기반 분할이 아니라 데이터 자체의 이웃 관계를 기반으로 하므로 고차원에서도 잘 동작한다.

현재 가장 널리 사용되는 ANN 알고리즘으로, Faiss, pgvector, Milvus, Qdrant, Weaviate 등 대부분의 벡터 DB에서 지원한다. 단점은 인덱스가 메모리에 올라가야 한다는 것과, 벡터 삭제가 까다롭다는 것이다.

## 조합

실제 시스템에서는 이 방법들을 조합하는 경우가 있다. Faiss의 `IVF4096,PQ64` 같은 인덱스는 IVF로 클러스터를 나눈 뒤 각 클러스터 안에서 PQ로 압축된 벡터를 비교한다. `OPQ`로 양자화 전 회전 변환을 적용하거나, `HNSW`를 IVF의 coarse quantizer로 사용하는 것도 가능하다.

Faiss의 인덱스 문자열이 이 조합을 잘 보여준다.

- `Flat`: brute force. 정확하지만 느리다. 벤치마크 기준선으로 사용.
- `IVF4096,Flat`: 4096개 클러스터, 각 리스트 안에서는 brute force.
- `IVF4096,PQ64`: 4096개 클러스터 + 64바이트 PQ 압축.
- `OPQ64,IVF4096,PQ64`: 회전 최적화 + IVF + PQ.
- `HNSW32`: M=32인 HNSW 단독 사용.
- `IVF4096_HNSW32,PQ64`: centroid 탐색에 HNSW를 사용하는 IVF + PQ.

선택 기준은 데이터 규모와 요구사항에 따라 다르다.

- 수십만 건 이하: HNSW 단독으로 충분하다. 메모리에 원본 벡터를 올릴 수 있으면 recall도 높다.
- 수백만~수천만 건: IVFPQ 조합이 메모리 효율적이다. GPU를 쓸 수 있으면 Faiss GPU가 빠르다.
- 수억 건 이상: 디스크 기반 인덱스(DiskANN 등)나 분산 벡터 DB(Milvus, Weaviate)가 필요하다.

[ann-benchmarks](https://ann-benchmarks.com/)에서 다양한 알고리즘의 recall-QPS 그래프를 데이터셋별로 비교할 수 있다. 알고리즘 자체의 우열보다는 데이터 특성과 파라미터 튜닝이 성능을 좌우하는 경우가 많다.

---
참고

- [Vector Search](./Vector%20Search.md)
- [Distance Metrics](./Distance%20Metrics.md)
- <https://www.pinecone.io/learn/series/faiss/product-quantization/>
- <https://arxiv.org/abs/2101.12631>
- <https://ann-benchmarks.com/>
- <https://arxiv.org/abs/1603.09320>

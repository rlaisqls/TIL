- HNSW는 고차원 벡터 공간에서 빠른 근사 최근접 이웃 검색을 위한 그래프 기반 알고리즘이다.
- 다층 그래프: Small World 네트워크 이론을 기반으로 여러 층으로 구성된다.
  - Layer 0 (최하단층): 모든 벡터가 포함된 완전한 그래프
  - 상위 층들: 확률적으로 선택된 일부 벡터들만 포함
  - 각 층은 독립적인 연결 구조를 가진다.

- 장점
  - 대용량 데이터에서 빠른 탐색 속도를 제공한다.
  - 적은 메모리로 높은 성능을 달성한다.
  - 실시간으로 벡터를 추가할 수 있다.

- 단점
  - 정확한 최근접 이웃을 보장하지 않는다.
  - 벡터 삭제가 복잡하다.
  - 인덱스 구성에 시간이 소요된다.

## 세부 동작

- **삽입**: 새 벡터를 인덱스에 추가하는 과정
  - 지수 분포를 사용하여 새 벡터의 최대 층 수를 결정한다.
  - 최상위 층의 진입점에서 시작하여 그리디 탐색을 수행한다.
  - 각 층에서 가장 가까운 이웃을 찾아가며 하강한다.
  - 목표 층에서 M개의 가장 가까운 이웃과 연결을 생성한다.

  ```cpp
  void insert(const std::vector<float>& vector, int max_conn = 16, int max_conn_l0 = 32) {
      int level = random_level();  // 지수분포로 층 수 결정
      
      // 상위 층에서 진입점 찾기
      Node* curr_nearest = entry_point;
      for (int lc = top_level; lc >= level + 1; lc--) {
          curr_nearest = greedy_search_layer(vector, curr_nearest, 1, lc);
      }
      
      // 목표 층들에서 연결 구성
      for (int lc = std::min(level, top_level); lc >= 0; lc--) {
          auto candidates = greedy_search_layer(vector, curr_nearest, ef_construction, lc);
          curr_nearest = select_neighbors(candidates, lc > 0 ? max_conn : max_conn_l0);
          add_connections(vector, curr_nearest, lc);
      }
  }
  ```

- **탐색**: 쿼리 벡터와 가장 유사한 벡터들을 찾는 과정
  - 최상위 층의 진입점에서 시작한다.
  - 각 층에서 가장 가까운 이웃으로 이동하며 하강한다.
  - Layer 0에서 ef개의 후보를 유지하며 정밀 탐색을 수행한다.
  - 상위 k개 결과를 반환한다.

  ```cpp
  std::vector<Node*> search(const std::vector<float>& query, int k, int ef = 200) {
      Node* curr_nearest = entry_point;
      
      // 상위 층에서 진입점 찾기
      for (int lc = top_level; lc >= 1; lc--) {
          curr_nearest = greedy_search_layer(query, curr_nearest, 1, lc);
      }
      
      // Layer 0에서 정밀 탐색
      auto candidates = greedy_search_layer(query, curr_nearest, ef, 0);
      return select_top_k(candidates, k);
  }
  ```

- **M**: 각 층에서 노드당 최대 연결 수 (일반적으로 16)
  - 값이 클수록 정확도가 높아지지만 메모리 사용량이 증가한다.
  
- **Mmax**: Layer 0에서 노드당 최대 연결 수 (일반적으로 32)
  - Layer 0은 가장 정밀한 탐색이 수행되므로 더 많은 연결이 필요하다.

- **mL**: 층 수 결정을 위한 스케일 팩터 (1/ln(2) ≈ 1.44)
  - 지수분포의 매개변수로 층 구조의 희소성을 결정한다.
  
- **ef_construction**: 구성 시 유지할 동적 후보 리스트 크기
  - 값이 클수록 더 정확한 인덱스를 구성하지만 구성 시간이 증가한다.
  
- **ef**: 탐색 시 유지할 동적 후보 리스트 크기
  - 값이 클수록 정확도가 높아지지만 탐색 시간이 증가한다.
  
- **k**: 반환할 최근접 이웃의 개수
  - 사용자가 원하는 결과의 개수를 지정한다.

## 성능

- 시간 복잡도
  - 구성: O(M × log N × d) per element
  - 탐색: O(log N × d) 평균
  - 공간: O(N × M × layers)
  
- 트레이드오프: 정확도와 속도 간의 균형을 조절할 수 있다.
  - ef 증가: 정확도 향상, 탐색 시간 증가
  - M 증가: 정확도 향상, 메모리 사용량 증가
  - 층 수 증가: 탐색 효율성 향상

---

참고

- <https://github.com/nmslib/hnswlib>
- <https://en.wikipedia.org/wiki/Hierarchical_navigable_small_world>
- <https://arxiv.org/abs/1603.09320>
- <https://faiss.ai/>

벡터 검색은 데이터의 의미를 기반으로 결과를 반환하는 검색 방법이다. 텍스트 일치를 찾는 기존 전체 텍스트 검색과 달리 벡터 검색은 다차원 공간에서 검색 쿼리에 가까운 벡터를 찾는다. 벡터가 쿼리에 가까울수록 의미가 더 유사하다.

벡터 검색을 통해 검색어와 데이터의 의미를 해석함으로써 검색자의 의도와 검색 컨텍스트를 고려하여 보다 관련성이 높은 결과를 검색할 수 있다.

벡터는 **데이터를 여러 차원으로 나타내는 숫자 배열**이다. 벡터는 텍스트, 이미지, 오디오, 구조화되지 않은 데이터까지 모든 종류의 데이터를 나타낼 수 있다. 의미적 유사성은 벡터 사이의 거리를 측정하여 결정된다.

## 과정 

1. 벡터 임베딩: vector embedding
    - 데이터의 의미있는 특징을 벡터로 나타낸다.
2. 유사도 점수 계산: similarity score computation
    - 데이터 포인트가 벡터로 표현되면 유사성을 점수로 계산한다
    - 이 때 이웃한(연관 있는) 벡터를 빠르게 검색하기 위해 다양한 Nearest neighbor (NN) 알고리즘이 사용된다. 

## Nearest Neighbor 알고리즘 

- k-Nearest Neighbors (kNN)
    - kNN 알고리즘은 브루트포스로 데이터세트에 있는 모든 벡터와의 거리를 비교하여 쿼리 벡터의 가장 가까운 k명의 이웃을 구한다. 
- Space Partition Tree and Graph (SPTAG)
    - SPTAG는 그래프 분할 기술을 사용하여 벡터를 계층 구조로 구성한다. 벡터를 영역으로 나누므로 이웃 검색을 더 빠르게 할 수 있다.
- Hierarchical Navigable Small World (HNSW)
    - 벡터를 연결하여 계층적 그래프를 구성하는 그래프 기반 알고리즘이다. 탐색 가능한 그래프 구조를 구축하기 위해 무작위화와 로컬 탐색을 활용한다.

---

- Vector Search는 컨텐츠 필터링 및 검색, 추천 시스템, 이상 탐지 등의 용도로 사용될 수 있다.
- mongoDB Atlas에서도 Vector Search를 지원한다. [(문서)](https://www.mongodb.com/docs/atlas/atlas-vector-search/vector-search-overview/)

---
참고
- https://www.mongodb.com/docs/atlas/atlas-vector-search/vector-search-overview
- https://encord.com/blog/vector-similarity-search/?utm_source=pytorchkr

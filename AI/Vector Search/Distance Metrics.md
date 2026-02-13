
벡터 검색에서 사용하는 거리 메트릭은 사용 중인 모델에 맞는 것을 선택해야 한다.

## Cosine Similarity

코사인 유사도는 다차원 공간에서 두 벡터 사이의 각도를 측정하는 방법이다. 유사한 벡터는 비슷한 방향을 가리킨다는 아이디어에 기반한다. 자연어 처리(NLP)에서 많이 사용되며, 벡터의 크기와 관계없이 문서 간의 유사성을 측정한다.

## Dot Product

내적은 두 개 이상의 벡터를 곱하는 연산이다. 출력이 단일 스칼라 값이므로 스칼라 곱이라고도 한다. 내적은 두 벡터의 정렬 상태를 나타낸다. 벡터가 서로 다른 방향을 향하면 음수, 같은 방향을 향하면 양수가 된다.

## Squared Euclidean (L2-Squared)

L2 노름은 벡터 값의 제곱의 합에 대한 제곱근을 취한 것이다.

## Manhattan (L1 Norm 또는 Taxicab Distance)

L1 노름은 벡터의 절대값의 합을 계산한다. 맨해튼 거리는 유클리드 거리에 비해 값이 일반적으로 작기 때문에 계산이 더 빠르다.

## Hamming

해밍 거리는 두 수치 벡터를 비교하는 메트릭이다. 하나의 벡터를 다른 벡터로 변환하는 데 필요한 변경 횟수를 계산한다. 필요한 변경이 적을수록 벡터가 더 유사하다.

1. 두 수치 벡터 비교
2. 두 이진 벡터 비교

---
참고

- <https://weaviate.io/blog/distance-metrics-in-vector-search>
- <https://www.linkedin.com/pulse/building-gen-ai-applications-choosing-right-similarity-sharad-gupta>
- <https://medium.com/advanced-deep-learning/understanding-vector-similarity-b9c10f7506de>
- <https://www.kdnuggets.com/2020/11/most-popular-distance-metrics-knn.html>

K-means는 데이터를 K개의 클러스터로 분할하는 비지도 학습 알고리즘이다. 각 클러스터의 중심(centroid)과 데이터 포인트 간의 거리를 반복적으로 최소화한다.

## 알고리즘

1. K개의 초기 중심점을 선택한다
2. 각 데이터 포인트를 가장 가까운 중심점의 클러스터에 할당한다
3. 각 클러스터의 중심점을 소속 포인트들의 평균으로 갱신한다
4. 중심점이 더 이상 변하지 않거나 최대 반복 횟수에 도달할 때까지 2~3을 반복한다

```python
import numpy as np

def kmeans(data, k, max_iter=20):
    # 초기 중심점 선택
    centroids = data[np.random.choice(len(data), k, replace=False)]

    for _ in range(max_iter):
        # 각 포인트를 가장 가까운 중심점에 할당
        distances = np.linalg.norm(data[:, None] - centroids, axis=2)
        labels = distances.argmin(axis=1)

        # 중심점 갱신
        new_centroids = np.array([
            data[labels == i].mean(axis=0) if np.any(labels == i) else centroids[i]
            for i in range(k)
        ])

        if np.allclose(centroids, new_centroids):
            break
        centroids = new_centroids

    return labels, centroids
```

시간복잡도는 반복당 O(n·k·d)이다. n은 데이터 수, k는 클러스터 수, d는 차원 수이다.

## 초기화 문제

초기 중심점 선택에 따라 결과가 크게 달라진다. 운이 나쁘면 지역 최적해에 빠진다.

**K-means++**는 이 문제를 완화하는 초기화 방법이다. 첫 중심점은 랜덤으로, 이후 중심점은 기존 중심점과의 거리에 비례하는 확률로 선택한다. 멀리 있는 포인트가 다음 중심점이 될 확률이 높아져서, 초기 중심점이 데이터 전체에 골고루 퍼진다. scikit-learn의 `KMeans`는 기본값으로 K-means++를 쓴다.

## K 선택

적절한 K를 모르는 경우가 많다.

**Elbow method**: K를 1부터 늘려가며 각 K에 대한 SSE(Sum of Squared Errors, 각 포인트와 소속 중심점 간 거리 제곱의 합)를 그래프로 그린다. SSE가 급격히 꺾이는 지점(elbow)의 K를 선택한다.

**Silhouette score**: 각 포인트에 대해 "같은 클러스터 내 평균 거리"와 "가장 가까운 다른 클러스터까지의 평균 거리"를 비교한다. -1~1 범위이며, 1에 가까울수록 클러스터링이 잘 된 것이다.

## 활용 예시: 이미지 색상 분석

이미지의 지배적인 색상을 추출할 때 K-means를 쓸 수 있다. 각 픽셀의 RGB 값을 데이터 포인트로, K=2로 클러스터링하면 배경색과 전경색(텍스트 색)을 분리할 수 있다.

```python
pixels = image.reshape(-1, 3)  # (H*W, 3)
labels, centroids = kmeans(pixels, k=2)

# 큰 클러스터 = 배경, 작은 클러스터 = 전경
counts = np.bincount(labels)
bg_color = centroids[counts.argmax()]
fg_color = centroids[counts.argmin()]
```

두 색상의 유클리드 거리가 너무 작으면(대비 부족) 흑백으로 폴백하는 식으로 처리한다.

## 한계

- 클러스터가 구형(spherical)이 아니면 잘 안 맞는다. 길쭉하거나 비정형 분포에는 DBSCAN이나 GMM이 낫다.
- K를 미리 정해야 한다.
- 이상치에 민감하다. 하나의 극단값이 중심점을 크게 끌어당긴다.
- 고차원 데이터에서는 거리 의미가 희석된다(curse of dimensionality).

---
참고

- <https://en.wikipedia.org/wiki/K-means_clustering>
- <https://en.wikipedia.org/wiki/K-means%2B%2B>

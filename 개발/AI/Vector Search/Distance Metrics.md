Use the distance metric that matches the model that you're using.

## Cosine Similarity

The cosine similarity measures the angle between two vectors in a multi-dimensional space – with the idea that similar vectors point in a similar direction. Cosine similarity is commonly used in Natural Language Processing (NLP). It measures the similarity between documents regardless of the magnitude.

## Dot Product

The dot product takes two or more vectors and multiplies them together. It is also known as the scalar product since the output is a single (scalar) value. The dot product shows the alignment of two vectors. The dot product is negative if the vectors are oriented in different directions and positive if the vectors are oriented in the same direction.

## Squared Euclidean (L2-Squared)

The L2 norm takes the square root of the sum of the squared vector values.

## Manhattan (L1 Norm or Taxicab Distance)

The L1 norm is calculated by taking the sum of the absolute values of the vector. The Manhattan distance is faster to calculate since the values are typically smaller than the Euclidean distance.

## Hamming

The Hamming distance is a metric for comparing two numeric vectors. It computes how many changes are needed to convert one vector to the other. The fewer changes are required, the more similar the vectors.

1. Compare two numeric vectors
2. Compare two binary vectors

---
참고

- <https://weaviate.io/blog/distance-metrics-in-vector-search>
- <https://www.linkedin.com/pulse/building-gen-ai-applications-choosing-right-similarity-sharad-gupta>
- <https://medium.com/advanced-deep-learning/understanding-vector-similarity-b9c10f7506de>
- <https://www.kdnuggets.com/2020/11/most-popular-distance-metrics-knn.html>

IoU(Intersection over Union)는 두 영역이 얼마나 겹치는지를 0~1 사이 값으로 나타내는 지표이다. object detection에서 예측 bbox와 정답 bbox의 일치도를 평가하는 데 쓰이고, 그 외에도 영역 기반 매칭이 필요한 곳에 범용적으로 쓰인다.

## 계산

```
IoU = 교집합 넓이 / 합집합 넓이
```

두 bbox A, B가 각각 `(x1, y1, x2, y2)` 형식일 때:

```python
def iou(a, b):
    # 교집합
    ix1 = max(a[0], b[0])
    iy1 = max(a[1], b[1])
    ix2 = min(a[2], b[2])
    iy2 = min(a[3], b[3])
    inter = max(0, ix2 - ix1) * max(0, iy2 - iy1)

    # 합집합
    area_a = (a[2] - a[0]) * (a[3] - a[1])
    area_b = (b[2] - b[0]) * (b[3] - b[1])
    union = area_a + area_b - inter

    return inter / union if union > 0 else 0
```

- IoU = 1.0: 두 영역이 완전히 일치
- IoU = 0.0: 겹치는 부분이 전혀 없음
- IoU ≥ 0.5: 보통 "매칭됨"으로 판정하는 임계값 (태스크마다 다름)

## Object Detection에서의 활용

**mAP 계산**: 예측 bbox와 정답 bbox의 IoU가 임계값(보통 0.5) 이상이면 True Positive로 간주한다. COCO 데이터셋은 IoU 0.5~0.95를 0.05 간격으로 평가하여 평균을 낸다(mAP@[0.5:0.95]).

**NMS(Non-Maximum Suppression)**: 같은 객체에 대한 중복 예측을 제거할 때 IoU를 쓴다. 가장 높은 confidence의 bbox를 남기고, 그것과 IoU가 임계값 이상인 다른 bbox를 제거하는 과정을 반복한다.

```python
def nms(boxes, scores, threshold=0.5):
    order = scores.argsort()[::-1]
    keep = []
    while len(order) > 0:
        i = order[0]
        keep.append(i)
        ious = [iou(boxes[i], boxes[j]) for j in order[1:]]
        remaining = [j for j, v in zip(order[1:], ious) if v < threshold]
        order = remaining
    return keep
```

## 텍스트 퓨전에서의 활용

OCR에서 인접 프레임의 텍스트 영역을 매칭할 때도 IoU를 쓸 수 있다. 프레임 A의 텍스트 bbox와 프레임 B의 텍스트 bbox를 IoU로 비교하여, 같은 위치의 텍스트인지 판별한다. IoU가 낮은(예: 0.3 미만) 텍스트는 해당 프레임에서 가려진(occluded) 텍스트일 수 있으므로, 인접 프레임에서 보완하는 방식으로 활용한다.

## 변형

- **GIoU (Generalized IoU)**: 두 bbox를 모두 포함하는 최소 enclosing box를 고려하여, 겹치지 않는 경우에도 거리 정보를 반영한다. 값의 범위가 -1~1이다.
- **DIoU (Distance IoU)**: 두 bbox 중심점 간의 거리를 추가로 고려한다.
- **CIoU (Complete IoU)**: DIoU에 종횡비(aspect ratio) 일관성까지 반영한다.

이 변형들은 주로 loss function으로 쓰인다. IoU 자체는 미분이 안 되는 구간(겹침 없을 때)이 있어서, GIoU/DIoU/CIoU가 학습 시 더 안정적인 그래디언트를 제공한다.

---
참고

- <https://en.wikipedia.org/wiki/Jaccard_index>
- <https://arxiv.org/abs/1902.09630> (GIoU)
- <https://arxiv.org/abs/1911.08287> (DIoU, CIoU)

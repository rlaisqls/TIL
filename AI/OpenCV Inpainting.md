
OpenCV의 `cv2.inpaint()` 함수는 이미지에서 손상된 영역이나 제거하고 싶은 객체를 주변 픽셀 정보를 이용해 자연스럽게 채우는 기법이다. 사진에서 스크래치를 제거하거나, 워터마크를 지우거나, 불필요한 객체를 없애는 데 사용된다.

```python
import cv2

# dst = cv2.inpaint(src, mask, inpaintRadius, flags)
result = cv2.inpaint(image, mask, 3, cv2.INPAINT_TELEA)
# 또는
result = cv2.inpaint(image, mask, 3, cv2.INPAINT_NS)
```

- `src`: 입력 이미지
- `mask`: 복원할 영역을 표시한 마스크 (흰색 픽셀이 복원 대상)
- `inpaintRadius`: 복원 시 참조할 주변 픽셀의 반경
- `flags`: 사용할 알고리즘 선택

OpenCV는 두 가지 inpainting 알고리즘을 제공한다. 각각의 원리와 특성을 살펴보자.

## INPAINT_TELEA (Fast Marching Method)

Alexandru Telea가 2004년에 제안한 알고리즘이다. Fast Marching Method를 기반으로 경계에서 안쪽으로 픽셀을 채워나간다.

- 경계에서 안쪽으로 순차적으로 채워나가므로 속도가 빠르다
- 텍스처가 적은 균일한 영역에서 좋은 결과를 보인다
- 작은 영역 복원에 적합하다
- 큰 영역에서는 흐릿해지는 경향이 있다

TELEA는 아래 순서로 계산한다.

1. 복원 영역의 경계에서 시작하여 안쪽으로 진행한다
2. Fast Marching Method를 사용해 픽셀 처리 순서를 결정한다
3. 각 픽셀을 채울 때 주변의 알려진 픽셀들의 가중 평균을 사용한다

가중치는 세 가지 요소를 곱하여 결정한다.

```
w(p,q) = dir(p,q) · dst(p,q) · lev(p,q)
```

- **dir (방향 요소)**: 경계에서 안쪽으로의 방향과 일치할수록 높은 가중치를 부여한다. 복원 방향과 같은 흐름의 픽셀 정보를 더 신뢰하는 것이다.
- **dst (거리 요소)**: 가까운 픽셀일수록 높은 가중치를 부여한다. 멀리 있는 픽셀보다 인접 픽셀이 더 유사할 가능성이 높기 때문이다.
- **lev (레벨 요소)**: 같은 등고선(isophote) 상에 있는 픽셀에 우선순위를 준다. 밝기가 비슷한 영역끼리 연결되도록 유도한다.

## INPAINT_NS (Navier-Stokes)

Bertalmio et al.이 2001년에 제안한 방법으로, 유체역학의 Navier-Stokes 방정식에서 구상되었다.

- 경계의 곡선과 모서리를 자연스럽게 연장한다 큰 영역 복원에서 구조적 일관성이 좋다
- 반복 계산이 필요하므로 TELEA보다 느리다
- 복잡한 텍스처 재현에는 한계가 있다

이 알고리즘의 핵심 아이디어는 이미지의 등휘도선(isophote)을 유체의 흐름으로 간주하는 것이다. 등휘도선이란 밝기가 같은 점들을 연결한 선으로, 이미지의 모서리와 수직인 방향이다.

손상된 영역으로 이 흐름을 자연스럽게 연장시키면 빈 공간으로 색이 흘러들어가듯이, 주변의 색상과 패턴을 자연스럽게 채운다.

수학적으로는 다음 편미분 방정식을 반복적으로 풀어 수렴할 때까지 진행한다.

```
∂I/∂t = ∇⊥I · ∇(∆I)
```

- `I`: 이미지 밝기 함수
- `∇⊥I`: 등휘도선 방향 벡터 (기울기의 수직 방향)
- `∆I`: 라플라시안 (smoothness term)

이 방정식이 의미하는 바는 다음과 같다.

1. Smoothness (라플라시안): 이미지의 부드러움을 유지하도록 한다
2. Isophote direction: 경계에서의 기울기 방향을 손상 영역 내부로 전파한다

---
참고

- <https://www.olivier-augereau.com/docs/2004JGraphworksTeworkslea.pdf>
- <https://www.math.ucla.edu/~berMDleo/papers/cvpr01.pdf>
- <https://docs.opencv.org/4.x/df/d3d/tutorial_py_inpainting.html>

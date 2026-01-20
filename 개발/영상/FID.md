FID(Fréchet Inception Distance)는 생성 모델이 만든 이미지의 품질과 다양성을 평가하는 지표이다. GAN, Diffusion 모델 평가의 사실상 표준으로 사용된다.

## 원리

Inception v3 네트워크의 마지막 풀링 레이어에서 feature를 추출하고, 실제 이미지와 생성 이미지의 feature 분포를 비교한다. 두 분포를 다변량 가우시안으로 모델링하여 Fréchet distance를 계산한다.

```
FID = ||μr - μg||² + Tr(Σr + Σg - 2(ΣrΣg)^(1/2))
```

- μr, μg: 실제/생성 이미지 feature의 평균
- Σr, Σg: 실제/생성 이미지 feature의 공분산 행렬

## 특징

- **낮을수록 좋음**: 0에 가까울수록 실제 이미지 분포와 유사
- **품질 + 다양성**: 단순 품질뿐 아니라 생성 이미지의 다양성도 반영
- **샘플 수 의존**: 안정적인 결과를 위해 최소 10,000장 이상 필요

## Python 구현

```python
from pytorch_fid import fid_score

fid = fid_score.calculate_fid_given_paths(
    [real_path, generated_path],
    batch_size=50,
    device='cuda',
    dims=2048
)
```

```bash
# 커맨드라인
python -m pytorch_fid real_images/ generated_images/
```

## 한계

- Inception v3에 의존하므로 해당 네트워크가 잘 인식하지 못하는 도메인에서는 부정확할 수 있다
- 샘플 수가 적으면 분산이 크다
- 두 분포의 거리만 측정하므로 개별 이미지 품질은 알 수 없다

## 관련 지표

- **IS (Inception Score)**: FID 이전에 사용되던 지표. 품질과 다양성을 측정하지만 실제 데이터 분포를 고려하지 않음
- **KID (Kernel Inception Distance)**: FID의 unbiased 버전. 적은 샘플에서도 안정적

---
참고
- [GANs Trained by a Two Time-Scale Update Rule Converge to a Local Nash Equilibrium (NeurIPS 2017)](https://arxiv.org/abs/1706.08500)
- [pytorch-fid GitHub](https://github.com/mseitzer/pytorch-fid)

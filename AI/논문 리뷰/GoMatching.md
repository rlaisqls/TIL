
GoMatching++는 영상에서 텍스트를 검출·인식·추적하는 Video Text Spotting(VTS) 모델이다. 이미 성능이 검증된 이미지 텍스트 스포터를 동결한 채 추적 모듈만 가볍게 학습하는 "freeze and adapt" 전략을 취한다. 원본 GoMatching(NeurIPS 2024)에서 LST-Matcher 구조를 재설계하여 파라미터를 64% 줄이면서 동등 이상의 성능을 달성하고, ArTVideo 벤치마크를 대폭 확장했다.

Video Text Spotting은 detection, recognition, tracking 세 태스크를 동시에 풀어야 한다. 기존 접근법(TransDETR 등)은 세 가지를 end-to-end로 동시 학습하는데, 근본적인 문제가 있다.

이미지 텍스트 스포팅에서는 이미 높은 인식 성능을 달성한 모델(DeepSolo 등)이 있다. 그런데 이것을 VTS에 맞춰 end-to-end로 재학습하면 인식 성능이 크게 떨어진다.

- **태스크 간 최적화 충돌**: detection, recognition, tracking은 각각 다른 방향으로 파라미터를 끌어당긴다. 동시 최적화하면 어느 쪽도 최적에 도달하지 못한다.
- **학습 데이터 부족**: VTS 데이터셋은 이미지 데이터셋에 비해 규모가 훨씬 작다. 이 적은 데이터로 recognition까지 학습하면 성능이 퇴화한다.
- **아키텍처 한계**: 기존 VTS 모델은 여전히 RoI 기반 인식을 사용하는데, 이미지 쪽에서는 query 기반 방식이 RoI를 넘어섰다.

(ablation 실험에서 DeepSolo를 동결하고 추적만 학습하면 MOTA 72.04%이지만, end-to-end로 학습하면 68.03%로 떨어졌다 함) GoMatching 시리즈는 **강력한 이미지 스포터를 그대로 두고, 추적만 추가하는 형태로 접근한다.**

## 아키텍처

세 개의 컴포넌트로 구성된다.

**Frozen Image Text Spotter (DeepSolo)**

각 프레임을 독립적으로 처리하여 텍스트를 검출·인식하는 백본이다. 파라미터를 완전히 동결한다. DeepSolo는 query 기반 아키텍처로, 각 텍스트 인스턴스를 p개의 query sequence로 표현한다. 이 query에는 위치, 형태, 내용에 대한 의미 정보가 담겨 있고, GoMatching++는 이것을 RoI feature 대신 추적의 입력으로 사용한다.

DeepSolo 자체가 RoI-free 설계로 arbitrary-shape 텍스트를 지원하기 때문에, 곡선 텍스트 처리를 위한 별도 모듈이 필요 없다.

**Rescoring Head**

이미지→영상 도메인 갭으로 인해 confidence score가 부정확해지는 문제를 보정하는 모듈이다.

- DeepSolo 분류 헤드의 파라미터로 초기화한 단일 linear layer
- frozen query를 입력받아 새로운 confidence score(`cr`)를 계산한다
- 원본 score(`co`)와 max fusion: `cf = max(co, cr)`
- focal loss(α=0.25, γ=2.0)로 학습하고, Hungarian algorithm으로 prediction-GT를 매칭한다

max 연산 덕분에 원본 점수가 높으면 그대로 유지되고, 낮을 때만 보정된다. ICDAR15-video 기준으로 rescoring 적용 시 MOTA +1.52%, IDF1 +1.69% 향상. ICDAR13에서는 recall이 65.7%→74.8%로 9.1%p 뛴다.

**LST-Matcher (Long-Short Term Matching)**

프레임 간 텍스트 인스턴스를 연결하여 궤적(trajectory)을 만드는 추적 모듈이다. 두 단계로 매칭한다.

- **ST-Matcher**: 현재 프레임 t와 직전 프레임 t-1 사이에서 매칭. 단순한 움직임 연속성을 처리한다.
- **LT-Matcher**: ST에서 매칭 실패한 인스턴스를 과거 H개 프레임의 히스토리 메모리와 매칭. occlusion이나 큰 외형 변화에 대응한다.

## LST-Matcher 설계 탐색

GoMatching++의 가장 큰 기여 중 하나는, LST-Matcher의 네 가지 아키텍처 변형을 체계적으로 비교한 것이다.

**Transformer-based (원본 GoMatching)**

원본 GoMatching에서 사용한 구조다. shared 2-layer FFN이 frozen query를 embedding으로 변환하고, 1-layer Transformer encoder가 과거 임베딩에 self-attention을 적용한 뒤, 1-layer Transformer decoder에서 현재 임베딩(query)과 과거 임베딩(key/value)으로 cross-attention을 수행하여 association score를 계산한다. 학습 파라미터 32.79M.

**Similarity-only**

FFN과 attention을 모두 제거하고, frozen query 간의 cosine similarity만으로 매칭한다. 파라미터가 거의 없지만, frozen query가 tracking용으로 설계된 것이 아니기 때문에 성능이 크게 떨어진다. 이 결과는 frozen query를 tracking embedding으로 변환하는 FFN이 필수적이라는 것을 보여준다.

**FFN-based**

FFN은 유지하되 attention을 제거한 구조다. 학습 파라미터 7.60M으로 가볍지만, 과거 프레임 간 관계를 모델링하지 못해 성능이 부족하다.

**Cross-attention-based (GoMatching++)**

GoMatching++가 최종 채택한 구조다. shared FFN + cross-attention만으로 구성하고, encoder의 self-attention을 제거했다. 학습 파라미터 11.80M으로 원본의 약 1/3이다.

self-attention 없이도 성능이 유지되는 이유는, cross-attention 단계에서 현재 프레임 query가 과거 임베딩 전체를 key/value로 참조하면서 이미 충분한 시간적 관계를 포착하기 때문이다. encoder의 self-attention은 과거 임베딩끼리의 관계를 정리하는 역할인데, 실제로는 이 과정이 없어도 cross-attention만으로 매칭 정확도가 유지된다.

```
GoMatching (Transformer-based):
  frozen query → FFN → encoder(self-attn) → decoder(cross-attn) → score
  파라미터: 32.79M

GoMatching++ (Cross-attention-based):
  frozen query → FFN → cross-attention → score
  파라미터: 11.80M (64% 감소)
```

ICDAR15-video 기준 GoMatching++ 구조는 MOTA 72.20%로 원본(72.04%)과 동등하면서 파라미터는 1/3이다.

## ST vs LT 매칭의 상호보완성

두 Matcher는 각각 다른 상황을 커버한다.

- **ST-Matcher만**: MOTA 71.17%, IDF1 75.53%. 인접 프레임 매칭은 잘 하지만, occlusion 후 재등장을 놓친다.
- **LT-Matcher만**: MOTA 70.07%, IDF1 78.48%. 장기 매칭은 강하지만 인접 프레임의 정밀한 연결에서 약하다.
- **LST-Matcher 결합**: MOTA 72.20%, IDF1 80.11%. 두 가지를 순차 적용하면 양쪽의 장점을 모두 취한다.

히스토리 길이 H는 5가 최적이다. 너무 길면 오래된 feature가 노이즈로 작용한다.

## 추론 파이프라인

영상의 각 프레임에 대해 순서대로 처리한다.

1. DeepSolo가 현재 프레임에서 텍스트 검출·인식 수행
2. Rescoring Head가 confidence score 보정 (`cf = max(co, cr)`)
3. NMS 적용 후 confidence 0.3 이상인 인스턴스를 추적 후보로 선정
4. ST-Matcher가 직전 프레임 궤적과 매칭
5. 미매칭 인스턴스를 LT-Matcher가 히스토리 궤적과 매칭
6. association score ≥ 0.2이면 가장 높은 점수의 기존 궤적에 연결
7. 어디에도 매칭되지 않은 인스턴스는 새 궤적 시작
8. 5프레임 미만의 짧은 궤적은 폐기

## 학습

**학습 대상**: Rescoring Head + LST-Matcher만 학습한다. DeepSolo 전체는 동결. 학습 파라미터 11.80M.

**Loss 함수**:

```
L = λ_res · L_res + λ_asso · L_asso
```

- `L_res`: focal loss (α=0.25, γ=2.0). Hungarian matching으로 prediction-GT 대응.
- `L_asso`: association loss. ST와 LT 각각에 대해 올바른 궤적 연결의 log-likelihood를 최대화한다. 미매칭 query에 대한 background loss도 포함한다.

association score는 cosine similarity 기반이다.

```
G(i, j) = exp(S_ij) / Σ_n exp(S_in)
```

여기서 `S_ij`는 임베딩 i와 j의 cosine similarity이다. 학습 시 GT 할당은 IoU 기반으로, `IoU ≥ 0.5`인 prediction을 해당 궤적에 대응시킨다.

- λ_res=1.0, λ_asso=0.5

**학습 설정**:

- Batch size 6 (같은 영상의 프레임들)
- 해상도 1280, scale-and-crop augmentation
- AdamW, learning rate 5e-5, warmup cosine annealing
- 총 30k iterations
- 단일 RTX 3090 (24GB)에서 약 3시간

TransDETR 대비: 학습 파라미터 70% 감소(11.80M vs 39.35M), 메모리 19.4GB 절약(7.3GB vs 26.7GB), 학습 시간 301 GPU 시간 절약(3시간 vs 304시간).

## 실험 결과

MOTA(Multi-Object Tracking Accuracy), MOTP(Precision), IDF1(ID 일관성)이 주요 지표이다.

**ICDAR15-video** (일반 텍스트): MOTA 72.20%, MOTP 78.52%, IDF1 80.11%. TransDETR 대비 MOTA +11.08%.

**BOVText** (중영 이중언어): MOTA 52.9%, MOTP 87.2%, IDF1 62.8%. 기존 모델들이 이중언어 인식에 약한 반면, DeepSolo의 인식 능력을 그대로 활용하여 CoText 대비 MOTA +42.6%.

**DSText** (밀집·소형 텍스트): MOTA 23.23%로 단일 모델 중 1위. 밀집 환경에서도 효과적이다.

**ArTVideo** (곡선 텍스트): 곡선 텍스트 spotting MOTA 73.3%. TransDETR-mask는 MOTA -25.5%로 음수 값을 기록하는데, GoMatching++는 DeepSolo가 이미 arbitrary-shape를 다룰 수 있어 곡선에서도 강하다.

GoMatching과 GoMatching++의 직접 비교에서 흥미로운 점은, ICDAR15 MOTA가 72.04%→72.20%로 차이가 미미하다는 것이다. GoMatching++의 핵심 가치는 성능 향상보다는 **동일 성능을 1/3 파라미터로 달성**한다는 효율성에 있다.

## ArTVideo 벤치마크

GoMatching++에서 대폭 확장한 곡선 텍스트 영상 벤치마크이다.

원본 GoMatching의 ArTVideo는 20개 영상, 884프레임의 소규모 테스트셋이었다. GoMatching++에서는 학습/테스트 분할을 갖춘 본격적인 벤치마크로 확장했다.

- 60개 영상, 12,711 프레임, 169,802 텍스트 인스턴스
- 직선 텍스트 111,784개(65%), 곡선 텍스트 58,018개(34%)
- 출처: YouTube 55개, ICDAR15-video 2개, BOVText 3개
- 직선 텍스트는 quadrilateral, 곡선 텍스트는 CTW1500 형식의 14-point polygon으로 annotation
- 인스턴스별 tracking ID, 텍스트 전사(transcription), segmentation mask 포함
- 프레임당 텍스트 인스턴스 수는 보통 2~30개, 밀집 프레임에서는 70개 이상

기존 VTS 벤치마크(ICDAR15-video, BOVText, DSText)에는 곡선 텍스트가 거의 없어서, arbitrary-shape VTS 연구를 위한 벤치마크가 부재했다. ArTVideo가 이 공백을 채운다.

## 의의

GoMatching++가 보여주는 것은 두 가지다.

첫째, end-to-end 학습이 항상 최선은 아니다. 이미 강력한 모듈이 있다면 동결하고 부족한 부분만 가볍게 학습하는 것이 성능과 효율 모두에서 유리할 수 있다.

둘째, 아키텍처를 단순화해도 성능이 유지될 수 있다. Transformer의 encoder self-attention을 제거하고 cross-attention만 남겨도 tracking 성능은 떨어지지 않으면서, 파라미터는 64% 줄어든다. 모든 구성요소가 실제로 기여하는지 검증하고, 불필요한 부분을 과감히 제거하는 것이 중요하다.

---
참고

- <https://arxiv.org/abs/2505.22228> (GoMatching++)
- <https://arxiv.org/abs/2401.07080> (GoMatching)
- <https://github.com/Hxyz-123/GoMatching>

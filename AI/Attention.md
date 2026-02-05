
Attention 연산을 이해하고 최적화하는 방법을 설명한다.

## Attention이란?

Attention은 "여러 정보 중에서 지금 중요한 것에 가중치를 더 주는" 메커니즘이다.

**일상적인 예시**

시끄러운 카페에서 친구와 대화한다고 생각해보자. 주변에 여러 소리가 있다.

- 친구 목소리
- 옆 테이블 대화
- 배경 음악
- 커피 머신 소리

우리 뇌는 자동으로 "친구 목소리"에 높은 가중치를 주고, 나머지는 낮은 가중치를 준다. 모든 소리가 들리지만, 친구 목소리를 중심으로 정보를 처리한다. 이것이 Attention이다.

**AI에서의 Attention**

문장 "The cat sat on the mat because it was tired"를 처리한다고 하자.

"it"이 무엇을 의미하는지 알려면, 다른 단어들을 참고해야 한다. 모델은 각 단어에 "관련도 점수"를 매긴다.

```
"it"이 참고할 때 각 단어의 점수:
- The: 0.02
- cat: 0.70  ← 높음! "it"은 "cat"을 가리킴
- sat: 0.05
- on: 0.01
- the: 0.02
- mat: 0.15
- because: 0.03
- was: 0.01
- tired: 0.01
```

점수 합은 1.0이다. "cat"의 점수가 0.70으로 가장 높으므로, "it"의 의미를 계산할 때 "cat"의 정보를 70% 반영하고 나머지 단어들은 조금씩 반영한다.

**Query, Key, Value**

이 점수를 계산하는 구조가 Query, Key, Value이다.

- **Query (Q)**: "나는 어떤 정보가 필요해?" - 현재 처리 중인 단어가 던지는 질문
- **Key (K)**: "나는 이런 정보를 가지고 있어" - 각 단어가 가진 특징
- **Value (V)**: 실제로 전달할 정보 내용

동작 과정:

1. "it"의 Query와 각 단어의 Key를 비교해서 점수를 계산
2. 점수를 확률로 변환 (합이 1이 되도록)
3. 각 단어의 Value를 점수에 따라 가중 평균

```
"it"의 최종 표현 = 0.02×(The의 Value) + 0.70×(cat의 Value) + 0.05×(sat의 Value) + ...
```

결과적으로 "it"은 "cat"의 정보를 많이 담은 벡터가 된다.

## Scaled Dot-Product Attention 공식

Transformer 논문에서 제안된 Attention 계산 공식이다. 현재 대부분의 언어 모델(GPT, BERT, LLaMA 등)이 이 방식을 사용한다.

```
Attention(Q, K, V) = softmax(QK^T / √d) × V
```

복잡해 보이지만, 단계별로 나누면 간단하다.

**1단계: 유사도 계산 (QK^T)**

Query와 Key의 내적(dot product)을 계산한다. 내적 값이 클수록 두 벡터가 비슷하다는 뜻이다.

```
예: Q = [1, 0, 1], K = [1, 1, 0]
내적 = 1×1 + 0×1 + 1×0 = 1
```

모든 Query와 Key 쌍에 대해 이 계산을 하면, N×N 크기의 "점수표"가 만들어진다 (N은 시퀀스 길이).

**2단계: 스케일링 (/ √d)**

내적 값을 √d로 나눈다 (d는 벡터 차원). 왜 나눌까?

벡터 차원이 크면 내적 값도 커지는 경향이 있다. 예를 들어 64차원 벡터의 내적은 4차원 벡터보다 훨씬 큰 값이 나온다. 이렇게 값이 너무 커지면 다음 단계인 softmax에서 문제가 생긴다.

```
예: d=64일 때, √d = 8
내적 값 64를 8로 나누면 → 8 (적당한 크기로 조정)
```

**3단계: Softmax**

점수를 확률로 변환한다. 모든 점수의 합이 1이 되도록 정규화하는 것이다.

```
점수: [2.0, 1.0, 0.5] → softmax → [0.59, 0.24, 0.17]
```

softmax는 큰 값은 더 크게, 작은 값은 더 작게 만든다. 즉, 가장 관련 높은 단어에 집중하게 된다.

**4단계: 가중 합 (× V)**

softmax로 얻은 확률(가중치)을 Value에 곱해서 더한다.

```
가중치: [0.59, 0.24, 0.17]
V1 = [1, 0], V2 = [0, 1], V3 = [1, 1]

결과 = 0.59×[1,0] + 0.24×[0,1] + 0.17×[1,1]
     = [0.59, 0] + [0, 0.24] + [0.17, 0.17]
     = [0.76, 0.41]
```

관련 높은 단어의 정보를 많이, 관련 낮은 단어의 정보를 적게 가져오는 것이다.

## Eager 구현의 문제점

공식을 그대로 코드로 옮기면 이렇게 된다.

```python
# Eager 구현
scores = torch.matmul(Q, K.transpose(-2, -1)) / math.sqrt(d)  # N×N 행렬 생성
attention_weights = torch.softmax(scores, dim=-1)  # N×N 행렬 저장
output = torch.matmul(attention_weights, V)
```

문제는 N×N 크기의 중간 행렬이 필요하다는 것이다.

시퀀스 길이가 4096인 경우를 생각해보자.

- 중간 행렬 크기: 4096 × 4096 = 16,777,216개의 숫자
- FP16(2바이트) 기준 메모리: 약 32MB
- 이런 행렬이 여러 개 필요 (각 layer, 각 head마다)
- 전체 모델에서 수 GB의 메모리 사용

시퀀스 길이가 2배가 되면 메모리는 4배가 된다 (N² 복잡도). GPT-4나 Claude처럼 긴 문맥을 처리하려면 이 문제를 해결해야 한다.

속도 문제도 있다. GPU의 메모리 구조를 이해해야 한다.

- **HBM (High Bandwidth Memory)**: GPU의 메인 메모리. 용량이 크지만 (A100: 80GB) 상대적으로 느림
- **SRAM**: GPU 칩 내부의 캐시. 용량이 작지만 (A100: 20MB) 매우 빠름

비유하면 HBM은 대형 창고, SRAM은 작업대라고 생각할 수 있다. 창고에서 물건을 가져오는 것은 시간이 걸리지만, 작업대 위의 물건은 바로 쓸 수 있다.

Eager 구현은 이렇게 동작한다.

```
1. Q, K를 HBM에서 SRAM으로 로드
2. QK^T 계산
3. 결과 S를 HBM에 저장 ← 느림
4. S를 다시 HBM에서 로드 ← 느림
5. softmax 계산
6. 결과 P를 HBM에 저장 ← 느림
7. P를 다시 HBM에서 로드 ← 느림
8. PV 계산
```

HBM 왕복이 너무 많다. 실제 계산(곱셈, 덧셈)보다 데이터 이동에 더 많은 시간이 걸린다.

## Memory-efficient Attention

Memory-efficient Attention은 xFormers 라이브러리에서 나온 최적화 구현이다. Eager의 O(N²) 메모리 문제를 해결하기 위한 첫 번째 시도 중 하나였다.

**핵심 아이디어: Chunking + Recomputation**

전체 시퀀스를 한 번에 처리하지 않고, Query를 청크(chunk) 단위로 나눠서 처리한다.

```
Eager: 전체 Q × 전체 K^T → 거대한 N×N 행렬

Memory-efficient:
Q를 청크로 분할: [Q1, Q2, Q3, ...]
각 청크마다: Qi × K^T → 작은 chunk_size × N 행렬
```

각 청크의 결과를 계산한 후 바로 출력에 반영하고, 중간 행렬은 버린다. Backward pass에서는 gradient checkpointing을 사용해서 필요할 때 다시 계산한다.

**Flash Attention과의 차이**

둘 다 O(N) 메모리를 달성하지만 접근 방식이 다르다.

- **Memory-efficient**: Query 방향으로 청크 분할. 각 청크마다 전체 K, V를 봄
- **Flash Attention**: Query와 Key 모두 블록으로 분할. Online Softmax로 블록 단위 계산

```
Memory-efficient:
Q1 × [전체 K] → softmax → × [전체 V] → 출력1
Q2 × [전체 K] → softmax → × [전체 V] → 출력2
...

Flash Attention:
[Q블록1 × K블록1] → 부분 softmax → 보정하며 누적
[Q블록1 × K블록2] → 부분 softmax → 보정하며 누적
...
```

**성능 비교**

- **메모리**: 둘 다 O(N)
- **속도**: Flash Attention이 더 빠름
  - Memory-efficient는 각 청크마다 전체 K, V를 읽어야 함 (HBM 접근 많음)
  - Flash Attention은 K, V도 블록 단위로 처리해서 HBM 접근 최소화
- **호환성**: Memory-efficient가 더 넓음
  - Flash Attention은 특정 GPU(Ampere 이상), 특정 조건 필요
  - Memory-efficient는 대부분의 환경에서 동작

따라서 Flash Attention을 쓸 수 있으면 Flash를 쓰고, 못 쓰면 Memory-efficient를 쓰는 것이 일반적인 전략이다.

## Flash Attention

Flash Attention은 Stanford의 Tri Dao가 개발한 알고리즘이다. 같은 공식(Scaled Dot-Product Attention)을 계산하지만, 구현 방식이 다르다.

핵심 아이디어는 세 가지이다.

**Tiling (타일링)**

전체 행렬을 한 번에 계산하지 않고, 작은 블록으로 나눠서 처리한다.

```
Eager 방식:
┌─────────────────┐
│                 │
│   전체 4096×4096 │  ← SRAM에 안 들어감, HBM에 저장
│                 │
└─────────────────┘

Flash Attention:
┌───┬───┬───┬───┐
│128│   │   │   │
├───┼───┼───┼───┤
│   │128│   │   │  ← 128×128씩 처리
├───┼───┼───┼───┤     (SRAM에서 처리, HBM 저장 안 함)
│   │   │128│   │
├───┼───┼───┼───┤
│   │   │   │128│
└───┴───┴───┴───┘
```

각 블록은 SRAM에 올릴 수 있는 크기다. 블록 단위로 계산하고, 중간 결과를 HBM에 저장하지 않고 바로 다음 계산에 사용한다.

**Online Softmax**

일반적인 softmax는 전체 행을 알아야 계산할 수 있다.

```
softmax([a, b, c]) = [e^a, e^b, e^c] / (e^a + e^b + e^c)
                                       ↑ 전체 합이 필요
```

블록 단위로 나눠서 계산하면, 나중에 처리할 블록 값을 아직 모르는 상태에서 softmax를 어떻게 계산할까?

Online Softmax 알고리즘은 이 문제를 해결한다. 각 블록에서 "현재까지의 최댓값"과 "현재까지의 합"을 추적하면서, 새 블록이 들어올 때마다 이전 결과를 적절히 보정한다.

```
블록 1: [2, 1] 처리 → 임시 결과와 통계 저장
블록 2: [3, 0] 처리 → 이전 결과를 보정하면서 합침
최종: softmax([2, 1, 3, 0])과 동일한 결과
```

수학적으로 정확히 같은 결과가 나온다는 것이 증명되어 있다.

**Recomputation (재계산)**

딥러닝 학습에서는 forward pass(순전파)와 backward pass(역전파)가 있다. 보통 forward에서 계산한 중간 결과를 저장해두고 backward에서 사용한다.

Flash Attention은 중간 결과(S, P 행렬)를 저장하지 않는다. 대신 backward에서 필요할 때 다시 계산한다.

```
Eager 방식:
Forward: Q, K, V → S, P 저장 → 출력
Backward: 저장된 S, P 사용

Flash Attention:
Forward: Q, K, V → (S, P 저장 안 함) → 출력
Backward: Q, K, V로 S, P 다시 계산해서 사용
```

계산을 두 번 하는 게 낭비처럼 보이지만, HBM 읽기/쓰기가 워낙 느려서 다시 계산하는 게 더 빠르다. A100 GPU 기준으로 계산 속도는 312 TFLOPS이고 메모리 대역폭은 2TB/s인데, 이 비율을 따져보면 재계산이 이득이다.

**성능 비교**

- **메모리**: O(N²) → O(N)으로 감소
- **속도**: 2~4배 빨라짐
- **정확도**: 완전히 동일 (근사가 아닌 exact computation)

## PyTorch에서의 구현 방식들

이제 실제로 코드에서 어떻게 사용하는지 살펴보자. 여기서 용어가 헷갈리기 쉬우니 주의가 필요하다.

**방법 1: Eager 구현**

공식을 직접 코드로 작성하거나, Hugging Face에서 `attn_implementation="eager"`를 사용한다.

```python
# 직접 구현
scores = torch.matmul(Q, K.transpose(-2, -1)) / math.sqrt(d)
weights = torch.softmax(scores, dim=-1)
output = torch.matmul(weights, V)
```

- 메모리: O(N²)
- 장점: 디버깅 쉬움, 커스텀 attention mask 자유로움
- 단점: 느리고 메모리 많이 씀

**방법 2: PyTorch의 `F.scaled_dot_product_attention` 함수**

PyTorch 2.0에서 도입된 함수다. 내부적으로 세 가지 백엔드 중 하나를 자동 선택한다.

```python
import torch.nn.functional as F

output = F.scaled_dot_product_attention(Q, K, V)
```

세 가지 백엔드:

- **Flash Attention 백엔드**: O(N) 메모리, 가장 빠름
  - 조건: Ampere 이상 GPU, FP16/BF16, head_dim ≤ 256 등
- **Memory-efficient 백엔드**: O(N) 메모리, Flash보다 약간 느림
  - 조건: Flash를 못 쓸 때 차선책
- **Math 백엔드**: O(N²) 메모리, 가장 느림
  - 조건: 위 둘 다 안 될 때 fallback

**중요**: Math 백엔드가 선택되면 Eager와 성능이 거의 같다. 둘 다 O(N²) 메모리를 쓰고 중간 결과를 HBM에 저장한다. "SDPA 함수를 쓰면 항상 빠르다"는 것은 오해다.

```
F.scaled_dot_product_attention 호출
    → Flash 가능? → Yes → O(N) 메모리, 빠름 ✓
                  → No  → Memory-efficient 가능? → Yes → O(N) 메모리 ✓
                                                 → No  → Math 백엔드 → O(N²), Eager와 동일 ✗
```

**방법 3: flash-attn 라이브러리 직접 사용**

Flash Attention을 확실히 사용하고 싶으면 flash-attn 라이브러리를 직접 호출한다.

```python
from flash_attn import flash_attn_func

output = flash_attn_func(q, k, v, causal=True)
```

- 메모리: 항상 O(N)
- 단점: 별도 설치 필요, GPU 호환성 확인 필요

**어떤 백엔드가 선택됐는지 확인하기**

```python
import torch

print(torch.backends.cuda.flash_sdp_enabled())  # Flash 가능?
print(torch.backends.cuda.mem_efficient_sdp_enabled())  # Memory-efficient 가능?
print(torch.backends.cuda.math_sdp_enabled())  # Math 가능? (항상 True)
```

**특정 백엔드 강제하기**

```python
with torch.backends.cuda.sdp_kernel(
    enable_flash=True, enable_math=False, enable_mem_efficient=False
):
    output = F.scaled_dot_product_attention(Q, K, V)
    # Flash를 못 쓰는 환경이면 에러 발생
```

## Hugging Face Transformers에서 사용하기

`attn_implementation` 파라미터로 선택한다.

```python
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    torch_dtype=torch.float16,
    attn_implementation="sdpa",  # 또는 "eager", "flash_attention_2"
)
```

- **"eager"**: 모델 코드에서 직접 matmul, softmax 호출. O(N²) 메모리
- **"sdpa"**: PyTorch의 `F.scaled_dot_product_attention` 사용. 백엔드 자동 선택
- **"flash_attention_2"**: flash-attn 라이브러리 직접 사용. 항상 O(N) 메모리

정리하면 이렇다.

- GPU가 Flash를 지원하면: `sdpa`든 `flash_attention_2`든 비슷한 성능
- GPU가 Flash를 지원하지 않으면: `sdpa`는 Math로 fallback → `eager`와 동일
- 확실히 최적화를 원하면: `flash_attention_2` 명시 (단, flash-attn 설치 필요)

## 정리

- **Scaled Dot-Product Attention**은 `softmax(QK^T / √d) × V` 공식이다. 이것은 "무엇을 계산할지"를 정의한다
- **Eager 구현**은 이 공식을 그대로 코드로 옮긴 것이다. N×N 중간 행렬을 메모리에 저장하므로 O(N²) 메모리가 필요하고 느리다
- **Flash Attention**은 같은 공식을 다른 방식으로 구현한 것이다. Tiling, Online Softmax, Recomputation을 사용해서 O(N) 메모리로 줄이고 속도도 2~4배 빨라진다
- **PyTorch의 `F.scaled_dot_product_attention`**은 여러 백엔드 중 하나를 자동 선택하는 함수다. Flash 백엔드가 선택되면 빠르지만, Math 백엔드로 fallback되면 Eager와 동일하다
- 확실한 최적화가 필요하면 `flash_attention_2`를 명시하거나 flash-attn 라이브러리를 직접 사용한다

---
참고

- <https://arxiv.org/abs/2205.14135>
- <https://arxiv.org/abs/1706.03762>
- <https://pytorch.org/docs/stable/generated/torch.nn.functional.scaled_dot_product_attention.html>

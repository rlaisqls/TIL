
Attention은 Transformer 아키텍처의 핵심 연산으로, 입력 시퀀스의 각 위치가 다른 모든 위치와 얼마나 관련있는지 계산한다. 시퀀스 길이 N에 대해 O(N²) 연산과 메모리가 필요해 긴 시퀀스에서 병목이 된다.

Flash Attention은 Transformer의 Attention 연산을 빠르고 메모리 효율적으로 수행하는 알고리즘이다. Stanford의 Tri Dao가 제안했으며, GPU 메모리 계층 구조를 고려한 IO-aware 접근으로 기존 Attention 대비 2~4배 빠른 속도와 메모리 사용량 감소를 달성한다.

표준 Attention 연산은 다음과 같이 수행된다.

```
S = QKᵀ        # N×N 행렬
P = softmax(S) # N×N 행렬
O = PV         # 최종 출력
```

문제는 중간 행렬 S와 P가 N×N 크기로 매우 크다는 것이다. 시퀀스 길이가 4096이면 S와 P만으로 4096² × 2 = 134MB (FP16 기준)가 필요하다.

> **HBM(High Bandwidth Memory)** 은 GPU의 메인 메모리로, 용량이 크지만(A100: 40~80GB) 상대적으로 느리다. **SRAM**은 GPU 칩 내부의 캐시 메모리로, 용량이 작지만(A100: 20MB) 매우 빠르다.

기존 구현은 S와 P를 HBM에 저장하고 다시 읽어오기 때문에 메모리 대역폭이 병목이 된다. 실제 연산(FLOP)보다 메모리 읽기/쓰기(IO)가 더 오래 걸리는 memory-bound 상황이 발생한다.

Flash Attention은 아래 세가지 방식으로 계산 속도를 개선한다.

- **Tiling**: Q, K, V를 작은 블록으로 나눠 SRAM에 올릴 수 있는 크기로 분할한다.
  - 블록 크기는 SRAM 용량에 맞춰 결정 (예: A100에서 Br=Bc=128)
  - 외부 루프에서 K, V 블록을 순회하고, 내부 루프에서 Q 블록을 처리
  - 각 블록에 대해 부분적인 Attention을 계산하고, 중간 결과 S, P를 HBM에 저장하지 않고 바로 다음 연산에 사용
  - kernel fusion: QKᵀ 계산, softmax, PV 곱셈을 하나의 GPU 커널에서 수행하여 HBM 왕복을 제거

- **Online Softmax**: 일반적인 softmax는 전체 행을 알아야 계산할 수 있다 (분모의 합계 때문).
  - 각 블록에서 local `max(m)`와 local `sum(l)`을 계산
  - 새 블록 처리 시: `m_new = max(m_old, m_current)`, `l_new = e^(m_old - m_new) × l_old + e^(m_current - m_new) × l_current`
  - 이전 출력을 rescale: `O_new = (l_old × e^(m_old - m_new) × O_old + e^(m_current - m_new) × O_current) / l_new`
  - 수치적으로 안정적인 softmax를 블록 단위로 점진적으로 계산 가능

- **Recomputation**: Forward pass에서 S, P 행렬을 저장하지 않는다.
  - Backward pass에서 gradient 계산 시 Q, K, V로부터 S, P를 다시 계산
  - 추가 연산량: O(N²d), 절약되는 메모리 IO: O(N²)
  - HBM IO가 워낙 느리기 때문에 (A100: 연산 312 TFLOPS vs 메모리 2TB/s) 재계산이 더 효율적
  - 메모리 사용량: O(N²) → O(N)으로 감소

## I/O 복잡도 분석

**표준 Attention**: O(Nd + N²) HBM 접근

- Q, K, V 읽기: O(Nd)
- S, P 쓰기/읽기: O(N²)

**Flash Attention**: O(N²d²M⁻¹) HBM 접근

- M은 SRAM 크기
- d는 head dimension (보통 64~128)

d=64, M=100KB일 때, Flash Attention은 표준 대비 약 9배 적은 HBM 접근을 달성한다.

이 복잡도가 asymptotically optimal함이 증명되었다. 즉, exact attention을 계산하면서 이보다 더 적은 HBM 접근은 불가능하다.

> **Exact Attention**: 아래에 있는 Flash Attention 2, 3도 모두 근사(approximation) 없이 **정확히 동일한 결과**를 계산한다. "asymptotically optimal"은 IO 복잡도의 이론적 하한선을 의미하며, Flash Attention 2와 3의 개선점은 IO 복잡도가 아닌 하드웨어 활용률이다. 같은 최단 경로(IO 최적)를 더 고효율로 달리는 것과 같다.
>
> **버전별 하드웨어 활용률 비교**
>
> - **Flash Attention 1**: IO 복잡도 최적, Tensor Core 활용률 25~40%
> - **Flash Attention 2**: 동일한 IO 복잡도, Tensor Core 활용률 70%
> - **Flash Attention 3**: 동일한 IO 복잡도, Tensor Core 활용률 85%

---

## Flash Attention 2

원래 Flash Attention은 이론적 최대 FLOPS의 25~40%만 달성했지만, Flash Attention 2는 개선 방식을 더 적용하여 70% 이상을 달성한다.

- **Non-matmul 연산 최소화**: softmax의 rescaling 등 non-matmul 연산을 최소화하도록 알고리즘을 재설계했다.
  - A100 기준 matmul(Tensor Core)은 312 TFLOPS, 일반 FP32 연산은 19.5 TFLOPS로 16배 차이
  - 기존: 매 블록마다 출력을 rescale → 개선: 마지막에 한 번만 rescale
  - softmax 통계(m, l)만 유지하고 최종 단계에서 diag(l)⁻¹ 적용
  - non-matmul 연산 비율을 낮춰 Tensor Core 활용률 극대화

> **matmul**은 matrix multiplication(행렬 곱셈)의 줄임말이다. Attention의 `QKᵀ`, `PV` 같은 연산이 matmul이다. GPU의 Tensor Core는 matmul에 특화되어 매우 빠르다. 반면 **non-matmul 연산**(softmax, rescaling, max 등)은 Tensor Core를 사용하지 못해 훨씬 느리다.

- **시퀀스 길이 방향 병렬화**: 기존에는 batch와 head 차원으로만 병렬화했다.
  - batch × head 수가 적으면 GPU SM(Streaming Multiprocessor)이 놀게 됨
  - Flash Attention 2는 시퀀스 길이(N) 방향으로도 thread block을 분할
  - 긴 시퀀스, 작은 batch에서 GPU 점유율(occupancy) 향상
  - Forward: Q 블록 기준 병렬화, Backward: K/V 블록 기준 병렬화

- **Warp 간 작업 분배 개선**: 기존 Flash Attention의 "sliced-K" 방식을 개선했다.
  - 기존: 4개 warp가 K를 분할 처리 → shared memory에 중간 결과 쓰기 → 동기화 → 합산
  - 개선: 4개 warp가 Q의 다른 행을 담당 (split-Q 방식)
  - shared memory 쓰기와 동기화(__syncthreads) 횟수 대폭 감소
  - warp 간 통신 오버헤드 제거로 처리량 향상

> **Warp**는 GPU에서 32개 스레드가 동시에 같은 명령을 실행하는 단위다. **Tensor Core**는 행렬 곱셈에 특화된 유닛으로 일반 연산보다 훨씬 빠르다.

---

## Flash Attention 3

Flash Attention 3는 NVIDIA Hopper GPU(H100)의 새로운 하드웨어 기능을 활용한다. H100에서 Flash Attention 2는 35% 활용률에 그쳤지만, Flash Attention 3는 85%까지 달성한다.

- **비동기 실행과 Warp Specialization**: Hopper GPU(Nvidia H100)의 비동기 하드웨어를 활용한다.
  - TMA(Tensor Memory Accelerator): Hopper의 하드웨어 유닛으로, CPU 개입 없이 global memory ↔ shared memory 전송을 처리한다.
  - WGMMA: Hopper의 새로운 Tensor Core 명령으로, 행렬 곱셈을 비동기로 실행. 이전 연산 완료를 기다리지 않고 다음 명령 발행 가능
    - Producer warp: 다음 블록의 K, V를 미리 로딩 (메모리 전송 담당)
    - Consumer warp: 현재 블록의 QKᵀ, softmax, PV 연산 수행
  - 메모리 전송과 연산이 동시에 진행되어 latency hiding 효과

- **Pingpong Scheduling**: 서로 다른 warpgroup이 번갈아가며 작업을 수행한다.
  - 문제: softmax(non-matmul)는 느리고 GEMM(Tensor Core)은 빠름 → 파이프라인 불균형
  - 해결: 2개의 warpgroup이 서로 다른 K/V 블록을 처리
  - Warpgroup 0이 softmax 계산하는 동안 Warpgroup 1은 GEMM 수행
  - Tensor Core와 일반 연산 유닛의 동시 활용으로 처리량 극대화
  - register 사용량 증가 trade-off가 있지만 성능 이득이 더 큼

- **FP8 저정밀도 지원**: 단순 FP8 변환의 정확도 손실을 보완하는 기법들을 적용했다.
  - Block quantization: 각 블록마다 별도의 scale factor 적용하여 dynamic range 확보
  - Incoherent processing: Q, K에 random orthogonal matrix를 곱해 outlier 분산
  - 수식: `Q' = QR`, `K' = KR` (R은 random rotation) → `(Q')(K')ᵀ = QRRᵀKᵀ = QKᵀ` (결과 동일)
  - 기존 FP8 attention 대비 2.6배 낮은 numerical error
  - H100에서 FP8: 1978 TFLOPS (FP16의 2배 처리량)

**성능**

- BF16: 840 TFLOPS (85% 활용률), Flash Attention 2 대비 1.5~2배
- FP8: 1.3 PFLOPS

## 사용법

**설치**

```bash
pip install flash-attn --no-build-isolation
```

> CUDA 11.6 이상, PyTorch 1.12 이상 필요. Flash Attention 3는 H100과 CUDA 12.3 이상 필요 (12.8 권장).

**PyTorch에서 사용**

```python
from flash_attn import flash_attn_func

# Q, K, V: (batch, seqlen, nheads, headdim)
output = flash_attn_func(q, k, v, causal=True)
```

**Hugging Face Transformers**

```python
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    torch_dtype=torch.float16,
    attn_implementation="flash_attention_2",  # Flash Attention 사용
)
```

**주요 파라미터**

- `causal`: True면 causal mask 적용 (decoder용)
- `softmax_scale`: attention score scaling factor (기본값: 1/√d)
- `dropout_p`: attention dropout 확률

## 제약사항

- head dimension이 8의 배수여야 함 (최대 256)
- 시퀀스 길이가 블록 크기의 배수가 아니면 padding 필요
- Ampere(A100), Ada(RTX 4090), Hopper(H100) 등 최신 GPU 필요
- FP16/BF16만 지원 (Flash Attention 3는 FP8도 지원)

---

참고

- <https://github.com/Dao-AILab/flash-attention>
- <https://tridao.me/blog/2024/flash3/>
- <https://arxiv.org/abs/2205.14135> (Flash Attention 1)
- <https://arxiv.org/abs/2307.08691> (Flash Attention 2)
- <https://arxiv.org/abs/2407.08608> (Flash Attention 3)

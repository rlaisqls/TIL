
Qwen3는 Alibaba Qwen 팀에서 2025년 5월에 공개한 LLM 시리즈다. Dense 모델 6개(0.6B~32B)와 MoE 모델 2개(30B-A3B, 235B-A22B), 총 8개 모델로 구성된다. 전 모델이 thinking(Chain-of-Thought) 모드를 기본 지원하며, 사용자가 thinking ON/OFF를 전환할 수 있는 "hybrid thinking" 설계가 특징이다. ([Qwen3 Blog](https://qwenlm.github.io/blog/qwen3/), [Technical Report](https://arxiv.org/abs/2505.09388))

## 모델

**Dense 모델**

Dense 모델은 모든 파라미터가 항상 활성화되는 일반적인 Transformer 구조다. 입력 토큰이 들어오면 모든 레이어의 모든 가중치를 거쳐 출력이 나온다. 각 레이어는 Multi-Head Attention과 Feed-Forward Network(FFN)으로 구성되며, 토큰 하나를 처리할 때 모델의 전체 파라미터가 연산에 참여한다. 따라서 파라미터 수가 곧 연산량에 비례하고, VRAM 사용량과 처리 속도가 파라미터 수에 직결된다. ([HuggingFace Qwen3 Collection](https://huggingface.co/collections/Qwen/qwen3-67dd247413f0e2e4f653967f))

- **Qwen3-0.6B**: 6억 파라미터. FP16 기준 약 1.2GB. 임베딩, 모바일, 초경량 추론 용도. 단일 CPU에서도 실시간 추론이 가능한 수준이다.
- **Qwen3-1.7B**: 17억 파라미터. FP16 기준 약 3.4GB. 경량 로컬 추론. 4GB VRAM GPU에서 서빙 가능하다.
- **Qwen3-4B**: 40억 파라미터. FP16 기준 약 8GB. 로컬 추론, 엣지 디바이스. 8GB VRAM GPU 하나로 서빙할 수 있다.
- **Qwen3-8B**: 80억 파라미터. FP16 기준 약 16GB. 단일 GPU 서빙. 16GB 이상 GPU(예: RTX 4080)에서 운용 가능하다.
- **Qwen3-14B**: 140억 파라미터. FP16 기준 약 28GB. 중간 사이즈 범용 모델. 24GB GPU에서는 양자화가 필요하고, 32GB 이상에서 FP16 서빙이 가능하다.
- **Qwen3-32B**: 320억 파라미터. FP16 기준 약 64GB. 고성능 모델로 코딩/수학에 강하다. A100 80GB 단일 GPU에서 FP16 서빙이 가능하며, 24GB GPU에서는 GPTQ-Int4로 약 18GB까지 줄여 서빙할 수 있다.

FP16에서 파라미터 하나가 2바이트를 차지하므로, 모델 크기(바이트) = 파라미터 수 × 2다. 예를 들어 32B 모델은 32 × 10⁹ × 2 = 64GB가 된다.

**MoE 모델**

MoE(Mixture of Experts)는 다수의 전문가(expert) FFN 블록을 두고, 라우터가 입력 토큰마다 일부 expert만 선택하여 활성화하는 구조다. 총 파라미터는 크지만 추론 시 활성 파라미터가 적어, Dense 대비 같은 연산량으로 더 큰 모델의 성능을 낼 수 있다. ([Technical Report §2.1](https://arxiv.org/abs/2505.09388))

- **Qwen3-30B-A3B**: 총 310억 파라미터 중 30억 활성. 128개 expert 중 8개 활성. 경량 MoE로 엣지/모바일에 적합하다. Dense 3B 모델과 비슷한 연산량이면서 30B급 지식을 갖는다.
- **Qwen3-235B-A22B**: 총 2350억 파라미터 중 220억 활성. 128개 expert 중 8개 활성. 플래그십 모델이다. Dense 22B 수준의 연산량으로 235B급 성능을 낸다.

MoE의 핵심은 라우터(router) 메커니즘이다. Qwen3 MoE는 각 Transformer 레이어의 FFN 위치에 128개의 독립적인 expert FFN과 1개의 게이트 네트워크(라우터)를 배치한다. 라우터는 입력 hidden state를 받아 128차원 로짓을 출력하고, 이 중 top-8을 선택하여 softmax로 가중치를 계산한다.

```
# 라우터 동작 (의사 코드)
router_logits = Linear(hidden_state)          # shape: [batch, seq_len, 128]
topk_weights, topk_indices = topk(router_logits, k=8)
topk_weights = softmax(topk_weights)          # 선택된 8개에 대한 가중치 정규화

output = sum(topk_weights[i] * expert[topk_indices[i]](hidden_state) for i in range(8))
```

이 구조가 효율적인 이유는 다음과 같다:

1. **연산 효율**: 토큰 하나를 처리할 때 128개 expert 중 8개만 실행하므로, FFN의 연산량이 8/128 = 6.25%로 줄어든다. Attention 레이어는 모든 토큰에 대해 동일하게 실행되므로, 전체 연산량 감소는 FFN 비중에 비례한다. Transformer에서 FFN이 전체 연산의 약 2/3를 차지하므로, 대략 전체 연산의 60% 이상이 절약된다.

2. **메모리 비효율**: 반면 128개 expert의 가중치를 전부 GPU 메모리에 올려두어야 하므로, 활성 파라미터는 22B지만 VRAM은 235B 전체에 대해 필요하다. Qwen3-235B-A22B의 FP16 모델 크기가 약 470GB인 이유다.

3. **낮은 GPU Utilization**: 매 토큰마다 128개 expert 중 8개만 사용하므로, 대부분의 가중치가 메모리에 있지만 연산에 참여하지 않는다. 단일 요청 기준 GPU compute utilization이 35~40% 수준으로 낮다. 이는 배치 크기를 키워 서로 다른 요청이 서로 다른 expert를 사용하게 하면 개선된다.

4. **로드 밸런싱**: 특정 expert에 토큰이 몰리면 처리 지연이 발생하고, 반대로 안 쓰이는 expert는 낭비된다. Qwen3는 학습 시 auxiliary load balancing loss를 적용하여 expert 사용률을 균등화한다. ([Technical Report §2.1](https://arxiv.org/abs/2505.09388)) 이 loss는 각 expert의 토큰 할당 비율이 균일하도록 유도하는 정규화 항으로, expert capacity가 균등해지면 multi-GPU 환경에서 expert parallelism의 효율도 높아진다. 이 기법은 Google의 Switch Transformer에서 처음 제안되었다. ([Switch Transformers](https://arxiv.org/abs/2101.03961))

## 변형(Variant)

**학습 단계별**

- **Base**: 사전학습(pretraining)만 완료된 모델. 텍스트 이어쓰기(completion)만 가능하며, 대화나 지시 수행은 불가능하다. fine-tuning의 출발점으로 사용한다.
- **기본 (접미사 없음)**: Instruct 튜닝이 완료된 모델. SFT(Supervised Fine-Tuning) + RLHF(Reinforcement Learning from Human Feedback)를 거쳐 사용자 지시를 따르도록 학습된 상태다. thinking 모드를 ON/OFF할 수 있는 hybrid thinking을 지원한다.

**2507 업데이트 (2025년 7월)**

- **Thinking-2507**: thinking(추론 과정 출력) 능력을 추가 강화한 버전. 복잡한 수학, 코딩, 논리 문제에서 더 정교한 reasoning을 수행한다. 추가 RLHF를 통해 thinking 토큰의 품질을 높인 것이 핵심이다. ([Model Card](https://huggingface.co/Qwen/Qwen3-235B-A22B-Thinking-2507))
- **Instruct-2507**: thinking 없이 바로 답변하는 것에 최적화된 버전. thinking 오버헤드 없이 빠른 응답이 필요한 서빙 환경에 적합하다. non-thinking 모드에서의 응답 품질을 별도로 최적화했다. ([Model Card](https://huggingface.co/Qwen/Qwen3-235B-A22B-Instruct-2507))

## 양자화 포맷

양자화(quantization)는 모델의 가중치를 낮은 정밀도로 변환하여 모델 크기를 줄이는 기법이다. 핵심 아이디어는 "대부분의 가중치가 좁은 범위에 분포하므로, 전체 표현 범위를 줄여도 정보 손실이 적다"는 것이다.

FP16(16비트 부동소수점)에서 파라미터 하나가 2바이트를 차지한다면, INT4(4비트 정수)로 양자화하면 0.5바이트로 줄어든다. 다만 양자화된 가중치를 복원하기 위한 scale, zero-point 등의 메타데이터가 추가되므로, 실제 압축률은 이론적 4배보다 약간 낮다.

**FP8**

FP8(8비트 부동소수점)은 IEEE 754 확장 포맷으로, 두 가지 변형이 있다. ([FP8 Formats for Deep Learning](https://arxiv.org/abs/2209.05433))

- **E4M3**: 지수(exponent) 4비트, 가수(mantissa) 3비트. 표현 가능한 동적 범위가 넓어 가중치 저장에 적합하다. ±240 범위를 표현할 수 있다.
- **E5M2**: 지수 5비트, 가수 2비트. 더 넓은 범위를 표현하지만 정밀도가 낮다. 주로 gradient 저장에 사용된다.

LLM 양자화에서는 E4M3이 표준이다. FP16 대비 크기가 정확히 50%이며, 부동소수점 형식을 유지하므로 정수 양자화와 달리 dequantize 없이 바로 연산이 가능하다. NVIDIA H100의 FP8 Tensor Core가 이를 하드웨어 수준에서 지원하므로, H100 이상에서는 FP8이 가장 효율적인 선택지다. ([H100 Datasheet](https://www.nvidia.com/en-us/data-center/h100/))

- 서빙 프레임워크: vLLM, TGI, SGLang
- 크기: 원본의 약 50%
- 품질: FP16 대비 거의 동일 (perplexity 차이 0.1% 미만)
- 하드웨어 요구: NVIDIA Ada Lovelace(RTX 4090) 이상, 최적 성능은 Hopper(H100) 이상

**GPTQ**

GPTQ(GPT Quantization)는 캘리브레이션 기반 post-training quantization 기법이다. ([GPTQ 논문](https://arxiv.org/abs/2210.17323)) 소량의 캘리브레이션 데이터(보통 128~256 샘플)를 모델에 통과시켜, 각 레이어의 가중치 분포와 활성화 패턴을 분석한 뒤 최적의 양자화 파라미터를 결정한다.

GPTQ의 핵심 알고리즘은 OBS(Optimal Brain Surgeon)에서 유래했다. 가중치를 하나씩 양자화할 때, 양자화로 인한 출력 오차를 나머지 가중치를 보정하여 보상한다. 이때 Hessian 행렬(가중치에 대한 loss의 2차 미분)의 역행렬을 활용하여, 어떤 가중치가 출력에 더 큰 영향을 미치는지 판단하고 보정량을 결정한다. 이 과정을 레이어별로 순차적으로 수행한다.

양자화된 가중치는 group 단위로 scale과 zero-point를 저장한다. group_size가 128이면, 128개의 가중치마다 FP16 scale 1개와 zero-point 1개를 공유한다. group_size가 작을수록 양자화 정밀도가 높아지지만 메타데이터 오버헤드가 커진다.

```
# GPTQ 복원 과정
dequantized_weight = scale × (quantized_weight - zero_point)
# group_size=128, INT4 기준:
# 128개 가중치(64바이트) + scale(2바이트) + zero_point(2바이트) = 68바이트
# FP16 대비: 68/256 ≈ 26.6% (약 3.8배 압축)
```

- 서빙 프레임워크: vLLM, TGI, SGLang (단, vLLM은 GPTQ+MoE 조합 미지원)
- 양자화 레벨: Int4, Int8 + group size (32, 64, 128)
- GPU 전용: dequantize 과정이 CUDA 커널에서 수행되어야 효율적이므로 GPU 필수
- 커널: vLLM에서는 [Marlin](https://github.com/IST-DASLab/marlin) 커널을 사용하여, dequantize와 행렬 곱셈을 하나의 커널에서 fused 연산하므로 FP16에 근접하는 추론 속도를 달성한다

**AWQ**

AWQ(Activation-Aware Weight Quantization)는 "모든 가중치가 동등하게 중요하지 않다"는 관찰에 기반한다. ([AWQ 논문](https://arxiv.org/abs/2306.00978)) 활성화(activation)의 크기가 큰 채널에 연결된 가중치가 출력에 더 큰 영향을 미치므로, 이러한 가중치를 보호하는 전략을 사용한다.

구체적으로, 양자화 전에 각 가중치 채널의 중요도를 활성화 크기로 측정한다. 중요도가 높은 채널의 가중치는 scale을 조정하여 양자화 오차를 줄인다. GPTQ처럼 Hessian 역행렬 계산이 필요 없으므로 양자화 속도가 빠르고, 추론 시에도 동일한 INT4 커널을 사용하므로 GPTQ와 속도가 비슷하거나 약간 빠르다.

- 서빙 프레임워크: vLLM, TGI, SGLang
- 양자화 레벨: 4bit + group size (32, 64, 128)
- GPU 전용
- GPTQ 대비 양자화 시간이 짧고, 품질은 비슷하거나 약간 우수하다

**[GGUF](https://github.com/ggerganov/ggml/blob/master/docs/gguf.md)**

GGUF는 llama.cpp 전용 모델 파일 포맷이자 양자화 체계다. ([GGUF 스펙](https://github.com/ggerganov/ggml/blob/master/docs/gguf.md)) 가중치, 토크나이저, 모델 설정을 단일 파일에 담으며, CPU/GPU 모두에서 실행 가능하다. 양자화 레벨이 가장 다양한데, llama.cpp가 CPU/저사양 환경부터 고성능 GPU까지 넓은 범위를 타겟으로 하기 때문이다.

타입 이름의 규칙은 `Q{비트수}_{방식}`이다. K-quant 계열은 super-block 구조를 사용하여 가중치 중요도에 따라 비트를 차등 할당한다:

- **Q2_K**: 2비트. 매우 높은 압축률(FP16 대비 약 87% 감소)이지만 정확도 손실이 크다. 극단적인 VRAM 제약 환경에서만 사용한다.
- **Q3_K_S / Q3_K_M / Q3_K_L**: 3비트의 Small/Medium/Large 변형. L로 갈수록 일부 레이어에 더 높은 비트를 사용하여 정확도를 높인다.
- **Q4_K_S / Q4_K_M**: 4비트. K-quant의 super-block 구조에서, 256개 가중치로 이루어진 super-block 안에 32개씩의 sub-block을 두고, sub-block마다 별도의 scale을 저장한다. M이 S보다 약간 크지만 attention 레이어에 6비트를 할당하여 정확도가 더 높다. **Q4_K_M이 크기 대비 정확도 균형이 가장 좋아 가장 널리 사용된다.**
- **Q5_K_S / Q5_K_M**: 5비트. 4비트 대비 파일 크기가 약 25% 증가하지만 정확도가 눈에 띄게 개선된다.
- **Q6_K**: 6비트. FP16 대비 거의 손실이 없는 수준의 정확도를 제공한다.
- **Q8_0**: 8비트 양자화. 블록당 scale만 저장하는 단순한 방식이다. 정확도가 높지만 압축률이 낮다.

- 서빙 프레임워크: llama.cpp, ollama
- CPU/GPU 모두 지원. mmap 기반 로딩으로 물리 메모리보다 큰 모델도 로드 가능하다 (접근 시 page fault로 I/O 발생).

**MLX**

MLX는 Apple이 만든 Apple Silicon(M1~M4) 전용 프레임워크다. ([MLX](https://github.com/ml-explore/mlx)) Apple Silicon의 unified memory 아키텍처를 활용하여, CPU와 GPU가 동일한 메모리 공간을 공유하므로 메모리 복사 오버헤드가 없다.

- 양자화 레벨: 4bit, 6bit, 8bit, bf16
- Apple Silicon 전용. Metal GPU 셰이더를 사용하여 연산한다.
- M4 Max (128GB 통합 메모리) 같은 고사양 Mac에서 상당히 큰 모델도 로컬 추론이 가능하다.

양자화 포맷 선택은 서빙 환경에 따라 결정된다. NVIDIA GPU 서버에서 vLLM으로 서빙한다면 H100 이상에서는 FP8이, 이전 세대에서는 GPTQ/AWQ가 적합하다. GPU 수가 부족하여 VRAM이 빡빡한 환경에서는 GGUF + llama.cpp를, Mac에서는 MLX를 사용한다.

## 서빙 프레임워크

LLM 서빙 프레임워크는 모델을 GPU에 올리고 HTTP API로 추론 요청을 처리하는 시스템이다. 단순히 모델을 로드하는 것 이상으로, 동시 요청의 효율적 처리, 메모리 관리, 양자화 커널 지원이 핵심이다.

**vLLM**

버클리 대학에서 시작된 프로젝트로, 현재 GPU LLM 서빙의 사실상 표준이다. ([vLLM](https://github.com/vllm-project/vllm), [PagedAttention 논문](https://arxiv.org/abs/2309.06180)) 핵심 기술 두 가지:

- **PagedAttention**: 운영체제의 가상 메모리 페이징에서 영감을 받은 KV cache 관리 기법이다. 기존 프레임워크는 요청마다 최대 시퀀스 길이에 해당하는 KV cache를 연속 메모리로 사전 할당했다. 예를 들어 max_seq_len=4096이면 실제 생성이 100 토큰만 되어도 4096 토큰분의 메모리를 점유한다. PagedAttention은 KV cache를 고정 크기 블록(기본 16 토큰)으로 나누어 비연속 메모리에 저장하고, 블록 테이블로 논리적 연속성을 유지한다. 이로써 메모리 낭비를 거의 없애고, 같은 VRAM으로 더 많은 동시 요청을 처리할 수 있다.

- **Continuous Batching**: 기존 static batching은 배치 내 모든 요청이 끝날 때까지 기다린 뒤 다음 배치를 처리했다. 짧은 요청이 긴 요청을 기다리느라 GPU가 놀게 된다. Continuous batching은 매 iteration(1 토큰 생성)마다 완료된 요청을 빼고 새 요청을 넣어, GPU utilization을 극대화한다.

지원 양자화: safetensors(FP16/BF16), FP8, GPTQ, AWQ. Tensor Parallelism(`--tp`)으로 멀티 GPU 분산 서빙을 지원한다.

**SGLang**

vLLM 대안으로 부상 중인 프레임워크다. ([SGLang](https://github.com/sgl-project/sglang), [SGLang 논문](https://arxiv.org/abs/2312.07104)) vLLM과 유사한 PagedAttention + continuous batching을 구현하되, RadixAttention이라는 추가 최적화를 제공한다. RadixAttention은 이전 요청의 KV cache를 radix tree 자료구조에 캐싱하여, 동일한 prefix를 공유하는 후속 요청이 해당 prefix의 KV cache를 재사용할 수 있게 한다. 예를 들어 같은 system prompt를 사용하는 요청이 반복되면, system prompt 부분의 KV cache 계산을 건너뛴다.

Qwen3-235B GPTQ-Int4를 공식 지원하며, vLLM이 GPTQ+MoE를 미지원하는 시점에서 GPTQ 양자화된 대형 MoE 모델의 유일한 고처리량 서빙 옵션이다.

**llama.cpp**

C++ 기반 경량 추론 엔진으로, GGUF 포맷 전용이다. CPU/GPU 모두 지원하며, 적은 GPU로 큰 모델을 돌릴 수 있다. vLLM/SGLang 대비 처리량은 낮지만, 메모리 관리 측면에서 독특한 장점이 있다.

- **mmap 기반 로딩**: 모델 파일을 가상 메모리에 매핑하여, 실제 접근하는 페이지만 물리 메모리에 올린다. mmap 시스템 콜 자체는 즉시 반환되고, 실제 I/O는 page fault 시점에 발생한다. GGUF의 텐서 데이터가 64바이트 정렬되는 이유도 mmap 페이지 경계와 맞추기 위함이다.
- **유연한 메모리 사용**: KV cache를 사전 할당하지 않고 필요한 만큼 동적으로 할당한다. vLLM처럼 대량의 KV cache 공간을 미리 확보할 필요가 없어, VRAM이 빡빡한 환경에서도 동작한다.
- **GPU 분할 모드**: `--split-mode row`로 MoE expert를 GPU 간 균등 분할할 수 있다. 이를 통해 2장의 GPU로도 대형 MoE 모델을 서빙할 수 있다.

([llama.cpp](https://github.com/ggml-org/llama.cpp))

**TGI (Text Generation Inference)**

HuggingFace의 서빙 프레임워크다. 2025년 12월부터 maintenance mode에 진입하여, 새로운 기능 개발이 중단되고 vLLM/SGLang 전환이 권장된다. 기존에 TGI를 사용하던 HuggingFace Inference Endpoints도 vLLM 백엔드로 전환 중이다. ([TGI Docs](https://huggingface.co/docs/inference-endpoints/en/engines/tgi))

**MLX**

Apple이 만든 Apple Silicon(M1~M4) 전용 프레임워크다. ([MLX](https://github.com/ml-explore/mlx)) Metal GPU와 unified memory를 활용한다. 서버 서빙보다는 로컬 추론/개발 용도에 적합하다.

## VRAM 요구량과 프레임워크 선택

모델을 서빙하려면 가중치 전체를 GPU 메모리에 올려야 한다. 그러나 모델 가중치만으로는 부족하고, 추론 과정에서 추가 메모리가 필요하다:

- **모델 가중치**: 양자화 포맷에 따른 고정 크기
- **KV cache**: 동시 처리 중인 모든 요청의 key/value 텐서. 요청 수 × 시퀀스 길이에 비례한다. 이것이 가장 가변적이고 큰 부분이다.
- **Activation memory**: forward pass 중간 결과. 배치 크기에 비례한다.
- **CUDA context**: GPU 드라이버와 CUDA 런타임이 차지하는 고정 오버헤드. GPU당 약 500MB~1GB.

따라서 실제 필요 VRAM은 "모델 크기 + KV cache + activation + CUDA context"다. 모델 크기 대비 10~20% 이상의 여유가 필요하고, 높은 동시 처리를 원하면 KV cache 공간을 더 확보해야 한다.

**Qwen3-235B-A22B 포맷별 크기**

- **FP16**: 모델 약 470GB. 필요 VRAM 약 490GB 이상. H100 80GB 기준 7장 이상 필요.
- **FP8 (E4M3)**: 모델 약 235GB. 필요 VRAM 약 255GB 이상. H100 80GB 기준 4장.
- **GPTQ-Int4**: 모델 약 120GB. 필요 VRAM 약 140GB 이상. H100 80GB 기준 최소 4장 (아래 설명 참조).
- **GGUF Q4_K_M**: 모델 약 133GB. 필요 VRAM 약 140GB. H100 80GB 기준 2장 가능.

GPTQ-Int4가 GGUF Q4_K_M보다 파일 크기가 작은데(120GB vs 133GB) 더 많은 GPU가 필요한 이유는, 사용하는 서빙 프레임워크의 메모리 관리 방식 차이 때문이다. vLLM/SGLang은 KV cache를 사전 할당하여 대량의 추가 VRAM을 요구하고, llama.cpp는 동적 할당으로 필요한 만큼만 사용한다.

**H100 2장으로 Qwen3-235B-A22B를 서빙할 수 있는가?**

- **vLLM + FP8**: 불가능. 모델만 약 235GB로 2장(160GB)에 들어가지 않는다.
- **vLLM + GPTQ-Int4**: 불가능. GPTQ+MoE 조합이 미구현이다. fused Marlin MoE 모듈에서 `NotImplementedError`가 발생한다. ([vllm#22906](https://github.com/vllm-project/vllm/issues/22906))
- **SGLang + GPTQ-Int4**: 불가능. 공식 최소 구성이 `--tp 4`다. ([GPTQ-Int4 Model Card](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4)) 모델 120GB를 2장에 올리면 GPU당 여유가 약 20GB인데, SGLang의 KV cache 사전 할당 + activation 버퍼 + CUDA context를 감당하기에 부족하다.
- **TGI**: 불가능. maintenance mode로 Qwen3 MoE를 지원하지 않는다.
- **llama.cpp + GGUF Q4_K_M**: 가능. 133GB 모델을 2장(160GB)에 적재하고, `--split-mode row`로 MoE expert를 GPU 간 균등 분할한다. KV cache 동적 할당으로 남은 약 27GB를 유연하게 사용한다.

llama.cpp가 유일하게 가능한 이유를 정리하면:

1. mmap 기반 로딩으로 메모리를 유연하게 사용한다
2. KV cache를 사전 할당하지 않아 모델 적재 후 남은 공간을 전부 활용할 수 있다
3. `--split-mode row`가 MoE expert를 GPU 간 분할하는 것을 지원한다

GPU가 4장 이상이라면 SGLang/vLLM + GPTQ-Int4 또는 FP8 조합이 처리량 면에서 훨씬 유리하다. vLLM의 continuous batching + PagedAttention은 다수의 동시 요청을 처리할 때 llama.cpp 대비 2~5배 높은 처리량을 보인다. llama.cpp는 GPU 자원이 제한된 환경에서의 "돌아가게 하기" 옵션으로 이해하면 된다.

## Hybrid Thinking

Qwen3의 특징적인 기능으로, 하나의 모델에서 thinking 모드를 ON/OFF 전환할 수 있다.

- **Thinking ON**: `<think>...</think>` 태그 안에 추론 과정을 출력한 뒤 최종 답변을 생성한다. 복잡한 문제에서 정확도가 높아지지만 토큰 소모가 크다. Chain-of-Thought 추론을 수행하므로, 수학 문제에서 풀이 과정을 단계별로 전개하거나, 코딩 문제에서 접근 방식을 탐색한 뒤 코드를 작성한다.
- **Thinking OFF**: 추론 과정 없이 바로 답변한다. 간단한 질문이나 빠른 응답이 필요할 때 사용한다. thinking 토큰이 생성되지 않으므로 latency와 비용이 낮다.

OpenAI 호환 API에서는 응답의 `reasoning_content` 필드에 thinking 내용이, `content` 필드에 최종 답변이 분리되어 반환된다.

```json
{
  "message": {
    "role": "assistant",
    "content": "Hello! How can I assist you today?",
    "reasoning_content": "The user said hello. I should respond politely..."
  }
}
```

system prompt에 `/no_think`를 포함하면 thinking을 비활성화할 수 있고, `/think`를 포함하면 명시적으로 활성화한다. 이는 vLLM, SGLang의 OpenAI 호환 API에서도 동일하게 작동한다. thinking 모드의 ON/OFF가 추가 모델 로딩이나 설정 변경 없이 프롬프트 수준에서 전환되므로, 요청별로 thinking 사용 여부를 다르게 할 수 있다. ([Qwen3 Blog — Thinking Mode](https://qwenlm.github.io/blog/qwen3/#thinking-mode))

---
참고

- <https://huggingface.co/collections/Qwen/qwen3-67dd247413f0e2e4f653967f> — Qwen3 HuggingFace Collection
- <https://qwenlm.github.io/blog/qwen3/> — Qwen3 공식 블로그
- <https://arxiv.org/abs/2505.09388> — Qwen3 Technical Report
- <https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4> — GPTQ-Int4 모델 카드 (SGLang/vLLM `--tp 4` 안내)
- <https://huggingface.co/Qwen/Qwen3-235B-A22B/discussions/43> — vLLM 최소 하드웨어 관련 논의
- <https://github.com/vllm-project/vllm/issues/22906> — vLLM + GPTQ MoE 미지원 이슈
- <https://huggingface.co/docs/inference-endpoints/en/engines/tgi> — TGI maintenance mode 안내
- <https://arxiv.org/abs/2210.17323> — GPTQ: Accurate Post-Training Quantization for Generative Pre-trained Transformers
- <https://arxiv.org/abs/2306.00978> — AWQ: Activation-aware Weight Quantization
- <https://arxiv.org/abs/2309.06180> — Efficient Memory Management for Large Language Model Serving with PagedAttention
- <https://arxiv.org/abs/2209.05433> — FP8 Formats for Deep Learning
- <https://arxiv.org/abs/2101.03961> — Switch Transformers (MoE load balancing loss)
- <https://arxiv.org/abs/2312.07104> — SGLang: Efficient Execution of Structured Language Model Programs
- <https://github.com/ggerganov/ggml/blob/master/docs/gguf.md> — GGUF 포맷 스펙
- <https://github.com/IST-DASLab/marlin> — Marlin CUDA 커널
- <https://github.com/ml-explore/mlx> — Apple MLX 프레임워크

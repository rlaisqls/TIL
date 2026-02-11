
Qwen3는 Alibaba Qwen 팀에서 2025년 5월에 공개한 LLM 시리즈다. Dense 모델 6개(0.6B~32B)와 MoE 모델 2개(30B-A3B, 235B-A22B), 총 8개 모델로 구성된다. 전 모델이 thinking(Chain-of-Thought) 모드를 기본 지원하며, 사용자가 thinking ON/OFF를 전환할 수 있는 "hybrid thinking" 설계가 특징이다. ([Qwen3 Blog](https://qwenlm.github.io/blog/qwen3/), [Technical Report](https://arxiv.org/abs/2505.09388))

## 모델

### Dense 모델

Dense 모델은 모든 파라미터가 항상 활성화되는 일반적인 Transformer 구조다. 입력이 들어오면 모든 가중치를 거쳐 출력이 나온다.

| 모델 | 파라미터 | 용도 |
|------|---------|------|
| Qwen3-0.6B | 6억 | 임베딩, 모바일, 초경량 추론 |
| Qwen3-1.7B | 17억 | 경량 로컬 추론 |
| Qwen3-4B | 40억 | 로컬 추론, 엣지 디바이스 |
| Qwen3-8B | 80억 | 단일 GPU 서빙 |
| Qwen3-14B | 150억 | 중간 사이즈, 범용 |
| Qwen3-32B | 330억 | 고성능, 코딩/수학에 강함 |

### MoE 모델

MoE(Mixture of Experts)는 다수의 전문가(expert) FFN 블록을 두고, 라우터가 입력 토큰마다 일부 expert만 선택하여 활성화하는 구조다. 총 파라미터는 크지만 추론 시 활성 파라미터가 적어, Dense 대비 같은 연산량으로 더 큰 모델의 성능을 낼 수 있다. ([Technical Report §2.1](https://arxiv.org/abs/2505.09388))

| 모델 | 총 파라미터 | 활성 파라미터 | Expert 구성 | 용도 |
|------|-----------|-------------|------------|------|
| Qwen3-30B-A3B | 310억 | 30억 | 128 expert 중 8개 활성 | 경량 MoE, 엣지/모바일 |
| Qwen3-235B-A22B | 2350억 | 220억 | 128 expert 중 8개 활성 | 플래그십 모델 |

Qwen3-235B-A22B의 경우 총 파라미터가 2350억이지만, 토큰 하나를 처리할 때 실제로 연산에 참여하는 파라미터는 220억개뿐이다. 나머지 expert들은 GPU 메모리에 상주하지만 연산에는 참여하지 않는다. 이 때문에:

- 220억 파라미터만 활성화되므로, 단일 요청 기준 GPU utilization이 낮다 (35~40% 수준)
- 전체 2350억 파라미터를 올려야 하므로 VRAM을 많이 차지한다

## 변형(Variant)

### 학습 단계별

- Base: 사전학습(pretraining)만 완료된 모델. 텍스트 이어쓰기(completion)만 가능하며, 대화나 지시 수행은 불가능하다. fine-tuning의 출발점으로 사용한다.
- 기본 (접미사 없음): Instruct 튜닝이 완료된 모델. thinking 모드를 ON/OFF할 수 있는 hybrid thinking을 지원한다. 일반적인 사용 목적의 기본 선택지다.

### 2507 업데이트 (2025년 7월)

- Thinking-2507: thinking(추론 과정 출력) 능력을 추가 강화한 버전. 복잡한 수학, 코딩, 논리 문제에서 더 정교한 reasoning을 수행한다. ([Model Card](https://huggingface.co/Qwen/Qwen3-235B-A22B-Thinking-2507))
- Instruct-2507: thinking 없이 바로 답변하는 것에 최적화된 버전. thinking 오버헤드 없이 빠른 응답이 필요한 서빙 환경에 적합하다. ([Model Card](https://huggingface.co/Qwen/Qwen3-235B-A22B-Instruct-2507))

### 양자화 포맷별

양자화는 모델의 가중치를 낮은 정밀도로 변환하여 크기를 줄이는 기법이다. 포맷마다 지원하는 양자화 레벨이 다르다.

| 포맷 | 서빙 프레임워크 | 양자화 레벨 | 설명 |
|------|--------------|-----------|------|
| FP8 | vLLM, TGI | E4M3 (사실상 1가지) | 8bit 부동소수점. 원본 대비 ~50% 크기, 품질 거의 동일 |
| GPTQ | vLLM, TGI | Int4, Int8 + group size (32, 64, 128) | 캘리브레이션 기반 정수 양자화. group size가 작을수록 정확도↑ 크기↑. GPU 전용 |
| AWQ | vLLM, TGI | 4bit + group size (32, 64, 128) | Activation-aware 양자화. GPTQ와 유사하나 속도가 약간 빠름. GPU 전용 |
| [GGUF](https://github.com/ggerganov/ggml/blob/master/docs/gguf.md) | llama.cpp, ollama | Q2_K, Q3_K_S/M/L, Q4_K_S/M, Q5_K_S/M, Q6_K, Q8_0 | llama.cpp 전용 파일 포맷. 선택지가 가장 많다. CPU/GPU 모두 지원 |
| MLX | MLX (Apple) | 4bit, 6bit, 8bit, bf16 | Apple Silicon(M1~M4) 최적화 |

GGUF가 양자화 레벨이 가장 다양한 이유는, llama.cpp가 CPU/저사양 환경부터 고성능 GPU까지 넓은 범위를 타겟으로 하기 때문이다. 다른 포맷들은 GPU 서빙 전용이라 선택지가 적다.

양자화 포맷 선택은 서빙 환경에 따라 결정된다. GPU 서버에서 vLLM으로 서빙한다면 FP8이나 GPTQ를, 로컬이나 VRAM이 부족한 환경에서는 GGUF를, Mac에서는 MLX를 사용한다.

## 서빙 프레임워크

- **vLLM** — GPU 서빙 표준. continuous batching + PagedAttention으로 동시 요청 처리량이 높다. safetensors/GPTQ/AWQ/FP8 지원. ([vLLM](https://github.com/vllm-project/vllm))
- **SGLang** — vLLM 대안으로 부상 중인 프레임워크. Qwen3-235B GPTQ-Int4를 공식 지원하며, 성능이 vLLM과 비슷하거나 일부 상회한다. ([SGLang](https://github.com/sgl-project/sglang))
- **llama.cpp** — C++ 기반 경량 추론 엔진. GGUF 포맷 전용. CPU/GPU 모두 지원하며, 적은 GPU로 큰 모델을 돌릴 수 있다. KV cache를 사전 할당하지 않고 mmap 기반으로 유연하게 메모리를 사용하기 때문에, VRAM이 빡빡한 환경에서도 동작한다. 처리량은 vLLM 대비 낮다. ([llama.cpp](https://github.com/ggml-org/llama.cpp))
- **TGI** (Text Generation Inference) — HuggingFace의 서빙 프레임워크. 2025년 12월부터 maintenance mode에 진입하여 vLLM/SGLang 전환이 권장된다. ([TGI Docs](https://huggingface.co/docs/inference-endpoints/en/engines/tgi))
- **MLX** — Apple이 만든 Apple Silicon(M1~M4) 전용 프레임워크.

## VRAM 요구량과 프레임워크 선택

모델을 서빙하려면 모든 파라미터를 GPU 메모리에 올려야 한다. 포맷에 따른 대략적인 크기 테스트 결과는 아래와 같다.

### Qwen3-235B-A22B

| 포맷 | 모델 크기 | 필요 VRAM | H100 80GB 기준 |
|------|----------|----------|---------------|
| FP16 | ~470GB | ~490GB+ | 7장 이상 |
| FP8 | ~235GB | ~255GB+ | 4장 |
| GPTQ-Int4 | ~120GB | ~140GB+ | 4장 |
| GGUF Q4_K_M | ~133GB | ~140GB | 2장 |

> 실제 VRAM은 모델 가중치 외에 KV cache, activation, CUDA context 등 추가 메모리가 필요하므로 모델 크기보다 더 많이 소요된다.

GPTQ-Int4(~120GB)면 H100 2장(160GB)에 이론상 들어갈 것 같지만, vLLM/SGLang 모두 공식 예시에서 `--tp 4` (4 GPU)를 기준으로 안내한다. ([GPTQ-Int4 Model Card](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4)) 2장으로 안 되는 이유:

1. **vLLM은 GPTQ + MoE 조합을 아직 지원하지 않는다.** GPTQ로 양자화된 MoE 모델의 expert routing 과정에서 `NotImplementedError`가 발생한다 (fused Marlin MoE 모듈 미구현). ([vllm#22906](https://github.com/vllm-project/vllm/issues/22906))
2. **SGLang은 GPTQ+MoE를 지원하지만 최소 4장이 필요하다.** 모델 120GB를 2장에 올리면 GPU당 여유가 ~20GB인데, KV cache와 activation을 위한 공간이 부족하다.
3. **공식 권장은 4~8 GPU이다.** Qwen 팀은 GPTQ-Int4 기준 `--tp 4`, FP16/FP8 기준 `--tp 8`을 안내한다. ([HF Discussion](https://huggingface.co/Qwen/Qwen3-235B-A22B/discussions/43))

### H100 2장으로 Qwen3-235B-A22B를 서빙할 수 있는가?

| 프레임워크 + 포맷 | 가능 여부 | 이유 |
|-----------------|----------|------|
| vLLM + FP8 | X | 모델만 ~235GB, 2장(160GB)에 안 들어감 |
| vLLM + GPTQ-Int4 | X | GPTQ+MoE 미구현 (NotImplementedError) |
| SGLang + GPTQ-Int4 | X | 공식 최소 `--tp 4`, KV cache 공간 부족 |
| TGI | X | maintenance mode, Qwen3 MoE 미지원 |
| llama.cpp + GGUF Q4_K_M | O | 133GB → 2장에 적재 가능 |

llama.cpp가 유일하게 가능한 이유는, KV cache를 사전 할당하지 않고 mmap 기반으로 메모리를 유연하게 사용하며, `--split-mode row`로 MoE expert를 GPU간 균등 분할하기 때문이다. GPU가 4장 이상이라면 SGLang/vLLM + GPTQ-Int4 또는 FP8 조합이 처리량 면에서 더 유리하다.

## Hybrid Thinking

Qwen3의 특징적인 기능으로, 하나의 모델에서 thinking 모드를 ON/OFF 전환할 수 있다.

- **Thinking ON**: `<think>...</think>` 태그 안에 추론 과정을 출력한 뒤 최종 답변을 생성한다. 복잡한 문제에서 정확도가 높아지지만 토큰 소모가 크다.
- **Thinking OFF**: 추론 과정 없이 바로 답변한다. 간단한 질문이나 빠른 응답이 필요할 때 사용한다.

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

system prompt에 `/no_think`를 포함하면 thinking을 비활성화할 수 있고, `/think`를 포함하면 명시적으로 활성화한다. ([Qwen3 Blog — Thinking Mode](https://qwenlm.github.io/blog/qwen3/#thinking-mode))

---
참고

- <https://huggingface.co/collections/Qwen/qwen3-67dd247413f0e2e4f653967f>
- <https://qwenlm.github.io/blog/qwen3/>
- <https://arxiv.org/abs/2505.09388>
- <https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4> — GPTQ-Int4 모델 카드 (SGLang/vLLM `--tp 4` 안내)
- <https://huggingface.co/Qwen/Qwen3-235B-A22B/discussions/43> — vLLM 최소 하드웨어 관련 논의
- <https://github.com/vllm-project/vllm/issues/22906> — vLLM + GPTQ MoE 미지원 이슈
- <https://huggingface.co/docs/inference-endpoints/en/engines/tgi> — TGI maintenance mode 안내

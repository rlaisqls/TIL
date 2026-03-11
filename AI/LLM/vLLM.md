
vLLM은 LLM 추론과 서빙을 위한 고성능 엔진이다. 같은 모델을 HuggingFace transformers로 돌릴 때와 비교해 수배~수십 배 빠른 처리량을 보여주는데, 이는 GPU 메모리 관리, 커널 최적화, 스케줄링 등 여러 계층에서의 최적화가 결합된 결과이다.

같은 모델인데 추론 엔진에 따라 성능 차이가 나는 이유를 이해하려면, LLM 추론이 왜 느린지부터 알아야 한다.

## LLM 추론의 병목

LLM의 텍스트 생성은 autoregressive 방식이다. 토큰 하나를 생성하려면 이전까지의 모든 토큰에 대한 attention 계산이 필요하고, 이 과정이 토큰 수만큼 반복된다. 100 토큰을 생성하면 모델의 forward pass가 100번 실행되는 것이다.

여기서 두 가지 핵심 병목이 발생한다.

- **메모리 병목 (Memory-bound)**: Attention 계산에는 이전 토큰들의 Key와 Value 텐서(KV cache)가 필요하다. 시퀀스가 길어질수록 KV cache가 커지고, GPU 메모리(HBM)에서 이 데이터를 읽는 시간이 지배적이 된다. 실제로 디코딩 단계에서는 연산량(FLOPs)보다 메모리 대역폭이 병목이다.
- **Python 오버헤드**: PyTorch의 eager execution은 연산 하나마다 Python → CUDA kernel launch → 동기화 과정을 거친다. 개별 연산 자체는 마이크로초 단위지만, 모델 하나의 forward pass에 수백 개의 연산이 포함되고 이것이 토큰마다 반복되면 누적 오버헤드가 수 초에 달한다.

HuggingFace transformers는 이 두 병목을 그대로 안고 있다. vLLM은 각각에 대해 최적화를 적용한다.

## PagedAttention

vLLM의 핵심 기술이다. UC Berkeley 연구팀이 2023년에 발표했고, OS의 가상 메모리에서 아이디어를 가져왔다.

**기존 KV cache 관리의 문제**

transformers에서 KV cache를 관리하는 방식은 단순하다. 요청이 들어오면 max_sequence_length만큼의 연속된 GPU 메모리를 미리 할당한다. 예를 들어 max_length=2048인 모델에서 실제로 300 토큰만 생성한다면, 나머지 1748 토큰분의 메모리는 그냥 낭비된다.

이 낭비는 세 가지 형태로 나타난다:

- **Internal fragmentation**: 할당했지만 사용하지 않는 메모리. 위 예시에서 1748 토큰분의 공간이다.
- **External fragmentation**: 여러 요청의 할당과 해제가 반복되면서 생기는 메모리 조각. 전체적으로는 공간이 남아있지만 연속된 큰 블록을 할당하지 못하는 상황이다.
- **Reservation waste**: 최대 길이를 알 수 없으므로 보수적으로 큰 공간을 예약해야 한다.

논문에 따르면 기존 시스템에서 KV cache 메모리의 60~80%가 이런 낭비로 사라진다.

**가상 메모리 방식의 해결**

PagedAttention은 KV cache를 고정 크기 블록(page)으로 나눈다. 기본값은 16 토큰 단위다.

OS의 페이지 테이블처럼, 논리적 시퀀스 위치와 물리적 GPU 메모리 블록 사이의 매핑 테이블을 유지한다. 이 방식의 장점:

- **필요한 만큼만 할당**: 토큰이 생성될 때마다 블록을 하나씩 추가한다. 300 토큰이면 19개 블록만 사용하고, 마지막 블록의 남는 공간(4 토큰분)만이 내부 단편화다.
- **비연속 메모리 사용 가능**: 블록이 물리적으로 연속되지 않아도 된다. 외부 단편화가 사라진다.
- **메모리 공유**: 같은 프롬프트를 공유하는 여러 요청(beam search, parallel sampling)이 KV cache 블록을 물리적으로 공유할 수 있다. Copy-on-Write 방식으로 분기 시점에만 복사한다.

결과적으로 같은 GPU 메모리에서 2~4배 더 많은 요청을 동시에 처리할 수 있다. 배치 크기가 커지면 GPU 활용률이 올라가고, throughput이 비례해서 증가한다.

## CUDA Graph

autoregressive 디코딩에서 매 토큰 생성마다 발생하는 Python 오버헤드를 제거하는 기술이다.

**문제: 토큰당 수백 번의 kernel launch**

LLM의 forward pass 한 번에는 수백 개의 CUDA 커널 호출이 포함된다. 각 호출마다:

1. Python에서 연산 파라미터를 준비한다
2. CUDA driver API를 통해 GPU에 커널을 제출한다
3. GPU가 커널을 실행한다
4. 다음 연산을 위해 Python으로 제어가 돌아온다

GPU에서의 실제 연산 시간은 수십 마이크로초인데, Python ↔ GPU 간의 launch 오버헤드가 커널당 수~수십 마이크로초씩 붙는다. 수백 개 커널이면 한 토큰당 수 밀리초의 오버헤드가 추가되고, 수백 토큰을 생성하면 초 단위가 된다.

**해결: 연산 그래프 캡처와 리플레이**

CUDA Graph는 일련의 GPU 연산을 한 번 실행하면서 그 전체 흐름을 그래프로 캡처한다. 이후에는 이 그래프를 단 한 번의 API 호출로 리플레이한다. 일반 실행에서는 토큰마다 300번의 kernel launch 오버헤드가 발생하지만, CUDA Graph를 쓰면 1번의 replay 호출로 줄어든다.

vLLM은 디코딩 단계의 forward pass를 CUDA Graph로 캡처한다. 다만, 그래프는 텐서의 shape이 고정되어야 하므로, 배치 크기별로 여러 그래프를 미리 캡처해두고 현재 배치 크기에 맞는 것을 선택한다. 이를 통해 토큰당 Python 오버헤드가 수 밀리초에서 수십 마이크로초로 줄어든다.

## Flash Attention

표준 Attention은 Q, K, V 행렬의 연산 과정에서 중간 결과(attention score 행렬)를 HBM에 써야 한다. N개 토큰이면 N×N 크기의 행렬이 생기고, 이를 쓰고 다시 읽는 메모리 접근이 병목이 된다.

Flash Attention은 이 문제를 tiling으로 해결한다.

- **표준 Attention**: `S = Q × K^T` → `P = softmax(S)` → `O = P × V` 각 단계에서 N×N 행렬을 HBM에 쓰고 다시 읽는다. HBM 접근이 O(N²)이다.
- **Flash Attention**: Q, K, V를 블록 단위로 SRAM(on-chip)에 로드하고, 블록별로 softmax를 점진적으로 계산한다(online softmax). 중간 결과는 SRAM에만 유지하고 최종 결과만 HBM에 기록하므로, HBM 접근이 O(N)으로 줄어든다.

핵심은 online softmax 알고리즘이다. 전체 행에 대한 softmax를 한 번에 계산하지 않고, 블록을 하나씩 처리하면서 running max와 running sum을 갱신해 나가는 방식이다. 이렇게 하면 N×N attention score 행렬을 HBM에 저장하지 않아도 된다.

GPU에서 SRAM(Shared Memory)은 약 20TB/s, HBM은 약 2~3TB/s의 대역폭을 가진다. Flash Attention은 대부분의 데이터 접근을 SRAM에서 처리하기 때문에, 실질적인 메모리 대역폭이 수 배 증가하는 효과를 얻는다. 실제로 표준 Attention 대비 2~4배의 속도 향상을 보인다.

vLLM은 Flash Attention을 기본 attention 백엔드로 사용하며, PagedAttention과 결합하여 paged 레이아웃의 KV cache에서도 효율적으로 동작하도록 커스텀 커널을 구현하고 있다.

## Continuous Batching

전통적인 서빙 시스템은 static batching을 사용한다. 배치 내의 모든 요청이 완료될 때까지 기다린 뒤 다음 배치를 시작하는 방식이다. 요청 A가 50 토큰, 요청 B가 200 토큰을 생성한다면, A가 끝난 후 150 토큰 동안 A의 슬롯은 GPU를 낭비하게 된다.

vLLM의 continuous batching은 토큰 생성 한 iteration마다 스케줄링 결정을 내린다. 완료된 요청의 슬롯을 즉시 회수하고 대기 중인 새 요청을 투입하기 때문에, GPU가 항상 최대 배치 크기에 가깝게 유지된다. 개별 요청의 latency도 줄어든다. 큰 배치가 끝날 때까지 기다리지 않고 바로 처리가 시작되기 때문이다.

이 방식은 PagedAttention과 시너지가 있다. 기존 방식에서는 새 요청이 들어오면 연속된 큰 KV cache 공간을 할당해야 했기 때문에, 동적으로 요청을 추가/제거하기 어려웠다. PagedAttention은 블록 단위로 유연하게 할당/해제할 수 있어 continuous batching이 원활하게 동작한다.

## Speculative Decoding

autoregressive 디코딩은 토큰을 하나씩 순차 생성해야 하므로, GPU 병렬 연산 능력을 충분히 활용하지 못한다. Speculative decoding은 이를 우회한다.

- **Draft model**: 작고 빠른 모델(또는 n-gram 기반 예측기)이 K개의 토큰을 빠르게 "추측"한다
- **Verification**: 원본(target) 모델이 이 K개 토큰을 한 번의 forward pass로 동시에 검증한다
- **Accept/Reject**: 수학적으로 target 모델의 분포를 정확히 보존하는 방식으로 토큰을 수락하거나 거부한다

K개 중 k개가 수락되면, 1번의 target forward pass로 k+1개의 토큰을 생성한 셈이 된다. draft model의 예측이 정확할수록 이득이 크다. 실제로 코드 생성이나 반복적인 패턴이 많은 텍스트에서는 acceptance rate가 높아 2~3배의 속도 향상이 가능하다.

vLLM은 speculative decoding을 내장 지원하며, draft model 방식과 n-gram 기반 방식(Medusa, Eagle 등의 변형 포함)을 모두 제공한다.

## Optimized CUDA Kernels

vLLM은 표준 PyTorch 연산 대신 최적화된 커스텀 CUDA 커널을 사용한다.

- **Fused kernels**: 여러 연산을 하나의 커널로 합친다. 예를 들어 RMSNorm + Residual Add, SiLU + Element-wise Multiply 등을 fuse하면, 각 연산 사이의 HBM 읽기/쓰기가 제거된다.
- **양자화 커널**: GPTQ, AWQ, GGUF 등의 양자화 모델을 위한 전용 커널(Marlin 등)이 dequantize와 GEMM을 하나의 커널에서 수행한다. 이에 대한 자세한 내용은 [GPTQ와 Marlin](./GPTQ와%20Marlin.md) 문서를 참조한다.
- **RoPE (Rotary Position Embedding)**: 위치 인코딩 계산을 GPU에서 인라인으로 처리하여 별도의 메모리 할당 없이 수행한다.

개별적으로는 10~30% 정도의 개선이지만, 모델 전체에 걸쳐 수십 개가 적용되면 누적 효과가 크다.

## Tensor Parallelism

단일 GPU의 메모리나 연산 능력이 부족할 때, 여러 GPU에 모델을 분산하는 기법이다.

vLLM은 Megatron-LM 스타일의 텐서 병렬화를 지원한다. 각 Transformer 레이어의 행렬 곱셈을 GPU 간에 분할한다:

- **Column parallel**: 가중치 행렬을 열 방향으로 분할. 각 GPU가 출력의 일부분을 계산한다.
- **Row parallel**: 가중치 행렬을 행 방향으로 분할. 각 GPU의 결과를 all-reduce로 합산한다.

Attention의 경우, head 단위로 GPU에 분배하는 것이 자연스럽다. 예를 들어 32개의 attention head를 4개 GPU에 분산하면, 각 GPU가 8개의 head를 담당한다.

GPU 간 통신은 NCCL을 사용하며, all-reduce 연산이 레이어당 2번(attention 후, FFN 후) 필요하다. NVLink가 있는 환경에서는 이 통신 오버헤드가 충분히 작아서 거의 선형적인 확장이 가능하다.

---
참고

- <https://arxiv.org/abs/2309.06180> (vLLM / PagedAttention 논문)
- <https://arxiv.org/abs/2205.14135> (Flash Attention 논문)
- <https://developer.nvidia.com/blog/cuda-graphs/>
- <https://arxiv.org/abs/2302.01318> (Speculative Decoding)
- <https://docs.vllm.ai/en/latest/>

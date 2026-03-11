
GPTQ(GPT Quantization)는 LLM 가중치를 양자화하는 기법이다. 70B 모델이 FP16으로 약 140GB VRAM을 잡아먹는데, INT4로 양자화하면 약 35GB까지 줄일 수 있다.

## 양자화 방식

레이어별로 가중치 행렬을 순차 양자화하는데, 하나를 양자화할 때 나머지를 보정(compensation)해서 출력 오차를 최소화한다. Hessian 역행렬로 어떤 가중치가 더 중요한지 판단하고, 캘리브레이션 데이터는 128~256 샘플이면 된다.

양자화된 가중치는 group 단위로 scale과 zero-point를 갖는다. group_size=128이면 128개 가중치가 FP16 scale/zero-point 하나를 공유하고, 추론할 때 `dequantized_weight = scale × (quantized_weight - zero_point)`로 복원해서 행렬 곱셈을 수행한다.

## Marlin

GPTQ로 양자화한 모델을 그냥 돌리면 매번 dequantize → matmul을 거쳐야 해서 오히려 느려질 수 있다. Marlin은 이걸 해결하는 고성능 CUDA 커널이다.

- **Fused Dequantize-GEMM**: INT4 dequantize와 행렬 곱셈을 하나의 커널에서 처리한다. 중간 결과를 HBM에 쓰고 읽는 과정이 없어진다
- **레지스터 수준 최적화**: INT4 가중치를 GPU 레지스터에서 직접 unpack해서 FP16으로 변환한다. Shared Memory 접근도 최소화한다
- **Tensor Core 활용**: FP16 MMA 명령어를 직접 쓴다. INT4 → FP16 변환 후 바로 Tensor Core에 넣는다
- **메모리 접근 패턴 최적화**: 가중치 레이아웃을 coalesced memory access에 맞게 재배열(repack)한다

INT4에서 FP16에 거의 근접하는 추론 속도가 나오기 때문에, vLLM에서 GPTQ 모델의 기본 커널로 쓰인다.

## vLLM에서의 CUDA 호환성 문제

Marlin 커널은 [PTX](../../OS/GPU/PTX.md) 인라인 어셈블리를 직접 쓰기 때문에 일반 CUDA 코드보다 버전 호환성에 민감하다.

```cuda
// Marlin 내부의 PTX 인라인 어셈블리 예시
asm volatile("mma.sync.aligned.m16n8k16.row.col.f32.f16.f16.f32 ..."
             : ... );
asm volatile("cp.async.cg.shared.global [%0], [%1], %2;"
             : ... );
```

예를 들어 vLLM wheel이 CUDA 12.4로 빌드되면 Marlin 커널의 PTX가 ISA 8.4로 생성되는데, 실행 환경에서 PyTorch가 CUDA 12.8을 사용하면 ptxas와 호환되지 않아 커널 로드가 실패할 수 있다.

**해결 방법**

- **실행 환경의 CUDA 버전에 맞는 wheel 설치**: PyTorch가 CUDA 12.8이면 CUDA 12.8용 vLLM을 설치한다
  ```bash
  pip install vllm --extra-index-url https://download.pytorch.org/whl/cu128
  ```
- **소스 빌드**: 현재 환경의 CUDA Toolkit으로 직접 컴파일하면 PTX 버전이 자동으로 맞춰진다
  ```bash
  pip install vllm --no-binary :all:
  ```
- **버전 통일**: PyTorch, vLLM, CUDA Toolkit을 같은 CUDA 계열로 맞추는 것이 가장 안정적이다

---
참고

- <https://arxiv.org/abs/2210.17323> (GPTQ 논문)
- <https://github.com/IST-DASLab/marlin>
- <https://docs.vllm.ai/en/latest/getting_started/installation.html>

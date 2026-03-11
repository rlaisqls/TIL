
PTX(Parallel Thread Execution)는 NVIDIA GPU의 가상 ISA(명령어 집합 아키텍처)이다. CUDA 코드가 GPU에서 실행되려면 여러 단계의 컴파일을 거치는데, PTX는 그 중간 표현에 해당한다. Java의 바이트코드와 비슷한 위치다.

- **CUDA C++ (.cu)** → nvcc 프론트엔드가 컴파일
- **PTX (.ptx)** → 가상 어셈블리. 특정 GPU에 종속되지 않는다
- **SASS** → ptxas가 PTX를 변환한 실제 GPU 기계어. sm_75, sm_89 같은 특정 아키텍처에 종속된다
- **cubin/fatbin** → GPU 실행 바이너리. fatbin은 PTX와 SASS를 함께 묶어둔 것으로, 런타임에 맞는 SASS가 있으면 그걸 쓰고 없으면 PTX를 JIT 컴파일한다

## PTX 버전과 CUDA 버전

PTX 버전은 CUDA 버전에 대응된다.

- CUDA 12.0 → PTX ISA 8.0
- CUDA 12.4 → PTX ISA 8.4
- CUDA 12.8 → PTX ISA 8.8

상위 CUDA 런타임은 하위 PTX를 JIT 컴파일할 수 있다. 반대 방향은 안 된다. 하위 CUDA 런타임이 상위 PTX를 만나면 모르는 명령어가 있어서 실패한다. PTX 인라인 어셈블리를 직접 쓰는 커스텀 커널(예: vLLM의 [Marlin](../../AI/LLM/GPTQ와%20Marlin.md) 커널)은 이 문제에 특히 민감해서, 빌드 환경과 실행 환경의 CUDA 버전이 다르면 커널 로드가 깨질 수 있다.

---
참고

- <https://docs.nvidia.com/cuda/parallel-thread-execution/>
- <https://docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/>

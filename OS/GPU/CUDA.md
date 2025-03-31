
## CUDA Toolkit

CUDA Toolkit은 NVIDIA에서 제공하는 GPU 가속 애플리케이션 개발을 위한 툴체인이다. 주로 다음과 같은 구성 요소를 포함한다.

### 구성 요소

- **nvcc (NVIDIA CUDA Compiler)**: `.cu` 확장자의 CUDA C/C++ 소스를 컴파일하여 실행 가능한 코드로 변환
- **라이브러리**
  - `cuBLAS`: GPU 가속 BLAS 연산
  - `cuDNN`: 딥러닝 연산 최적화를 위한 라이브러리
  - `Thrust`: STL과 유사한 병렬 알고리즘 라이브러리
- **디버깅 및 프로파일링 도구**
  - `cuda-gdb`, `nsight` 등의 디버깅 도구
  - `nvprof`, `Nsight Compute`, `Nsight Systems` 등의 성능 분석 도구

### 버전 확인

CUDA Toolkit의 버전은 다음 명령어로 확인할 수 있다.

```bash
$ nvcc --version
CUDA compilation tools, release 12.8, V12.8.89
```

버전 정보는 release 및 내부 버전 번호(V12.8.89) 형태로 제공된다.

## Compute Capability

Compute Capability는 NVIDIA GPU의 하드웨어 기능을 버전 숫자로 표현한 것이다. CUDA 코드는 GPU의 기능 수준에 따라 다르게 동작하거나 최적화되기 때문에, 이를 명시적으로 지정해야 한다.

**표기 방식**

- compute_75: 가상 아키텍처(PTX)를 대상으로 하는 컴파일
- sm_75: 실제 하드웨어 아키텍처(SASS)를 대상으로 하는 컴파일
- 둘 다 지정하면, nvcc는 PTX와 SASS를 모두 생성한다.

아래 명령어는 Compute Capability 7.5 (Turing 아키텍처) GPU를 대상으로 코드를 컴파일한다.

```
nvcc -gencode=arch=compute_75,code=sm_75 ...
```

### 주요 Compute Capability 버전

|버전|아키텍처|GPU 예시|
|-|-|-|
|7.0|Volta|V100|
|7.5|Turing|RTX 2080, RTX 2070|
|8.0|Ampere|A100A|
|8.6|Ampere|RTX 30 시리즈 일부A|
|9.0|Hopper|H100A|

- 코드의 하위 호환성을 확보하거나 최신 하드웨어의 기능을 최대한 활용하기 위해 사용한다.
- 다양한 Compute Capability를 지정하여 멀티타겟 바이너리를 생성할 수 있다.

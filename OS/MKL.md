
**Intel Math Kernel Library (MKL)**은 고성능 수학 연산을 위한 라이브러리로, 선형대수, 푸리에 변환, 벡터 수학 등 다양한 수학 계산에 최적화된 함수들을 제공한다. Intel CPU 아키텍처에 최적화되어 있으며, 과학, 공학, 머신러닝 분야에서 널리 사용된다.

MKL은 다음과 같은 특징이 있다.

- Intel 하드웨어에 최적화된 고성능 연산
- 멀티스레딩과 벡터화를 활용한 성능 향상
- BLAS, LAPACK, FFT 등 다양한 수학 연산 함수 포함
- C, C++, Fortran 등의 언어와 호환

## 기능

### 1. BLAS (Basic Linear Algebra Subprograms)

기본 선형대수 연산을 위한 함수들을 제공한다. 벡터, 행렬 연산 등을 빠르게 수행할 수 있다.

- Level 1: 벡터-벡터 연산 (dot, axpy, 등)
- Level 2: 행렬-벡터 연산 (gemv, symv, 등)
- Level 3: 행렬-행렬 연산 (gemm, syrk, 등)

### 2. LAPACK (Linear Algebra Package)

고급 선형대수 연산을 위한 라이브러리로, 행렬 분해, 선형 시스템 해법, 고유값 문제 등을 다룬다.

- LU, QR, Cholesky 분해
- 선형 방정식 시스템 해법
- 고유값 계산 및 특이값 분해(SVD)

### 3. FFT (Fast Fourier Transform)

1D, 2D, 3D 푸리에 변환을 위한 고속 알고리즘을 제공한다. 주로 신호처리나 스펙트럼 분석 등에 사용된다.

- 복소수 및 실수 신호 모두 지원
- 다양한 크기 및 차원의 FFT 지원
- 멀티스레딩 최적화 포함

### 4. 벡터 수학(Vector Math)

벡터 단위로 수학 함수를 계산할 수 있는 최적화된 루틴을 제공한다. 대규모 데이터를 처리하는 데 유용하다.

- 삼각함수, 지수함수, 로그함수 등 지원
- 정확도 옵션(High/Low Accuracy) 제공
- SIMD 명령어 최적화 적용

### 5. 스레딩 및 병렬처리

MKL은 Intel TBB(Intel Threading Building Blocks), OpenMP 등의 스레드 모델을 통해 병렬 연산을 자동으로 처리한다.

- MKL_NUM_THREADS 환경변수로 스레드 수 설정 가능
- 내부적으로 작업 분할 및 병렬화 수행

## 아키텍처 최적화

MKL은 Intel CPU 아키텍처에 맞춰 최적화되어 있다. AVX2, AVX-512 등 SIMD 명령어를 활용하며, 하드웨어에 맞는 코드 경로를 자동으로 선택한다.

```
# 사용 가능한 아키텍처 확인
source /opt/intel/mkl/bin/mklvars.sh intel64
```

## 사용

Python에서 NumPy를 사용할 때 MKL을 백엔드로 설정하면 자동으로 MKL이 사용된다. Conda 환경에서 설치되는 대부분의 numpy, scipy는 기본적으로 MKL을 사용한다.

```
import numpy as np
A = np.random.rand(1000, 1000)
B = np.linalg.inv(A)  # 내부적으로 MKL을 호출
```

C/C++에서 직접 MKL을 사용할 수도 있다.

```c
#include "mkl.h"
cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
            M, N, K, alpha, A, K, B, N, beta, C, N);
```

설치 방법

```bash
# Conda를 사용하는 경우
conda install -c intel mkl

# APT 기반 리눅스에서 설치 (Intel OneAPI 포함)
sudo apt install intel-oneapi-mkl
```

## 유의사항

- ARM 아키텍처에서는 공식적으로 지원되지 않는다. (x86 전용)
- 라이선스는 Intel OneAPI의 일부로 무료이나, 상업적 사용 시 조건 확인이 필요하다.
- 성능 최적화를 위해 CPU 플래그와 연동이 중요하다 (예: `MKL_DEBUG_CPU_TYPE`)

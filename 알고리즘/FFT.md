
먼저 일반적인 푸리에 변환인 DFT에서, N개의 샘플 x₀, x₁, ..., x_{N-1}이 있을 때, k번째 주파수 성분 X_k는 이렇게 계산한다:

```
X_k = x₀·ω⁰ + x₁·ω^k + x₂·ω^(2k) + ... + x_{N-1}·ω^((N-1)k)
```

여기서 ω = e^(-2πi/N) 이다. 복소수 단위원 위의 점이라고 생각하면 된다.

N개 주파수 각각에 대해 N번 곱셈을 해야 하니까, 총 N × N = N² 번의 연산이 필요하다.

## 고속 푸리에 변환(Fast Fourier Transform, FFT)

FFT의 핵심은 중복 계산을 없애는 것이다.

8개 샘플로 DFT를 계산한다고 해보자. 8개 주파수(0~7Hz)에 대해 각각 8번씩 곱해야 하니까 64번의 곱셈이 필요하다.

여기서 ω의 성질을 응용하면 연산을 줄일 수 있다. ω = e^(-2πi/8) 이라고 하면,

- ω⁸ = 1 (복소수 평면에서 한 바퀴를 돌면 제자리로 돌아옴). 따라서:
  - ω⁹ = ω¹
  - ω¹⁰ = ω²
  - ω¹² = ω⁴

- ω⁴ = -1 ( 반 바퀴 돌면 정반대 위치임 ). 따라서:
  - ω⁵ = ω⁴ · ω¹ = -ω¹
  - ω⁶ = ω⁴ · ω² = -ω²
  - ω⁷ = ω⁴ · ω³ = -ω³

### 짝수/홀수로 쪼개기

8개 샘플을 짝수 인덱스(0, 2, 4, 6)와 홀수 인덱스(1, 3, 5, 7)로 나눠보자.

주파수 k에 대한 DFT를 다시 쓰면:

```
X_k = (x₀ + x₂·ω^(2k) + x₄·ω^(4k) + x₆·ω^(6k))
    + ω^k · (x₁ + x₃·ω^(2k) + x₅·ω^(4k) + x₇·ω^(6k))
```

괄호 안을 보면, 첫 번째는 짝수 인덱스 샘플들의 4-점 DFT이고, 두 번째는 홀수 인덱스 샘플들의 4-점 DFT다.

이걸 E_k (짝수)와 O_k (홀수)라고 부르면:

```
X_k = E_k + ω^k · O_k
```

여기서 ω⁴ = -1 이라는 성질을 쓰면:

```
X_{k+4} = E_k - ω^k · O_k
```

따라서 E_k와 O_k를 한 번만 계산하면 X_k와 X_{k+4}를 둘 다 구할 수 있다.

### 예시

8-점 DFT에서 X₀과 X₄를 계산해보자.

```
X₀ = E₀ + ω⁰ · O₀ = E₀ + O₀
X₄ = E₀ - ω⁰ · O₀ = E₀ - O₀
```

X₁과 X₅는:

```
X₁ = E₁ + ω¹ · O₁
X₅ = E₁ - ω¹ · O₁
```

E_k와 O_k 각각 4번 계산하면, X_k 8개를 모두 구할 수 있다. 원래 64번 해야 할 곱셈이 절반으로 줄었다.

### 재귀

4-점 DFT인 E_k와 O_k도 같은 방식으로 쪼갤 수 있다.

```
8-점 DFT
    → 4-점 DFT 2개
        → 2-점 DFT 4개
            → 1-점 DFT 8개 (그냥 값 자체)
```

각 단계에서 N번의 연산이 필요하고, 총 log₂N 단계가 있으므로 총 연산 횟수는 N × log₂N이다.

## 버터플라이 연산

FFT의 기본 단위를 버터플라이 연산이라고 부른다. 모양이 나비 날개 같아서 붙은 이름이다.

```
a ──┬──→ a + b·W
    ╲╱
    ╱╲
b ──┴──→ a - b·W
```

두 입력 a, b에서 두 출력 a+b·W, a-b·W를 만든다. 곱셈 한 번으로 두 개의 결과를 얻는 거다.

8-점 FFT는 3단계(log₂8 = 3)의 버터플라이로 구성된다:

- 단계 1: 2-점 버터플라이 4개
- 단계 2: 4-점 버터플라이 2개
- 단계 3: 8-점 버터플라이 1개

## 구현

재귀 버전이 이해하기 쉽다:

```cpp
#include <complex>
#include <vector>
#include <cmath>

using cd = std::complex<double>;
const double PI = acos(-1);

std::vector<cd> fft(std::vector<cd> x) {
    int N = x.size();
    if (N <= 1) return x;

    std::vector<cd> even(N / 2), odd(N / 2);
    for (int i = 0; i < N / 2; i++) {
        even[i] = x[i * 2];
        odd[i] = x[i * 2 + 1];
    }

    even = fft(even);
    odd = fft(odd);

    cd w = std::exp(cd(0, -2 * PI / N));
    std::vector<cd> result(N);

    for (int k = 0; k < N / 2; k++) {
        cd t = std::pow(w, k) * odd[k];
        result[k] = even[k] + t;
        result[k + N / 2] = even[k] - t;
    }

    return result;
}
```

실제로는 반복문 버전이 더 빠르다. 비트 역순(bit-reversal) 재배열을 먼저 하고 버터플라이를 쌓아올린다:

```cpp
void fft_iterative(std::vector<cd>& a) {
    int N = a.size();
    int bits = __builtin_ctz(N);  // log2(N)

    // 비트 역순 재배열
    for (int i = 0; i < N; i++) {
        int rev = 0;
        for (int j = 0; j < bits; j++) {
            if (i & (1 << j)) rev |= (1 << (bits - 1 - j));
        }
        if (i < rev) std::swap(a[i], a[rev]);
    }

    // 버터플라이 연산
    for (int size = 2; size <= N; size *= 2) {
        cd w = std::exp(cd(0, -2 * PI / size));
        for (int start = 0; start < N; start += size) {
            cd wk = 1;
            for (int k = 0; k < size / 2; k++) {
                cd t = wk * a[start + k + size / 2];
                a[start + k + size / 2] = a[start + k] - t;
                a[start + k] = a[start + k] + t;
                wk *= w;
            }
        }
    }
}
```

---
참고

- <https://www.youtube.com/watch?v=spUNpyF58BY>
- <https://www.youtube.com/watch?v=h7apO7q16V0>
- <https://www.acmicpc.net/step/60>

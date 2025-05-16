
참고

- <https://github.com/SakanaAI/continuous-thought-machines>
- <https://discuss.pytorch.kr/t/continuous-thought-machine-ctm-feat-sakana-ai/6932>
- <https://pub.sakana.ai/ctm>
- <https://sakana.ai/ctm>
  - <img width="507" alt="image" src="https://github.com/user-attachments/assets/b978c3de-23a3-43cb-b23e-986e5aedf309" />

---

Continuous Thought Machine(CTM)은 생각한다는 행위를 계산 가능한 절차로 환원하기 위해 개발된 인공지능 아키텍처이다.

크게 Internal Ticks, MLM, SR 세 가지 개념으로 모델을 구성한다.

### 내부 사고 차원(Internal Ticks)

CTM의 internal tick은 모델 내부에서 자율적으로 진행되는 사고 단계이다.

- 독립적 시간 축을 가지므로 입력 시퀀스 길이와 무관하게 사고를 반복할 수 있다.
- 각 tick에서 모델은 동일 입력을 재해석하며 사고 깊이(depth) 를 축적한다.

- 외부 입력 시퀀스와 무관하게 **자율적인 사고 단위**를 반복한다.  
- 입력이 정적이어도 원하는 만큼 사고를 ‘깊게’ 진행할 수 있다.  
- 문제 난이도에 따라 사고 단계 수가 적응적으로 증가·감소하기 때문에 **Adaptive Compute** 를 자연스럽게 구현한다.
  - (인간이 복잡한 문제를 더 오랜 시간 고민하는 것과 유사한 동작이다.)

### 뉴런 수준 모델(Neuron-Level Models, NLM)

기존 신경망이 모든 뉴런에 동일한 단순 활성화 함수를 적용하는 것과 달리, CTM의 뉴런은 다음과 같은 특성을 지닌다.

1. 고유 MLP 구조
    - 각 뉴런은 작은 다층 퍼셉트론(MLP)을 자체적으로 보유한다.
2. 시계열 입력 처리
    - 단일 스칼라가 아닌, 일정 길이의 과거 pre-activation 시퀀스를 입력으로 받아들인다.
3. 시간적 패턴 학습
    - 뉴런은 자신의 과거 활동 패턴을 기억·해석하여 post-activation을 계산한다.

이 설계는 생물학적 뉴런이 시간 누적 신호를 기반으로 발화 결정을 내리는 원리와 유사하고, 뉴런 간 계산적 다양성과 표현력을 크게 증대시킨다

### 동기화 기반 표현(Synchronization Representation)

각 tick에서 뉴런들이 출력한 post-activation 벡터 `Z_t`를 모은 뒤, 다음과 같이 동기화 행렬을 구성한다.

- `S_t`의 원소 `S_{t,ij}`는 뉴런 i와 j가 시간 축에서 얼마나 함께 발화했는지의 유사도를 나타낸다.
- 이 행렬이 곧 CTM의 잠재 표현(latent representation) 으로 기능한다.
- 뉴런 쌍의 동시 발화 패턴을 분석함으로써, 모델이 어떤 특징을 주목했는지 해석 가능성을 높인다.
- 관계 기반 표현이므로 밀도와 해상도가 기존 벡터형 임베딩보다 우수하며, 정보 손실이 적다.


- 은닉층 안에 하나 이상의 순환 계층을 갖는 신경망
- 기존 신경망 구조: 모든 입력과 출력이 각각 독립적이라 가정하고, 시간에 따른 입출력 간의 관계를 고려되지 않았음
- RNN은 현재 입력을 유추할 때 이전 결과를 반영하여 계산하기 때문에 시간적 순서를 가지는 Sequence 기반 데이터, 연속적인 시계열(time series) 데이터를 잘 다룸
- 시간 순서를 기반으로 데이터들의 상관관계를 파악해서 그를 기반으로 현재 및 과거 데이터를 통해서 미래에 발생될 값을 예측
- 활성화 함수로 탄젠트 하이퍼볼릭을 많이 사용함
- Cell 안에 Unit이 여러개 들어가고, 각 Cell마다 은닉상태를 가짐

<img width="837" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/c10319a8-31b8-4ed9-9ff9-f8be61ea687b">

## 유형

영향을 주는 셀과 영향받는 셀의 관계에 따라 One-to-One, One-to-Many, Many-to-Many 등으로 나뉜다. 사용하는 데이터나 개발한 모델에 따라 다른 종류를 사용한다.

<img width="484" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/70c719e6-1bd2-42e8-b65b-9ed74fb65580">

## LSTM

- RNN은 과거의 정보를 기억할 수 있다. 하지만 멀리 떨어져있는 문맥은 기억할 수 없다.
- LSTM은 이러한 "긴 기간의 의존성(long-term dependencies)"를 완벽하게 다룰 수 있도록 개선한 버전이다.

- 모든 RNN은 neural network 모듈을 반복시키는 체인과 같은 형태를 하고 있다. 기본적인 RNN에서 이렇게 반복되는 모듈은 굉장히 단순한 구조를 가지고 있다. 예를 들어 tanh layer 한 층을 들 수 있다.
  - 아래는 RNN의 일반적인 모습이다.
    
    <img width="828" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/02a1a10e-1f8b-410e-8bbd-b8d9a1272597">

- LSTM도 똑같이 체인과 같은 구조를 가지고 있지만, 각 반복 모듈은 다른 구조를 갖고 있다. 단순한 neural network layer 한 층 대신에, 3개의 게이트가 특별한 방식으로 서로 정보를 주고 받도록 되어 있다.
    - LSTM 반복 모듈의 모습이다.
      
      <img width="782" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/23007c2d-15d6-4492-a0b0-9725096b357c">

- LSTM의 게이트 3개
  - 삭제 게이트(forget gate layer) : 셀 상태에서 감소 및 삭제시킬 기억을 결정
    -  cell state로부터 어떤 정보를 버릴 것인지를 정하는 것으로, sigmoid layer에 의해 결정된다.
  - 입력 게이트(input gate layer): 현재 입력된 정보 중 어떤 것을 저장할지 제어
    - sigmoid layer가 어떤 값을 업데이트할지 정한다.
    - tanh layer가 새로운 후보 값들인 ct라는 vector를 만들고, cell state에 더할 준비를 한다. 이렇게 두 단계에서 나온 정보를 합쳐서 state를 업데이트할 재료를 만든다.
  - 출력 게이트(output gate layer): 업데이트된 셀 상태를 기반으로 특정 부분을 읽어 현재의 은닉 상태 제어
    - 이미 이전 단계에서 어떤 값을 얼마나 업데이트해야 할 지 다 정해놨으므로 여기서는 그 일을 실천만 하면 된다.

---
참고
- https://www.ibm.com/kr-ko/topics/recurrent-neural-networks
- https://dgkim5360.tistory.com/entry/understanding-long-short-term-memory-lstm-kr

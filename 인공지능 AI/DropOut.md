# DropOut

 <img width="530" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/91ba4db6-eef3-4741-a6a2-6e76fe64269e">

Drop-out은 서로 연결된 연결망(layer)에서 0부터 1 사이의 확률로 뉴런을 제거(drop)하는 기법이다. 예를 들어, 위의 그림 1 과 같이 drop-out rate가 0.5라고 가정하자. Drop-out 이전에 4개의 뉴런끼리 모두 연결되어 있는 전결합 계층(Fully Connected Layer)에서 4개의 뉴런 각각은 0.5의 확률로 제거될지 말지 랜덤하게 결정된다. 위의 예시에서는 2개가 제거된 것을 알 수 있다. 즉, 꺼지는 뉴런의 종류와 개수는 오로지 랜덤하게 drop-out rate에 따라 결정된다. Drop-out Rate는 하이퍼파라미터이며 일반적으로 0.5로 설정한다.

## 사용 목적

Drop-out은 어떤 특정한 설명변수 Feature만을 과도하게 집중하여 학습함으로써 발생할 수 있는 과대적합(Overfitting)을 방지하기 위해 사용된다.

위의 그림에서 노란색 박스 안에 있는 Drop-Out이 적용된 전결합계층은 하나의 Realization 또는 Instance라고 부른다. 각 realization이 일부 뉴런만으로도 좋은 출력값을 제공할 수 있도록 최적화되었다고 가정했을 때, 모든 realization 각각의 출력값에 평균을 취하면(=ensemble) 그림의 오른쪽과 같이 모든 뉴런을 사용한 전결합계층의 출력값을 얻을 수 있다. 특히 이 출력값은 Drop-out을 적용하기 전과 비교했을 때, 더욱 편향되지 않은 출력값을 얻는 데 효과적이다.

 Drop-out을 적용하지 않고 모델을 학습하면 해당 Feature에 가중치가 가장 크게 설정되어 나머지 Feature에 대해서는 제대로 학습되지 않을 것이다. 반면 Drop-out을 적용하여 상관관계가 강한 Feature를 제외하고 학습해도 좋은 출력값을 얻을 수 있도록 최적화되었다면, 해당 Feature에만 출력값이 좌지우지되는 과대적합(overfitting)을 방지하고 나머지 Feature까지 종합적으로 확인할 수 있게 된다. 이것이 모델의 일반화(Generalization) 관점에서 Drop-out을 사용하는 이유이다.

## Mini-batch 학습 시 Drop-out

 <img width="530" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/181bdd5c-96b6-4fa9-b4f7-f981f5ea2899">

위의 그림과 같이 전결합 계층에서 Mini-batch 학습 시 Drop-out을 적용하면 각 batch별로 적용되는 것을 알 수 있다. Drop-out Rate를 0.5로 설정했기 때문에 뉴런별로 0.5의 확률로 drop 될지 여부가 결정된다. 첫 번째 batch에서는 위에서 2, 3번 뉴런이 꺼졌고, 2번째 batch에서는 3번 뉴런 1개만 꺼졌고, 3번째 batch에서는 1, 2, 3번 뉴런 3개가 꺼질 수 있다.

## Test 시 Drop-out

 <img width="330" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/ff3f6a23-3649-4502-b778-39506e056131">

Test 단계에서는 모든 뉴런에 scaling을 적용하여 동시에 사용한다. 여기서 a는 activation function, 알파는 drop-out rate를 의미한다. Drop-out rate를 활용해 scaling 하는 이유는 기존에 모델 학습 시 drop-out rate 확률로 각 뉴런이 꺼져 있었다는 점을 고려하기 위함이다. 즉, 같은 출력값을 비교할 때 학습 시 적은 뉴런을 활용했을 때(상대적으로 많은 뉴런이 off 된 경우)와 여러 뉴런을 활용했을 때와 같은 scale을 갖도록 보정해 주는 것이다.

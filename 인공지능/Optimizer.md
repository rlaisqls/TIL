# Optimizer
  손실함수를 줄여나가면서 학습하는 방법은 여러가지가 있는데, 이를 최적화 하는 방법들을 Optimizer라고 부른다.

## 경사 하강법

경사하강법은 손실 함수또는 비용 함수라 불리는 목적 함수를 정의하고, 이 함수의 값이 최소화되는 파라미터를 찾는 방법이다.

> 손실 (loss) : 실제값과 모델로 예측한 값이 얼마나 차이가 나는가를 나타내는 값으로, 손실이 작을수록 예측값이 정확한 것이다.<br>비용(cost, error)은 손실을 전체 데이터에 대해 구한 경우이며 비용을 함수로 나타낸 것을 손실 함수또는 비용 함수라고 한다.

함수의 최소값을 찾기 위해 임의의 위치에서 시작해서 기울기를 따라 조금씩 더 낮은 위치로 내려가며 극값에 이를 때까지 반복시킨다.

손실 함수는 인공지능의 파라미터를 통하여 나온 예측 값과 실제 값의 차이이기 때문에, 특정 파라미터를 통하여 나온 손실 함수 값이 가장 낮은 곳이 바로 **최적의 파라미터**라고 할 수 있다.

**경사 하강법 동작 순서**

1. 가중치 초기화
    - 0이나 랜덤 값으로 초기화해준다.
2. 비용함수 계산
    - 만약 현재 위치의 기울기가 **음수**라면 파라미터를 **증가**시키면 최솟값을 찾을 수 있다.
    - 반대로 기울기가 **양수**라면 파라미터를 **감소**시키면 최솟값을 찾을 수 있다.
    - **따라서 해당 파라미터에서 학습률 * 기울기를 빼면 최솟값이 되는 장소를 찾을 수 있다.**
        
        <img width="257" alt="image" src="https://user-images.githubusercontent.com/81006587/230717745-2b10da10-eba5-4a0b-bd0e-b20a45140983.png">
        
3. 가중치 갱신
    - 기울기는 음수 값을 가진다. (오른쪽으로 이동(하강)하게 하기 위해 기울기에 - 를 붙여준다.)
    - 가중치를 조금씩 움직이는 것을 반복하다보면 최저점에 접근할 수 있다.
4. 2~3 과정을 지정한 횟수나 비용함수값이 일정 임계값 이하로 수렴할때까지 반복한다.
    - 전체를 한번 도는걸 1 epoch이라 한다.

## 배치 경사 하강법

![image](https://github.com/rlaisqls/TIL/assets/81006587/633e77d9-4c05-4ed1-bf3c-b7a2c5f484ba)


배치 경사 하강법은 경사 하강법의 손실 함수의 기울기 계산에 **전체 학습 데이터셋**에 대한 에러를 구한 뒤 기울기를 한 번만 계산하여 모델의 파라미터를 업데이트하는 방식을 의미한다.

**배치 경사 하강법의 문제점**

- 모든 데이터를 적용하여 변화량을 구하기 떄문에 연산량이 많이 필요하다.
- 초기 W값에 따라 지역적 최소값에 빠지는 경우가 발생한다.
    - 이를 해결하기 위해 학습률을 상태에 따라 적응적으로 조절할 필요가 있다. (Stochastic Gradient Descent)
    
        <img width="595" alt="image" src="https://user-images.githubusercontent.com/81006587/230717724-4ef4924a-c178-44d1-aabb-b091b4b4799c.png">

## 확률적 경사 하강법 (Stochastic Gradient Descent, SGD)

![image](https://github.com/rlaisqls/TIL/assets/81006587/f07e34d4-c7e7-46ee-bf18-3fca5ce6abf9)

- 전체 학습 데이터를 사용하지 않고 확률적으로 선택한 샘플의 일부만을 사용하고, 진동하며 결과값으로 수렴한다.
- 일부 데이터만 사용하기 때문에 학습 속도가 매우 빠르다.
- 일반적인 경사 하강법과 반대로 local minimum에 빠지더라도 쉽게 빠져나올 수 있어서 global minimum을 찾을 가능성이 더 크다.
- 손실 함수가 최솟값에 가는 과정이 불안정하다 보니 최적해(global minimum)에 정확히 도달하지 못할 가능성이 있다.
- 결과의 진폭이 크고 불안하다는 단점이 있다. (오차율이 크다)

```python
weight[i] += - learning_rate * gradient
```

```python
keras.optimizers.SGD(lr=0.1)
```

확률적 경사 하강법의 노이즈를 줄이면서도 전체 배치보다 더 효율적인 방법으로는 미니배치 경사 하강법이 있다.

## 미니배치 경사 하강법

![image](https://user-images.githubusercontent.com/81006587/230538678-c5917ce6-926a-48bc-991b-6bfbae2012a0.png)

SGD와 BGD의 절충안으로 배치 크기를 줄여 확률적 경사 하강법을 이용하는 방법이다.

전체 데이터를 작은 그룹으로 나누고, 작은 그룹 단위로 가중치를 갱신한다. 

전체 데이터를 batch_size개씩 나눠 배치로 학습 시키는 방법이고, 배치 크기는 사용자가 지정한다. 일반적으로는 메모리가 감당할 수 있는 정도로 결정한다.

**미니배치 경사 하강법 특징**
- 전체 데이터셋을 대상으로 한 SGD 보다 parameter 공간에서 shooting이 줄어든다.(미니배치의 손실 값 평균에 대해 경사 하강을 진행하기 때문에)
- BGD에 비해 Local Minima를 어느정도 회피할 수 있다.
- 최적해에 더 가까이 도달할 수 있으나 local optima 현상이 발생할 수 있다. local optima의 문제는 무수히 많은 임의의 parameter로부터 시작하면 해결된다. (학습량 늘리기)

## 모멘텀

- 모멘텀은 SGD의 높은 편차를 줄이고 수렴을 부드럽게 하기 위해 고안되었다. 

- 관련 방향으로의 수렴을 가속화하고 관련 없는 방향으로의 변동을 줄여준다. 말 그대로 이동하는 방향으로 나아가는 '관성'을 주는 것이다. 

- γ는 현재 기울기 값(현재 가속도)뿐만 아니라 (과거의 가속도로 인한) 현재 속도를 함께 고려하여 이동 속도를 나타내는 momentum term이다.

<img width="215" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/864eba83-7923-4d5d-b919-c9031e4dfff3">

- 이전 gradient들의 영향력을 매 업데이트마다 γ배 씩 감소
- momentum term γ는 보통 0.9 정도로 정함

- SGD에 비해 파라미터의 분산이 줄어들고 덜 oscillate한다는 장점이 있고, 빠르게 수렴한다. 하지만 γ라는 새로운 하이퍼 파라미터가 추가되었으므로 적절한 값을 설정해줘야 한다는 단점이 있다.

 <img width="587" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/ce2dfde4-c593-4e84-8f6a-35cde50aa4db">

## NAG (Nesterov Accelerated Gradient)

- 모멘텀은 좋은 방법일 수 있지만, 모멘텀이 너무 높으면 알고리즘이 minima를 놓치고 건너뛰어버릴 우려가 있다.
- NAG는 '앞을 내다보는' 알고리즘이다. NAG에서는 momentum step을 먼저 고려하여, momentum step을 먼저 이동했다고 생각한 후 그 자리에서의 gradient를 구해서 gradient step을 이동한다. 

<img width="281" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/f2c7b820-76e1-4bcb-9cb9-081f2c0427f9">

- 식을 보면 gradient와 momentum step이 독립적으로 계산되는 것이 아님을 알 수 있다.

- 모멘텀에 비해 멈춰야 할 지점(minima)에서 제동을 걸기 쉽다. 일단 모멘텀으로 이동을 반 정도 한 후, 어떤 방식으로 이동해야 할 지 결정할 수 있다. 하지만 여전히 하이퍼 파라미터 값을 수동으로 결정해줘야 한다는 단점이 존재한다.

## Adagrad

- 위에 설명한 모든 옵티마이저의 단점 중 하나는 학습률이 모든 파라미터와 각 cycle에 대해 일정하다는 것이다.

- Adagrad는 각 파라미터와 각 단계마다 학습률을 변경할 수 있다. second-order 최적화 알고리즘의 유형으로, 손실함수의 도함수에 대해 계산된다.

- 이 알고리즘의 기본적인 아이디어는 ‘지금까지 많이 변화하지 않은 변수들은 step size를 크게 하고, 지금까지 많이 변화했던 변수들은 step size를 작게 하자’ 라는 것이다.
  
  - 자주 등장하거나 변화를 많이 한 변수들의 경우 optimum에 가까이 있을 확률이 높기 때문에 작은 크기로 이동하면서 세밀한 값을 조정하고, 적게 변화한 변수들은 optimum 값에 도달하기 위해서는 많이 이동해야할 확률이 높기 때문에 먼저 빠르게 loss 값을 줄이는 방향으로 이동하려는 방식이라고 생각할 수 있겠다.

Adagrad의 한 스텝을 수식화하면,


 
- Gt는 k차원 벡터, ‘time step t까지 각 변수가 이동한 gradient의 sum of squares’ -> <img width="13" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/771bdeab-6073-42ad-abde-5adcb99e8f97">를 업데이트 할 때 Gt의 루트값에 반비례한 크기로 이동
- <img width="13" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/37c33d7d-8df7-4086-a227-c912997409f3">은 0으로 나누어지는 것을 방지하는 smoothing term
  
- 각 학습 파라미터에 대해 학습률이 바뀌기 때문에 수동으로 조정할 필요가 없지만, 이계도함수를 계산해야 하기 때문에 계산 비용이 많이 든다. 또, Adagrad에는 학습을 진행하면 진행할 수록 학습률이 줄어든다는 문제점이 있다. 
- Gt에 계속 제곱한 값을 넣어주기 때문에 값이 계속 커지므로, 학습이 오래 진행될 경우 학습률이 너무 작아져 결국 거의 움직이지 않게 된다. 즉, 최솟값에 도달하기도 전에 학습률이 0에 수렴해버릴 수도 있다.
 

 ## Adam (Adaptive Moment Estimation)

- Adagrad나 RMSProp처럼 각 파라미터마다 다른 크기의 업데이트를 진행하는 방법이다.
- Adam의 직관은 local minima를 뛰어넘을 수 있다는 이유만으로 빨리 굴러가는 것이 아닌, minima의 탐색을 위해 조심스럽게 속도를 줄이고자 하는 것이다.
- Adam은 AdaDelta와 같이 decaying average of squared gradients를 저장할 뿐만 아니라, 과거 gradient 
의 decaying average도 저장한다. 
    <img width="322" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/fa2547dd-661d-4889-b046-87db920009fc">

- mt와 vt가 학습 초기에 0으로 biased 되는 것을 방지하기 위해 uncentered variance of the gradients인 ^mt, ^vt를 계산해준다.
    <img width="146" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/f3ead0a6-515b-4ec1-8e7b-5cea21525ec2">

- 이 보정된 값들을 가지고 파라미터를 업데이트한다. 기존에 Gt 자리에 ^vt를 넣고, gradient 자리에 ^mt를 넣으면 된다.
    <img width="230" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/db20377f-9222-436f-a870-466b7ed509b1">

- β1의 값은 0.9, β2는 0.999, ε은 (10 x exp(-8))이다.

- loss가 최솟값으로 빠르게 수렴하고 vanishing learning rate 문제, high variance 문제를 해결하였다.
- 계산 비용이 많이 든다는게 단점이다.

 
### 케라스

케라스는 파이썬으로 구현된 쉽고 간결한 딥러닝 라이브러리로, 내부적으로 텐서플로우Tensorflow, 티아노Theano,CNTK 등의 딥러닝 전용 엔진이 구동되지만 내부엔진을 알 필요 없이 직관적인 API로 쉽게 다층퍼셉트론 신경망 모델, 컨벌루션 신경망 모델, 순환 신경망 모델 등 다양한 구성을 할 수 있다.

케라스의 가장 핵심적인 데이터 구조는 바로 **모델**이다. 케라스에서 제공되는 시퀀스 모델을 사용하면 원하는 레이어를 쉽게 순차적으로 정의할 수 있고, 다중 출력과 같이 좀 더 복잡한 모델을 구성하려면 케라스 함수 API를 사용하면 된다. 케라스로 딥러닝 모델을 만들 때는 다음과 같은 순서로 작성한다.

1. **데이터셋 생성하기 (전처리)** 

- 원본 데이터를 불러오거나 시뮬레이션을 통해 데이터 생성. Training set, Test set, Validation set을 생성하며 이 때 모델의 학습 및 평가를 할 수 있도록 format 변환을 한다.

2. **모델 구성하기**

- 시퀀스 모델을 생성한 뒤 필요한 레이어를 추가하여 구성하며 좀 더 복잡한 모델이 필요할 때 케라스 함수 API를 사용한다.

3. **모델 학습과정 설정하기**

- 학습하기 전 학습에 대한 설정을 수행하는데 Loss 함수(ex. cross-entropy) 및 최적화 방법(ex. Gradient Descent)을 정의하고 케라스에서는 compile() 함수를 사용한다.

4. **모델 학습시키기**

- 구성한 모델을 Training dataset으로 학습시키는데 fit() 함수를 사용한다.

5. **학습과정 살펴보기**

- 모델 학습 시 Training dataset, Validation dataset의 Loss 및 Accuracy를 측정하고 반복 횟수(epoch)에 따른 Loss 및 Accuracy 추이를 보며 학습 상황을 판단한다.

6. **모델 평가하기**

- 준비된 Test dataset으로 학습한 모델을 평가하는데 evaluate() 함수를 사용한다.

7. **모델 사용하기**

- 임의의 입력으로 모델의 출력을 얻는데 predict() 함수를 사용한다.

### Sequential 모델

케라스에서는 층을 조합하여 모델을 생성한다. 레이어 인스턴스를 생성자에게 넘겨줌으로써 `Sequential` 모델을 구성할 수 있다.

```python
from keras.models import Sequential
from keras.layers import Dense, Activation

model = Sequential()
model.add(Dense(32, input_dim=784, activation='sigmoid')) # 층 갯수, 입력값 수, 활성화 함수
```

### 컴파일

모델을 학습시키기 이전에, `compile` 메소드를 통해서 학습 방식에 대한 환경설정을 해야 한다. 다음의 세 개의 인자를 입력으로 받는다.

- **정규화기 (optimizer)**
    - `rmsprp`나 `adagrad`와 같은 [optimizer](https://keras.io/optimizers)에 대한 문자열 식별자 또는 `Optimizer` 클래스의 인스턴스를 사용할 수 있다.
- **손실 함수 (loss function)**
    - 모델 최적화에 사용되는 목적 함수이다.
    - `categorical_crossentropy` 또는 `mse`와 같은 기존의 손실 함수의 문자열 식별자 또는 목적 함수를 사용할 수 있다. 참고: [손실](https://keras.io/losses)
- **Metrics**
    - 분류 문제에 대해서는 `metrics=['accuracy']`로 설정한다. 기준은 문자열 식별자 또는 사용자 정의 기준 함수를 사용할 수 있다.

```python
# For a multi-class classification problem
model.compile(optimizer='rmsprop',
              loss='categorical_crossentropy',
              metrics=['accuracy'])

# For a binary classification problem
model.compile(optimizer='rmsprop',
              loss='binary_crossentropy',
              metrics=['accuracy'])

# For a mean squared error regression problem
model.compile(optimizer='rmsprop',
              loss='mse')

# For custom metrics
import keras.backend as K

def mean_pred(y_true, y_pred):
    return K.mean(y_pred)

model.compile(optimizer='rmsprop',
              loss='binary_crossentropy',
              metrics=['accuracy', mean_pred])
```

### 모델 학습

- `fit()` 은 오차로부터 매개변수를 업데이트시키는 과정을 학습 과정을 수행하는 역할을 한다.
- **epoch:** 전체 학훈련데이터 학습을 몇 회 반복할지 결정
- **batch_szie:** 계산하는 단위 크기
- **validation_data:** 모델의 성능을 모니터링하기 위해서 사용. 입력과 정답 데이터로 이루어진 검증 데이터를 전달하면 1회 epoch이 끝날때마다 정달된 검증데이터에서의 손실과 평가지표를 출력함

```python
model.fit(x,y,epochs=3000,batch_size=1)
```

훈련데이터(x, y)와는 별도로 모델을 계속 학습하면서 각 에폭마다 검증데이터로 현재 모델에 대한 유효성(성능)을 검증할 수도 있다. 보통은 전체 훈련 데이터와 검증데이터를 8:2 비율로 분할하여 사용하며, 이때는 다음과 같이 코드를 구성하면 된다.

```python
model.fit(x,y,epochs=3000,batch_size=1,validation_split=0.2)
```

### 모델 학습 및 구성에 대한 예시

```python
# For a single-input model with 2 classes (binary classification):

model = Sequential()
model.add(Dense(32, activation='relu', input_dim=100))
model.add(Dense(1, activation='sigmoid'))
model.compile(optimizer='rmsprop',
              loss='binary_crossentropy',
              metrics=['accuracy'])

# Generate dummy dataimport numpyas np
data = np.random.random((1000, 100))
labels = np.random.randint(2, size=(1000, 1))

# Train the model, iterating on the data in batches of 32 samples
model.fit(data, labels, epochs=10, batch_size=32)

```

```python
# For a single-input model with 10 classes (categorical classification):

model = Sequential()
model.add(Dense(32, activation='relu', input_dim=100))
model.add(Dense(10, activation='softmax'))
model.compile(optimizer='rmsprop',
              loss='categorical_crossentropy',
              metrics=['accuracy'])

# Generate dummy dataimport numpyas np
data = np.random.random((1000, 100))
labels = np.random.randint(10, size=(1000, 1))

# Convert labels to categorical one-hot encoding
one_hot_labels = keras.utils.to_categorical(labels, num_classes=10)

# Train the model, iterating on the data in batches of 32 samples
model.fit(data, one_hot_labels, epochs=10, batch_size=32)
```

### 모델 평가

- `evaluate()`  : 테스트 데이터를 통해 학습한 모델에 대한 정확도를 평가
- `predict()` : 임의의 입력에 대한 모델의 출력값을 확인

---

### XOR

keras로 XOR을 분류하는 인공지능을 만들어보자

```python
import numpy as np
import tensorflow as tf

x = np.array([[1,1], [1,0], [0,1], [0,0]])
y = np.array([[0],[1],[1],[0]])

model = tf.keras.Sequential()
model.add(tf.keras.layers.Dense(units=2, input_dim=2, activation='sigmoid'))
model.add(tf.keras.layers.Dense(units=1, activation='sigmoid'))

model.compile(optimizer=tf.optimizers.SGD(learning_rate=0.1), loss='mse') # mse는 값을 이분화시켜줌. 여러개면 categorical_entropy 사용

model.summary()

history = model.fit(x, y, epochs=3000, batch_size=1)

for weight in model.weights:
  print(weight)

loss = model.evaluate(x,y,batch_size=1)
print(loss)

print("====================================")
print(x)
print(model.predixt(x))
print("====================================")
```

```python
# 출력값
====================================
[[1 1]
 [1 0]
 [0 1]
 [0 0]]
1/1 [==============================] - 0s 256ms/step
[[0.09821586]
 [0.92452645]
 [0.92447394]
 [0.06521357]]
====================================
```
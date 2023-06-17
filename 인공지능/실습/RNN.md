# RNN

mnist 알파벳 데이터를 식별하는 RNN 모델 예제입니다.

Keras의 SimpleRNN을 사용하여 간단하게 구현하였습니다.

```python
import tensorflow as tf
import numpy as np
from tensorflow.keras.layers import SimpleRNN, Dense
import matplotlib.pylab as plt

(train_images, train_labels), (test_images, test_labels) = tf.keras.datasets.mnist.load_data()

train_images, test_images = train_images / 255.0, test_images / 255.0

print(train_labels[:10])

one_hot_train_labels = tf.keras.utils.to_categorical(train_labels, 10)
one_hot_test_labels = tf.keras.utils.to_categorical(test_labels, 10)

model = tf.keras.models.Sequential()
model.add(SimpleRNN(units=64, input_shape = (28, 28), return_sequences=False))
model.add(Dense(10, activation='softmax'))

model.compile(optimizer=tf.optimizers.Adam(learning_rate=0.01),loss='categorical_crossentropy', metrics=['accuracy'])

model.summary()
history = model.fit(train_images, one_hot_train_labels, epochs=2, batch_size=10)

plt.figure(figsize=(12,4))
plt.subplot(1,1,1)
plt.plot(history.history['loss'], 'b--', label='loss')
plt.plot(history.history['accuracy'], 'g-', label='Accuracy')
plt.xlabel('Epoch')
plt.legend()
plt.show()
print("최적화 완료")

print("\n================================================\n")
labels=model.predict(test_images)
print("accuracy: %.4f"% model.evaluate(test_images, one_hot_test_labels, verbose=2)[1])

fig = plt.figure()
for i in range(36):
  subplot = fig.add_subplot(3,12,i+1)
  subplot.set_xticks([])
  subplot.set_yticks([])
  subplot.set_title('%d' % np.argmax(labels[i]))
  subplot.imshow(test_images[i].reshape((28, 28)), cmap=plt.cm.gray_r)

plt.show()

print("\n================================================\n")
```

### 실행결과

```js
[5 0 4 1 9 2 1 3 1 4]
Model: "sequential_4"
_________________________________________________________________
 Layer (type)                Output Shape              Param #   
=================================================================
 simple_rnn_2 (SimpleRNN)    (None, 64)                5952      
                                                                 
 dense_6 (Dense)             (None, 10)                650       
                                                                 
=================================================================
Total params: 6,602
Trainable params: 6,602
Non-trainable params: 0
_________________________________________________________________
Epoch 1/5
1875/1875 [==============================] - 14s 7ms/step - loss: 0.4983 - accuracy: 0.8468
Epoch 2/5
1875/1875 [==============================] - 13s 7ms/step - loss: 0.2367 - accuracy: 0.9312
Epoch 3/5
1875/1875 [==============================] - 13s 7ms/step - loss: 0.1963 - accuracy: 0.9415
Epoch 4/5
1875/1875 [==============================] - 13s 7ms/step - loss: 0.1778 - accuracy: 0.9492
Epoch 5/5
1875/1875 [==============================] - 12s 7ms/step - loss: 0.1622 - accuracy: 0.9534
```

<img width="828" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/4daa5dc8-22f6-4024-8835-04603d98d965">


```js
최적화 완료

================================================

313/313 [==============================] - 1s 3ms/step
313/313 - 1s - loss: 0.1581 - accuracy: 0.9550 - 1s/epoch - 3ms/step
accuracy: 0.9550
```

<img width="524" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/990b49f6-8a4e-4a59-a2a2-e77aa505ba29">

# CNN

mnist 알파벳 데이터를 식별하는 CNN 모델 예제입니다.

```python
import tensorflow as tf
import numpy as np

import matplotlib.pylab as plt

(train_images, train_labels), (test_images, test_labels) = tf.keras.datasets.mnist.load_data()

plt.figure(figsize=(6,1))

for i in range(36):
  plt.subplot(3,12,i+1)
  plt.imshow(train_images[i], cmap="gray")
  plt.axis("off")

plt.show()
# 28 * 28의 벡터 이미지 60000개, 채널은 1개
train_images = train_images.reshape((60000, 28, 28, 1))
test_images = test_images.reshape((10000, 28, 28, 1))
train_images, test_images = train_images / 255.0, test_images / 255.0

print(train_labels[:10])

one_hot_train_labels = tf.keras.utils.to_categorical(train_labels, 10)
one_hot_test_labels = tf.keras.utils.to_categorical(test_labels, 10)

print(one_hot_train_labels[:10])

model = tf.keras.models.Sequential()

model.add(tf.keras.layers.Conv2D(32, (3,3), activation='relu', strides=(1,1), input_shape=(28, 28, 1)))
model.add(tf.keras.layers.MaxPooling2D((2,2)))
model.add(tf.keras.layers.Conv2D(64, (3,3), activation='relu'))
model.add(tf.keras.layers.Flatten())
model.add(tf.keras.layers.Dense(64, activation='relu'))
model.add(tf.keras.layers.Dense(10, activation='softmax'))

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
labels = model.predict(test_images)
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


#### 출력
<img width="476" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/659cd7b0-aebb-43e7-bc53-9f3dd3d26fdc">

```js
[5 0 4 1 9 2 1 3 1 4]
[[0. 0. 0. 0. 0. 1. 0. 0. 0. 0.]
 [1. 0. 0. 0. 0. 0. 0. 0. 0. 0.]
 [0. 0. 0. 0. 1. 0. 0. 0. 0. 0.]
 [0. 1. 0. 0. 0. 0. 0. 0. 0. 0.]
 [0. 0. 0. 0. 0. 0. 0. 0. 0. 1.]
 [0. 0. 1. 0. 0. 0. 0. 0. 0. 0.]
 [0. 1. 0. 0. 0. 0. 0. 0. 0. 0.]
 [0. 0. 0. 1. 0. 0. 0. 0. 0. 0.]
 [0. 1. 0. 0. 0. 0. 0. 0. 0. 0.]
 [0. 0. 0. 0. 1. 0. 0. 0. 0. 0.]]
Model: "sequential_1"
_________________________________________________________________
 Layer (type)                Output Shape              Param #   
=================================================================
 conv2d_2 (Conv2D)           (None, 26, 26, 32)        320       
                                                                 
 max_pooling2d_1 (MaxPooling  (None, 13, 13, 32)       0         
 2D)                                                             
                                                                 
 conv2d_3 (Conv2D)           (None, 11, 11, 64)        18496     
                                                                 
 flatten_1 (Flatten)         (None, 7744)              0         
                                                                 
 dense_2 (Dense)             (None, 64)                495680    
                                                                 
 dense_3 (Dense)             (None, 10)                650       
                                                                 
=================================================================
Total params: 515,146
Trainable params: 515,146
Non-trainable params: 0
_________________________________________________________________
Epoch 1/2
6000/6000 [==============================] - 94s 16ms/step - loss: 0.1885 - accuracy: 0.9462
Epoch 2/2
6000/6000 [==============================] - 95s 16ms/step - loss: 0.1358 - accuracy: 0.9648
```

<img width="828" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/0c64b569-57d4-454e-81bd-5c4ed4f88f2c">

```js
최적화 완료

================================================

313/313 [==============================] - 3s 9ms/step
313/313 - 3s - loss: 0.1350 - accuracy: 0.9671 - 3s/epoch - 8ms/step
accuracy: 0.9671
```

<img width="532" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/d271ecfc-8545-4d65-b044-0cf35d1dc260">

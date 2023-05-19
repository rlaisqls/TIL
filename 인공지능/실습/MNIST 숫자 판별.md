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
train_images = train_images.reshape((60000, 28*28))
test_images = test_images.reshape((10000, 28*28))
train_images, test_images = train_images / 255.0, test_images / 255.0

print(train_labels[:10])

one_hot_train_labels = tf.keras.utils.to_categorical(train_labels, 10)
one_hot_test_labels = tf.keras.utils.to_categorical(test_labels, 10)

print(one_hot_train_labels[:10])


model = tf.keras.models.Sequential()
model.add(tf.keras.layers.Dense(input_dim=784, units=128, activation='relu'))
model.add(tf.keras.layers.Dropout(0.2))
model.add(tf.keras.layers.Dense(units=10, activation='softmax'))

model.compile(optimizer=tf.optimizers.Adam(learning_rate=0.01),loss='categorical_crossentropy', metrics=['accuracy'])

model.summary()
history = model.fit(train_images, one_hot_train_labels, epochs=1, batch_size=10)

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
for i in range(10):
  subplot = fig.add_subplot(2,5,i+1)
  subplot.set_xticks([])
  subplot.set_yticks([])
  subplot.set_title('%d' % np.argmax(labels[i]))
  subplot.imshow(test_images[i].reshape((28, 28)), cmap=plt.cm.gray_r)

plt.show()

print("\n================================================\n")

```

## Drop out

```python
...
model = tf.keras.models.Sequential()
model.add(tf.keras.layers.Dense(input_dim=784, units=128, activation='relu'))
model.add(tf.keras.layers.Dropout(0.2))
model.add(tf.keras.layers.Dense(units=10, activation='softmax'))
...
```

## 배치정규화

```python
...
model = tf.keras.models.Sequential()
model.add(tf.keras.layers.Dense(input_dim=784, units=128, activation='relu'))
# 배치 정규화 시행
model.add(tf.keras.layers.BatchNormalization())
# 정규화된 결과값에 relu 활성화 함수 적용
model.add(tf.keras.layers.Activation('relu'))
model.add(tf.keras.layers.Dense(units=10, activation='softmax'))
...
```

<img width="652" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/3fd9534e-3d02-4e7a-884c-834ff2ac623c">
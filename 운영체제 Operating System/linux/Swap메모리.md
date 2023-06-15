# 🐧 Swap 메모리

Swap 메모리란, 실제 메모리 Ram이 가득 찼지만 더 많은 메모리가 필요할때 디스크 공간을 이용하여 부족한 메모리를 대체할 수 있는 공간을 의미한다.

실제로 메모리는 아니지만, 디스크 공간을 마치 가상의 메모리처럼 사용하기 때문에 가상 메모리라고 부른다.

실제 메모리가 아닌 하드디스크를 이용하는 것이기 때문에 속도면에서는 부족할 수 있으나 성능의 제약으로 메모리가 부족한 경우엔 유용하게 사용할 수 있다.

## Swap 메모리 확인

`swapon -s` 또는 `free -h` 명령어를 통해 Swap 메모리를 확인할 수 있다.

<img src="https://user-images.githubusercontent.com/81006587/201456074-72d7bb55-2cd7-4704-a7c4-3a582aa798c9.png" height=100px/>

아직 Swap 메모리를 설정하지 않은 상태이기 때문에, Swap의 total 메모리가 0으로 뜬다.

## Swap 메모리 설정

Swap 메모리를 설정하기 위해선, 우선 Swap 메모리를 저장할 파일에 공간을 할당해준 후에 그 파일을 메모리로 쓸 것이라고 선언해줘야한다.

아래 명령어는 파일에 공간을 할당하여 파일 포맷을 바꿔준 후, swap으로 지정해주는 명령어이다.

```js
sudo fallocate -l 2G /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 시스템이 재시작 되더라도 Swap 메모리 활성화

시스템 설정 파일을 열어서 그 파일의 맨 밑부분에 swap 메모리를 default로 하도록 명령어를 추가해주면, linux 시스템을 껐다가 켜도 계속 활성화되도록 할 수 있다.

```js
sudo vi /etc/fstab 
```

```js
/swapfile swap swap defaults 0 0
```


## Swap 메모리 해제

swapoff 명령어를 사용하여 Swap 메모리를 비활성화할 수 있다.

```java
sudo swapoff swapfile
```

그 후, 스왑파일로 사용했던 파일을 제거하면 Swap 메모리를 완전히 삭제할 수 있다.

```java
sudo rm -r swapfile
```

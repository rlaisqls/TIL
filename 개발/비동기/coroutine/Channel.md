
Channel은 2개의 Coroutine 사이를 연결한 파이프라고 생각하면 된다.

이 파이프는 두 Coroutine 사이에서 정보를 전송할 수 있도록 한다.

하나의 Coroutine은 파이프를 통해서 정보를 보낼 수 있고, 다른 하나의 Coroutine은 정보를 받기위해 기다린다.

이 채널을 통한 두 Coroutine간의 커뮤니케이션은 공유메모리가 아닌, 커뮤니케이션을 통해서 이뤄진다.

### Thread는 어떻게 Communicate 할까

소프트웨어를 만들면서 Resource를 Blocking하는 작업, 예를 들면 네트워킹이나 DB를 사용하거나 아니면 계산이 필요한 작업을 할때 우리는 그 작업들을 쓰레드로 분리한다.

이 쓰레드간에 공유할 자원이 필요할때 우리는 두개의 쓰레드가 동시에 그걸 쓰거나 읽게 하지 못하도록 자원을 [lock]()한다. 이것이 흔히 쓰레드가 커뮤니케이션하는 방식이다. 하지만 이렇게하면 데드록, 레이스 컨디션 같은 이슈가 발생할 수 있다.

* 데드록: 교착상태라고도 하며 한정된 자원을 여러 곳에서 사용하려고 할때 발생

* 레이스 컨디션: 한정된 공유 자원을 여러 프로세스가 동시에 이용하기 위해 경쟁을 벌이는 현상

```kotlin
fun main(args: Array<String>) = runBlocking<Unit> {
    val channel = Channel<Int>()
    launch(coroutineContext) {
        repeat(10) { i ->
            delay(100)
            channel.send(i)
        }
        channel.close()
    }
    launch(coroutineContext) {
        for(i in chan) {
            println(i)
        }
    }
}
```

## 채널 버퍼의 타입

Channel은 여러 버퍼 타입을 통해 Coroutine과의 커뮤니케이션의 유연성을 제공한다.

### 1. Rendezvous (Unbuffered)

![image](https://github.com/rlaisqls/TIL/assets/81006587/87c25464-da85-463f-ab42-df8af98f319d)

```kotlin
val channel = Channel<Menu>(capacity = Channel.RENDEZVOUS)
```

특별한 채널 버퍼를 설정하지 않을 시 이 타입이 기본적으로 설정된다. `Rendezvous`는 버퍼가 없다. 이것이 위 예제코드에서 본 것처럼 수신측 Coroutine과 송신측 Coroutine이 모두 가능한 상태로 "모일때까지" suspend 되는 이유다.


### 2. Conflated

![image](https://github.com/rlaisqls/TIL/assets/81006587/331cff90-f0c8-4d0a-be46-42cab0fa2805)

```kotlin
val channel = Channel<Menu>(capacity = Channel.CONFLATED)
```

Conflate의 뜻은 `"융합하다"`, `"하나로 합치다"`이다.

이렇게 하면 크기가 1인 고정 버퍼가 있는 채널이 생성된다. 만약에 수신하는 Coroutine이 송신하는 Coroutine을 따라잡지 못했다면, 송신하는 쪽은 새로운 값을 버퍼의 마지막 아이템에 덮어씌운다. 수신 Coroutine이 다음 값을 받을 차례가 되면, 송신 Coroutine이 보낸 마지막 값을 받는다. 즉 송신하는 쪽은 수신측 Coroutine이 가능할때까지 기다리는게 없다는 말이다. 수신측 Coroutine은 채널 버퍼에 값이 올때까지 suspend 된다.

### 3. Buffered

![image](https://github.com/rlaisqls/TIL/assets/81006587/229ad9aa-0860-42a4-a2a9-6e9f7672d69c)

```kotlin
val channel = Channel<Menu>(capacity = 10)
```

이 모드는 고정된 크기의 버퍼를 생성한다. 버퍼는 Array 형식이다.

송신 Coroutine은 버퍼가 꽉 차있으면 새로운 값을 보내는 걸 중단한다. 수신 Coroutine은 버퍼가 빌때까지 계속해서 꺼내서 수행한다.

### 4. Unlimited

```kotlin
val channel = Channel<Menu>(capacity = Channel.UNLIMITED)
```

이 모드는 이름처럼 제한 없는 크기의 버퍼를 가진다. 버퍼는 LinkedList 형식이다.

만약에 버퍼가 소비되지 않았다면 메모리가 다 찰때까지 계속해서 아이템을 채운다. 결국엔 `OutOfMemeoryException`을 일으킬 수 있다.

송신 Coroutine은 suspend 되지않지만, 수신 Coroutine은 버퍼가 비면 suspend 된다.

---

참고
- https://proandroiddev.com/kotlin-coroutines-channels-csp-android-db441400965f
- https://www.youtube.com/watch?v=YrrUCSi72E8&t=110s
- https://en.wikipedia.org/wiki/Communicating_sequential_processes
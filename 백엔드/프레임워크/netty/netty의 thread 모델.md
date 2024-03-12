
이벤트 루프란 이벤트를 실행하기 위한 무한루프 스레드를 말한다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/513a5ad9-3cde-47ec-ad2b-a13b6730e24e)

위의 그림과 같이 객체에서 발생한 이벤트는 이벤트 큐에 입력되고 이벤트 루프는 이벤트 큐에 입력된 이벤트가 있을 때 해당 이벤트를 꺼내서 이벤트를 실행한다. 이것이 이벤트 루프의 기본 개념이다. 이벤트 루프는 지원하는 스레드 종류에 따라서 단일 스레드 이벤트 루프와 다중 스레드 이벤트 루프로 나뉜다. 이것을 [reactor pattern](../%EB%B9%84%EB%8F%99%EA%B8%B0/reactor/Reactor%20Pattern%EA%B3%BC%E2%80%85event%E2%80%85loop.md)이라 부르기도 한다.

## single thread event loop

현재는 다중 코어나 CPU를 장착한 시스템이 일반적이므로 최신 애플리케이션은 시스템 리소스를 효율적으로 활용하기 위해 정교한 멀티스레딩 기법을 이용하는 경우가 많다. 자바 초창기의 멀티스레딩 체계는 동시 작업 단위를 실행하기 위해 필요할 때마다 새로운 스레드를 만들고 시작하는 기초적인 수준이었기 때문에 부하가 심한 상황에서는 성능 저하가 심했다. 다행히 자바 5에는 Thread 캐싱과 재사용을 통해 성능을 크게 개선한 스레드 풀을 지원하는 Executor API가 도입됐다.

싱글 스레드 이벤트 루프는 말 그대로 이벤트를 처리하는 스레드가 하나인 상태를 이야기 한다. 설명하자면 다음과 같다.

- 요청된 작업(Runnable의 구현)을 실행하기 위해 풀의 가용 리스트에서 Thread하나를 선택해 할당한다.
- 작업이 완료되면 Thread가 리스트로 반환되고 재사용할 수 있게 된다.

스레드를 풀링하고 재사용하는 방식은 작업별로 스레드를 생성하고 삭제하는 방식보다 분명히 개선된 것이지만, 컨텍스트 전환 비용이 아예 사라진 것은 아니다. 이 비용은 스레드의 수가 증가하면 명백하게 드러나고 부하가 심한 상황에서는 심각한 문제가 된다. 또한 애플리케이션의 동시성 요건이나 전반적인 복잡성 때문에 프로젝트의 수명주기 동안 다른 스레드 관련 문제가 발생할 수 있다.

## multi thread event loop

다중 스레드 이벤트 루프는 이벤트를 처리하는 스레드가 여러개인 모델이다. 단일 스레드 이벤트 루프에 비해서 프레임워크의 구현이 복잡하지만, 이벤트 루프 스레드들이 이벤트 메서드를 병렬로 수행하므로 멀티 코어 CPU를 효율적으로 사용한다. 단점으로는 여러 이벤트 루프 스레드가 이벤트 큐 하나에 접근하므로 여러 스레드가 자원 하나를 공유할 때 발생하는 스레드 경합이 발생할 수 있고, 이벤트들이 병렬로 처리되므로 이벤트의 발생 순서와 실행 순서가 일치하지 않게 된다는 것이 있다.

Netty에서는 멀티 스레드 이벤트 루프의 단점인 발생 순서와 실행 순서가 일치하지 않는다는 문제를 아래와 같은 방법으로 해결한다.

![image](https://github.com/rlaisqls/TIL/assets/81006587/d8d9948d-7387-4568-a4eb-2c8d5e29ccc2)

- Netty의 이벤트는 Channel에서 발생한다.
- 각각의 이벤트 루프 객체는 개인의 이벤트 큐를 가지고 있다.
- Netty Channel은 하나의 이벤트 루프에 등록된다.
- 하나의 이벤트 루프 스레드에는 여러 채널이 등록될 수 있다.
- Channel의 라이프 사이클 동안 모든 동작은 하나의 thread에서 처리되게 된다.

멀티 스레드 이벤트 모델에서 이벤트의 실행 순서가 일치하지 않는 이유는 루프들이 이벤트 큐를 공유하기 때문이다. Netty는 이벤트 루프 스레드마다 개인의 이벤트 큐를 가짐으로써, 해당 이벤트를 처리하는 스레드가 지정하도록 하기 때문에 공유된 하나의 이벤트 큐에 스레드들이 접근하지 않게 된다.

## EventLoop 인터페이스

연결의 수명기간 동안 발생하는 이벤트를 처리하는 작업을 실행하는 것은 네트워킹 프레임워크의 기본 기능이다. 이를 나타내는 프로그래밍 구조를 이벤트 루프(event loop)라고 하는데, 네티에서도 `io.netty.channel.EventLoop` 인터페이스에 이를 적용했다.

네티의 EventLoop는 동시성과 네트워킹의 두 가지 기본 API를 활용해 설계됐다.

1. `io.netty.util.concurrent` 패키지는 JDK 패키지인 `java.util.concurrent`에 기반을 두는 스레드 실행자를 제공한다.
2. `io.netty.channel` 패키지의 클래스는 Channel이벤트와 인터페이스를 수행하기 위해 이러한 API를 확장한다.

이 모델에서 EventLoop는 변경되지 않는 Thread 하나로 움직이며, 작업을 EventLoop구현으로 직접 제출해 즉시 또는 예약 실행할 수 있다. 구성과 사용 가능한 코어에 따라서는 리소스 활용을 최적화하기 위해 여러 EventLoop가 생성되고 여러 Channel에 서비스를 제공하기 위해 단일 EventLoop가 할당되는 경우도 있다.

네티의 EventLoop는 변경되지 않는 Thread 하나로 움직이며, 작업(Runnable 또는 Callable)을 EventLoop 구현으로 직접 제출해 즉시 또는 예약 실행할 수 있따. 구성과 사용 가능한 코어에 따라서는 리소스 활용을 최적화하기 위해 여러 EventLoop가 생성되고, 여러 Channel에 서비스를 제공하기 위해 단일 EventLoop가 할당되는 경우도 있다.

네티의 EventLoop는 `ScheduledExecutorService`를 확장하며, `parent()` 라는 메서드 하나만 정의한다. 이 메서드는 다음 코드에 나오는 것처럼 현재 EventLoop구현 인스턴스가 속한 EventLoopGroup의 참조를 반환하기 위한 것이다.

```java
public interface EventGroup extends EventExecutor, EventLoopGroup {
    @Override
    EventLoopGroup parent();
}
```

네티4의 모든 입출력 작업과 이벤트는 EventLoop에 할당된 Thread에 의해 처리된다.

## EventLoop를 이용한 작업 스케줄링

`ScheduledExecutorService`구현은 풀 관리 작업의 일부로 스레드가 추가로 생성되는 등의 한계점을 가지고 있으며, 이 때문에 많은 작업을 예약할 경우 병목 현상이 발생할 수 있다.

**EventLoop를 이용한 작업 예약**

```java
Channel ch = ...;
ScheduledFuture<?> future = ch.eventLoop().schedule(
    new Runnable() {
        @Override
        public void run()
        {
            System.out.println("60 seconds later");
        }
    }, 60, TimeUnit.SECONDS
);
```

**EventLoop를 이용한 반복 작업 예약**

```java
Channel ch = ...
ScheduledFuture<?> future = ch.eventLoop().scheduleAtFixedRate(
    new Runnable() {
        @Override
        public void run()
        {
            System.out.println("Run every 60 seconds");
        }
    }, 60, 60, TimeUnit.Seconds
);
```

**SchedueldFuture를 이용한 작업 취소**

```java
ScheduledFuture<?> future = ch.eventLoop().scheduleAtFixedRate(...);
boolean mayInterruptIfRunning = false;
future.cancel(mayInterruptIfRunngin);
```

# 스레드 관리

네티 스레딩 모델이 탁월한 성능을 내는 데는 현재 실행중인 Thread의 ID를 확인하는 기능, 즉 Thread가 현재 Chanenl과 해당 EventLoop에 할당된 것인지 확인하는 기능이 중요한 역할을 한다.(EventLoop는 수명주기 동안 Channel하나의 모든 이벤트를 처리한다.)

호출 Thread가 EventLoop에 속하는 경우 해당 코드 블록이 실행되며, 그렇지 않으면 EventLoop이 나중에 실행하기 위해 작업을 예약하고 내부 큐에 넣는다. EventLoop는 다음 해당 이벤트를 처리할 떄 큐에 있는 항목을 실행한다. Thread가 ChannelHandler를 도익화 하지 않고도 Chanel과 직접 상호작용할 수 있는 것은 이런 작동 방식 때문이다.

장기 실행 작업은 실행 큐에 넣지 않아야 하며, 그렇지 않으면 동일한 스레드에서 다른 작업을 실행할 수 없게 된다. 블로킹 호출을 해야하거나 장기 실행 작업을 실행해야 하는 경우 전용 EventExecutor를 사용하느 것이 좋다.

###  EventLoop와 스레드 할당

Channel에 이벤트와 입출력을 지원하는 EventLoop는 EventLoopGroup에 포함된다. EventLoop가 생성 및 할당되는 방법은 전송의 구현에 따라 다르다.

- 비동기 전송
    - 비동기 구현은 적은 수의 EventLoop를 이용하며, 현재 모델에서는 이를 여러 Channel에서 공유할 수 있다. 덕분에 Channel마다 Thread를 할당하지 않고 최소한의 Thread로 다수의 Chanenl을 지원할 수 있다.
    - Channel은 EventLoop가 할당되면 할당된 EventLoop를 수명주기 동안 이용한다. 덕분에 ChannelHandler 구현에서 동기화와 스레드 안정성에 대해 걱정할 필요가 없다.
    - 또한 ThreadLocal 이용을 위한 EventLoop 할당의 영향도 알아야 한다. 일반적으로 EventLoop하나가 둘 이상의 Channel에 이용되므로 **ThreadLocal은 연결된 모든 Channel에서 동일하다.** 즉, 상태 추적과 같은 기능을 구현하는 데는 적합하지 않지만 상태 비저장 환경에서는 여러 Channel에서 대규모 객체 또는 고비용 객체나 이벤트를 공유하는데 유용할 수 있다.
- 블로킹 전송
    - 각 Channel에 한 EventLoop가 할당된다. 그러나 이전과 마찬가지로, 각 Channel의 입출력 이벤트는 한 Thread에 의해 처리된다.

---
참고
- [네티 인 액션 : Netty를 이용한 자바 기반의 고성능 서버 & 클라이언트 개발](https://m.yes24.com/Goods/Detail/25662949)
- https://netty.io/wiki/thread-model.html
- https://medium.com/@akhaku/netty-data-model-threading-and-gotchas-cab820e4815a
- https://livebook.manning.com/book/netty-in-action/chapter-7/27
- https://shortstories.gitbook.io/studybook/netty/c774_bca4_d2b8_baa8_b378
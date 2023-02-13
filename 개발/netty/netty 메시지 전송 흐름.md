# netty 메시지 전송 흐름

<img src="https://user-images.githubusercontent.com/81006587/218373375-e1660f25-adf4-4c4a-9aa3-93cfec8eef46.png" height=300px>

1. `Channel`을 통해 메시지 전송을 요청한다.

```java
Channel channel = ...
channel.writeAndFlush(message); 
```

2. Channel은 `ChannelPipeline`으로 메시지를 전달한다. 

- ChannelPipeline은 기본적으로 `TailContext`와 `HeadContext`를 가진다. (Pipeine의 시작과 끝이라 할 수 있다.)
- Tail과 Head 사이에는 사용자가 등록한 ChannelHandlerContext가 체인 구조로 연결되고, 전달된 메시지가 체인을 따라 Outbound 방향으로 흘러간다.

3. ChannelPipeline이 메시지가 각각의 Handler를 거칠 때 마다, **Handler에게 바인딩된 EventExecutor 쓰레드**와 현재 **메시지 전송을 요청하고 있는 쓰레드**가 동일한지 체크한다. 

- 만약 서로 다른 쓰레드라면(Handler의 EventExecutor가 아니라면) **메시지를 Queue에 삽입하고 그대로 실행을 반환한다.**
- Queue에 쌓인 메시지는 이후에 EventExecutor에 의해 비동기적으로 처리되게 된다.
- Pipeline의 첫 ChannelHandlerContext에서는 **항상** 요청 쓰레드와 EventExecutor가 다르게 되고 메시지가 Queue에 쌓인다.

```java
abstract class AbstractChannelHandlerContext ... {
    private void write(Object msg, boolean flush, ChannelPromise promise) {
    	...
        EventExecutor executor = next.executor();
        if (executor.inEventLoop()) {
            if (flush) {
                next.invokeWriteAndFlush(m, promise);
            } else {
                next.invokeWrite(m, promise);
            }
        } else {
            final WriteTask task = WriteTask.newInstance(next, m, promise, flush);
            if (!safeExecute(executor, task, promise, m, !flush)) {
                task.cancel();
            }
        }
        ... 
    }
}
```

4. 만약 사용자가 별도의 EventExecutor를 설정하지 않았다면(기본 설정) 모든 Handler는 Channel의 EventLoop 쓰레드를 공유해서 사용하게 된다. 그러으로 Pipeline의 Tail 외에는 Queue에 메시지가 버퍼링되는 일이 일어나지 않는다. 
- 반면에 사용자가 특정 Handler의 EventExecutor를 설정해주었다면, Executor가 달라지는 Handler에서는 Queue에 메시지가 버퍼링 된 후 서로 다른 EventExecutor에 의해 메시지가 비동기적으로 처리되게 된다. 

```java
abstract class AbstractChannelHandlerContext ... {
    public EventExecutor executor() {
        if (executor == null) {
            return channel().eventLoop();
        } else {
            return executor;
        }
    }
}
```

<img src="https://user-images.githubusercontent.com/81006587/218383017-f15474b8-ba22-4b65-9b94-39467096e6e8.png" height=200px>

5. Pipeline을 통과한 메시지는 다시 Channel로 전달된다.

6. Netty Channel은 내부적으로 NIO 채널을 통해 네트워크로 메시지를 전송한다.

```java
public class NioSocketChannel ... {
    protected void doWrite(ChannelOutboundBuffer in) throws Exception {
        SocketChannel ch = javaChannel();
        ... 
        ByteBuffer buffer = nioBuffers[0];
        int attemptedBytes = buffer.remaining();
        final int localWrittenBytes = ch.write(buffer);
        if (localWrittenBytes <= 0) {
            incompleteWrite(true);
            return;
        }
        ...
    }
}
```

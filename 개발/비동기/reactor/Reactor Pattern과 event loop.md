# Reactor Pattern과 event loop

Reactor 패턴은 동시에 들어오는 여러 종류의 이벤트를 처리하기 위한 동시성을 다루는 디자인 패턴 중 하나이다. Reactor 패턴은 관리하는 리소스에서 이벤트가 발생할 때까지 대기하다가 이벤트가 발생하면 해당 이벤트를 처리할 수 있는 핸들러(`handler`)에게 디스패치(`dispatch`)하는 방식으로 이벤트에 반응하며, '이벤트 핸들링(event handling)', event loop 패턴이라고도 부른다.

Reactor 패턴은 크게 Reactor와 핸들러로 구성된다.

|name|description|
|-|-|
|Reactor|무한 반복문을 실행해 이벤트가 발생할 때까지 대기하다가 이벤트가 발생하면 처리할 수 있는 핸들러에게 디스패치한다. 이벤트 루프라고도 부흔다.|
|Handler|이벤트를 받아 필요한 비즈니스 로직을 수행한다.|

간단한 동작을 나타내는 예제 코드를 확인해보자.

물론 세부적인 구현은 상황에 맞게 변경할 수 있다. 세부 구현 내용에 초점을 맞추기보다는 리소스에서 발생한 이벤트를 처리하기까지의 과정과, 그 과정에서 Reactor와 핸들러가 어떤 역할을 하는지 이해해보자.

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.util.Set;
  
public class Reactor implements Runnable {
    final Selector selector;
    final ServerSocketChannel serverSocketChannel;
  
    Reactor(int port) throws IOException {
        selector = Selector.open();
  
        serverSocketChannel = ServerSocketChannel.open();
        serverSocketChannel.socket().bind(new InetSocketAddress(port));
        serverSocketChannel.configureBlocking(false);
        SelectionKey selectionKey = serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);
  
        // Attach a handler to handle when an event occurs in ServerSocketChannel.
        selectionKey.attach(new AcceptHandler(selector, serverSocketChannel));
    }
  
    public void run() {
        try {
            while (true) {
                // Selector에서 이벤트가 발생하기까지 대기하다가
                // 이벤트가 발생하는 경우 적절한 핸들러에서 처리할 수 있도록 dispatch한다.
                selector.select();
                Set<SelectionKey> selected = selector.selectedKeys();
                for (SelectionKey selectionKey : selected) {
                    dispatch(selectionKey);
                }
                selected.clear();
            }
        } catch (IOException ex) {
            ex.printStackTrace();
        }
    }
  
    void dispatch(SelectionKey selectionKey) {
        Handler handler = (Handler) selectionKey.attachment();
        handler.handle();
    }
}
```

```java
public interface Handler {
    void handle();
}
```

```java
import java.io.IOException;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
  
class AcceptHandler implements Handler {
    final Selector selector;
    final ServerSocketChannel serverSocketChannel;
  
    AcceptHandler(Selector selector, ServerSocketChannel serverSocketChannel) {
        this.selector = selector;
        this.serverSocketChannel = serverSocketChannel;
    }
  
    @Override
    public void handle() {
        try {
            final SocketChannel socketChannel = serverSocketChannel.accept();
            if (socketChannel != null) {
                new EchoHandler(selector, socketChannel);
            }
        } catch (IOException ex) {
            ex.printStackTrace();
        }
    }
}
```

```java
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
  
public class EchoHandler implements Handler {
    static final int READING = 0, SENDING = 1;
  
    final SocketChannel socketChannel;
    final SelectionKey selectionKey;
    final ByteBuffer buffer = ByteBuffer.allocate(256);
    int state = READING;
  
    EchoHandler(Selector selector, SocketChannel socketChannel) throws IOException {
        this.socketChannel = socketChannel;
        this.socketChannel.configureBlocking(false);
        // Attach a handler to handle when an event occurs in SocketChannel.
        selectionKey = this.socketChannel.register(selector, SelectionKey.OP_READ);
        selectionKey.attach(this);
        selector.wakeup();
    }
  
    @Override
    public void handle() {
        try {
            if (state == READING) {
                read();
            } else if (state == SENDING) {
                send();
            }
        } catch (IOException ex) {
            ex.printStackTrace();
        }
    }
  
    void read() throws IOException {
        int readCount = socketChannel.read(buffer);
        if (readCount > 0) {
            buffer.flip();
        }
        selectionKey.interestOps(SelectionKey.OP_WRITE);
        state = SENDING;
    }
  
    void send() throws IOException {
        socketChannel.write(buffer);
        buffer.clear();
        selectionKey.interestOps(SelectionKey.OP_READ);
        state = READING;
    }
}
```

## 다양한 event loop 구현체

### Netty

> Netty is an asynchronous event-driven network application framework for rapid development of maintainable high performance protocol servers & clients. Netty is a NIO client server framework which enables quick and easy development of network applications such as protocol servers and clients. It greatly simplifies and streamlines network programming such as TCP and UDP socket server.

Netty는 비동기식 이벤트 기반 네트워크 애플리케이션 프레임워크이다. Netty 자체로도 많이 사용하지만 고성능 네트워크 처리를 위해 Armeria를 포함해서 [정말 많은 프레임워크나 라이브러리](https://netty.io/wiki/related-projects.html)에서 사용되고 있다. 이와 같은 Netty도 기본적으로는 지금까지 살펴본 Java NIO의 Selector와 Reactor 패턴을 기반으로 구현돼 있다.

### node.js

> Node.js is a JavaScript runtime built on Chrome's V8 JavaScript engine.

JavaScript 런타임 환경을 제공하는 Node.js에도 이벤트 루프가 있다. 정확히는 Node.js에서 사용(참고)하는 libuv 라이브러리가 이벤트 루프를 제공한다. libuv는 비동기식 I/O를 멀티 플랫폼 환경에서 제공할 수 있도록 만든 라이브러리이다. 내부적으로 멀티플렉싱을 위해 epoll, kqueue, IOCP(input/output completion port)를 사용하고 있다.

### Redis

> The open source, in-memory data store used by millions of developers as a database, cache, streaming engine, and message broker.

Redis는 이벤트 처리를 위해 자체적으로 이벤트 루프(참고)를 구현해서 사용하는 싱글 스레드 애플리케이션이다.

```c
typedef struct aeEventLoop{
    int maxfd;
    long long timeEventNextId;
    aeFileEvent events[AE_SETSIZE]; /* Registered events */
    aeFiredEvent fired[AE_SETSIZE]; /* Fired events */
    aeTimeEvent *timeEventHead;
    int stop;
    void *apidata; /* This is used for polling API specific data */
    aeBeforeSleepProc *beforesleep;
} aeEventLoop;
```

---
참고
- https://en.wikipedia.org/wiki/Reactor_pattern
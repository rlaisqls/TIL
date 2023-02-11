# netty server 예제

클라이언트의 입력을 그대로 응답으로 돌려주는 서버를 Netty 프레임워크로 구현하고 이해해보자.

### 메인 클래스

```kotlin
class EchoServer {
    
    private val allChannels: ChannelGroup = DefaultChannelGroup("server", GlobalEventExecutor.INSTANCE)
    private var bossEventLoopGroup: EventLoopGroup? = null
    private var workerEventLoopGroup: EventLoopGroup? = null

    fun startServer() {

        // (1)
        bossEventLoopGroup = NioEventLoopGroup(1, DefaultThreadFactory("boss"))
        workerEventLoopGroup = NioEventLoopGroup(1, DefaultThreadFactory("worker"))

        // (2)
        val bootstrap = ServerBootstrap()
        bootstrap.group(bossEventLoopGroup, workerEventLoopGroup)

        // Channel 생성시 사용할 클래스 (NIO 소켓을 이용한 채널)
        bootstrap.channel(NioServerSocketChannel::class.java)

        // accept 되어 생성되는 TCP Channel 설정
        bootstrap.childOption(ChannelOption.TCP_NODELAY, true)
        bootstrap.childOption(ChannelOption.SO_KEEPALIVE, true)

        // (3)
        // Client Request를 처리할 Handler 등록
        bootstrap.childHandler(EchoServerInitializer())

        // (4)
        try {
            // Channel 생성후 기다림
            val bindFuture = bootstrap.bind(InetSocketAddress(SERVER_PORT)).sync()
            val channel: Channel = bindFuture.channel()
            allChannels.add(channel)

            // Channel이 닫힐 때까지 대기
            bindFuture.channel().closeFuture().sync()
        } catch (e: InterruptedException) {
            throw RuntimeException(e)
        } finally {
            close()
        }
    }

    private fun close() {
        allChannels.close().awaitUninterruptibly()
        workerEventLoopGroup!!.shutdownGracefully().awaitUninterruptibly()
        bossEventLoopGroup!!.shutdownGracefully().awaitUninterruptibly()
    }

    companion object {
        private const val SERVER_PORT = 8080

        @Throws(Exception::class)
        @JvmStatic
        fun main(args: Array<String>) {
            EchoServer().startServer()
        }
    }
}
```

netty TCP 서버를 생성하기 위해서는 다음 과정을 수행해야한다.

- (1) EventLoopGroup을 생성
  - `NIO` 기반의 `EventLoop`를 생성해서, 비동기처리할 수 있도록 헀다. `bossEventLoopGroup`은 서버 소켓을 listen하고, `workerEventLoopGroup`은 만들어진 Channel에서 넘어온 이벤트를 처리하는 역할을 할 것이다. 각각 1개의 쓰레드를 할당해줬다.

- (2) ServerBootstrap을 생성하고 설정
  - netty 서버를 생성하기 위한 헬퍼 클래스인 ServerBootstrap 인스턴스를 만들어준다.
  - 우선 만들어둔 EventLoopGroup을 `group()` 메서드로 세팅해주고, 채널을 생성할 때 NIO 소켓을 이용한 채널을 생성하도록 `channel()` 메소드에 `NioServerSocketChannel.class`를 인자로 넘겨준다.
  - 그리고 TCP 설정을 `childOption()`으로 설정해준다. `TCP_NODELAY`, `SO_KEEPALIVE` 설정이 이 서버 소켓으로 연결되어 생성되는 connection에 적용될 것이다.

- (3) ChannelInitializer 생성
  - 채널 파이프라인을 설정하기 위해 `EchoServerInitializer` 객체를 할당한다. 서버 소켓에 연결이 들어오면 이 객체가 호출되어 소켓 채널을 초기화해준다.

- (4) 서버 시작
  - 마지막으로 bootstap의 `bind()` 메서드로 서버 소켓에 포트를 바인딩한다. `sync()` 메서드를 호출해서 바인딩이 완료될 때까지 기다리고, 서버가 시작된다.

### 서버의 채널 파이프라인을 정의하는 클래스

```java
class EchoServerInitializer : ChannelInitializer<SocketChannel>() {

    @Throws(Exception::class)
    override fun initChannel(ch: SocketChannel) {
        val pipeline: ChannelPipeline = ch.pipeline()
        pipeline.addLast(LineBasedFrameDecoder(65536))
        pipeline.addLast(StringDecoder())
        pipeline.addLast(StringEncoder())
        pipeline.addLast(EchoServerHandler())
    }
}
```

`initChannel()` 메서드의 역할은 채널 파이프라인을 만들어주는 것이다. TCP 연결이 accept 되면 이 파이프라인을 따라 각 핸들러에 해당하는 동작이 수행된다.

inbound와 Outboud 핸들러가 섞여있는 것을 볼 수 있는데, 채널에 이벤트(메시지)가 발생하면 소켓 채널에서 읽어들이는 것인지 소켓 채널로 쓰는 것인지에 따라서 파이프라인의 핸들러가 수행된다.

이 파이프라인에서는 `LineBasedFrameDecoder()`를 통해 네트워크에서 전송되는 바이트 값을 읽어 라인 문자열로 만들어주고, 필요하다면 디코딩을 한 다음 `EchoServerHandler`를 호출해준다. 이후 `write()`가 되면 `StringEncoder()`를 통해 네트워크 너머로 데이터를 전송하게 된다.

채널이 생성될때마다 호출되는 메서드이기 때문에, 이 코드에서는 각 핸들러 메서드의 객체가 매번 새로 생성된다. 원한다면 핸들러 객체를 싱글톤으로 해서 공유하도록 할 수 있다. (물론 그렇게 하면 클래스를 무상태로 설계해야한다.)

마지막에 추가한 `EchoServerHandler`는 우리가 정의할 클래스이고, 나머지는 네티에 정의되어있는 코덱이다. (`io.netty.handler.codec`)

### 클라이언트로부터 메시지를 받았을때 처리할 클래스

```kotlin
class EchoServerHandler : ChannelInboundHandlerAdapter() {

    override fun channelRead(
        ctx: ChannelHandlerContext,
        msg: Any
    ) {
        val message = msg as String
        val channel = ctx.channel()
        channel.writeAndFlush("Response : '$message' received\n")
        if ("quit" == message) {
            ctx.close()
        }
    }
}
```

전달받은 msg를 가지고 원하는 값으로 변환해서 `writeAndFlush()` 해주면 클라이언트에게 그 데이터를 그대로 반환한다.

<img src="https://user-images.githubusercontent.com/81006587/218368972-245a5bcb-493a-4a01-bd37-89d612b739f7.png" height="200px">
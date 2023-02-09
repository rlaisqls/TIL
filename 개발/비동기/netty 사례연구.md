
파일을 업로드하면 그 파일을 순간 공유할 수 있도록 하는 플랫폼이 있다고 해보자. 그 파일 자체는 아마존 S3에 저장된다.

간단한 업로드 흐름을 구축하자면 아래와 같이 할 수 있다.

1. 전체 파일을 수신한다. 
2. S3로 업로드한다.
3. 이미지인 경우 섬네일을 생성한다.
4. 클라이언트 애플리케이션에 응답한다.

여기에서는 2단계와 3단계가 병목 지점이 될 수 있다. 클라이언트에서 서버로 아무리 빠른 속도로 업로드하더라도 실제 드롭을 생성하고 클라이언트에 응답하려면 업로드가 완료된 후 파일을 S3로 업로드라고 섬네일을 생성할 때까지 오랫동안 기다려야했다. 파일이 클수록 대기 시간은 길었고, 아주 큰 파일의 경우 서버로부터 응답을 기다리다가 시간이 만료되는 경우도 있다.

업로드 시간을 줄이기 위한 두가지 다른 방법이 고안됐다.

- A 낙관적이지만 간단한 방법
  1. 전체 파일을 수신한다. 
  2. 파일을 로컬 파일 시스템에 저장하고 (클라이언트-서버 스트리밍) 클라이언트에는 즉시 성공했다고 보고한다.
  3. S3로 파일 업로드를 예약한다.

이 방법의 맹점은, S3에 파일업로드가 성공했는지 성공하지 않았는지 알 수 없다는 것이다. 사용자는 업로드된 이미지의 위치를 알 수 없거나, 이미지가 실제로 있는지 없는지 모르는 임시 URL만을 가질 수 있다.

파일을 S3로 푸시하기 전까지 임시로 제공할 시스템을 마련하는 방법이 있지만 그 방법에도 파일 손실이나 클러스터간 동기화 문제가 문제가 있어 해결하기 어렵다.. 

- B 복잡하지만 안전한 방법
  1. 클라이언트에서 S3로 실시간으로 업로드르 파이프한다. (클라이언트-서버-S3 스트리밍)

이 방법을 구현하려면 전체 프로세스를 세부적으로 제어해야한다. 자세히 얘기하자면 다음과 같은 기능이 필요하다.

```
1. 클라이언트로부터 업로드를 수신하는 동안 S3에 연결한다.
2. 클라이언트 연결에서 S3 연결로 데이터를 파이프한다.
3. 두 연결에 버퍼와 스로틀을 적용한다.
  - 버퍼링은 클라이언트-서버-S3 업로드 간에 안정적인 흐름을 유지하는 데 필요하다.
  - 스로틀은 서버-S3 업로드 단계가 클라이언트 -서버 업로드 단계보다 느릴 경우 과도한 메모리 소비를 예방하는 데 필요하다.
4. 문제가 발생한 경우 모든 작업을 깔끔하게 롤백한다.
```

개념상으로는 간단하지만 보통 웹 서버로 해결 가능한 수준의 기능이 아니다. 특히 TCP 연결에 스로틀을 적용하려면 해당 소켓에 대한 저수준 접근이 필요하다. 또한, 지연 섬네일 생성이라는 새로운 개념이 필요하므로 최종 아키텍처의 형태를 근본적으로 다시 고려해야했다.

즉, 최상의 성능과 안정성을 가지고 있으면서도 바이트 단위의 저수준을 제어할 수 있는 유연성을 가진 기술이 필요했다. 그래서 이 경우 netty를 사용해서 문제를 해결할 수 있다.

```java
pipelineFactory = new ChannelPipelineFactory() {
    @Override
    public ChannelPipeline getPipeline() throw Exception {
        ChannelPipeline pipeline = Channels.pipeline();
        pipeline.addLast("idleStateHandler", new IdleStateHandler(...)); // IdelStateHandler가 비활성 연결을 종료
        pipeline.addLast("httpServerCodec", new HttpServerCodec()); // HttpServerCodec이 오가는 데이터를 직렬화, 역직렬화 
        pipeline.addLast("requestController", new RequestController(...)); // RequestController를 파이프라인에 추가
        return pipeline;
    }
}
```

```java
public class RequestController extends IdleStateAwareChannelUpstreamHandler {

    @Override
    public void channelIdle(ChannelHandlerContext ctx, IdelStateEvent e) throws Exception {
        // 클라이언트에 대한 연결을 닫고 모든 항목을 롤백함
    }

    @Override
    public void channelConnected(ChannelHandlerContext ctx, ChannelStateEvent e) throws Exception {
        if (!acquireConnectoinSlot()) {
            // 허용하는 최대 서버 연결 횟수에 도달함
            // 503 service nuavaliablefh 응답하고 연결 종료
        } else {
            // 연결의 요청 파이프라인을 설정함
        }
    }

    @Override
    public void messageReceived(ChannelHandlerContext ctx, MessageEvent e) throws Exception {
        if (isDone()) return;

        if (e.getMessage() instanceof HttpRequest) {
            handlerHttpRequest((HttpRequest) e.getMessage()); // 서버 요청 유효성 검사의 핵심 사항
        } else if (e.getMessage() instanceof HttpChunk) {
            handleHttpChunk((HttpChunk)e,getMessage()); // 현재 요청에 대한 황성 핸들러가 청크를 수락하는 경우 청크 전달
        }
    }
}
```

이런식으로 구현헀다고 한다.

> 근데 여기서 클라이언트에서 서버를 거치지 않고, s3에 바로 파일을 넣을 수 있도록 하면 서버에 가는 부하는 최적으로 줄일 수 있지 않을까?
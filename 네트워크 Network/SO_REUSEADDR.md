# SO_REUSEADDR 옵션은 무슨 의미일까?

> SO_REUSEADDR Specifies that the rules used in validating addresses supplied to bind() should allow reuse of local addresses, if this is supported by the protocol. This option takes an int value. This is a Boolean option

`SO_REUSEADDR`를 true로 설정한다는 것은, TIME_WAIT 상태의 주소에 바인딩할 수 있도록 한다는 의미이다. 특정 포트의 소켓이 사용 중인 경우(TIME_WAIT 상태)라도 커널에 사용 가능이라고 알려서 reuse할 수 있도록 하는 것이다. 정말 간단하게 예를 들자면, 내 컴퓨터에 8080 포트가 이미 열려있더라도 같은 8080 포트를 listen하는 process를 또 시작할 수 있게 한다는 의미이다.

이 옵션은 어떤 애플리케이션을 빠르게 종료했다가 다시 시작해야하는 경우에 특히 유용하다.

TCP 연결의 마지막 과정은 필요한 데이터를 모두 전송했으니, 더 이상 패킷을 전송하지 않겠다! 라고 약속하는 `FIN` 패킷(보통 서버가 보냄)과 `FIN_ACK` 패킷(보통 클라이언트가 보냄_을 전송하는 것이다. 그렇기 때문에 요청을 처리할 서버 애플리케이션이 내려갔다고 하더라도, `FIN_ACK`를 받기 위해 커널이 해당 소켓(포트)을 잠시 점유하고 있어야 한다.

이 때 만약 애플리케이션을 닫은 다음 바로 다시 시작하려고 하면, 해당 port가 이미 binding 되어있다는 이유로 실패하게 될 것이다. 이렇게 되면 이전에 있던 애플리케이션이 내려갔지만, 소켓을 점유하고 있는 동안은 사용자의 요청을 전혀 처리할 수 없게 된다. 하지만 `SO_REUSEADDR`를 설정하면 포트를 동일하게 사용할 수 있기 때문에 새 애플리케이션을 조금 더 빨리 시작할 수 있다.

이 밖에도 두 개 이상의 IP 주소를 갖는 호스트에서 IP 주소별로 서버를 운용할 경우에도 이 옵션을 사용하면 사용 중인 포트에 대해서도 소켓을 성공적으로 주소에 연결(bind)할 수 있다. 멀티캐스팅 응용 프로그램이 동일한 포트를 사용할 때도 이 옵션을 활용한다.

### 주의할 점

SO_REUSE ADDR을 설정하는 것은, 약간의 모호함을 동반한다. TCP packet의 header가 완전히 unique한 것이 아니어서 그 패킷이 이미 죽은 listener를 향한 패킷인지, 아니면 새 listene를 향한 메시지인지 완전히 구분하는 것이 힘들기 때문이다.

보통은 패킷이 동일한 연결에 속한것인지 확인하기 위해 `4-Tuple`(송신/수신 IP 주소, 포트번호)를 사용하지만, 중복 패킷이 오거나 요청이 같은 튜플로 여러개 들어오면 식별이 불가능해져서 일부 정보가 제대로 처리되지 못할 수도 있다.

결국 TIME_WAIT(애플리케이션은 죽었지만 포트를 점유중인 상태) 기간동안 기다리느냐, 혹은 일부 데이터를 lost할 가능성을 감당하느냐 사이의 선택이 되는데, 대부분의 서버 프로그램은 수신 연결을 놓치지 않도록 서버를 즉시 복구하는 것이 좋다고 판단하고 이러한 위험을 감수하는 경우가 많다고는 한다. (패킷이 손실되는 경우가 매우 드물기도 하다.)

Nginx Blue/Green 배포같은거 사용하면 port reuse 설정을 할 필요 없이 더 효율적인 무중단 배포를 할 수 있곘지만, 패킷 구분에 있어서는 동일한 문제가 발생하긴 할 것 같다.


---
 
참고

- http://www.unixguide.net/network/socketfaq/4.11.shtml
- https://stackoverflow.com/questions/3229860/what-is-the-meaning-of-so-reuseaddr-setsockopt-option-linux
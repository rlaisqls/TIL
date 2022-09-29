
# 📡 Ethernet
<p>이더넷(Ethernet)이란 CSMA/CD라는 프로토콜을 사용해 네트워크에 연결된 각 기기들이 하나의 전송 매체를 통해 인터넷 망에 접속해 통신할 수 있도록 하는 네트워크 방식이다.</p>
<p>CSMA/CD란 Carrier Sense Multiple Access / Collision Detection의 약자로, 다중 접속(콜리전)이 생겼을때 그것을 감지해 대기 후 재전송하는 것을 뜻한다. 즉, 네트워크 상의 데이터 신호들을 감지하다 두 개 이상의 PC가 서로 데이터를 보내다가 충돌이 발생하면 임의의 시간동안 기다린 후 다시 데이터를 보낸다. 따라서 CSMA/CD라는 프로토콜을 사용하는 이더넷이라는 네트워킹 방식은 네트워크상에 하나의 데이터만 오고 갈 수 있다는 특징이 있다.</p>
<p>과거에 쓰이던 Token ring을 대체하여, 현재는 LAN, MAN 및 WAN에서 가장 많이 쓰이는 방식이다.</p>
<br>

<img src="https://m1.daumcdn.net/cfile245/image/2268BA4C57130B423072AC" height=240px width=390px>

<br>

# 📡 Token ring
<p>Token ring 이란 네트워크 안에서 링 속에서 토큰을 가진 하나의 장치만이 네트워크에 데이터를 실어 보낼 수 있는 방식이다. 토큰 링에는 여러 컴퓨터가 연결되어있고, 토큰을 가지고 있는 컴퓨터가 데이터를 다 보냈거나 전송할 데이터가 없을 경우 옆 PC에게 토큰을 전달하며 전송매체 하나로 각 기기들이 모두 인터넷 망에 접속해있는 것과 같은 구조를 구현한다.</p>
<p>토큰을 가지고 있는 컴퓨터만 요청할 수 있기 때문에 콜리전이 발생하지 않지만, 요청할 일이 생겨도 토큰을 넘겨받을 때는 까지 무조건 대기해야 하기 때문에 지연이 생긴다는 단점이 있다. </p>

<br>

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Token_ring.png/800px-Token_ring.png" height=250px width=550px>

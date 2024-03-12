
HTTP는 Hypertext Transfer Protocol의 약어이다. Hypertext 즉, HTML을 전송하는 통신 프로토콜을 의미하는 것이다.

그리고, HTTPS의 약자는 Hypertext Transfer Protocol Secure이다. 간단하게 말하자면 HTML통신 규약이긴한데 그게 안전하게 이루어진다는 것이다. HTTPS에는 TLS라는 프로토콜이 함께 사용되어, 사용자의 인증 과정을 추가로 거치게 된다.

![image](https://user-images.githubusercontent.com/81006587/216963905-420674e8-3330-4adb-b93e-4f0425edd095.png)

## TLS

TLS는 Transport Layer Security의 약자로, 컴퓨터 네트워크를 통해 통신 보안을 제공하도록 설계된 암호화 프로토콜이다. 통신을 하는 과정에서 도청, 간섭, 위조를 막을 수 있도록 암호 코드를 교환하고 인증하는 절차를 거치도록 한다.TLS 위에서 HTTP가 동작하면 HTTPS가 되고, FTP가 동작하면 SFTP가 된다. (즉, 꼭 HTTPS만을 위한 것은 아니다.)

[TLS](https://en.wikipedia.org/wiki/Comparison_of_TLS_implementations)에도 여러 구현이 있다.

HTTPS를 얘기할떄 SSL라는 용어를 사용하기도 한다. 원래 처음 HTTPS가 만들어졌을때는 Netscape Communications가 개발한 SSL(Secure Sockets Layer)가 사용되었었는데, IETF(Internet Engineering Task Force)에서 표준으로 TLS를 다시 정의하면서 이제는 사용되지 않게 된 구버전이다. 하지만 TLS가 SSL을 계승받아서 만들어진 것이니 개념은 거의 비슷하다고 볼 수 있다.

## 장단점

공개키 암호화 방식과 대칭키 암호화 방식을 같이 사용하여 덕분에 보안상 안전하다는 장점이 있지만, 인증서 유지 비용이 들고 암호화, 복호화 과정 때문에 HTTP에 비해서 느리다는 단점이 있다.

## 보안적 특성

패킷이 암호화되어 송수신 되므로 정보탈취 부분에서는 강하다. 기밀성이 우선이므로 **스니핑 공격(sniffing attack)**에서 뛰어난 보안성을 보인다. 다만 암호화된 패킷이 클라이언트 PC 또는 서버로 전송되기 때문에 송수신자간 데이터 교환이 일어나는 일에 대해서는 무력해진다. **개인정보유출, 기밀정보유출, DDoS, APT, 악성코드 공격**이 발생할 경우 무력화된다.

## 인증서

TLS 통신을 하려면 인증서가 필요한데, 이 인증서는 공인된 CA로부터 발급 받아야한다. 그 인증서는 공개키와 비밀키, 서명과 Finger Print 등등의 인증 정보를 가지고 있다.

자세한 절차는 [문서](TLS 인증서 발급 절차를 이해해보자.md)에서 볼 수 있다.

# 보안 인증 과정

서버가 CA에게 인증서를 발급받았다고 가정했을떄, 그 서버에게 클라이언트가 요청을 보내면 어떤 통신 과정을 거치는지 살펴보자.

<img src="https://user-images.githubusercontent.com/81006587/216968207-6977af3d-53d0-4bd3-a4a1-0c6092a23c7c.png" height=500px>

### 1. Client : Client Hello

Client가 서버에 접속할때 Server에게 몇가지 데이터를 먼저 알려준다.

- random : 클라이언트는 32바이트 난수값을 전달해서 전달한다. 이 랜덤값은 나중에 비밀 데이터(master secret)를 위해 사용된다.

- Session ID : 매번 연결할 때마다 Handshake 과정을 진행하는 것은 비효율적이니 최초 한번 전체 Handshake 과정을 진행하고 Session ID를 가진다. 후에는 이 Session ID를 사용해서 위 과정을 반복해서 진행하지 않는다. (앞으로의 통신에도 계속해서 Session ID값이 포함될 것이다.)

<img src="https://user-images.githubusercontent.com/81006587/216971608-d402ef28-ab86-43f2-b7d1-a05eefcbc0ee.png" height=275px>

- cipher suite : 클라이언트가 지원가능한 키 교환 알고리즘, 대칭키 암호 알고리즘, 해시 알고리즘 목록을 알려준다. 이렇게 전체 목록을 주면 서버는 최적의 알고리즘을 선택한다.

`TLS_RSA_WITH_AES_128_GCM_SHA256` <- 이런식으로 데이터를 전달하는데, 키 교환 알고리즘은 RSA, 대칭키 알고리즘은 AES_128 GCM방식을 사용하고 Hash 알고리즘으로는 SHA256을 사용한다는 의미이다.

암호화 알고리즘으로 쓰이는 것들은 아래와 같은 것들이 있다.

- 키교환: RSA, Diffie-Hellman, ECDH, SRP, PSK
- 대칭키 암호: RC4, 트리플 DES, AES, IDEA, DES, ARIA, ChaCha20, Camellia (SSL에서는 RC2)
- 해시 함수: TLS에서는 HMAC-MD5 또는 HMAC-SHA. (SSL에서는 MD5와 SHA)

### 2. Server : Server Hello

TLS Version, 암호화 방식(Client가 보낸 암호화 방식 중에 서버가 사용 가능한 암호화 방식을 선택), Server Random Data(서버에서 생성한 난수, 대칭키를 만들 때 사용), SessionID(유효한 Session ID)를 전달한다.

### 3. Server : Server Certificate

서버의 인증서를 클라이언트에게 보내는 단계로, 필요에 따라 CA의 Certificate도 함께 전송한다.

> 클라이언트는 이 패킷을 통해 서버의 인증서가 무결한지 검증한다.

### 4. Server : Server ket exchange (선택)

키교환에 추가 정보가 필요하면 이때, 전송한다. 예를 들면, 알고리즘을 Diffie-Hellman으로 사용해서 소수, 원시근 등 값이 필요한 경우 등이 있다.

### 5. Server : Certificate request (선택)

서버 역시 클라이언트를 인증할때 인증서를 요청할 수 있지만, 받지 않을 수도 있다.

### 6. Server : Server Hello Done

서버가 클라이언트에게 보낼 메시지를 모두 보냈다.

### 7. Client : Certificate (선택)

서버가 인증서를 요청했으면 전송하고, 아니면 생략한다.

### 8. Client : Client Key Exchange

우선 서버에서 보낸 인증서가 무결한지 확인해본다. OS나 브라우저는 기본적으로 CA 리스트를 가지고 있다. (Mac에는 keyChain, 브라우저는 소스코드) 그렇기 떄문에 서버의 공개키와 CA 공개키를 비교하면 서버가 보낸 인증서가 정상적인지 검증할 수 있다.

CA는 서버에게 인증서를 발급해줄때 제출받은 서버의 공개키에 CA의 공개키 정보를 암호화하여 넣어놓는다. 그러면 클라이언트는 서버의 인증서를 받은 다음, 알고있는 CA의 공개키를 해시해서 해당 값과 일치하는지 비교하면 해당 인증서가 유효한지를 확인할 수 있다. 

인증서를 확인한 다음에는 클라이언트가 생성한 랜덤값과 서버에서 보내준 랜덤값을 합쳐 pre-master secret를 만든다. 이 값을 사용해서 세션에 사용될 키를 생성하게 되는데, 그 키가 바로 대칭키이다.

중요한 정보이기 때문에 아까 받았던 인증서 안에 있는 서버의 공개키로 암호화해서 전송한다.

### 9. Certificate verify (선택)

클라이언트에 대한 Certificate request를 받았다면 보낸 인증서에 대한 개인키를 가지고 있다는 것을 증명한다. (handshake과정에서 주고 받은 메시지 + master secret을 조합한 hash값에 개인키로 디지털 서명하여 전송한다.)

### 10. Server & Client : Change Cipher Spec

이제부터 전송되는 모든 패킷은 협상된 알고리즘과 키를 이용하여 암호화 하겠다 알리고 끝낸다. 이제 이 뒤로 통신되는 모든 데이터는 대칭키로 암호화해서, 서버와 클라이언트끼리만 해독할 수 있도록 만든다.

# 결론

TLS는 이러한 과정을 거쳐서 통신 보안을 유지한다. 암호 코드를 교환하고 인증하는 절차가 있으니 통신 과정에서의 도청, 간섭, 위조를 막을 수 있다. (중간에 패킷을 탈취하거나 해도, 대칭키가 없으면 해독이 불가능하기 떄문)

뭔가 복잡해보였는데, 자세히 들여다보면 막 어렵진 않은 것 같다. 현재 https는 거의 모든 인터넷에서 사용되고 있는 프로토콜이기 때문에 이렇게 공부해놓으면 나중에 응용할 일이 꼭 생기지 않을까? 싶은 마음이다.
# 📡 TLS 인증서 발급 절차를 이해해보자

[TLS](TLS.md) 보안 인증 과정을 거치기 전에, 서버는 CA (Certificate Authority) 기관에서 인증서를 발급받아야한다. CA는 신뢰성이 엄격하게 공인된 기업들만 할 수 있다고 한다.

CA에서 인증서를 발급 받으려면 아래와 같은 과정을 거쳐야한다.

<img src="https://user-images.githubusercontent.com/81006587/216975631-bb0c1cf2-6f9e-470f-b1e9-90865197746f.png" height=500px>

- 먼저, 발급 받고자 하는 기관은 자신의 사이트 정보(도메인 등)과 공개키를 CA에게 제출한다.
- 그러면 CA는 검증을 걸친 후 발급 받고자 하는 기관의 공개 키를 해시한다. (SHA-256 등..)
- 이렇게 해시한 값을  **Finger Print(지문)**이라고 한다.

<img width="400" alt="Screenshot 2023-02-06 at 22 10 44" src="https://user-images.githubusercontent.com/81006587/216980213-1a31424b-5d07-418e-86f6-a214435ae5ea.png">

이제 이 지문을 CA의 비밀키로 암호화 하고, 인증서의 발급자 서명으로 등록한다. 이렇게 서명된 것을 **디지털 서명(Digital Signing)이라고 한다.

<img width="533" alt="Screenshot 2023-02-06 at 22 13 47" src="https://user-images.githubusercontent.com/81006587/216980545-8091a9a6-554c-44d6-9ea6-4c47adc54c8a.png">

이제 CA는 서버에게 이 디지털 서명, 발급자 정보 등등이 등록되어 있는 인증서를 발급해 준다.

이러한 방식처럼, 상위 인증 기관이 하위 인증서가 포함하고 있는 공개키 (인증서)를 상위 기관의 비밀키로 암호화 하여 상호 보증하게 되는 것을 인증서 체인(Certificate Chain) 이라고 한다.

내가 발급받는 CA 기관이 Root CA가 아니라면, 이 CA 기관마저 또 상위 CA에게 인증서를 발급받은 것이다.

<img src="https://user-images.githubusercontent.com/81006587/216979411-8759d2d3-83f9-4206-861a-4449adb42dd1.png" height=150px>

보통 3단계에 걸쳐서 인증서 체인이 일어나는데, 구글(*.google.com)의 인증서를 보면 

- `*.google.com`은 `GTS CA 1C3`의 비밀키로 암호화 되어있고,
- `GTS CA 1C3`는 `GRS Root R1`의 비밀키로 암호화 되어있다는 것을 알 수 있다.

`GRS Root R1`는 상위 인증기관이 없는 Root CA이기 때문에 Self-Signed 되어있다. (Self-Signed는 자신의 인증서를 해시한 후, CA가 아닌 자신의 비밀키로 암호화 하여 서명으로 등록하는 것이다!)

### CA 인증 없이 인증서를 생성할 수 있을까? 

신뢰성은 떨어지겠지만 가능은 하다. CA 인증과 상관 없이 발행하는 인증서를 **사설 인증서**라고 하고, 이 사설 인증서는 Root CA처럼 Self-Signed 되어 있다.

이제 인증서를 발급받은 서버는, 클라이언트와 [TLS 통신](TLS.md)을 할 수 있다
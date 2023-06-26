## 📡 브라우저에 url을 입력하면 어떤일이 벌어질까?

### 1. 브라우저 주소창에 google.com을 입력한다.

### 2. 웹 브라우저가 도메인의 IP 주소를 조회한다.

- DNS(Domain Name System)는 웹 사이트의 이름(URL)을 가지고 있는 데이터베이스와 같다. 인터넷의 모든 URL에는 고유한 IP 주소가 할당되어 있으며, IP 주소는 액세스 요청 웹 사이트의 서버를 호스트하는 컴퓨터에 속한다. DNS는 영어로된 URL과 IP를 연결해주는 시스템이다.

- 예를 들어, www.google.com의 IP주소는 http://209.85.227.104이다. 따라서 원하는 경우 브라우저에서 https://142.250.196.110 를 입력해도 www.google.com에 접속할 수 있다. 

> nslookup google.com로 IP주소를 확인할 수 있다.

- DNS의 목적은 사람들이 쉽게 사이트 주소를 찾을 수 있도록 도와주는 것이다. 만약 DNS가 없다면 google.com과 같이 도메인 주소가 아닌, 142.250.196.110 라는 ip 주소를 외워야한다. DNS는 자동으로 URL과 IP 주소를 매핑해주기 떄문에, 쉽게 원하는 사이트에 접속할 수 있다.

#### 캐시 확인

- DNS 기록을 찾기 위해, 브라우저는 우선 네개의 캐시를 확인한다.

1. 브라우저 캐시를 확인한다. 브라우저는 이전에 방문했던 DNS 기록을 일정 기간동한안 저장하고 있다.

2. OS 캐시를 확인한다. 브라우저 캐시에 원하는 DNS 레코드가 없다면, 브라우저가 내 컴퓨터 OS에 시스템 호출(i.e., 윈도우에서 `gethostname`)을 통해 DNS 기록을 가져온다. (OS도 DNS 레코드 캐시를 저장하고 있다.)

3. 라우터 캐시를 확인한다. 만약 컴퓨터에도 원하는 DNS 레코드가 없다면, 라우터에 저장되어있는 DNS 캐시를 확인한다.

4. ISP 캐시를 확인한다. ISP(Internet Service Provider)는 **DNS 서버**를 가지고 있는데, 해당 서버에서 DNS 기록 캐시를 검색할 수 있다.

- DNS 캐시는 네트워크 트래픽을 규제하고 데이터 전송 시간을 개선하는 데 꼭 필요한 정보이기 때문에 여러 단계에 걸쳐 캐싱되어있다.

#### DNS 쿼리

- 만약 요청한 URL이 캐시에 없다면, ISP의 DNS 서버가 DNS 쿼리로 서버의 IP주소를 찾는다.

- DNS 쿼리의 목적은 웹 사이트에 대한 올바른 IP 주소를 찾을 때까지 인터넷에서 여러 DNS 서버를 검색하는 것이다. 필요한 IP 주소를 찾거나, 찾을 수 없다는 오류 응답을 반환할 때까지 한 DNS 서버에서 다른 DNS 서버로 검색이 반복적으로 계속되기 때문에 이 유형의 검색을 재귀적 질의(Recursive Query)라고 한다.

- 이러한 상황에서, 우리는 ISP의 DNS 서버를 DNS 리커서(DNS Recursor)라고 부르는데, DNS 리커서는 인터넷의 다른 DNS 서버에 답변을 요청하여 의도된 도메인 이름의 적절한 IP 주소를 찾는 일을 담당한다. 다른 DNS 서버는 웹사이트 도메인 이름의 도메인 아키텍처를 기반으로 DNS 검색을 수행하므로 네임 서버(Name Server)라고 한다.

- DNS 리커서가 루트 네임 서버(Root Name Server)에 연결하면, 최상위 도메인에 따라 해당하는 도메인 네임 서버로 리디렉션한다. 하위 네임 서버의 DNS 기록에서 찾는 URL과 일치하는 IP 주소를 찾으면 DNS 리커서를 거쳐 브라우저로 반환된다.

- 위와 같은 요청(Request)은 내용 및 IP 주소(DNS 리커서의 IP 주소)와 같은 정보가 패킷에 담겨진 형태로 전송된다. 이 패킷은 올바를 DNS 서버에 도단하기 전에 클라이언트와 서버 사이의 여러 네트워킹 장비를 통해 이동한다. 이 장비들은 **라우팅 테이블**을 사용하여 패킷이 못적지에 도달할 수 있는 가장 빠른 방법을 알아낸다.

- 올바른 경로를 통해 DNS 서버에 도달하면 IP 주소를 가져온 후 브라우저로 돌아간다.

### 3. 브라우저가 해당 서버와 TCP 연결을 시작한다.

- 인터넷에 연결된 웹 브라우저 요청 패킷은 일반적으로 TCP/IP(Transmission Control Protocol/Internet Protocol)라고 하는 전송 제어 프로토콜이 사용된다. TCP 연결은 TCP/IP 3-way handshake라는 연결 과정을 통해 이뤄진다. 클라이언트와 서버가 SYN(synchronize: 연결 요청) 및 ACK(acknowledgement: 승인) 메시지를 교환하여 연결을 설정하는 3단계 프로세스이다.

1. 클라이언트는 인터넷을 통해 서버에 SYN 패킷을 보내 새 연결이 가능한지 여부를 묻는다.

2. 서버에 새 연결을 수락할 수 있는 열린 포트가 있는 경우, SYN/ACK 패킷을 사용하여 SYN 패킷의 ACK(승인)으로 응답한다.

3. 클라이언트는 서버로부터 SYN/ACK 패킷을 수신하고 ACK 패킷을 전송하여 승인한다.

### 4. 웹 브라우저가 HTTP 요청을 서버로 전송한다.

- 웹 브라우저가 서버에 연결되면, HTTP(s) 프로토콜에 대한 통신 규칙을 따른다. HTTP 요청에는 요청 라인, 헤더(또는 요청에 대한 메타데이터) 및 본문이 포함되며, 클라이언트가 서버에 원하는 작업을 요청하지 위한 정보가 들어간다.

- 요청 라인에는 다음이 포함된다.
  - GET, POST, PUT, PATCH, DELETE 또는 몇 가지 다른 HTTP 동사 중 하나인 요청 메서드
  - 요청된 리소스를 가리키는 경로
  - 통신할 HTTP 버전

<img src="https://user-images.githubusercontent.com/81006587/198164298-9d8b2266-575f-4905-aa40-22496b8a6074.png">

- HTTPS를 사용하는 경우 주고 받는 데이터의 암호화를 위한 **TLS (Transport Layer Security)** 핸드셰이크라는 추가 과정을 수행한다.

### 5. 서버가 요청을 처리하고 응답(response)을 보낸다.

- 서버에는 웹 서버(예: Apache, IIS)가 포함되어 있는데, 이는 브라우저로부터 요청을 수신하고, 해당 내용을 request handler에 전달하여 응답을 읽고 생성하는 역할을 한다. Request handler는 요청, 요청의 헤더 및 쿠키를 읽고 필요한 경우 서버의 정보를 업데이트하는 프로그램이다(NET, PHP, Ruby, ASP 등으로 작성됨). 그런 다음 response를 특정 포맷으로(JSON, XML, HTML)으로 작성한다.

### 7. 서버가 HTTP 응답을 보낸다.

- 서버 응답에는 요청한 웹 페이지와 함께 상태 코드(status code), 압축 유형(Content-Encoding), 페이지 캐싱 방법(Cache-Control), 설정할 쿠키, 개인 정보 등이 포함 된다.

- 서버의 HTTP 응답 예시이다:

```bash
Server: nginx/1.18.0 (Ubuntu)
Date: Mon, 26 Jun 2023 05:47:16 GMT
Content-Type: application/json;charset=UTF-8
Content-Length: 64
Connection: keep-alive
Vary: Origin
Vary: Access-Control-Request-Method
Vary: Access-Control-Request-Headers
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY

{"message":"Hello"}
```

### 8. 브라우저가 HTML 컨텐츠를 보여준다.

- 브라우저는 응답받은 HTML을 화면에 단계별로 표시한다. 첫째, HTML 골격을 렌더링한다. 그런 다음 HTML 태그를 확인하고 이미지, CSS 스타일시트, 자바스크립트 파일 등과 같은 웹 페이지의 추가 요소에 대한 GET 요청을 보낸다. 정적 파일(Static File)은 브라우저에서 캐싱되므로 다음에 페이지를 방문할 때 다시 가져올 필요가 없다. 

- 드디어, google.com 페이지가 브라우저에 나타난다.
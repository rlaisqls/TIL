# **IP - Internet protocol**

### 정의
    - 각 컴퓨터에 IP 주소를 부여해서 Packet이라는 통신 단위로 데이터를 전달해주는 방식 (규약으로 합의됨)
    
 ### 한계
- #### 비연결성
    패킷을 받을 대상이 없거나 서비스 불능 상태여도 패킷 전송

- #### 비신뢰성
    중간에 패킷이 사라지거나, 패킷이 순서대로 오지 않을 수도 있음

- #### 프로그램 구분 X
    같은 IP를 사용하는 서버에서 여러개의 프로그램을 돌리면 섞일 수 있음

<br>

# **TCP - Transmisson Control Protocol**
    - IP에 있었던 문제점을 인터넷계층의 상위 계층인 전송 계층(TCP)에서 보완해줌

<br>

## 프로토콜 4계층
- #### 어플리케이션 계층 - HTTP,FTP
- #### 전송 계층 - TCP, UDP
    출발지 PORT, 목적지 PORT, 전송 제어, 순서, 검증 정보 등을 지정
- #### 인터넷 계층 - IP
    출발지 IP, 목적지 IP 등을 지정
- #### 네트워크 인터페이스 계층
    LAN 카드를 통해 정보가 송신될때 필요한 Ethernet frame을 씌움


## 특징

- ### 연결지향 - TCP 3 way handshake (가상 연결)
    1. SYN(접속 요청)
    2. SYN+ACK(요청 수락)
    3. ACK

- ### 데이터 전달 보증
    전송제어, 검증 정보로 전달 했는지 확인 가능

- ### 순서 보장
    잘못 오면 클라이언트에게 재요청

<br>

## **UDP - User Datagram Protocol**
IP 패킷에 PORT랑 체크섬만 추가한거 <br>
자체 기능은 별로 없는데 애플리케이션에서 여기에다 추가 작업을 좀 해서 최적화 할 수 있음

<br>

## **PORT**

0 ~ 65535: 할당 가능
0 ~ 1023: 잘 알려진 포트

- FTP - 20,21
- TELNET - 23
- HTTP - 80
- HTTPS - 443

<br><br>

# **URI - Uniform Resource Identifier**
로케이터(URL)와 이름(URN)으로 분류됨

- Uniform : 리소스 식별하는 통일된 방식
- Resource : 자원, URI로 식별할 수 있는 모든 것
- Identifier : 다른 항목과 구분하는데 쓰는 정보

URL은 변할 수 있지만 URN은 변하지 않는다.<br>
하지만 URN 이름만으로 실제 리소스를 찾을 수 있는 방법이 많진 않다. 그래서 보통 URL을 보는 경우가 더 잦다.

### **URL 문법**

 ### **-> _scheme://[userinfo@]host[:port][/path][?query][#fragment]_**
 <br>
     scheme
        보통 프로토콜 정보가 들어감
        ex) http (80), https (443), ftp 등
     userinfo
        사용자정보를 포함해서 인증해야 할때 적는데 잘 안씀
     host
        호스트명
     port
        보편적으론 생략 가능
     path
        리소스가 있는 경로, 계층적 구조
     query
        key=value 현태
        ?로 시작, &로 추가 가능
        query parameter, puery string 등으로 불림. 
     fragment
        html 내부 북마크에 사용

<br>

---

<br>

# **HTTP - HyperText Transfer protocol**

## 특징
- #### 클라이언트 서버 구조 (Request Response)
    - 클라이언트는 서버에 요청을 보내고, 응답을 대기<br>
    - 서버가 요청에 대한 경과를 만들어서 응답<br>
    - 복잡한 비즈니스 로직은 서버에서 해결할 수 있게 하고 클라이언트는 UI에 집중할 수 있음
- #### 무상태 프로토콜 (stateless)
    - 서버가 클라이언트의 상태를 보존하지 않음<br>
    - 장점 : 서버 확장성 높음 (스케일 아웃)<br>
    - 단점 : 클라이언트가 데이터를 다 전송해줘야 함
- #### 비연결성(connectionless)
    필요한 정보만 받고 연결을 끊어버림<br>
    - 장점 : 계속 연결을 유지하지 않으니까 자원을 아낄 수 있음<br>
        (사용자가 실제로 동시에 처리하는 요청은 적기 때문)
    - 단점: TCP/IP연결을 새로 맺어야함<br>
        웹 브라우저로 사이트를 요청할때 매번 처음부터 끝까지 다 다운로드 해야함<br>
        그래서 지속연결 (Persistent Connections)을 함

## HTTP 메시지
 - ### start-line 시작 라인
    - #### 요청 request-line
    - -> method SP request-target SP HTTP-version CRLF
    - #### 응답 status-line
    - -> HTTP-version SP status-code SP reason-phrase CRLF
 - ### header 헤더
    - header-field = field-name: OWS field-value OWS
    - HTTP 전송에 필요한 모든 부가정보를 담음.
    - -> ex) 메세지 바디의 내용, 크기, 압축, 인증, 요청 클라이언트(브라우저) 정보 등
 - ### empty line 공백 라인(CRLF)
 - ### message body
    - 실제 전송할 데이터 (HTML, 이미지, 영상 등등 모든 데이터)

<br>

# **HTTP - HyperText Transfer protocol**
## HTTP 메서드
 - ### GET
    - 리소스 조회
    - 서버에 전달하고 싶은 데이터는 query(쿼리스트링)를 통해 전달
    - 캐싱
    - (메시지 바디를 절대 못쓰는건 아니긴 함)
 - ### POST
    - 요청 데이터 처리
    - 메시지 바디를 통해 서버로 요청 데이터 전달
        - 들어온 데이터를 처리하는 모든 기능을 수행
    - 스펙: POST 메서드는 대상 리소스가 리소스의 고유한 의미 체계에 따라 요청에 포함된 표현을 처리하도록 요청합니다.
    - 이 리소스 URI에 POST 요청이 오면 요청 데이터를 어떻게 처리할지 정해줘야함
    - 사용 예
        - 새 리소스 생성(등록)
        - 요청 데이터 처리(프로세스)
        - 등등 많은 것들
 - ### PUT
    - 리소스를 대체, 리소스가 없으면 생성
    - 클라이언트가 리소스 위치를 알고 URI 지정 (정확히 여기에 넣겠다)
    - 일부만 넣으면 나머지 그냥 삭제됨
 - ### PATCH
    - 리소스 부분 변경
 - ### DELETE
    - 리소스 삭제
 - ### HEAD
    - GET과 동일하지만 상태줄과 헤더만 변환
 - ### OPTIONS
    - 대상 리소스에 대한 통신 가능 옵션(메서드)을 설명(주로 CORS에서 사용)
 - ### CONNECT
    - 대상 자원으로 식별되는 서버에 대한 터널을 설정
 - ### TRACE
    - 대상 리소스에 대한 경로를 따라 메시지 루프백 테스트를 수행

## HTTP 메서드의 속성
 - ### 안전 safe
    호출해도 리소스를 변경하지 않는다.
 - ### 멱등 idempotent
    몇 번 호출하든 결과가 같다.
    f(f(x)) = f(x)
    - GET: 한 번 조회하든, 두 번 조회하든 같은 결과가 조회된다.
    - PUT: 결과를 대체한다. 같은 요청을 하면 남는건 똑같다.
    - DELETE: 결과를 삭제한다. 똑같이 지워진다.
    - POST: 멱등이 아니다. 두 번 호출하면 같은 함수가 중복해서 발생 할 수 있다.
    멱등이라면 자동 복구 메커니즘에 활용할 수 있음 (막혔을때 여러번 시도)
 - ### 캐시 가능 cacheable
    - 웹브라우저에 임시 저장 (앞주머니)
    - GET, HEAD는 캐시로 사용
        - POST, PATCH는 본문 내용까지 캐시 키로 고려해야 하는데, 구현이 쉽지 않음

|HTTP 메소드|RFC|요청BODY|응답BODY|안전|멱등|캐시가능|
|------|:----:|:---:|:---:|:---:|:---:|:---:|
|GET|RFC7231|X|O|O|O|O|
|POST|RFC7231|O|O|X|X|O|
|PUT|RFC7231|O|O|X|O|X|
|DELETE|RFC7231|X|O|X|O|X|
|PATCH|RFC5789|O|O|X|X|O|

<br>

## HTTP 메서드 활용
### 클라이언트 -> 서버
 - #### 쿼리 파라미터를 통한 데이터 전송
    - GET
    - 주로 정렬 필터(검색어)
 - #### 메시지 바디를 통한 데이터 전송
    - POST, PUT, PATCH
    - 회원가입, 상품 주문, 리소스 등록, 리소스 변경

 - #### 예시
    - 정적 데이터 조회
        - 쿼리 파라미터 없이 GET으로 리소스 경로 단순 조회
    - 동적 데이터 조회
        - 쿼리 파라미터 사용 GET으로 데이터 전달
        - -> 서버에서 쿼리 파라미터를 기반으로 검색을 한 결과를 동적으로 생성
    - HTML Form 데이터 전송
        - GET, POST만 지원
        - post 전송 - 저장
        - <input type="text" name="name"\> 이런식으로 넣어주면 key value 스타일로 body에 포함해서 전송
        - 메소드를 get으로 바꿔서 쿼리 파라미터로 넘길 수도 있음
        - Content-Type: multipart/form-data
            - 파일 업로드 같은 바이너리 데이터 전송시 사용
            - 다른 종류의 여러 파일과 폼의 내용 함께 전송 가능(그래서 이름이 multipart)
    - HTML API 데이터 전송
        - 서버 to 서버 (백엔드 시스템 통식)
        - 앱 클라이언트 (아이폰, 안드로이드)
        - 웹 클라이언트
            - HTML에서 Form 전송 대신 자바 스크립트를 통한 통신에 사용(AJAX)
                - react나 vue같은 웹 클라이언트들이랑 할떄 많이 씀
            - POST, PUT, PATCH: 메시지 바디를 통해 데이터 전송
            - GET: 조회, 쿼리 파라미터로 데이터 전달
            - Content-Type: application/json을 주로 사용
                - TEXT, XML, JSON 등등

 - #### 설계 예시
    - HTTP API - 컬렉션
        - POST 기반 등록
        - 서버가 리소스 URI  결정
    - HTTP API - 스토러
        - PUT 기반 등록
        - 클라이언트가 리소스 URI 결정
    - HTML FORM 사용
        - 순수 HTML + HTMLM form 만 사용하면 GET, POST만 지원

 - #### 참고 개념
    - 문서(document) 
        - 단일 개념(파일 하나, 객체 인스턴스, 데이터베이스 row)
        - 예) /members/100, /files/star.jpg
    - 컬렉션(collection) 
        - 서버가 관리하는 리소스 디렉터리
        - 서버가 리소스의 URI를 생성하고 관리
        - 예) /members
    - 스토어(store) 
        - 클라이언트가 관리하는 자원 저장소
        - 클라이언트가 리소스의 URI를 알고 관리
        - 예) /files
    - 컨트롤러(controller), 컨트롤 URI 
        - 문서, 컬렉션, 스토어로 해결하기 어려운 추가 프로세스 실행
        - 동사를 직접 사용
        - 예) /members/{id}/delete
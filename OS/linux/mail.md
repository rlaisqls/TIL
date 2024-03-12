
linux에서 mail 서비스를 운영할 수 있다.

### mail 관련 프로토콜

- SMTP(Simple Mail Transfer Protocol)
  - MTA 클라이언트와 서버를 구성하는 프로토콜 (TCP/25)
  - 송신자와 송신자의 메일 서버 사이, 메일 서버와 메일 서버 사이에서 사용된다.

- POP3(Post Office Protocol)
  - 메일 서버로부터 메일을 수신하기 위한 서버/클라이언트 프로토콜 (TCP/110)
  - 메일 서버로부터 메일을 가져온 후 서버에서 메일을 삭제함
  
- IMAP4(Internet Mail Access Protocol)
  - POP3와 비슷한 기능이지만 더 많은 기능을 포함하고 복잡함 (TCP/143)
  - 메일 서버로부터 메일을 가져와도 서버에 메일이 유지됨.

### 메일 서비스

**기본 컴포넌트 3가지**
  
  - MUA(Mail User Agent): 사용자들이 메일을 송/수신하기 위한 클라이언트 에이전트
  - MTA(Mail Transfer Agent): 메일 서버로 메일을 전송하기 위한 서버/클라이언트 에이전트 - MDA(Mail Delivery Agent): 수신된 메일을 해당 사용자에게 전달해주는 에이전트
  
**포워딩(forwarding) 방법**
  
  1. virtusertable 파일 설정을 통한 포워딩
  2. aliases 파일 설정을 통한 포워딩
  3. `.forward` 파일을 통한 포워딩 : 일반 계정 사용자가 자신의 홈 디렉터리에 만들어 설정

**메일 관련 프로그램**
  
- MTA 프로그램
  - Sendmail: SMTP를 기반으로 한 메일 전송 프로그램. 리눅스 배포판에 기본적으로 설치됨 - 
  - Qmail: Sendmail에 비교해 보안이 뛰어나며 모듈 방식으로 편리한 기능
  - Postfix: IBM 라이선스를 따르는 오픈소스 프로그램
  
- MUA 프로그램
  - Thunderbird(썬더버드): 모질라에서 만든 메일 클라이언트 프로그램
  - Evolution(에볼루션): GNOME의 메일 관리 프로그램
  
- MDA 프로그램
  - Procmail: 메일을 필터링하는 기본적인 프로그램
  - SpamAssassin: 아파치 재단에서 개발한 메일 필터링 프로그램. 펄(perl)로 제작됨.
  
- 보안 프로그램
  - PGP(Pretty Good Privacy): PEM에 비해 보안성은 떨어지지만 구현이 쉽다.
  - PEM(Privacy Enhanced Mail): 높은 보안성, 복잡한 구현 방식으로 잘 쓰이지 않음
  
- 기타 관련 프로그램
  - dovecot: POP3와 IMAP4 역할을 수행하는 프로그램

### sendmail 환경설정 파일

- `/etc/mail/sendmail.cf`
  - Sendmail의 핵심. 메일 송/수신 시 이 파일을 해석하여 실행한다.
  - m4 명령어로 생성할 수 있다. (`$ m4 sendmail.mc > snedmail.cf`)
- 설정
  - **Cw**: 호스트 지정
  - **Fw**: 파일 지정
  - **Dj**: 특정 도메인을 강제 지정
  
- `/etc/mail/local-host-names`
  - 메일 서버에서 사용하는 호스트(도메인)을 등록하는 파일

- `/etc/mail/access`
  - 각종 접근 제어 설정이 저장되는 파일
  - makemap 명령어: `/etc/mail/access` 파일 편집 후에 DB 파일(access.db)을 만드는 명령어 (`$makemap hash /etc/mail/access < /etc/mail/access`)
- 설정
  - **RELAY**: relay(중계) 허용
  - **OK**: 무조건 허용
  - **REJECT**: relay 차단 (주로 스팸 서버의 IP를 차단)
  - **DISCARD**: relay 없이 `/etc/sendmail.cf`에 지정된 $#discard mailer에 폐기됨 (어떠한 답신도 보내지 않음)

- 메일 거부패턴 옵션
    - **501**: 지정된 메일 주소와 일치하는 모든 메일의 수신 차단
    - **553**: 발신 메일주소에 호스트명이 없을 경우 메일 차단
    - **550** : 지정된 도메인과 관련된 모든 메일 수신 거부ㅋ

- access 파일 예제
  - ```c
        Connect:192.168.10.9   OK        /* 192.168.10.9 호스트로 접속하는 클라이언트의 메일 허용 */
        Connect:localhost      RELAY     /* localhost로 접속하는 클라이언트의 RELAY 허용 */
        From:add@spam.com      REJECT    /* add@spam.com에서(발신) 오는 메일을 거절하고 거절 답신 보냄 */
        From:root@spam.co.kr   DISCARD   /* root@spam.co.kr에서(발신) 오는 메일을 거절하고 거절 답신을 보내지 않음 */
        To:log@shionista.com   OK        /* log@shionista.com으로(수신) 오는 메일을 허용 */
    ```

- `/etc/aliases`
  - 특정 ID로 들어오는 메일을 여러 호스트에게 전달할 때 사용하는 파일 (작은 규모의 메일링 리스트)
  - 사용자가 다른 메일 계정 (별칭)을 사용할 수 있도록 할 수 있다.
  - `newaliases` 명령어 : `/etc/aliases` 파일의 변동 사항을 적용
    - `sendmail -bi` 명령어와 같은 기능
  
- `/etc/mail/virtusertable`
  - 가상 메일 사용자의 설정이 저장되는 파일
  - access 파일과 마찬가지로 `makemap hash` 명령어로 DB 파일을 만들어 주어야 함
  - `webmaster@server.shionista.com admin` → 해당 메일 주소로 오는 메일을 admin 계정으로 수신
  - `webmaster@test.shionista.com test` → 해당 메일 주소로 오는 메일을 test 계정으로 수신

### 관련 명령어

- mailq 명령어 2015(1) 2016(1)
- 메일 큐 목록(/var/spool/mqueue) 출력 (sendmail -bp 명령어와 같은 기능)
- [-v] : 자세하게 출력
- [-Ac] : /etc/spool/submit.cf 에 지정된 메일 큐 목록(/var/spool/clientmqueue)을 출력

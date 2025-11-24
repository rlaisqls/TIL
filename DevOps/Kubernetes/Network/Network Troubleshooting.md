
각 상황에 맞는 네트워크 트러블슈팅 도구를 정리하면 다음과 같다:

|상황|도구|
|-|-|
|연결 확인|`traceroute`, `ping`, `telnet`, `netcat`|
|포트 스캔|`nmap`|
|DNS 레코드 확인|`dig`, 연결 확인 도구들|
|HTTP/1 확인|`cURL`, `telnet`, `netcat`|
|HTTPS 확인|`OpenSSL`, `cURL`|
|리스닝 프로그램 확인|`netstat`|

## 보안

본격적으로 도구를 다루기 전에, 보안에 대해 먼저 인지해야 한다.

공격자는 여기 소개된 모든 도구를 이용해 시스템을 탐색하고 침투할 수 있다. 그래서 최선의 방법은 각 머신에 최소한의 네트워킹 도구만 설치하는 것이다.

물론 공격자가 직접 도구를 다운로드하거나 패키지 매니저를 쓸 수도 있다(권한이 있다면). 대부분의 경우 단지 공격 전 약간의 마찰만 추가할 뿐이다. 하지만 때로는 도구를 사전 설치하지 않는 것만으로도 공격자의 능력을 제한할 수 있다.

Linux 파일 권한에는 `setuid bit`이라는 게 있다. 파일에 setuid 비트가 설정되어 있으면, 그 파일은 현재 사용자가 아닌 파일 소유자의 권한으로 실행된다. 권한 표시에서 `x` 대신 `s`가 보이면 setuid 비트가 설정된 것이다:

```bash
$ ls -la /etc/passwd
-rwsr-xr-x 1 root root 68208 May 28  2020 /usr/bin/passwd
```

이를 통해 프로그램에 제한적인 특권 기능을 제공할 수 있다. 예를 들어 passwd 명령은 이 기능으로 사용자가 비밀번호 파일에 직접 쓰지 못하게 하면서도 자신의 비밀번호는 바꿀 수 있게 한다. ping, nmap 같은 네트워킹 도구도 raw 패킷을 보내거나 패킷을 스니핑하기 위해 setuid 비트를 사용하는 경우가 있다.

만약 공격자가 root 권한을 얻지 못하고 자신의 도구를 다운로드한다면, 시스템이 setuid 비트로 설치한 도구보다 할 수 있는 일이 줄어든다.

## ping

```bash
ping <address>
```

ping은 네트워크 장비에 ICMP `ECHO_REQUEST` 패킷을 보내는 단순한 프로그램이다. 한 호스트에서 다른 호스트로의 네트워크 연결을 테스트하는 가장 기본적인 방법이다.

ICMP는 TCP, UDP와 같은 레이어 4 프로토콜이다. 그런데 Kubernetes 서비스는 TCP와 UDP만 지원하고, **ICMP는 지원하지 않는다**. **따라서 Kubernetes 서비스에 ping을 보내면 항상 실패한다**. 서비스 연결을 확인하려면 telnet이나 cURL 같은 더 상위 레벨 도구를 써야 한다. <u>개별 Pod은 네트워크 설정에 따라 ping이 될 수도 있다.</u>

> 방화벽이나 라우팅 소프트웨어는 ICMP 패킷을 인식하고 필터링하거나 라우팅할 수 있다. ICMP 패킷을 기본적으로 허용하는 경우가 많지만, 항상 그런 건 아니다. 네트워크 관리자나 클라우드 제공사에 따라 다르다.

기본적으로 ping은 패킷을 계속 보낸다. Ctrl-C로 수동으로 멈춰야 한다. `-c <count>` 옵션을 쓰면 정해진 횟수만큼만 보내고 종료한다. 종료할 때는 통계 요약도 출력한다:

```bash
~ ping -c 2 k8s.io
PING k8s.io (34.107.204.206): 56 data bytes
64 bytes from 34.107.204.206: icmp_seq=0 ttl=51 time=9.934 ms
64 bytes from 34.107.204.206: icmp_seq=1 ttl=51 time=7.762 ms

--- k8s.io ping statistics ---
2 packets transmitted, 2 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 7.762/8.848/9.934/1.086 ms
```

|옵션|설명|
|-|-|
|`-c <count>`|지정한 횟수만큼 패킷을 보낸다. 마지막 패킷을 받거나 타임아웃되면 종료한다.|
|`-i <seconds>`|패킷을 보내는 간격을 설정한다. 기본값은 1초다. 너무 낮은 값은 네트워크를 flood할 수 있어 권장하지 않는다.|
|`-o`|패킷 1개를 받으면 종료한다. `-c 1`과 같다.|
|`-S <source address>`|패킷의 소스 주소를 지정한다.|
|`-W <milliseconds>`|패킷 응답을 기다리는 시간을 설정한다. 늦게 도착해도 최종 통계에는 포함된다.|

## traceroute

`traceroute`는 한 호스트에서 다른 호스트까지의 네트워크 경로를 보여준다. 어느 경로로 패킷이 가는지, 또는 어디서 라우팅이 실패하는지 쉽게 확인하고 디버깅할 수 있다.

그렇다면 traceroute는 어떻게 동작할까?

IP 패킷에는 TTL(time-to-live)이라는 값이 있다. 호스트가 패킷을 받으면 TTL을 1 감소시킨다. TTL이 0이 되면 그 호스트는 `TIME_EXCEEDED` 패킷을 보내고 원래 패킷을 버린다. 이 응답 패킷에는 패킷이 타임아웃된 머신의 주소가 담겨 있다.

traceroute는 이 원리를 이용한다. TTL을 1부터 시작해서 하나씩 늘려가며 패킷을 보낸다. 그러면 경로상의 각 호스트로부터 응답을 받을 수 있다.

traceroute는 첫 번째 외부 머신부터 한 줄씩 호스트를 표시한다. 각 줄에는 호스트명(있으면), IP 주소, 응답 시간이 나온다:

```bash
$traceroute k8s.io
traceroute to k8s.io (34.107.204.206), 64 hops max, 52 byte packets
 1  router (10.0.0.1)  8.061 ms  2.273 ms  1.576 ms
 2  192.168.1.254 (192.168.1.254)  2.037 ms  1.856 ms  1.835 ms
 3  adsl-71-145-208-1.dsl.austtx.sbcglobal.net (71.145.208.1)
4.675 ms  7.179 ms  9.930 ms
 4  * * *
 5  12.122.149.186 (12.122.149.186)  20.272 ms  8.142 ms  8.046 ms
 6  sffca22crs.ip.att.net (12.122.3.70)  14.715 ms  8.257 ms  12.038 ms
 7  12.122.163.61 (12.122.163.61)  5.057 ms  4.963 ms  5.004 ms
 8  12.255.10.236 (12.255.10.236)  5.560 ms
    12.255.10.238 (12.255.10.238)  6.396 ms
    12.255.10.236 (12.255.10.236)  5.729 ms
 9  * * *
10  206.204.107.34.bc.googleusercontent.com (34.107.204.206)
64.473 ms  10.008 ms  9.321 ms
```

특정 홉에서 타임아웃 전에 응답을 받지 못하면 `*`가 출력된다. 어떤 호스트는 `TIME_EXCEEDED` 패킷을 보내지 않거나, 방화벽이 패킷을 막을 수도 있다.

|옵션|구문|설명|
|-|-|-|
|First TTL|`-f <TTL>`, `-M <TTL>`|시작 IP TTL을 설정한다(기본값: 1). TTL을 n으로 설정하면 처음 n-1개 호스트는 보고하지 않는다.|
|Max TTL|`-m <TTL>`|최대 TTL, 즉 traceroute가 시도할 최대 홉 수를 설정한다.|
|Protocol|`-P <protocol>`|지정한 프로토콜(TCP, UDP, ICMP 등)로 패킷을 보낸다. 기본값은 UDP다.|
|Source address|`-s <address>`|나가는 패킷의 소스 IP 주소를 지정한다.|
|Wait|`-w <seconds>`|응답을 기다리는 시간을 설정한다.|

## dig

`dig`는 DNS 조회 도구다. 명령줄에서 DNS 쿼리를 하고 결과를 볼 수 있다.

기본 형식은 `dig [options] <domain>`이다. 아무 옵션 없이 실행하면 CNAME, A, AAAA 레코드를 보여준다:

```bash
$ dig kubernetes.io

; <<>> DiG 9.10.6 <<>> kubernetes.io
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51818
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1452
;; QUESTION SECTION:
;kubernetes.io.   IN A

;; ANSWER SECTION:
kubernetes.io.  960 IN A 147.75.40.148

;; Query time: 12 msec
;; SERVER: 2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b#53
(2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b)
;; WHEN: Mon Jul 06 00:10:35 PDT 2020
;; MSG SIZE  rcvd: 71
```

특정 DNS 레코드 타입을 보려면 `dig <domain> <type>` 또는 `dig -t <type> <domain>`을 실행한다. dig의 주요 사용 사례다:

```bash
$ dig kubernetes.io TXT

; <<>> DiG 9.10.6 <<>> -t TXT kubernetes.io
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 16443
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;kubernetes.io.   IN TXT

;; ANSWER SECTION:
kubernetes.io.  3599 IN TXT
"v=spf1 include:_spf.google.com ~all"
kubernetes.io.  3599 IN TXT
"google-site-verification=oPORCoq9XU6CmaR7G_bV00CLmEz-wLGOL7SXpeEuTt8"

;; Query time: 49 msec
;; SERVER: 2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b#53
(2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b)
;; WHEN: Sat Aug 08 18:11:48 PDT 2020
;; MSG SIZE  rcvd: 171
```

|옵션|구문|설명|
|-|-|-|
|IPv4|`-4`|IPv4만 사용한다.|
|IPv6|`-6`|IPv6만 사용한다.|
|Address|`-b <address>[#<port>]`|DNS 쿼리를 보낼 주소를 지정한다. 포트는 #을 붙여 선택적으로 지정할 수 있다.|
|Port|`-p <port>`|DNS가 비표준 포트에 있을 때 쿼리할 포트를 지정한다. 기본값은 DNS 표준 포트인 53이다.|
|Domain|`-q <domain>`|쿼리할 도메인 이름이다. 보통은 위치 인수로 지정한다.|
|Record Type|`-t <type>`|쿼리할 DNS 레코드 타입이다. 위치 인수로도 지정할 수 있다.|

## telnet

`telnet`은 네트워크 프로토콜이자 그 프로토콜을 쓰는 도구다. 과거엔 SSH처럼 원격 로그인에 쓰였다. 보안이 더 좋은 SSH가 표준이 되었지만, telnet은 여전히 텍스트 기반 프로토콜을 쓰는 서버를 디버깅하는 데 아주 유용하다. 예를 들어 HTTP/1 서버에 연결해서 수동으로 요청을 만들 수 있다.

기본 문법은 `telnet <address> <port>`다. 연결하면 대화형 커맨드라인 인터페이스가 나온다. Enter를 두 번 누르면 명령이 전송되어 여러 줄 명령을 쉽게 쓸 수 있다. Ctrl-J로 세션을 종료한다:

```bash
$ telnet kubernetes.io
Trying 147.75.40.148...
Connected to kubernetes.io.
Escape character is '^]'.
> HEAD / HTTP/1.1
> Host: kubernetes.io
>
HTTP/1.1 301 Moved Permanently
Cache-Control: public, max-age=0, must-revalidate
Content-Length: 0
Content-Type: text/plain
Date: Thu, 30 Jul 2020 01:23:53 GMT
Location: https://kubernetes.io/
Age: 2
Connection: keep-alive
Server: Netlify
X-NF-Request-ID: a48579f7-a045-4f13-af1a-eeaa69a81b2f-23395499
```

telnet을 제대로 활용하려면 사용하는 애플리케이션 프로토콜이 어떻게 작동하는지 알아야 한다. HTTP, HTTPS, POP3, IMAP 등을 실행하는 서버를 디버깅하는 고전적인 도구다.

## nmap

`nmap`은 포트 스캐너다. 네트워크의 서비스를 탐색하고 검사할 수 있다.

기본 문법은 `nmap [options] <target>`이며, target은 도메인, IP 주소, IP CIDR이다. 기본 옵션으로 실행하면 호스트의 열린 포트를 빠르게 요약해준다:

```bash
$ nmap 1.2.3.4
Starting Nmap 7.80 ( https://nmap.org ) at 2020-07-29 20:14 PDT
Nmap scan report for my-host (1.2.3.4)
Host is up (0.011s latency).
Not shown: 997 closed ports
PORT     STATE SERVICE
22/tcp   open  ssh
3000/tcp open  ppp
5432/tcp open  postgresql

Nmap done: 1 IP address (1 host up) scanned in 0.45 seconds
```

이 예제에서 nmap은 세 개의 열린 포트를 찾아내고 각 포트에서 실행 중인 서비스를 추측한다.

> nmap은 원격 머신에서 어떤 서비스에 접근할 수 있는지 빠르게 보여준다. 노출되지 말아야 할 서비스를 발견하는 쉬운 방법이다. 이런 이유로 공격자들이 애용하는 도구다.

`nmap`에는 엄청나게 많은 옵션이 있어 스캔 방식과 상세도를 조절할 수 있다. 다른 명령들처럼 주요 옵션만 정리하지만, help나 man 페이지를 읽어보길 강력히 권장한다.

|옵션|구문|설명|
|-|-|-|
|추가 탐지|`-A`|OS 탐지, 버전 탐지 등을 활성화한다.|
|출력 감소|`-d`|명령 출력을 줄인다. 여러 개 쓰면(예: -dd) 효과가 증가한다.|
|출력 증가|`-v`|명령 출력을 늘린다. 여러 개 쓰면(예: -vv) 효과가 증가한다.|

## netstat

netstat은 머신의 네트워크 스택과 연결에 대한 다양한 정보를 보여준다:

```bash
$ netstat
Active internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0    164 my-host:ssh             laptop:50113            ESTABLISHED
tcp        0      0 my-host:50051           example-host:48760      ESTABLISHED
tcp6       0      0 2600:1700:2800:7d:54310 2600:1901:0:bae2::https TIME_WAIT
udp6       0      0 localhost:38125         localhost:38125         ESTABLISHED
Active UNIX domain sockets (w/o servers)
Proto RefCnt Flags   Type    State  I-Node  Path
unix  13     [ ]     DGRAM          8451    /run/systemd/journal/dev-log
unix  2      [ ]     DGRAM          8463    /run/systemd/journal/syslog
[Cut for brevity]
```

아무 인수 없이 netstat을 실행하면 머신의 모든 연결된 소켓이 표시된다. 이 예제는 TCP 소켓 3개, UDP 소켓 1개, 그리고 많은 UNIX 소켓을 보여준다. 출력에는 연결 양쪽의 주소(IP 주소와 포트)가 포함된다.

`-a` 플래그로 모든 연결을 보거나 `-l`로 리스닝 연결만 볼 수 있다:

```bash
$ netstat -a
Active internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address      State
tcp        0      0 0.0.0.0:ssh             0.0.0.0:*            LISTEN
tcp        0      0 0.0.0.0:postgresql      0.0.0.0:*            LISTEN
tcp        0    172 my-host:ssh             laptop:50113         ESTABLISHED
[Content cut]
```

netstat의 흔한 용도는 특정 포트에서 어떤 프로세스가 리스닝하는지 확인하는 것이다. `sudo netstat -lp`를 실행하면 된다. `-l`은 "listening", `-p`는 "program"이다. 모든 프로그램 정보를 보려면 sudo가 필요할 수 있다. `-l` 출력은 서비스가 리스닝하는 주소를 보여준다(예: `0.0.0.0`이나 `127.0.0.1`).

특정 결과를 찾을 때는 grep 같은 도구로 netstat 출력을 필터링하면 깔끔하다:

```bash
$ sudo netstat -lp | grep 3000
tcp6     0    0 [::]:3000       [::]:*       LISTEN     613/grafana-server
```

**주요 옵션**

|옵션|구문|설명|
|-|-|-|
|모든 소켓 표시|`netstat -a`|열린 연결뿐 아니라 모든 소켓을 표시한다.|
|통계 표시|`netstat -s`|네트워킹 통계를 표시한다. 기본적으로 모든 프로토콜의 통계를 보여준다.|
|리스닝 소켓 표시|`netstat -l`|리스닝 중인 소켓을 표시한다. 실행 중인 서비스를 찾는 쉬운 방법이다.|
|TCP|`netstat -t`|TCP 데이터만 표시한다. 다른 플래그와 함께 쓸 수 있다. 예: `-lt` (TCP로 리스닝하는 소켓 표시).|
|UDP|`netstat -u`|UDP 데이터만 표시한다. 다른 플래그와 함께 쓸 수 있다. 예: `-lu` (UDP로 리스닝하는 소켓 표시).|

## netcat

netcat은 연결을 만들고, 데이터를 보내거나, 소켓을 리스닝하는 다목적 도구다. 서버나 클라이언트를 "수동으로" 실행해서 무슨 일이 일어나는지 자세히 살펴보는 데 유용하다. 이런 점에서 telnet과 비슷하지만, netcat은 훨씬 더 많은 걸 할 수 있다.

> 대부분 시스템에서 nc는 netcat의 별칭이다.

`netcat <address> <port>`로 서버에 연결할 수 있다. netcat은 대화형 stdin을 제공해서 수동으로 데이터를 입력하거나 파이프로 데이터를 보낼 수 있다. 여기까진 매우 telnet스럽다:

```bash
$ echo -e "GET / HTTP/1.1\nHost: localhost\n" > cmd
$ nc localhost 80 < cmd
HTTP/1.1 302 Found
Cache-Control: no-cache
Content-Type: text/html; charset=utf-8
[Content cut]
```

## OpenSSL

OpenSSL은 전 세계 HTTPS 연결의 많은 부분을 담당하는 기술이다. OpenSSL로 하는 대부분의 작업은 프로그래밍 언어 바인딩을 통하지만, 운영 작업과 디버깅을 위한 CLI도 있다. openssl로 키와 인증서를 만들고, 인증서를 서명하며, 무엇보다 우리에게 중요한 TLS/SSL 연결을 테스트할 수 있다.

이 장에서 다룬 다른 도구들도 TLS/SSL 연결을 테스트할 수 있다. 하지만 openssl은 기능이 풍부하고 상세한 정보를 제공한다는 점에서 단연 돋보인다.

명령은 보통 `openssl [sub-command] [arguments] [options]` 형태다. openssl에는 수많은 하위 명령이 있다(예: `openssl rand`는 의사 난수 데이터를 생성한다). list 하위 명령으로 기능을 나열할 수 있다(예: 명령 목록은 `openssl list --commands`). 개별 하위 명령에 대해 더 알아보려면 `openssl <subcommand> --help`나 man 페이지(`man openssl-<subcommand>` 또는 `man <subcommand>`)를 확인하면 된다.

`openssl s_client -connect`는 서버에 연결해서 서버 인증서에 대한 자세한 정보를 보여준다. 기본 실행 예시다:

```bash
openssl s_client -connect k8s.io:443
CONNECTED(00000003)
depth=2 O = Digital Signature Trust Co., CN = DST Root CA X3
verify return:1
depth=1 C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
verify return:1
depth=0 CN = k8s.io
verify return:1
---
Certificate chain
0 s:CN = k8s.io
i:C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
1 s:C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
i:O = Digital Signature Trust Co., CN = DST Root CA X3
---
Server certificate
-----BEGIN CERTIFICATE-----
[Content cut]
-----END CERTIFICATE-----
subject=CN = k8s.io

issuer=C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3

---
No client certificate CA names sent
Peer signing digest: SHA256
Peer signature type: RSA-PSS
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 3915 bytes and written 378 bytes
Verification: OK
---
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Server public key is 2048 bit
Secure Renegotiation IS NOT supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 0 (ok)
---
```

자체 서명 CA를 쓴다면 `-CAfile <path>`로 그 CA를 사용할 수 있다. 이러면 자체 서명 인증서에 대한 연결을 설정하고 검증할 수 있다.

```bash
openssl x509 -text -noout -in ca.crt 
```

## cURL

cURL은 HTTP와 HTTPS를 포함한 여러 프로토콜을 지원하는 데이터 전송 도구다.

> wget은 curl과 비슷한 도구다. 일부 배포판이나 관리자는 curl 대신 wget을 설치하기도 한다.

cURL 명령은 `curl [options] <URL>` 형태다. cURL은 URL의 내용과 때때로 cURL 관련 메시지를 stdout으로 출력한다. 기본 동작은 HTTP GET 요청을 만드는 것이다:

```bash
$ curl example.org
<!doctype html>
<html>
<head>
    <title>Example Domain</title>
# Truncated
```

기본적으로 cURL은 HTTP 301이나 프로토콜 업그레이드 같은 리다이렉트를 따라가지 않는다. `-L` 플래그(또는 `--location`)를 쓰면 리다이렉트를 따라간다:

```bash
$ curl kubernetes.io
Redirecting to https://kubernetes.io

$ curl -L kubernetes.io
<!doctype html><html lang=en class=no-js><head>
# Truncated
```

특정 HTTP 메서드를 쓰려면 `-X` 옵션을 사용한다. 예를 들어 DELETE 요청은 `curl -X DELETE foo/bar`처럼 만든다.

데이터를 제공하는 방법은 여러 가지다(POST, PUT 등에서):

- URL 인코딩: `-d "key1=value1&key2=value2"`
- JSON: `-d '{"key1":"value1", "key2":"value2"}'`
- 파일로: `-d @data.txt`

`-H` 옵션으로 명시적인 헤더를 추가할 수 있다. Content-Type 같은 기본 헤더는 자동으로 추가된다:

```bash
-H "Content-Type: application/x-www-form-urlencoded"
```

몇 가지 예시를 보자:

```bash
curl -d "key1=value1" -X PUT localhost:8080

curl -H "X-App-Auth: xyz" -d "key1=value1&key2=value2" -X POST https://localhost:8080/demo
```

```bash
$ curl https://expired-tls-site
curl: (60) SSL certificate problem: certificate has expired
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

```bash
$ curl https://expired-tls-site -v
*   Trying 1.2.3.4...
* TCP_NODELAY set
* Connected to expired-tls-site (1.2.3.4) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (OUT), TLS alert, certificate expired (557):
* SSL certificate problem: certificate has expired
* Closing connection 0
curl: (60) SSL certificate problem: certificate has expired

More details here: https://curl.haxx.se/docs/sslcerts.html
# Truncated
```

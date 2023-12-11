# Deamon process

Deamon Process란 메모리에 상주하면서 요청이 들어올 때마다 명령을 수행하는 프로세스이다. (백그라운드에서 작동)

## 작동 방식

Deamon process의 작동 방식은 두가지가 있다.

### standalone 방식

- 각 데몬 프로세스들이 독립적으로 수행되며, 항상 메모리에 상주하는 방식
- 자주 실행되는 데몬 프로세스에 적용되는 방식이다.
- `/etc/rc.d/init.d` 디렉터리에 위치
- 웹 서비스 데몬(apached, httpd, mysqld 등), 메일 서비스 데몬(sendmail 등), NFS 등 서비스 요청이 많은 프로세스들이 standalone 방식으로 작동한다.

### (x)inetd 방식 (Super deamon)
- (x)inted 이라는 Super deamon이 서비스 요청을 받아 해당 데몬을 실행시켜 요청을 처리하는 방식
  - (x)inted는 기존의 inetd를 대체하는 보안이 강화된 오픈 소스 슈퍼 데몬이다.
- 서비스 속도는 standalone 방식보다 느리지만, (x)inted 데몬만 메모리에 상주해 있기 때문에 메모리를 많이 필요로 하지 않는다.
- `/etc/xinetd.d` 디렉터리에 위치
- telnetd, ftpd, pop3d, rsyncd 등의 서비스들이 Super deamon 방식으로 작동한다.

**(x)inted의 특징**
- TCP Wrapper 와 유사한 접근 제어 기능을 갖는다.
- RPC 요청에 대한 지원이 미비하지만, 포트맵(Portmap)으로 해결 가능 • standalone 과의 비교 : 12 페이지 참고 2014(1) 2015(1)
- 주요 기능
  - DoS 공격에 대한 효과적인 억제
  - 로그 파일 크기 제한
  - IP 주소 당 동시 접속 수 제한
  - TCP/UDP 및 RPC 서비스들에 대한 접근제어

**설정 파일 구조** (`/etc/xinetd.d/*`)  
```c
$ vi /etc/xinetd.d/telnet
service telnet {
    disable = no                           // 서비스 사용 설정
    socket_type = stream                   // tcp = stream , udp = dgram
    wait=no                                // 요청을 받은 후 즉시 다음 요청 처리(no)
    user = root                            // 실행할 사용자 권한 설정
    server = /usr/sbin/in.telnetd          // 서비스 실행 파일 경로
    log_type = FILE /var/log/xinetd.log    // 로그를 기록할 파일 경로 (FILE 선택자 사용 시)
    log_on_failure += USERID               // 로그인 실패 시 로그에 기록할 내용
    no_access = 10.0.0.0/8                 // 접속 거부할 IP 대역    
    only_from = 192.168.10.0/24            // 접속 허용할 IP 대역    
    cps = 10 30                            // 최대 접속 수 제한. 지정한 접속 수 초과할 시 지정 시간동안 서비스가 비활성화됨
    instances = 5                          // 동시에 작동할 수 있는 최대 갯수
    access_times = 08:00-17:00             // 접속 허용 시간대
}
```

**TCP Wrapper**
- Super deamon에 의해 수행되는 호스트 기반의 네트워킹 ACL(Access Control List) 시스템
- `/etc/hosts.allow` 파일과 `/etc/hosts.deny` 파일에 정의된 호스트 정보를 기준으로 접근 통제
- 접근 통제 파일 참조 순서 :`/etc/hosts.allow` → `/etc/hosts.deny` → 두 파일에 없으면 모든 접근 허용

---
참고
- http://litux.nl/Reference/Books/7213/ddu0139.html
- https://man7.org/linux/man-pages/man7/daemon.7.html
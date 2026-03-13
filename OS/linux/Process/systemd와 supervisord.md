
systemd와 supervisord는 둘 다 Linux에서 프로세스를 관리하는 도구이지만, 동작하는 계층이 다르다. systemd는 PID 1 init 시스템이고, supervisord는 유저스페이스 프로세스 매니저이다.

## systemd

Linux의 init 시스템이다. PID 1로 동작하면서 부팅, 서비스 관리, 마운트, 네트워크, 로깅까지 담당한다. 대부분의 주요 배포판(RHEL, Ubuntu, Debian, Arch 등)이 기본 init으로 채택하고 있다.

서비스는 unit 파일로 정의한다.

```ini
[Unit]
Description=My Application
After=network.target
Requires=postgresql.service

[Service]
Type=notify
ExecStart=/usr/bin/myapp --config /etc/myapp.conf
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
User=myapp
Group=myapp
MemoryMax=512M
CPUQuota=50%

[Install]
WantedBy=multi-user.target
```

`systemctl`로 서비스를 제어하고 `journalctl`로 로그를 본다.

```bash
systemctl start myapp          # 시작
systemctl enable myapp         # 부팅 시 자동 시작
systemctl status myapp         # 상태 확인
journalctl -u myapp -f         # 실시간 로그
systemctl show myapp -p MemoryCurrent  # 현재 메모리 사용량
```

**서비스 타입**

`Type=` 지시어로 프로세스의 준비 완료를 판단하는 방식을 지정한다.

- **simple** (기본값): `ExecStart`가 실행되면 즉시 준비 완료로 간주한다. 대부분의 foreground 프로세스에 적합하다.
- **forking**: 프로세스가 fork 후 부모가 종료되면 준비 완료로 간주한다. 전통적인 데몬(Apache httpd 등)이 이 방식이다. `PIDFile=`로 자식의 PID 파일 위치를 알려줘야 한다.
- **notify**: 프로세스가 `sd_notify(READY=1)`를 호출하면 준비 완료로 간주한다. 프로세스가 내부 초기화(DB 연결, 캐시 워밍업 등)를 마친 시점을 정확히 알릴 수 있다.
- **oneshot**: 프로세스가 종료되면 완료로 간주한다. 실행 후 끝나는 스크립트에 적합하다. `RemainAfterExit=yes`와 함께 쓰면 종료 후에도 active 상태를 유지한다.

**의존성**

`After=`/`Before=`는 시작 순서만 지정하고, `Requires=`/`Wants=`는 의존 관계를 지정한다. 이 둘은 독립적이다.

```ini
After=postgresql.service     # postgresql이 시작된 후에 시작
Requires=postgresql.service  # postgresql이 없으면 같이 실패
```

`Requires`+`After` 조합이 "선행 서비스가 준비된 후에 시작하고, 그게 죽으면 나도 중단"하는 일반적인 의존성이다. `Wants`는 약한 의존성으로, 대상이 실패해도 자신은 계속 동작한다.

**프로세스 추적**

systemd는 서비스마다 전용 [cgroup](./cgroup.md)을 생성한다. 서비스 프로세스가 fork한 자식, 그 자식이 또 fork한 손자까지 전부 같은 cgroup에 속한다. `systemctl stop`을 하면 cgroup 내 모든 프로세스에 시그널을 보내므로, 데몬이 fork-exec로 자식을 만들어도 누락 없이 정리할 수 있다.

이 구조 때문에 PID 파일에 의존할 필요가 줄어든다. PID 파일은 프로세스가 죽고 PID가 재사용되면 엉뚱한 프로세스를 가리키는 문제(PID recycling)가 있는데, cgroup 기반 추적에는 이 문제가 없다.

**타이머**

cron 대체. `.timer` unit으로 주기적/일회성 작업을 스케줄링한다.

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Daily backup

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true   # 꺼져있던 동안 놓친 실행을 부팅 후 보상

[Install]
WantedBy=timers.target
```

cron과 달리 journalctl로 로그를 통합 관리할 수 있고, `Persistent=true`로 놓친 실행을 보상하며, 서비스 unit의 리소스 제한을 그대로 적용할 수 있다. `systemctl list-timers`로 전체 타이머 상태를 확인한다.

**소켓 활성화**

서비스가 항상 떠 있지 않아도, 해당 소켓에 연결이 들어오면 그때 서비스를 시작한다.

```ini
# /etc/systemd/system/myapp.socket
[Socket]
ListenStream=8080

[Install]
WantedBy=sockets.target
```

systemd가 소켓을 들고 있다가 연결이 오면 서비스를 깨운다. 서비스가 죽어도 소켓은 systemd가 유지하므로 연결이 끊기지 않고, 서비스가 재시작되면 큐에 쌓인 연결을 처리한다. 무중단 배포에도 활용할 수 있다.

**journald**

systemd에 통합된 로깅 시스템. stdout/stderr, syslog, 커널 메시지를 전부 수집하여 바이너리 저널에 저장한다.

```bash
journalctl -u nginx -f              # 특정 서비스 실시간 로그
journalctl --since "1 hour ago"     # 시간 범위
journalctl -p err                   # 에러 이상만
journalctl _PID=1234                # 특정 PID
journalctl -o json                  # JSON 출력
```

구조화된 필드(유닛명, PID, 우선순위 등)로 필터링할 수 있어서 텍스트 기반 syslog보다 검색이 편하다. `Storage=volatile`로 메모리에만 저장하거나, `SystemMaxUse=`로 디스크 사용량을 제한한다.

**tmpfiles.d**

부팅 시 또는 주기적으로 디렉토리 생성, 권한 설정, 오래된 파일 정리를 수행한다.

```ini
# /etc/tmpfiles.d/myapp.conf
d /run/myapp 0755 myapp myapp -
D /tmp/myapp-cache 0700 myapp myapp 7d    # 7일 지난 파일 자동 삭제
```

`systemd-tmpfiles --create`로 즉시 적용하거나, `systemd-tmpfiles-clean.timer`가 주기적으로 정리한다.

**networkd / resolved**

systemd-networkd는 네트워크 인터페이스 설정을 담당한다. `.network` 파일로 선언적으로 정의한다.

```ini
# /etc/systemd/network/20-wired.network
[Match]
Name=eth0

[Network]
DHCP=yes
DNS=8.8.8.8
```

systemd-resolved는 DNS 리졸버로, DNS-over-TLS도 지원한다. 서버 환경에서는 NetworkManager 대신 networkd를 쓰는 경우가 많다.

**mount / automount**

fstab 대신 `.mount` unit으로 파일시스템 마운트를 관리할 수 있다. `.automount`를 쓰면 해당 경로에 접근할 때만 마운트한다.

```ini
# /etc/systemd/system/mnt-data.automount
[Automount]
Where=/mnt/data
TimeoutIdleSec=300   # 5분간 접근 없으면 언마운트
```

NFS 같은 네트워크 마운트에서 부팅 지연을 피하는 데 유용하다.

**nspawn**

`systemd-nspawn`은 chroot의 상위 호환이다. 별도의 파일시스템 트리를 격리된 네임스페이스에서 실행한다. Docker보다 가볍고, OS 테스트나 빌드 환경 격리에 쓴다.

```bash
systemd-nspawn -D /var/lib/machines/testenv --boot
```

`machinectl`로 관리하고, 호스트의 systemd와 통합되어 cgroup 리소스 제한도 적용된다.

**사용자 세션 관리 (logind)**

systemd-logind가 사용자 로그인 세션을 관리한다. 세션별 cgroup을 생성하고, 사용자가 로그아웃하면 남은 프로세스를 정리한다.

```bash
loginctl list-sessions           # 현재 세션
loginctl user-status rlaisqls    # 사용자의 프로세스 트리
loginctl enable-linger rlaisqls  # 로그아웃 후에도 사용자 서비스 유지
```

`enable-linger`는 사용자가 로그인하지 않아도 해당 사용자의 systemd 유저 인스턴스를 유지한다. 비대화형 서비스를 일반 유저 권한으로 돌릴 때 쓴다.

**사용자 단위 서비스**

root 권한 없이 `~/.config/systemd/user/`에 unit 파일을 두고 개인 서비스를 관리할 수 있다.

```bash
systemctl --user start myapp
systemctl --user enable myapp
journalctl --user -u myapp
```

공유 서버에서 root 없이 데몬을 돌리거나, 개발 환경에서 로컬 서비스를 관리할 때 유용하다.

**기타 구성 요소**

- **systemd-oomd**: 커널 OOM killer보다 먼저 메모리 압박을 감지해서 cgroup 단위로 프로세스를 종료한다
- **systemd-coredump**: 코어 덤프를 수집하고 `coredumpctl`로 조회한다
- **systemd-homed**: 사용자 홈 디렉토리를 LUKS 암호화 이미지로 관리한다
- **portablectl**: 컨테이너와 패키지의 중간 개념. 서비스 이미지를 호스트에 attach하여 실행한다

systemd가 이렇게 넓은 범위를 커버하는 것에 대해 "하나가 너무 많은 걸 한다"는 비판도 있고, Devuan 같은 배포판은 sysvinit/OpenRC를 고수한다. 하지만 현실적으로 주요 배포판이 전부 채택했고, 이 도구들을 활용하면 별도의 cron, syslog, inetd, autofs를 대체할 수 있다.

## supervisord

Python으로 작성된 유저스페이스 프로세스 매니저이다. OS 전체가 아니라 애플리케이션 프로세스 관리에 초점이 맞춰져 있다.

```ini
[program:myapp]
command=/usr/bin/python app.py
directory=/opt/myapp
autostart=true
autorestart=unexpected
startretries=3
startsecs=10
exitcodes=0
stdout_logfile=/var/log/myapp.stdout.log
stderr_logfile=/var/log/myapp.stderr.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=10
environment=DATABASE_URL="postgres://localhost/mydb"
user=myapp
```

`supervisorctl`로 제어하고, XML-RPC 기반 웹 UI도 지원한다.

```bash
supervisorctl status           # 전체 상태
supervisorctl start myapp      # 시작
supervisorctl tail -f myapp    # 실시간 로그
supervisorctl update           # 설정 변경 반영
```

**프로세스 그룹**

여러 프로세스를 그룹으로 묶어서 한 번에 제어할 수 있다.

```ini
[group:webstack]
programs=nginx,gunicorn,celery
```

`supervisorctl start webstack:*`으로 그룹 전체를 시작한다.

**이벤트 리스너**

프로세스 상태 변화(시작, 종료, 크래시 등)에 반응하는 커스텀 리스너를 등록할 수 있다. 프로세스가 죽으면 Slack 알림을 보내는 식의 처리가 가능하다.

```ini
[eventlistener:crashmail]
command=/usr/bin/crashmail -a -m ops@example.com
events=PROCESS_STATE_EXITED
```

**한계**

supervisord 자체가 PID 1이 아니다. supervisord가 죽으면 관리하던 프로세스 모두가 고아(orphan)가 된다. 또한 fork한 직접 자식만 추적하기 때문에, 자식이 또 fork한 손자 프로세스는 관리 범위 밖이다. cgroup 통합이 없으므로 리소스 제한도 직접 할 수 없다.

## 비교

- **프로세스 추적**: systemd는 cgroup으로 프로세스 트리 전체를 추적한다. supervisord는 직접 fork한 자식만 안다.
- **리소스 제한**: systemd는 `MemoryMax`, `CPUQuota` 등 cgroup 기반 제한을 unit 파일에서 선언한다. supervisord에는 이 기능이 없다.
- **의존성**: systemd는 서비스 간 순서와 의존성을 선언적으로 정의한다. supervisord는 `priority` 값으로 시작 순서를 조절하는 정도이다.
- **로깅**: systemd는 journald와 통합되어 구조화된 로깅을 제공한다. supervisord는 자체적으로 로그 파일을 관리한다.
- **권한**: systemd는 root로 PID 1에서 동작한다. supervisord는 일반 유저로도 실행할 수 있다.
- **이식성**: supervisord는 대부분의 Unix에서 동작한다. systemd는 Linux 전용이다.

systemd가 있는 환경이라면 supervisord를 추가할 이유는 별로 없다.

## 컨테이너에서의 프로세스 관리

컨테이너에서 여러 프로세스를 관리해야 할 때 systemd 대신 supervisord나 s6, tini 같은 경량 도구를 쓰는 경우가 많다.

systemd가 init으로 동작하려면 PID 1 점유, `/sys/fs/cgroup` 읽기/쓰기, D-Bus 시스템 버스, `CAP_SYS_ADMIN` 등의 조건이 필요하다. 컨테이너는 기본적으로 이 조건을 충족하지 못한다.

우선 컨테이너의 PID 1은 애플리케이션 프로세스가 차지한다. `CMD ["nginx"]`라고 선언하면 nginx가 PID 1이 된다. systemd가 끼어들면 "컨테이너 하나에 관심사 하나"라는 원칙과 맞지 않는다.

cgroup도 문제이다. 호스트의 cgroup은 컨테이너 런타임(containerd, runc)이 관리한다. 컨테이너 내부에서 systemd가 cgroup을 건드리면 호스트와 충돌할 수 있다. 컨테이너는 기본적으로 unprivileged이므로 `CAP_SYS_ADMIN`이 없어서 systemd가 필요한 작업을 수행할 수도 없다.

근본적으로 컨테이너에는 부팅이 없다. 파일시스템 마운트, 네트워크 인터페이스, 디바이스 초기화는 호스트와 런타임이 이미 끝내놓은 상태이다. init 시스템이 할 일이 없다.

`--privileged`와 cgroup 마운트를 조합하면 억지로 돌릴 수는 있고, CI에서 systemd 서비스를 테스트하거나 VM 대체 용도로 쓰는 경우가 있긴 하다. 하지만 보안상 권장되지 않는다.

---
참고

- <https://www.freedesktop.org/wiki/Software/systemd/>
- <https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html>
- <https://supervisord.org/>
- <https://docs.docker.com/engine/daemon/start/systemd/>

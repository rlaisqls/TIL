
systemd와 supervisord는 둘 다 Linux에서 프로세스를 관리하는 도구이다. 하지만 둘의 범위와 역할은 꽤 다르다.

## supervisord

supervisord는 Python으로 작성된 프로세스 매니저이다. OS 전체가 아니라 애플리케이션 프로세스를 관리하는 데 초점이 맞춰져 있다. 설정 파일은 INI 형식으로, 프로세스를 fork해서 자식으로 직접 관리하는 구조이다.

```ini
[program:myapp]
command=/usr/bin/python app.py
autostart=true
autorestart=true
stdout_logfile=/var/log/myapp.log
```

`supervisorctl`로 start/stop/restart 등을 제어할 수 있고, 웹 UI도 지원한다. 프로세스가 죽으면 자동으로 재시작해주는 것이 핵심 기능이다. 다만 supervisord 자체가 PID 1이 아니기 때문에, supervisord가 죽으면 관리하던 프로세스들도 같이 영향을 받을 수 있다.

## systemd

systemd는 Linux의 init 시스템이다. PID 1로 동작하면서 OS 전체의 부팅 과정, 서비스 관리, 마운트, 네트워크, 로깅까지 담당한다.

```ini
[Unit]
Description=My Application
After=network.target

[Service]
ExecStart=/usr/bin/python app.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

cgroups를 통한 리소스 제한, 서비스 간 의존성 선언(`After=`, `Requires=`), 소켓 활성화 등 기능이 많다. `systemctl`로 서비스를 제어하고 `journalctl`로 로그를 본다. 커널과 긴밀하게 통합되어 있어서, 프로세스 트리 전체를 cgroups로 추적할 수 있다는 점이 supervisord와의 큰 차이다. supervisord는 직접 fork한 자식만 알고 있지만, systemd는 그 자식이 또 fork한 손자 프로세스까지 놓치지 않는다.

그 외 차이를 정리하면 다음과 같다.

- **권한**: systemd는 root로 PID 1에서 동작한다. supervisord는 일반 유저로도 실행할 수 있다
- **의존성 관리**: systemd는 서비스 간 순서와 의존성을 선언적으로 정의할 수 있다. supervisord는 `priority` 값으로 시작 순서를 조절하는 정도이다
- **로깅**: systemd는 journald와 통합되어 있고, supervisord는 자체적으로 로그 파일을 관리한다
- **이식성**: supervisord는 대부분의 Unix에서 동작하지만, systemd는 Linux 전용이다

현재 systemd가 있는 환경이라면 굳이 supervisord를 추가로 설치할 이유는 많지 않다.

## 컨테이너에서 systemd를 쓰지 않는 이유

컨테이너 안에서 여러 프로세스를 관리해야 할 때, systemd 대신 supervisord나 s6 같은 경량 도구를 쓰는 경우가 많다. 왜 그럴까?

systemd가 init 시스템으로 동작하려면 다음 조건이 필요하다.

- PID 1로 실행되어야 한다
- `/sys/fs/cgroup`에 읽기/쓰기 접근이 가능해야 한다
- D-Bus 시스템 버스가 있어야 한다
- 마운트, 네트워크 설정, 디바이스 관리 등을 위한 커널 특권이 필요하다

컨테이너는 이 조건들을 충족하지 못한다.

우선, 컨테이너의 PID 1은 애플리케이션 프로세스가 차지한다. `CMD ["nginx"]`라고 선언하면 nginx가 PID 1이 된다. systemd가 여기에 끼어들면 "하나의 컨테이너에 하나의 관심사"라는 원칙과 맞지 않는다.

cgroups도 문제가 된다. 호스트의 cgroups는 컨테이너 런타임(containerd, runc 등)이 이미 관리하고 있다. 컨테이너 내부에서 systemd가 cgroups를 건드리면 호스트 쪽과 충돌할 수 있다. 거기다 컨테이너는 기본적으로 unprivileged로 실행되기 때문에 `CAP_SYS_ADMIN` 같은 capability가 없어서 systemd가 필요한 작업을 수행할 수 없다.

근본적으로, 컨테이너에는 부팅 과정 자체가 없다. 파일시스템 마운트, 네트워크 인터페이스 설정, 디바이스 초기화 같은 일은 호스트와 컨테이너 런타임이 이미 다 해놓은 상태이다. init 시스템이 해줄 일이 없다.

`--privileged` 플래그와 cgroup 마운트 등을 조합하면 억지로 돌릴 수는 있다. CI에서 systemd 서비스를 테스트하거나 VM 대체 용도로 쓰는 경우가 실제로 있긴 하다. 하지만 보안상 권장되지 않고 컨테이너의 경량화 철학과도 거리가 멀다.

---
참고

- https://supervisord.org/
- https://www.freedesktop.org/wiki/Software/systemd/
- https://docs.docker.com/engine/daemon/start/systemd/

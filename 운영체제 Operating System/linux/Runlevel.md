# Runlevel

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/db6af408-ed8e-45bc-882c-789ae5c112d5)

---

### Runlevel 확인

런레벨은 아래 경로에 runlevel로 검색하면 시스템에 등록된 Runlevel을 직접 확인할 수 있다.

- 경로 : `/lib/systemd/system`
- 파일명 : `runlevel*.target`

```bash
$ sudo ls -al /lib/systemd/system/runlevel*.target
lrwxrwxrwx 1 root root 15 Mar  2 21:58 /lib/systemd/system/runlevel0.target -> poweroff.target
lrwxrwxrwx 1 root root 13 Mar  2 21:58 /lib/systemd/system/runlevel1.target -> rescue.target
lrwxrwxrwx 1 root root 17 Mar  2 21:58 /lib/systemd/system/runlevel2.target -> multi-user.target
lrwxrwxrwx 1 root root 17 Mar  2 21:58 /lib/systemd/system/runlevel3.target -> multi-user.target
lrwxrwxrwx 1 root root 17 Mar  2 21:58 /lib/systemd/system/runlevel4.target -> multi-user.target
lrwxrwxrwx 1 root root 16 Mar  2 21:58 /lib/systemd/system/runlevel5.target -> graphical.target
lrwxrwxrwx 1 root root 13 Mar  2 21:58 /lib/systemd/system/runlevel6.target -> reboot.target
```

기본으로 지정된 런레벨 확인은 symbolic link가 `default.target`으로 걸려있는 파일을 찾으면 된다.

```bash
$ sudo ls -al /lib/systemd/system/default.target
lrwxrwxrwx 1 root root 16 Mar  2 21:58 /lib/systemd/system/default.target -> graphical.target
```

---

### Runlevel 설정하는 방법

`default.target`의 심볼릭 링크 파일을 변경하면 기본 런레벨 변경을 할 수 있다.

- 변경 전: 그래픽 모드 (런레벨 5)
- 변경 후: 콘솔 모드 (런레벨 3)

```bash
$ ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
$ ls -al /etc/systemd/system/default.target
lrwxrwxrwx. 1 root root 37 Sep 25 15:05 /etc/systemd/system/default.target -> /lib/systemd/system/multi-user.target
```

---

### 관련 명령어

- chkconfig : 간단한 유틸리티로 특정 run level에서 실행할 프로그램을 등록/설정/변경 할수 있음
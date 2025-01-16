보통 서버의 타임존은 NTP 라는 프로토콜로 중앙 서버와 통신하여 동기화된다.

`timedatectl`로 Local time과 NTP 정보를 확인할 수 있다.

```
$ timedatectl
     Local time: 금 2025-01-17 01:46:55 KST
  Universal time: 목 2025-01-16 16:46:55 UTC
        RTC time: 목 2025-01-16 16:46:56
       Time zone: Asia/Seoul (KST, +0900)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: no
      DST active: n/a

$ timedatectl --help
timedatectl [OPTIONS...] COMMAND ...

Query or change system time and date settings.

  -h --help                Show this help message
     --version             Show package version
     --no-pager            Do not pipe output into a pager
     --no-ask-password     Do not prompt for password
  -H --host=[USER@]HOST    Operate on remote host
  -M --machine=CONTAINER   Operate on local container
     --adjust-system-clock Adjust system clock when changing local RTC mode

Commands:
  status                   Show current time settings
  set-time TIME            Set system time
  set-timezone ZONE        Set system time zone
  list-timezones           Show known time zones
  set-local-rtc BOOL       Control whether RTC is in local time
  set-ntp BOOL             Control whether NTP is enabled
```

### chronyd

NTP 정보를 가져와서 동기화하는 데몬은 여러가지가 존재한다. (chronyd, ntpd, timesyncd 등..)

그 중 chronyd는 아래처럼 정보를 확인, 설정할 수 있다.

```
$ ls /etc/chrony.d
README  link-local.sources  ntp-pool.sources

$ cat /etc/chrony.d/README
This directory splits up the configuration of chrony into multiple fragments so
that NTP servers can be more easily dynamically configured at an instance's
launch time without losing customizations at a global level.

Files found under the /etc/chrony.d directory with the ".conf" extension are
parsed in the lexicographical order of the file names when chronyd starts up.

Files in this directory that end with the ".sources" extension can only contain
the "peer", "pool" and "server" directives and must have all lines terminated by
a trailing newline. There is no need to restart chronyd for these time sources
to be usable, running 'chronyc reload sources' is sufficient.

Example:
# echo 'server 192.0.2.1 iburst' > /etc/chrony.d/local-ntp-server.sources
# chronyc reload sources

Note: for any settings in this directory to take effect, /etc/chrony.conf
must have the following two directive enabled:

confdir /etc/chrony.d
sourcedir /etc/chrony.d

If they are not present, then previous modifications to this file may have
prevented the RPM Package Manager from updating and overwriting chrony's
configuration with new defaults. You can either replace chrony.conf with
/etc/chrony.conf.rpmnew or manually merge desired changes by hand.
```

### AWS의 NTP

amazon linux ami로 EC2를 생성해서 chroyd 데몬 설정을 확인해보면 Amazon에서 제공하는 NTP 서버를 바라보고 있는 걸 알 수 있다.

따라서 AWS에서 관리하는 EC2는 기본적으로 같은 time으로 동기화된다.

- <https://docs.aws.amazon.com/ko_kr/AWSEC2/latest/UserGuide/set-time.html>

---
참고
<https://ubuntu.com/server/docs/use-timedatectl-and-t>d

## namespace

VM에서는 각 게스트 머신별로 독립적인 공간을 제공하고 서로가 충돌하지 않도록 하는 기능을 갖고 있다. 리눅스에서는 이와 동일한 역할을 하는 namespaces 기능을 커널에 내장하고 있다. 리눅스 커널에서는 다음 6가지 namespace를 지원하고 있다. 

|namespace|description|
|-|-|
|mnt<br/>(파일시스템 마운트)|호스트 파일시스템에 구애받지 않고 독립적으로 파일시스템을|마운트하거나 언마운트 가능|
|pid<br/>(프로세스)|독립적인 프로세스 공간을 할당|
|net<br/>(네트워크)|namespace간에 network 충돌 방지 (중복 포트 바인딩 등)|
|ipc<br/>(SystemV IPC)|프로세스간의 독립적인 통신통로 할당|
|uts<br/>(hostname)|독립적인 hostname 할당|
|user<br/>(UID)|독립적인 사용자 할당|

namespaces를 지원하는 리눅스 커널을 사용하고 있다면 다음 명령어를 통해 바로 namespace를 만들어 실행할 수 있다. 예시로 PID namespace를 띄워보자.

```js
$ sudo unshare --fork --pid --mount-proc bash
```

```js
root@ec2-user:~# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  4.0  0.0  17656  6924 pts/9    S    22:06   0:00 bash
root         2  0.0  0.0  30408  1504 pts/9    R+   22:06   0:00 ps aux
```

namespace를 생성함으로써 독립적인 공간이 할당되었다. PID namespace에 실행한 bash가 PID 1로 할당되어 있고(일반적으로 init(커널)이 PID 1) 바로 다음으로 실행한 "ps aux" 명령어가 PID 2를 배정받았다.

PID namespace 안에서 실행한 프로세스는 밖에서도 확인할 수 있다. namespaces 기능은 같은 공간을 공유하되 조금 더 제한된 공간을 할당해주는 것이라 볼 수 있다.

namespace를 통해 독립적인 공간을 할당한 후에는 nsenter(namespace enter)라는 명령어를 통해 이미 돌아가고 있는 namespace 공간에 접근할 수 있다.

Docker에서는 docker exec가 이와 비슷한 역할을 하고 있다. (단 nsenter의 경우 docker exec와는 다르게 cgroups에 들어가지 않기 때문에 리소스 제한의 영향을 받지 않는다)

## cgroups (Control Groups)

cgroups(Control Groups)는 자원(resources)에 대한 제어를 가능하게 해주는 리눅스 커널의 기능이다. `메모리`, `CPU`, `I/O`, `네트워크`, `device 노드`등의 리소스에 제한을 걸 수 있다.

실행중인 프로그램의 메모리를 제한하고 싶다면 `/sys/fs/cgroup/*/groupname`의 아래에 있는 파일의 내용을 수정하면 된다.

```bash
$ echo 2000000 > /sys/fs/cgroup/memory/testgrp/memory.kmem.limit_in_bytes
```

최대 메모리 사용량을 2MB로 제한하는 명령어이다.
# signal

리눅스에서는 프로세스끼리 서로 통신할 때 정해진 signal을 사용한다.

리눅스에서 사용하는 signal에는 사용자의 key interrupt로 인한 signal, 프로세스나 하드웨어가 발생시키는 signal 등 다양한 종류가 있다.

signal 목록을 확인하고 싶다면 `kill -l` 명령어를 치면 된다. (`man 7 signal`으로 더 자세하게 확인할 수도 있다.)

```bash
$ kill -l
 1) SIGHUP	 2) SIGINT	 3) SIGQUIT	 4) SIGILL	 5) SIGTRAP
 6) SIGABRT	 7) SIGBUS	 8) SIGFPE	 9) SIGKILL	10) SIGUSR1
11) SIGSEGV	12) SIGUSR2	13) SIGPIPE	14) SIGALRM	15) SIGTERM
16) SIGSTKFLT	17) SIGCHLD	18) SIGCONT	19) SIGSTOP	20) SIGTSTP
21) SIGTTIN	22) SIGTTOU	23) SIGURG	24) SIGXCPU	25) SIGXFSZ
26) SIGVTALRM	27) SIGPROF	28) SIGWINCH	29) SIGIO	30) SIGPWR
31) SIGSYS	34) SIGRTMIN	35) SIGRTMIN+1	36) SIGRTMIN+2	37) SIGRTMIN+3
38) SIGRTMIN+4	39) SIGRTMIN+5	40) SIGRTMIN+6	41) SIGRTMIN+7	42) SIGRTMIN+8
43) SIGRTMIN+9	44) SIGRTMIN+10	45) SIGRTMIN+11	46) SIGRTMIN+12	47) SIGRTMIN+13
48) SIGRTMIN+14	49) SIGRTMIN+15	50) SIGRTMAX-14	51) SIGRTMAX-13	52) SIGRTMAX-12
53) SIGRTMAX-11	54) SIGRTMAX-10	55) SIGRTMAX-9	56) SIGRTMAX-8	57) SIGRTMAX-7
58) SIGRTMAX-6	59) SIGRTMAX-5	60) SIGRTMAX-4	61) SIGRTMAX-3	62) SIGRTMAX-2
```

`kill`은 특정 프로세스에 signal을 보내기 위한 명령어이기도 하다.

프로세스를 종료할 때 사용하는 `kill -9 [pid]` 명령어 또한, 9번인 `SIGKILL` signal을 프로세스에 보내 종료시키는 것 이었다...!

## signal handler

프로세스가 signal을 받았을 때는 기본적으로 정의되어있는 동작에 따르지만, 프로세스가 특정 signal을 포착했을 때 수행해야한 별도의 함수는 signal handler로 따로 정의할 수 있다.

프로세스는 signal을 포착했을 떄 작업을 일시중단하고, handler를 수행한 다음 중단된 작업을 재개한다.

## 주로 쓰이는 sinal

자주 사용되는 signal을 몇 개 알아보자.

#### SIGHUP(1)

SIGHUP을 프로세스에게 주면 해당 pid 프로세스가 다시 시작된다. 그래서 데몬 프로세스의 설정을 마치고 설정 내용을 재적용시킬 때 자주 사용된다.

#### SIGKILL(9) vs SIGTERM(15)

둘 다 프로세스를 종료하는 signal이지만 sigkill은 자식 프로세스까지 동시에 즉시 삭제해버리고, sigterm은 자식 프로세스는 건드리지 않는 채 graceful하게 삭제한다.  

#### SIGSTOP(19) vs SIGTSTP(20)

둘 다 프로세스를 대기(정지) 시키는 명령어이다.

`SIGTSTP`는 유저가 키보드로 `Ctrl+Z`를 입력했을 때 쓰이는 signal이고 handler 처리가 가능한 반면에, `SIGSTOP`는 잡아서 처리가 불가능하다.

## signal 종류

아래는 31번까지의 signal의 종류와 동작을 나타내는 표이다.

|번호|signal 이름|발생 및 용도|defailt action|리눅스 버전|
|-|-|-|-|-|
|1|SIGHUP(HUP)|hangup signal; 전화선 끊어짐|종료|POSIX|
|2|SIGINT(INT)|interrupt signal; `Ctrl + c`|종료|ANSI|
|3|SIGQUIT(QUIT)|quit signal; `Ctrl + \` |종료(코어덤프)|POSIX|
|4|SIGILL(ILL)|잘못된 명령||ANSI|
|5|SIGTRAP(TRAP)|트렙 추적||POSIX|
|6|SIGIOT(IOT)|IOT 명령||4.2 BSD|
|7|SIGBUS(BUS)|버스 에러||4.2 BSD|
|8|SIGFPE(FPE)|부동 소수점 에러|종료|ANSI|
|9|SIGKILL(KILL)|무조건적으로 즉시 중지한다.|종료|POSIX|
|10|SIGUSR1(USR1)|사용자 정의 signal1|종료|POSIX|
|11|SIGSEGV(SEGV)|세그멘테이션 위반||ANSI|
|12|SIGUSR2(USR2)|사용자 정의 signal2|종료|POSIX|
|13|SIGPIPE(PIPE)|읽으려는 프로세스가 없는데 파이프에 쓰려고 함|종료|POSIX|
|14|SIGALRM(ALRM)|경보(alarm) signal; alarm(n)에 의해 n초 후 생성됨|종료|POSIX|
|15|SIGTERM(TERM)|일반적으로 kill signal이 전송되기 전에 전송된다. 잡히는 signal이기 때문에 종료되는 것을 트랙할 수 있다.|종료|ANSI|
|16|SIGTKFLT|코프로세서 스택 실패|||
|17|SIGCHLD(CHLD)|프로세스 종료시 그 부모 프로세스에게 보내지는 signal|무시|POSIX|
|18|SIGCONT(CONT)|STOP signal 이후 계속 진행할 때 사용. ; 정지 되지 않은 경우 무시됨||POSIX|
|19|SIGSTOP(STOP)|정지 signal; SIGSTP과 같으나 잡거나 무시할 수 없음|프로세스 정지POSIX|
|20|SIGTSTP(TSTP)|키보드에 의해 발생하는 signal로 `Ctrl + Z`로 생성된다. ; 터미널 정지 문자|프로세스 정지|POSIX|
|21|SIGTTIN|백그라운드에서의 제어터미널 읽기|프로세스 정지|POSIX|
|22|SIGTTOU|백그라운드에서의 제어터미널 쓰기|프로세스 정지|POSIX|
|23|SIGURG|소켓에서의 긴급한 상태||4.2 BSD|
|24|SIGXCPU|CPU 시간 제한 초과 setrlimit(2)||4.2 BSD|
|25|SIGXFSZ|파일 크기제한 초과 setrlimit(2)||4.2 BSD|
|26|SIGVTALRM|가상 시간 경고 setitimer(2)||4.2 BSD|
|27|SIGPROF|프로파일링 타이머 경고. setitimer(2) ||4.2 BSD|
|28|SIGWINCH|윈도우 사이즈 변경4.3 BSD, Sun|
|29|SIGIO|기술자에서 입출력이 가능함. fcntl(2)||4.2 BSD|
|30|SIGPWR|전원 실패||System V|
|31|UNUSED|사용 안함|||

---
참고
- https://linuxhandbook.com/sigterm-vs-sigkill/
- linux man
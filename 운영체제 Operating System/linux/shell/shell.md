# 쉘

쉘은 사용자가 운영체제의 서비스를 사용할 수 있도록 사용자의 입력을 기반으로 프로그램을 실행해 주는 역할을 한다. 즉, 커널과 사용자 사이의 인터페이스 역할을 담당한다. 커널은 쉘로부터 전달 받은 명령을 기계가 이해할 수 있는 언어로 변환하여 CPU, I/O, 메모리 등 다양한 리소스에 접근해 주는 역할을 한다.

다시 말해, 쉘은 사용자(프로그램)에게 받은 명령을 전달받아 커널이 이해할 수 있도록 해석하여 전달하고, 커널은 하드웨어와 직접적으로 통신한다. 사용자는 시스템 손상 방지를 위해 접근할 수 있는 영역이 제한되어 있어 하드웨어에 엑세스하기 위해선 시스템 콜이라는 특정 작업을 수행해야 한다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/558363ec-93b8-46b2-a306-3d13066134bd)

## 시스템 콜 (System Call)

시스템 콜은 Mode bit를 기반으로 0이면 커널모드, 1이면 사용자 모드로 나뉘어서 작동한다. 사용자가 파일 생성, 프로그램 실행 등의 호출을 수행하려면 시스템 콜을 통해 서비스를 제공받을 수 있다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/c0d5e495-ccc5-4dd8-b162-00641684d30f)

예를 들어 유저 프로그램이 I/O 요청을 하면 trap이 발동되면서 모드비트가 1에서 0으로 변경되고, 커널에 전달된다. 커널은 해당 서비스를 수행하고, 다시 trap을 통해 모드비트를 0에서 1로 변경하여 사용자모드로 전달해 준다. 

## 쉘 종류 

`cat /etc/shells` 명령어를 통해 /etc/shells 파일을 보면 현재 운영체제 환경에서 사용할 수 있는 쉘의 종류를 확인할 수 있다. bash, zsh, ksh 등 다양한 쉘의 종류가 있다. 

다양한 쉘의 종류가 있으며 대부분 bash나 zsh를 많이 쓴다.

```bash
# List of acceptable shells for chpass(1).
# Ftpd will not allow users to connect who are not using
# one of these shells.

/bin/bash
/bin/csh
/bin/dash
/bin/ksh
/bin/sh
/bin/tcsh
/bin/zsh
```

|쉘 이름|위치|특징|
|-|-|-|
|sh (Bourne Shell)|`/bin/sh`|최초의 유닉스 쉘로 스크립트를 지원하며 sh로 표기한다. 본쉘은 논리 및 산술 연산을 처리하는 내장 기능이 없어 이전에 사용한 명령을 기억할 수 없다. (history 기능 제공하지 않음)|
|ksh (Korn Shell)|`/bin/ksh`|본 쉘을 개선한 상위집합으로 history, alias 등의 작업기능이 추가되었다. (csh, sh 보다 빠름)|
|csh (C Shell)|`/bin/csh`|ksh 처럼 본쉘의 개선버전으로 history, alias, ~ (홈디렉토리) 기능 추가, 명령어 편집 기능 제공 X 
|tcsh|`/bin/tcsh`|csh 개선 버전으로 명령어 편집기능 제공, 자동완성, where 명령어 제공|
|bash (Bourne Again Shell)|`/bin/bash`|본쉘의 확장버전으로 만든 Unix 쉘로 Linux, Mac의 기본 쉘로 사용된다.<br>mv, cp, rm, touch, ls, mkdir, cd, rmdir 등의 명령어 들이 추가되었다.|
|zsh|`/bin/zsh`|bash, ksh, tcsh의 기능을 결합하여 맞춤법 검사, 로그인 감시, 자동 생성, 플러그인 및 테마가 지원되며, oh my zsh 등의 사용자 정의 테마를 지원한다.|

#### 사용 중인 shell 확인
```bash
echo $0
echo $SHELL
ps | grep sh
env | grep SHELL
```

#### shell 변경
```bash
chsh -s [shell이름] [사용자명]
chsh -s /bin/bash sasca37
```

현재 사용중인 쉘을 변경하려면 그냥 실행하고자 하는 쉘 이름을 넣으면 된다고 한다.
```bash
$ tcsh
```

---
참고
- https://www.tutorialspoint.com/unix/unix-what-is-shell.htm
- https://linuxcommand.org/lc3_lts0010.php
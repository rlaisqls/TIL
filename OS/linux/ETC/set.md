linux의 set 명령어는 다양한 기능을 가지고 있다.

### 변수 출력

set 명령어를 인수 없이 실행하면 셸에 설정된 환경변수 및 변수 목록을 출력한다.

```
$ set
'!'=0
'#'=0
'$'=65931
'*'=(  )
-=569XZilms
0=-zsh
'?'=0
@=(  )
ARGC=0
BUN_INSTALL=/Users/rlaisqls/.bun
CDPATH=''
COLORTERM=truecolor
COLUMNS=178
COMMAND_MODE=unix2003
CPUTYPE=arm64
DISABLE_UPDATE_PROMPT=true
...
```

### 옵션

set 명령어의 옵션으로 셸의 다양한 동작 모드를 설정할 수 있다.
각 옵션 앞에 -를 붙여서 사용하면(`-a`) 옵션을 추가한다는 뜻이고, +를 붙이면 (`+a`)는 옵션을 삭제한다는 뜻이다.

- `-a` (allexport): 모든 변수를 자동으로 내보내기한다. 이 옵션을 사용하면 새로 만들거나 수정한 모든 변수가 자동으로 환경 변수가 된다.
  - 예시

        ```bash
        set -a
        MY_VAR="Hello"  # MY_VAR은 자동으로 환경 변수가 된다
        ```

- `-b` (notify): 백그라운드 작업이 끝나면 즉시 알려준다. 보통은 다음 프롬프트가 나타날 때 알려주지만, 이 옵션을 사용하면 작업이 끝나자마자 바로 알림을 받을 수 있다.
  - 예시

        ```bash
        set -b
        sleep 10 &  # 10초 동안 대기하는 백그라운드 작업
        # 10초 후 즉시 "Done" 메시지를 받게 된다
        ```

- `-B` (braceexpand): 중괄호 확장을 활성화한다. 이 기능을 사용하면 여러 문자열을 간단히 생성할 수 있다.
  - 예시

        ```bash
        echo {1..5}  # 출력: 1 2 3 4 5
        echo {a,b,c}{1,2,3}  # 출력: a1 a2 a3 b1 b2 b3 c1 c2 c3
        ```

- `-C` (noclobber): 기존 파일을 실수로 덮어쓰는 것을 방지한다.
  - 예시

        ```bash
        set -C
        echo "hello" > existing_file.txt  # 이미 파일이 있다면 에러 발생
        ```

- `-e` (errexit): 오류가 발생하면 스크립트 실행을 즉시 중단한다. 디버깅에 유용하다.
  - 예시

        ```bash
        set -e
        non_existent_command  # 이 명령어가 실패하면 스크립트가 여기서 종료된다
        echo "실행되지 않는 라인"
        ```

- `-f` (noglob): 파일명 확장(와일드카드 사용)을 비활성화한다.
  - 예시

        ```bash
        set -f
        echo *  # '*'가 확장되지 않고 그대로 출력된다
        ```

- `-h` (hashall): 실행한 명령어의 위치를 기억한다. 이를 통해 같은 명령어를 다시 실행할 때 더 빠르게 찾을 수 있다.
  - 예시

        ```bash
        set -h
        ls  # ls 명령어의 위치를 기억한다
        ls  # 두 번째 실행 시 더 빠르게 찾을 수 있다
        ```

- `-H` (histexpand): 히스토리 확장을 활성화한다. '!'를 사용해 이전 명령어를 쉽게 재사용할 수 있다.
  - 예시

        ```bash
        set -H
        echo "Hello"
        !echo  # "Hello"를 다시 출력한다
        ```

- `-k` (keyword): 모든 키워드 인자를 환경 변수로 취급한다.
  - 예시

        ```bash
        set -k
        VAR1=value1 VAR2=value2 command  # VAR1과 VAR2가 command의 환경 변수가 된다
        ```

- `-m` (monitor): 작업 제어를 활성화한다. 이를 통해 작업을 일시 중지하거나 백그라운드로 보낼 수 있다.
  - 예시

        ```bash
        set -m
        sleep 100 &  # 백그라운드로 작업 실행
        jobs  # 실행 중인 작업 목록 확인
        ```

- `-n` (noexec): 명령어를 실행하지 않고 구문 오류만 검사한다. 스크립트 디버깅에 유용하다.
  - 예시

        ```bash
        set -n
        echo "This is a test"  # 이 명령어는 실제로 실행되지 않는다
        ```

- `-o`: 옵션 없이 사용하면 현재 설정된 모든 옵션을 보여준다. `+o`를 사용하면 현재 설정을 재현할 수 있는 명령어 목록을 출력한다.
  - 예시

        ```bash
        set -o  # 모든 옵션 상태 출력
        set +o  # 현재 설정을 재현할 수 있는 명령어 목록 출력
        ```

### 위치 파라미터 조작

set 명령어를 사용하여 `$1`, `$2`, `$3`과 같은 위치 파라미터에도 값을 대입할 수 있다.
값이 하이픈으로 시작하면 옵션으로 인식한다. `--` 뒤에 인수를 지정하면 하이픈으로 시작하는 값도 변수로 인식한다.

```bash
#!/bin/sh

set "A" "B" "C"
echo $2

# 출력결과: C
```

----
참고

- <https://linuxcommand.org/lc3_man_pages/seth.html>
- <https://ss64.com/bash/set.html>

## wait

```c
#include <sys/wait.h>

pid_t wait(int *_Nullable wstatus);
```

- wait은 child process가 종료될 때까지 기다렸다가 child process가 종료되면 종료된 child process의 값을 반환한다. 
  - 만약 실패하는 경우 `-1`을 반환한다. 

- status에는 child process가 어떤 방식으로 종료되었는지가 담겨있다. 
- 관련 매크로로 상세한 정보를 알아낼 수 있다.
  - `WIFEXITED(status)` : exit, _exit, _Exit 혹은 main에서의 return으로 종료되었는지 여부를 반환한다.
  - `WEXITSTATUS(status)` : `WIFEXITED`의 값이 참인 경우 exit code를 반환한다.
  - `WIFSIGNALED(status)` : signal에 의하여 terminate 되었는지 여부를 반환한다.
  - `WTERMSIG(status)` : `WIFSIGNALED`의 값이 참인 경우 어느 signal에 의하여 terminate 되었는지를 반환한다.

## waitpid

```c
#include <sys/types.h>
#include <sys/wait.h>
 
pid_t waitpid(pid_t pid, int *status, int options);
```

- waitpid 함수는 인수로 주어진 pid 번호의 자식프로세스가 종료되거나, 시그널 함수를 호출하는 신호가 전달될때까지 waitpid를 호출한 영역에서 일시중지 된다.
- 만일 pid로 지정된 자식이 waitpid 함수 호출전에 이미 종료되었다면, 함수는 즉시 리턴하고 자식프로세스는 좀비프로세스로 남는다.

- pid 값은 다음중 하나가 된다.
  - `pid < -1`: 프로세서 그룹 ID가 pid 의 절대값과 같은 자식 프로세스를 기다린다.
  - `pid == -1`: 임의의 자식프로세스를 기다린다. (wait과 동일)
  - `pid == 0`: 프로세스 그룹 ID가 호출 프로세스의 ID와 같은 자식프로세스를 기다린다.
  - `pid > 0`: 프로세스 ID가 pid 의 값과 같은 자식 프로세스를 기다린다.

- options의 값은 0이거나 다음값들의 OR이다.
  - **WNOHANG**: `waitpid()`를 실행했을 때, 자식 프로세스가 종료되어 있지 않으면 블록상태가 되지 않고 바로 리턴하게 해준다.
    - 만약 기다리는 프로세스가 종료되지 않아 프로세스 회수가 불가능한 상황이라면 차단되지 않고 반환값으로 0을 받는다.
  - **WUNTRACED**: pid에 해당하는 자식 프로세스가 멈춤 상태일 경우 그 상태를 리턴한다. 즉 프로세스의 종료뿐 아니라 프로세스의 멈춤상태도 찾아낸다.

---
참고
- https://linux.die.net/man/2/waitpid
- https://www.ibm.com/docs/en/zos/2.1.0?topic=functions-waitpid-wait-specific-child-process-end
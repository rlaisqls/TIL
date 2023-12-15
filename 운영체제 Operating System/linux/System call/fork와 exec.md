# fork와 exec

## fork

```c
pid_t fork(void);
```

- 새로운 자식 프로세스를 생성할 때 사용하는 시스템 호출 함수이다.
- 자식 프로세스는 부모 프로세스의 PCB를 그대로 상속받는다.
- 함수의 반환값은 자식 프로세스에게 `0`, 부모에게는 자식 프로세스의 id이다.

```c
pid_t vfork(void);
```

- `vfork()`도 `fork()`와 마찬가지로 자식 프로세스를 생성하는 함수이다.
- `fork()`와 달리 자식 프로세스가 먼저 실행됨을 보장한다. 따라서 생성된 프로세스가 exec계열 함수를 이용하여 새 프로그램으로 실행하는 경우에 주로 사용한다.
- `vfork()`로 프로세스를 생성한 경우 부모의 주소 영역을 참조하지 않을 것이라고 생각하여 부모 프로세스의 공간을 자식에게 복사하지 않는다.
  - 복사하는 시간이 소요되지 않으므로 fork 보다 약간의 성능 향상이 있다.
- 생성된 자식 프로세스는 exec계열 함수나 `exit()`을 호출할 때까지 부모 프로세스의 메모리 영역에서 실행되고, 부모 프로세스는 자식 프로세스가 exec계열 함수나 `exit()`을 호출할 때까지 기다린다.
- 자식 프로세스를 종료할 때 `_exit()`을 이용해야한다. 
- 부모 프로세스의 표준 입출력 채널을 같이 사용하는데 자식 프로세스가 `exit()`을 호출할 경우 입출력 스트림을 모두 닫으므로, 부모 프로세스에서는 입출력을 하지 못한다. 따라서 입출력 스트림을 정리하지 않고 종료시키는 `_exit()`을 사용해야 한다.

## exec

- exec 계열 함수는 현재 실행되고 있는 프로세스를 다른 프로세스로 대신하여 새로운 프로세스를 실행하는 함수이다.
- 즉, 진행하던 프로세스의 pid와 정보를 물려주고 다른 프로세스로 대체되어 주어진 경로에 있는 새로운 프로세스 동작을 시작한다.

- exec 계열 함수에는 다양한 것들이 있다.

    ```c
    int execl(const char *pathname, const char *arg0, ... /* (char *)0*/);
    int execv(const char *pathname, char *const argv[]);
    int execle(const char *pathname, const char *arg0, .../*(char *)0, char *const envp[] */);
    int execve(const char *pathname,  char *const argv[], char *const envp[]);
    int execlp(const char *filename, const c har *arg0, .../* (char *)0 */);
    int execvp(const char *filename, char *const argv[]);
    ```

  - 뒤에 l이 붙은 경우 : 매개변수의 인자가 list 형태이다. 즉 `char*`형을 나열한다.
  - 뒤에 v가 붙은 경우 : 매개변수의 인자가 vector 형태이다. 두 번째 인잘르 보면 2차원 배열로 `char*`형을 배열로 한 번에 넘긴다.
  - 뒤에 e가 붙은 경우 : 환경변수를 포함하여 넘긴다. 
  - 뒤에 p가 붙은 경우 : 경로 정보가 없는 실행 파일 이름이다. 만약 filename에 `/`(슬래시)가 포함되어 있으면 filename을 경로로 취급하고 슬래시가 없으면 path로 취급한다.

- exec를 실행할 때 본 프로세스는 서브 프로세스에게 pid, ppid, uid, gid, 세션 id, 제어 터미널, 현재 작업 디렉토리, 파일 생성 마스크 등 다양한 정보를 상속해준다.

---
참고
- https://www.baeldung.com/linux/fork-vfork-exec-clone
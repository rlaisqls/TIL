# thread 관련 systemcall

- 우선 스레드란, 프로세스 내에 실행되는 흐름의 단위이다.
  - 프로세스는 반드시 1개 이상의 쓰레드를 가지고 있다.
  - 프로세스와 다르게 한 프로세스 안의 스레드들은 메모리 자원을 공유한다.

## `pthread_create`

- `pthread_create`는 말 그대로 thread를 생성하는 시스템 콜이다.
- 이 시스템 콜을 사용하는 경우 `-pthread` 옵션과 함께 컴파일해야 한다.
- 각 옵션의 의미는 다음과 같다.
  1. **thread**: 성공적으로 함수가 호출되면 이 포인터에 thread ID가 저장된다. 이 인자로 넘어온 값을 통해서 `pthread_join`과 같은 함수를 사용할 수 있다.
  2. **attr**: 스레드의 특성을 정의한다. 만약 스레드의 속성을 지정하려고 한다면 `pthread_attr_init`등의 함수로 초기화해야한다.
  3. **start_routine**: 어떤 로직을 할지 함수 포인터를 매개변수로 받는다. 
  4. **arg**: start_routine에 전달될 인자를 말합니다. start_routine에서 이 인자를 변환하여 사용한다.

```c
NAME
       pthread_create - create a new thread

SYNOPSIS
       #include <pthread.h>

       int pthread_create(pthread_t *thread, const pthread_attr_t *attr,
                          void *(*start_routine) (void *), void *arg);

       Compile and link with -pthread.
```

## `pthread_join`

- thread ID를 받아서 해당 스레드가 종료될 때까지 기다려서 join하는 시스템 콜이다.

```c
NAME
       pthread_join - join with a terminated thread

SYNOPSIS
       #include <pthread.h>

       int pthread_join(pthread_t thread, void **retval);

       Compile and link with -pthread.
```

### 예제

- `thread_routine`이라는 함수에 정의된 동작을 수행하는 스레드를 5개 생성하고, 해당 스레드가 모두 동작하는 동안 main 스레드에서 대기하는 예제이다.

    ```c
    #include <pthread.h>
    #include <stdio.h>
    #include <unistd.h>
    #include <stdlib.h>

    void* thread_routine(void *arg){
        pthread_t tid;

        tid=pthread_self();

        int i=0;
        printf("\ttid:%x\n",tid);
        while(i<10) {
            printf("\tnew thread:%d\n",i);
            i++;
            sleep(1);
        }
    }

    int main() {
        pthread_t thread;
        pthread_create(&thread, NULL, thread_routine, NULL);

        int i=0;
        printf("tid:%x\n",pthread_self());

        while(i<5) {
            printf("main:%d\n",i);
            i++;
            sleep(1);
        }
        pthread_join(thread,NULL);
    }
    ```

- 출력 결과
  
    ```
    tid:f9e36500
    main:0
        tid:6f95f000
        new thread:0
        new thread:1
    main:1
    main:2
        new thread:2
    main:3
        new thread:3
    main:4
        new thread:4
        new thread:5
        new thread:6
        new thread:7
        new thread:8
        new thread:9
    ```

## `pthread-detach`

```c
#define _OPEN_THREADS
#include <pthread.h>

int pthread_detach(pthread_t *thread);
```

- 실행중인 쓰레드를 detached(분리)상태로 만든다.
- 스레드가 독립적으로 동작하길 원하는 경우 사용한다. (join하지 않을 예정인 경우)
- `pthread-detach`는 쓰레드가 종료되는 즉시 쓰레드의 모든 자원을 되돌려(free)줄 것을 보장한다.
  - 반면, `pthread_create`만으로 스레드를 생성하면 루틴이 끝나도 자원이 자동으로 반환되지 않는다. join시에 메인과 함께 메모리가 처리될 것으로 예상하기 때문이다.

---
참고
- https://man7.org/linux/man-pages/man3/pthread_create.3.html
- https://stackoverflow.com/questions/6042970/pthread-detach-question
- https://www.joinc.co.kr/w/man/3/pthread_detach
- https://www.ibm.com/docs/en/zos/2.4.0?topic=functions-pthread-detach-detach-thread
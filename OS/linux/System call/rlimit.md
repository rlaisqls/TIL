## `getrlimit()`와 `setrlimit()`

```c
#include <sys/types.h>
#include <sys/resource.h>
#include <unistd.h>

int getrlimit(int resource, struct rlimit *rlim);
int setrlimit(int resource, const struct rlimit *rlim);
```

- `getrlimit()`과 `setrlimit()`는 자원의 제한값을 조회하거나 설정하기 위해서 사용하는 시스템 콜이다.

- 자원의 종류를 뜻하는 resource는 다음중 하나이다. 

    ```c
    RLIMIT_CPU     /* 초 단위의 CPU 시간 */
    RLIMIT_FSIZE   /* 최대 파일 크기 */
    RLIMIT_DATA    /* 최대 데이타 크기 */
    RLIMIT_STACK   /* 최대 스택 크기 */
    RLIMIT_CORE    /* 최대 코어 파일 크기 */
    RLIMIT_RSS     /* 최대 거주 집합 크기 */
    RLIMIT_NPROC   /* 최대 프로세스 수 */
    RLIMIT_NOFILE  /* 최대 열 수 있는 파일의 수 */
    RLIMIT_MEMLOCK /* 최대 잠긴 기억 장소 주소 공간 */
    RLIMIT_AS      /* 주소 공간(가상 메모리) 제한값 */
    ```

- 리소스의 크기는 rlim로 정의한다. rlim 구조체는 다음의 멤버들을 가진다.
    ```c
    struct rlimit
    {
        rlim_t rlim_cur;   /* soft limit */
        rlim_t rlim_max;   /* Hard limit */ 
    };
    ```

### `getrusage()`

```c
#include <sys/types.h>
#include <sys/resource.h>
#include <unistd.h>

int getrusage(int who, struct rusage *usage);
```
		
`getrusage()`는 현재 사용중인 resource 정보를 반환한다.

- who는 아래 두 값 중 하나이다.
  - `RUSAGE_SELF`: 현재 프로세스가 사용하는 리소스의 정보를 반환한다. 
  - `RUSAGE_CHILDREN`: 현재 프로세스와 그 자식 프로세스들이 사용하는 모든 리소스의 정보를 반환한다. (종료되어서 기다리는 자식 프로세스도 포함된다.) 

- 리소스 정보는 rusage에 저장된다.

    ```c
    struct rusage {
        struct timeval ru_utime; /* user time used */
        struct timeval ru_stime; /* system time used */
        long   ru_maxrss;        /* maximum resident set size */
        long   ru_ixrss;         /* integral shared memory size */
        long   ru_idrss;         /* integral unshared data size */
        long   ru_isrss;         /* integral unshared stack size */
        long   ru_minflt;        /* page reclaims */
        long   ru_majflt;        /* page faults */
        long   ru_nswap;         /* swaps */
        long   ru_inblock;       /* block input operations */
        long   ru_oublock;       /* block output operations */
        long   ru_msgsnd;        /* messages sent */
        long   ru_msgrcv;        /* messages received */
        long   ru_nsignals;      /* signals received */
        long   ru_nvcsw;         /* voluntary context switches */
        long   ru_nivcsw;        /* involuntary context switches */
    };
    ```

## 예제

```c

	
#include <sys/time.h>
#include <sys/resource.h>
#include <unistd.h>
#include <stdio.h>

int main()
{
    struct rlimit rlim;

    // 생성가능한 프로세스의 갯수를 출력한다. (현재 : 최대) 
    getrlimit(RLIMIT_NPROC, &rlim);
    printf("PROC MAX : %lu : %lu\n", rlim.rlim_cur, rlim.rlim_max);

    // 오픈가능한 파일의 갯수를 출력한다.   
    getrlimit(RLIMIT_NOFILE, &rlim);
    printf("FILE MAX : %lu : %lu\n", rlim.rlim_cur, rlim.rlim_max);

    // 사용가능한 CPU자원을 출력한다. 
    getrlimit(RLIMIT_CPU, &rlim);

    // 만약 무한대로 사용가능하다면 UNLIMIT를 출력하도록한다.
    // CPU자원은 최대한 사용가능하도록 되어있음으로 UNLIMIT를 출력할것이다.
    if(rlim.rlim_cur == RLIM_INFINITY)
    {
        printf("UNLIMIT\n");
    }
}
```

```c
#include <sys/time.h>
#include <sys/resource.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char **argv)
{
        struct rlimit rlim;

        getrlimit(RLIMIT_NOFILE, &rlim);
        printf("Open file %d : %d\n", rlim.rlim_cur, rlim.rlim_max);

        rlim.rlim_cur += 1024;
        rlim.rlim_max += 1024;
        if(setrlimit(RLIMIT_NOFILE, &rlim) == -1)
                return 0;
        printf("Open file %d : %d\n", rlim.rlim_cur, rlim.rlim_max);
}
```

---
참고
- https://linux.die.net/man/2/setrlimit
- https://docs.oracle.com/cd/E36784_01/html/E36849/faayq.html
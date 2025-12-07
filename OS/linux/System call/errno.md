errno는 시스템 콜이나 라이브러리 함수가 실패했을 때 에러 원인을 나타내는 전역 변수다.

```c
#include <errno.h>

extern int errno;
```

exit code가 프로세스 종료 상태를 표현하는 것과 비슷하게 errno는 시스템 콜 에러 상태를 나타내는 정수 반환 값이다.

| 구분 | errno | exit code |
|------|-------|-----------|
| 범위 | 시스템 콜 에러 | 프로세스 종료 상태 |
| 접근 | `errno` 변수 | `$?` 또는 `waitpid` |
| 값 | 양수 (1~133+) | 0~255 |
| 0의 의미 | 에러 없음 | 성공 |

## 주요 errno 값

### 리소스 관련

| errno | 값 | 설명 |
|-------|---|------|
| `EAGAIN` | 11 | Resource temporarily unavailable |
| `ENOMEM` | 12 | Out of memory |
| `EBUSY` | 16 | Device or resource busy |
| `EMFILE` | 24 | Too many open files (process limit) |
| `ENFILE` | 23 | Too many open files (system limit) |

### 파일 관련

| errno | 값 | 설명 |
|-------|---|------|
| `ENOENT` | 2 | No such file or directory |
| `EEXIST` | 17 | File exists |
| `EACCES` | 13 | Permission denied |
| `EISDIR` | 21 | Is a directory |
| `ENOTDIR` | 20 | Not a directory |

### 네트워크 관련

| errno | 값 | 설명 |
|-------|---|------|
| `ECONNREFUSED` | 111 | Connection refused |
| `ETIMEDOUT` | 110 | Connection timed out |
| `EADDRINUSE` | 98 | Address already in use |
| `ENETUNREACH` | 101 | Network is unreachable |

### 프로세스/쓰레드 관련

| errno | 값 | 설명 |
|-------|---|------|
| `EINTR` | 4 | Interrupted system call |
| `ECHILD` | 10 | No child processes |
| `ESRCH` | 3 | No such process |

## errno 확인 방법

**C 코드**

```c
#include <stdio.h>
#include <string.h>
#include <errno.h>

if (syscall() == -1) {
    printf("Error: %s (errno=%d)\n", strerror(errno), errno);
    perror("syscall");
}
```

**쉘**

```bash
# 마지막 명령의 exit code
echo $?

# errno 번호로 이름 찾기
python3 -c "import errno; print(errno.errorcode[11])" # EAGAIN
```

**strace 출력**

```
read(3, 0x7fff..., 1024) = -1 EAGAIN (Resource temporarily unavailable)
```

---
참고

- <https://man7.org/linux/man-pages/man3/errno.3.html>
- `/usr/include/asm-generic/errno.h`
- `/usr/include/asm-generic/errno-base.h`

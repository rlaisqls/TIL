TOCTOU(Time-of-Check to Time-of-Use)는 자원의 상태를 검사(check)한 뒤 사용(use)하기까지의 틈에 그 자원이 바뀌어 생기는 race condition이다.

## access + open

`access()`로 권한을 확인하고 `open()`으로 파일을 여는 코드를 생각해보자.

```c
if (access("/tmp/file", W_OK) == 0) {
    int fd = open("/tmp/file", O_WRONLY);
    write(fd, data, len);
    close(fd);
}
```

setuid 프로그램에서 이 코드가 돌아간다고 하자. `access()`는 real UID 기준으로 권한을 검사하고, `open()`은 effective UID(root) 권한으로 파일을 연다. 공격자가 두 호출 사이에 `/tmp/file`을 `/etc/shadow`로 가리키는 심볼릭 링크로 교체하면, `access()`는 원래 파일 기준으로 통과했지만 `open()`은 root 권한으로 `/etc/shadow`를 열게 된다.

두 시스템 콜 사이에 원자성이 보장되지 않기 때문이다. 커널은 각 시스템 콜을 개별적으로 처리하므로, 그 사이에 다른 프로세스가 파일 시스템을 얼마든지 변경할 수 있다. `/tmp`처럼 여러 사용자가 쓸 수 있는 디렉토리에서 특히 위험하다.

## 대응

핵심은 check와 use를 분리하지 않는 것이다.

**`open()` 후 `fstat()`**

파일을 먼저 열고 file descriptor에 대해 검사한다. fd는 열린 시점의 파일을 계속 가리키므로 이후 심볼릭 링크가 교체되어도 영향받지 않는다.

```c
int fd = open("/tmp/file", O_WRONLY | O_NOFOLLOW);
if (fd < 0) return -1;

struct stat st;
fstat(fd, &st);

if (st.st_uid != getuid()) {
    close(fd);
    return -1;
}
write(fd, data, len);
close(fd);
```

여기서 쓴 `O_NOFOLLOW`는 경로의 마지막 구성 요소가 심볼릭 링크이면 `open()`을 실패시키는 플래그다. 심볼릭 링크 교체 공격에 대한 가장 간단한 방어가 된다.

**`openat()` + `O_EXCL`**

디렉토리 fd를 기준으로 상대 경로를 지정하면 경로 탐색 과정의 race condition을 줄일 수 있다. `O_CREAT | O_EXCL` 조합은 파일이 이미 존재하면 실패하므로 생성이 원자적이다.

```c
int dirfd = open("/tmp", O_RDONLY | O_DIRECTORY);
int fd = openat(dirfd, "file", O_WRONLY | O_CREAT | O_EXCL, 0600);
```

아예 공유 디렉토리를 피하는 것도 방법이다. `mkdtemp()`로 해당 사용자만 접근 가능한 임시 디렉토리를 만들면 race condition 자체가 사라진다.

## 다른 영역

파일 시스템 말고도 같은 구조의 문제가 나타난다. 멀티스레드에서 공유 변수를 검사한 뒤 사용하는 패턴(mutex나 atomic으로 해결), 포트가 열려있는지 확인하고 바인드하는 패턴, DB에서 SELECT 후 UPDATE하는 패턴(`SELECT ... FOR UPDATE`로 해결) 등이다.

결국 "확인하고 행동"이 아니라 "행동하고 실패 처리"(ask forgiveness, not permission) 쪽이 TOCTOU에 강건하다.

---
참고

- [CWE-367: Time-of-check Time-of-use (TOCTOU) Race Condition](https://cwe.mitre.org/data/definitions/367.html)
- [Checking Access Permissions — GNU C Library](https://www.gnu.org/software/libc/manual/html_node/Testing-File-Access.html)
- [Secure Coding in C and C++ — Robert Seacord, Chapter 8: File I/O](https://www.oreilly.com/library/view/secure-coding-in/9780132981989/)

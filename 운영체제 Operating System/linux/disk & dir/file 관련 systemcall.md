# file 관련 systemcall

### open

- 파일을 열고 file descriptor 반환

**file descriptor**
- 실행중인 프로그램과 하나의 파일 사이에 연결된 개방 상태
- 음수가 아닌 정수형 값
- 파일 개방이 실패하면 -1이 됨
- 커널에 의해서 관리

```bash
NAME
     open, openat – open or create a file for reading or writing

SYNOPSIS
     #include <fcntl.h>

     int open(const char *path, int oflag, [mode_t mode], ...);

     int openat(int fd, const char *path, int oflag, ...);
```

- path: 개방할 파일의 경로 이름을 가지고 있는 문자열의 포인터
- oflags: 파일의 개방 방식 지정
- mode: 파일 오픈 모드
  - O_RDONLY: 읽기 전용
  - O_WRONLY: 쓰기 전용
  - O_RDWR: 둘 다 가능
  - O_EXCL: 이미 존재하는 파일을 개방할 때 개방을 막음
  - O_CREAT: 파일 생성
    ```bash
    filedes = open("temp.txt", O_CREAT | O_RDWR, 0644)
    ```

### close

- 파일 닫기

```bash
NAME
     close – delete a descriptor

SYNOPSIS
     #include <unistd.h>

     int close(int fildes);
```

### read

- 파일 읽기

```bash
NAME
     pread, read, preadv, readv – read input

LIBRARY
     Standard C Library (libc, -lc)

SYNOPSIS
     #include <sys/types.h>
     #include <sys/uio.h>
     #include <unistd.h>

     ssize_t
     pread(int d, void *buf, size_t nbyte, off_t offset);

     ssize_t
     read(int fildes, void *buf, size_t nbyte);

     ssize_t
     preadv(int d, const struct iovec *iov, int iovcnt, off_t offset);

     ssize_t
     readv(int d, const struct iovec *iov, int iovcnt);

```

### lseek

- 지정한 파일에 대해서 read/write 포인터의 위치를 임의로 변경한다.

**read/write pointer**
- 개방된 파일 내에서 읽기 작업이나 쓰기 작업을 수행할 바이트 단위의 위치
- 특정 위치를 기준으로 한 상대적인 위치 -> Offset이라고 부름
- 파일을 개방한 직후 read/write pointer는 0, 읽거나 내용 추가시 늘어남

```bash
NAME
     lseek – reposition read/write file offset

SYNOPSIS
     #include <unistd.h>

     off_t
     lseek(int fildes, off_t offset, int whence);
```
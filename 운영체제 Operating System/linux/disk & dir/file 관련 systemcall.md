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
  - `O_RDONLY`: 읽기 전용
  - `O_WRONLY`: 쓰기 전용
  - `O_RDWR`: 둘 다 가능
  - `O_EXCL`: 이미 존재하는 파일을 개방할 때 개방을 막음
  - `O_CREAT`: 파일 생성
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

### umask

```c
#include <sys/types.h> #include <sys/stat.h>
mode_t umask(mode_t mask);
```

```bash
#include<unistd.h>
#include<sys/types.h>
#include<sys/stat.h>
#include<fcntl.h>

int main() {
  mode_t oldmask = umask(023);
  int fd = open("test.txt", O_CREAT, 0777);
  close(fd);
}
```

### access

```c
#include <unistd.h>
int access(const char *pathname, int mode);
```

- `pathname`: 파일에 대한 경로이름이다.
- `mode`: 검사하려는 접근 권한으로 `R_OK`, `W_OK`, `X_OK`, `F_OK`를 사용할 수 있다.

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char **argv) {

  char *filename = argv[1];
  if ( access(filename, R_OK) == -1 ) {
    fprintf( stderr, "User cannot read file %s \n", filename);
    exit(1);
  }
  printf("%s readable, proceeding \n", filename);
}
```

<img width="483" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/ccdf3552-2bd2-4668-8d72-13191221f889">

### link, symlink

지정한 파일에 대한 하드 링크(link)와 소프트 링크(symlink)를 생성한다.

```c
#include <unistd.h>
int link(const char *oldpath, const char *newpath); int symlink(const char *oldpath, const char *newpath);
```

- `oldpath`: 원본 파일의 경로 이름이다.
- `newpath`: 하드 링크/소프트 링크의 경로 이름이다.
- 반환값: 호출이 성공하면 0을 반환하고, 실패하면 -1을 반환한다.

`ls -l`의 정보는 i-node 블록에 저장됨.
- 하드링크 -> 같은 파일(같은 i-node 블록을 공유)인데 파일 이름만 다른 것
- 소프트링크(심볼릭 링크) -> 원본파일의 경로를 가리킴

<img width="440" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/891b2646-ec63-4412-8b43-6eb6b780046d">

```c
#include <unistd.h>

int main(int argc, char *argv[]) {
  if(link(argv[1], argv[2]))
    printf("hard-link failed\n");
}
```
```c
#include <unistd.h>

int main(int argc, char *argv[]) {
  if(symlink(argv[1], argv[2])) printf("soft-link failed\n");
}
```

### readlink

소프트 링크 파일의 실제 내용을 읽는다

```c
#include <unistd.h> int readlink(const char *path, char *buf, size_t bufsize);
```
- `path`: 소프트 링크에 대한 경로 이름이다.
- `buf`: 소프트 링크의 실제 내용을 담을 공간이다.
- `bufsize`: buf의 크기이다

```c
#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
  char buffer[1024];
  int nread;
  nread = readlink(argv[1], buffer, 1024);
  write(1, buffer, nread);
}
```

### stat

지정한 파일에 대한 상세한 정보를 알아온다.

```c
#include <sys/types.h> #include <sys/stat.h> #include <unistd.h>
int stat(const char *filename, struct stat *buf); int fstat(int filedes, struct stat *buf);
```

```c
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>


struct stat {
  dev_t st_dev
  ino_t st_ino
  mode_t st_mode
  nlink_t st_ulink
  uid_t st_uid
  gid_t st_gid
  dev_t st_rdev
  off_t st_size
  timestruc_t st_atim
  timestruc_t st_mtim
  timestruc_t st_ctim
  blksize_t st_blksize
  blkcnt_t st_blocks
  char st__fstype[_ST_FSTYPSZ];
};

int main(int argc, char *argv[]) {
  struct stat finfo;
  char fname[1024];

  if(argc > 1) strcpy(fname, argv[1]);
  else strcpy(fname, argv[0]);

  if(stat(fname, &finfo) == -1) {
    fprintf(stderr, "Couldn't stat %s \n", fname);
    exit(1);
  }

  printf("%s \n", fname);
  printf("ID of device: %d \n", finfo.st_dev);
  printf("Inode number: %d \n", finfo.st_ino);
  printf("File mode : %o \n", finfo.st_mode);
  printf("Num of links: %d \n", finfo.st_nlink);
  printf("User ID : %d \n", finfo.st_uid);
  printf("Group ID : %d \n", finfo.st_gid);
  printf("Files size : %d \n", finfo.st_size);
  printf("Last access time : %u \n", finfo.st_atim);
  printf("Last modify time : %u \n", finfo.st_mtim);
  printf("Last stat change : %u \n", finfo.st_ctim);
  printf("I/O Block size : %d \n", finfo.st_blksize);
  printf("Num of blocks : %d \n", finfo.st_blocks);
  printf("File system : %s \n", finfo.st_fstype);
}
```

### 과제

a.txt에 대해 b.txt라는 심링크 생성
a.txt 삭제
b.txt 존재 여부 검사
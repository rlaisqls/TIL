# chattr

파일의 속성을 지정하는 명령어이다.

> change file attributes on a Linux file system

```bash
chattr [옵션] [+.-.=속성] [파일명]
```

**옵션**
- `-R` : 하위 디렉토리까지 재귀적으로 바꿈
- `-V` : 파일 속성을 바꾼 다음에 보여줌
- `-v` version : 지정된 파일에 버전을 설정할 수 있습니다.

**설정모드**
- `+` : 속성을 추가한다.
- `-` : 속성을 제거한다.
- `=` : 원래 파일이 가지고 있던 그 속성만을 유지하게 합니다.

**속성**
- `a` : 파일을 추가모드로만 열 수 있다.
- `c` : 압축하여 저장
- `d` : dump 명령을 통하여 백업받을 경우 백업 대상에 포함하지 않는다.
- `i` : 파일을 read-only로만 열 수 있게 설정한다. 루트만이 이 속성을 제거 할 수 있다.
- `s` : 파일이 삭제 될 경우에 디스크 동기화가 일어난다.
- `S` : 파일이 변경 될 경우에 디스크 동기화가 일어난다.
- `u` : 파일이 삭제 되어도 그 내용이 이전 버전으로 저장 되며, 삭제되기 전의 데이터로 복구 가능해진다.

---
# chown

리눅스에서 파일은 어떤 Onwer, Group에 속해있다.

chown 명령어는 파일의 Owner 또는 Group을 변경하는 명령어이다.

아래와 같이 사용할 수 있다.

```bash
$ chown [OPTIONS] USER[:GROUP] FILE...
```

## 소유자 변경
ls -l 명령어는 파일의 소유자가 누구인지 보여준다.

명령어를 입력하면 아래와 같은 결과가 출력된다. `js`라고 되어있는 부분이 현재 유저와 그룹을 나타낸다.

```bash
$ ls -l
-rwxr-xr-x 1 js js 6  3월 10 16:02 file1.txt
```

chown 명령어를 통해 소유자, 소유 그룹을 root로 바꾸는 모습이다.

```bash
$ sudo chown root file1.txt
$ ls -l
-rwxr-xr-x 1 root root 6  3월 10 16:02 file1.txt
```

---
참고
- https://man7.org/linux/man-pages/man1/chattr.1.html
- https://codechacha.com/ko/linux-chown/
- https://www.ibm.com/docs/ko/i/7.3?topic=directories-chown
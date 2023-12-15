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
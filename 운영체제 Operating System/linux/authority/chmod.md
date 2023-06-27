# chmod

ls -l 명령을 사용하여 파일, 디렉토리 리스트를 출력하면 파일에 지정된 permission을 확인할 수 있다.

```bash
$ ls -l
-rwxr-xr-x 1 pi pi 5720 Jul  3 20:06 a.out
-rw-r--r-- 1 pi pi  722 Jul  2 21:12 crontab.bak
-rw-r--r-- 1 pi pi   52 Jul  2 21:10 test.c
```

출력 결과는 각각 파일종류 및 권한(Permission), 링크수, 사용자(소유자), 그룹, 파일크기, 수정시간, 파일이름을 나타낸다.

권한을 변경하거나 할 때도 `chmod` 명령어 뒤에 옵션으로 부여할 권한과 대상을 적어주기만 하면 된다.

```bash
chmod [options] mode[,mode] file1 [file2 ...]
```

앞에 있는 부분은 세글자씩 각각 소유자, 그룹, 그 외의 접근 가능 권한을 뜻한다.

## option 표현법

```bash
# 3글자씩 각 권한을 의미
# R(ead), W(rite), (e)X(ecute)
# owner | group | other
 -rwx     r-x     r-x 
```

2진수로 표현하는 방법도 있다. 

r은 4, w는 2, x는 1을 뜻해서 각각을 더해서 숫자로 표현해도 같은 의미이다.

```bash
# 3글자씩 각 권한을 의미
# R(ead), W(rite), (e)X(ecute)
# owner | group | other
 -7       5       5 
```

표로 정리하면 아래와 같다.

|#|Sum|rwx|Permission|
|-|-|-|-|
|7|	4(r) + 2(w) + 1(x)  | rwx |	read, write and execute
|6|	4(r) + 2(w)         | rw- |	read and write|
|5|	4(r)        + 1(x)  | r-x |	read and execute|
|4|	4(r)                | r-- |	read only|
|3|	       2(w) + 1(x)  | -wx |	write and execute|
|2|	       2(w)	        | -w- |	write only|
|1|	              1(x)	| --x |	execute only|
|0|	0	                | --- |	none|

## 수정

명령어를 통해 기존에 부여된 권한에서 권한을 수정할 수도 있다.

```bash
$ chmod [references][operator][modes] file ...
```

|Reference	|Class	|Description|
|-|-|-|
|u	|user	|소유자|
|g	|group	|파일 그룹의 유저|
|o	|others	|그룹에 속하지 않는 유저|
|a	|all	|전부 포함|
|(empty)	|default|all과 동일|

|Operator|Description|
|-|-|
|+|추가|
|-|삭제|
|=|대입|

|Mode|Name|Description|
|-|-|-|
|r	|read	|조회|
|w	|write	|작성|
|x	|execute|실행(dir에서는 내부 파일 접근)|
|X	|special execute|디렉토리 또는 실행(x) 권한이 있는 파일에 실행(x) 권한 적용|
|s	|setuid/gid	|(특별 권한)실행 순간에 super 권한을 빌려오듯이 실행|
|t	|sticky	|(특별 권한)공유모드|

#### 예시
```bash
$ ls -ld shared_dir # show access modes before chmod
drwxr-xr-x   2 jsmitt  northregion 96 Apr 8 12:53 shared_dir
$ chmod  g+w shared_dir # 그룹에 읽기 권한 추가
$ ls -ld shared_dir  # show access modes after chmod
drwxrwxr-x   2 jsmitt  northregion 96 Apr 8 12:53 shared_dir

$ ls -l ourBestReferenceFile
-rw-rw-r--   2 tmiller  northregion 96 Apr 8 12:53 ourBestReferenceFile
$ chmod a-w ourBestReferenceFile # 전체에 읽기 권한 삭제
$ ls -l ourBestReferenceFile
-r--r--r--   2 tmiller  northregion 96 Apr 8 12:53 ourBestReferenceFile

$ ls -l sample
drw-rw----   2 oschultz  warehousing       96 Dec  8 12:53 NY_DBs
$ chmod ug=rx sample # 유저와 그룹을 rx로 초기화
$ ls -l sample
dr-xr-x---   2 oschultz  warehousing       96 Dec  8 12:53 NJ_DBs
```

## 특별 권한

아까 위에 있었던 s(setuid/gid), t(sticky)라는 권한에 대해 더 알아보자.

1. s(setuid/gid)
    - setuid가 붙은 프로그램은 실행시 소유자의 권한으로 전환되고, setgid가 붙은 프로그램은 실행시 소유 그룹의 권한으로 전환된다.
    - setuid와 setgid가 필요한 이유는 일반 사용자가 변경할 수 없는 파일이지만 변경이 필요한 경우가 있기 때문이다.
    - 예를 들어 사용자의 암호를 담고있는 `/etc/shadow` 파일은 root만 읽을수 있고 수정이 불가능하다. 하지만 사용자가 암호를 변경할 경우엔 해당 파일이 변경되어야 한다.
    - 그래서 암호를 변경하는 `/usr/bin/passwd`에 setuid를 붙이면 실행시 파일의 소유자 권한으로 전환되므로 root 권한을 갖게 되어 `/etc/shadow` 파일에 변경된 암호를 기록할 수 있게 된다.
    - 파일에 setuid 비트를 붙이려면 root 권한으로 다음과 같이 맨 앞에 4를 붙여서 지정하면 된다. 
        - `4755`
        - `-rwsr-xr-x`
    - setgid 비트는 root 권한으로 다음과 같이 맨 앞에 2를 붙여서 지정한다.
        - `2755`
        - `-rwr-xrs-x`

2. t(sticky)
   - 스티키 비트(1000)가 설정된 디렉터리는 누구나 파일을 만들수 있지만 자신의 소유가 아닌 파일은 삭제할 수 없다. 즉 일종의 공유 디렉터리라고 볼수 있는데 sticky bit가 붙은 가장 대표적인건 유닉스의 임시 파일 디렉터리인 `/tmp` 이다.
    - 디렉터리에 스티키 비트를 붙일 땐 누구나 읽고, 쓰고, 실행할 수 있도록 777 권한을 줘야 한다.
      - `1777`
      - `rwxt`

3. X
   - 디렉토리 또는 실행(x) 권한이 있는 파일에 실행(x) 권한 적용
   - 대상이 실행(x) 권한을 가져도 괜찮은 경우에만 실행 권한을 지정하고 싶을 때 사용한다
    ```bash
        $ chmod u+X FILE                    # FILE이 실행 권한을 가진 경우에만 파일 소유 사용자에게 실행 권한 추가.
        $ chmod -R a-x,a+X *                # 현재 디렉토리 아래 모든 파일의 실행 권한 제거, 디렉토리 실행 권한 추가.
        $ chmod -R a-x+X *                  # 위(chmod -R a-x,a+X *)와 동일.
    ```

## umask

```bash
$ umask --help
umask: umask [-p] [-S] [mode]
    Display or set file mode mask.
    
    Sets the user file-creation mask to MODE.  If MODE is omitted, prints
    the current value of the mask.
    
    If MODE begins with a digit, it is interpreted as an octal number;
    otherwise it is a symbolic mode string like that accepted by chmod(1).
    
    Options:
      -p	if MODE is omitted, output in a form that may be reused as input
      -S	makes the output symbolic; otherwise an octal number is output
    
    Exit Status:
    Returns success unless MODE is invalid or an invalid option is given.
```
---
참고
- https://en.wikipedia.org/wiki/Chmod
- https://eunguru.tistory.com/115
- https://www.lesstif.com/lpt/linux-setuid-setgid-sticky-bit-93127311.html
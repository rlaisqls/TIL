
- `>`는 overwrite를 뜻한다.
- `>>`는 append를 뜻한다.

- 명령어의 결과(ls *)를 파일에 남기고 싶다면 아래와 같은 명령어를 사용하면 된다.
  - `ls * > file.txt`

- "hello"라는 값을 파일의 맨 밑부분에 추가하고 싶다면 아래와 같은 명령어를 사용하면 된다.
  - `echo 'hello' >> file.txt`

### standard stream

- redirection은 stream을 통해 이뤄진다.

<img width="520" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/da9115dd-03db-4c9e-858d-b4e59911a170">

- `stream`이란 디스크상의 파일이나 컴퓨터에 연결되는 여러 장치들을 통일된 방식으로 다루기 위한 가상의 개념이다.
- 프로세스가 생성되면 기본적으로 입, 출력을 위한 채널을 가지게 되는데, 이것을 **standard stream**이라고 한다.
- stream은 각각 `/dev/stdin`, `/dev/stdout`, `/dev/stderr`에 파일로 저장된다.

### FD (File Descriptor)

- 우리가 사용하는 파일들은 실제 프로그램 실행시 FD(File Descriptor)라는 양의 정수 번호에 의해 입출력을 처리한다.
- 프로그램이 수행되면 운영체제는 실행되는 프로그램에게 3개의 기본 FD를 할당한다. 그리고 프로그램이 내부적으로 다른 파일을 open하게 되면 3번째 FD를 할당한다.

  |File Descripter|설명|
  |-|-|
  |0|표준 입력 (standard input)|
  |1|표준 출력 (standard output)|
  |2|표준 에러 (standard error)|

- FD를 아래와 같이 활용할 수 있다.
  - `hello.txt`라는 파일의 wc 결과를 `out.txt`에 출력하는 명령어이다.
  
    ```bash
    $ cat hello.txt
    hello
    world
    $ wc 0< hello.txt 1> out.txt
    $ cat outfile 
    2  2 12
    ```

- `<`의 좌측 기본 값은 0이고, `>`, `>>`의 좌측 기본값은 1이기 때문에 `wc < infile > outfile`처럼 입력해도 결과는 똑같다.
- 기호 오른쪽에 파일이름이 아닌 FD번호를 쓰고 싶을때는 `&`를 사용해서 표현할 수 있다.
- 만약 특정 명령어의 결과와 에러 출력 결과를 같은 파일에 넣고 싶으면 두 가지 방법이 있다.
  - `wc asdfghh > tmpfile 2>&1`: 2(표준 에러)는 1(표준 출력)으로, 1(표준 출력)은 `tmpfile`에 redirect
  - `wc asdfghh > tmpfile 2> tmpfile`: 1(표준 출력)과 2(표준 에러)를 각각 `tmpfile`에 redirect

---
참고
- https://unix.stackexchange.com/questions/42728/what-does-31-12-23-do-in-a-script
- https://www.shells.com/l/en-US/tutorial/Difference-between-%E2%80%9C%3E%E2%80%9D-and-%E2%80%9C%3E%3E%E2%80%9D-in-Linux

man은 manual을 의미하며, 설명서 페이지를 볼 수 있는 명령어이다.

```bash
 man [-adho] [-t | -w] [-M manpath] [-P pager] [-S mansect]
     [-m arch[:machine]] [-p [eprtv]] [mansect] page [...]
 man -f page [...] -- Emulates whatis(1)
 man -k page [...] -- Emulates apropos(1)
```

## 옵션

|옵션|설명|
|-|-|
|`-k`|apropos에 해당하는 매뉴얼의 내용을 출력.<br>apropos란 완전히 일치하지 않아도 대략적으로 비슷한 단어를 뜻한다. (ex: mount의 apropos는 amount, mounted, mounts 등이 있다.)|
|`-f`|키워드와 완전히 일치하는 매뉴얼의 내용을 출력|
|`-a`|매치되는 모든 매뉴얼 페이지를 출력|
|`-s`, `-S`|특정 섹션 번호를 지정하여 출력|
|`-w`|매뉴얼 페이지 파일의 위치 출력|

## 매뉴얼 섹션(Manual Section)

- 리눅스의 매뉴얼 섹션은 총 9개의 섹션으로 구분되어 있다.
  - 같은 이름이더라도 다른 용도인 경우 구분될 수 있도록 하기 위함이다.
- 섹션을 입력하지 않으면 번호가 낮은 섹션의 결과부터 보여진다.

|섹션|내용|
|-|-|
|1|실행 가능한 프로그램 혹은 쉘 명령어|
|2|시스템 콜(System Calls)|
|3|라이브러리 콜(Library Calls)|
|4|Special File (관련 장치 및 드라이버, 소켓(socket), FIFO, `/dev`의 형식과 관련된 규약)|
|5|파일 포맷(File Formats)과 컨벤션(convention)|
|6|게임(Games)|
|7|Miscellanea (리눅스 시스템 파일 관련 표준, 프로토콜, 문자셋, 규칙 등에 대한 정보가 담긴 영역)|
|8|시스템 관리자 명령어 (root가 사용하는 명령어)|
|9|리눅스 커널 루틴(Linux Kernel Routines)|

### man 페이지 사용법

- man 명령어로 man 페이지를 띄우고 나면 여러 키를 통해 페이지를 조작할 수 있다.
 
- [SPACE] : 한 페이지 밑으로 내려감
- [위,아래 화살표] : 한 줄 단위로 움직임
- [ENTER] : 한 줄 밑으로 내려감
- [b] : 전 페이지로 올라감
- [k] : 한 줄 위로 올라감
- [q] : man 페이지 종료
- [h] : 도움말
- [/] + 키워드 : 키워드 검색
  - n키 입력 시 다음 검색 결과로 이동,  N(shift + n) 키 입력 시 이전 검색 결과로 이동

---
참고
- https://www.ibm.com/docs/ru/aix/7.2?topic=m-man-command
- https://man7.org/linux/man-pages/man1/man.1.html
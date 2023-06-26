# Package Manager

- 리눅스 패키지(Linux Package)란 리눅스 시스템에서 소프트웨어를 실행하는데 필요한 파일들(실행 파일, 설정 파일, 라이브러리 등)이 담겨 있는 설치 파일 묶음이다.

- 패키지는 종류는 소스 패키지(Source Package)와 바이너리 패키지(Binary Package)가 있다.

- 소스 패키지(Source Package)는 말 그대로 소스 코드(C언어..등)가 들어 있는 패키지로 컴파일 과정(configure,make,make install 명령어)을 통해 바이너리 파일로 만들어야 실행할 수 있다. 즉, 소스 패키지는 설치할 때 컴파일 작업도 진행되므로 설치 시간이 길고 컴파일 작업 과정에서 오류가 발생할 수 있다.

- 바이너리 패키지(Binary Package)는 성공적으로 컴파일된 바이너리 파일이 들어있는 패키지이다. 이미 컴파일이 되어 있으니 소스 패키지에 비해 설치 시간도 짧고 오류가 발생할 가능성도 적다. 따라서 리눅스의 기본 설치 패키지들은 대부분 바이너리 패키지이다.

---

리눅스 배포판에 따라서 서로 다른 패키지 형식을 지원하는데, 대부분 다음의 3가지 중 하나를 지원한다.

- Debian 계열 (Debian, Ubuntu 등): `.deb` 파일
- RedHat 계열 (RedHat, Fedora, CentOS): `.rpm` 파일
- openSUSE 계열: openSUSE를 위해 빌드된 `.rpm` 파일

패키지 관리 도구는 저수준 툴과 고수준 툴이 있다.

- 저수준 툴(low-level tools): 실제 패키지의 설치, 업데이트, 삭제 등을 수행
- 고수준 툴(high-level toos): 의존성의 해결, 패키지 검색 등의 기능을 제공

`dpkg`, `rpm`과 같은 저수준 툴은 어떤 프로그램을 깔 때 그 프로그램을 돌리기 위해서 필요한 다른 프로그램 (종속된 프로그램)을 자동으로 깔아주지 않는다. 반면 `apt-get`, `yum`과 같은 고수준 툴은 종속된 프로그램을 알아서 깔아준다.

아래 표는 리눅스 배포판 별 저수준/고수준 패키지 관리 도구이다.

|구분|저수준 툴|고수준 툴|
|-|-|-|
|Debian 계열(ubuntu, debian)|dpkg|apt-get / apt|
|RedHat 계열(centos, redhat, fedora 등)|rpm|yum|
|openSUSE|rpm|zypper|

---

`/etc/apt/sources.list`에 저장소가 기록되어 있다.

```bash
## Note, this file is written by cloud-init on first boot of an instance
## modifications made here will not survive a re-bundle.
## if you wish to make changes you can:
## a.) add 'apt_preserve_sources_list: true' to /etc/cloud/cloud.cfg
##     or do the same in user-data
## b.) add sources in /etc/apt/sources.list.d
## c.) make changes to template file /etc/cloud/templates/sources.list.tmpl

# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://ap-northeast-2.ec2.archive.ubuntu.com/ubuntu/ jammy main restricted
# deb-src http://ap-northeast-2.ec2.archive.ubuntu.com/ubuntu/ jammy main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://ap-northeast-2.ec2.archive.ubuntu.com/ubuntu/ jammy-updates main restricted
# deb-src http://ap-northeast-2.ec2.archive.ubuntu.com/ubuntu/ jammy-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://ap-northeast-2.ec2.archive.ubuntu.com/ubuntu/ jammy universe
...
```

(누가 봐도 ec2)

담겨있는 정보 종류와 각 의미는 아래와 같다.

```bash
[deb or deb-src] [repository url] [distribution] [component]
```

- deb or deb-src: 바이너리 패키지 저장소(Binary Package Repositories)와 소스 패키지 저장소(Source Package Repositories) 중 어떤 저장소를 사용하는지를 의미
- repository url: 해당 저장소의 주소를 의미
- distribution: 릴리즈하는 리눅스 버전 이름을 의미
- component:
    - main(표준으로 제공되는 무료 오픈소스 소프트웨어),
    - restricted(공식적으로 지원하는 사유(유료) 소프트웨어),
    - universe(커뮤니티에 의해 유지되고 지원되는 오픈소스(무료) 소프트웨어),
    - multiverse(공식적으로 지원되지 않는 사유(유료) 소프트웨어)를 의미

---
참고
- https://gamsungcoding.tistory.com/entry/Linux-%EB%A6%AC%EB%88%85%EC%8A%A4Linux-%ED%8C%A8%ED%82%A4%EC%A7%80-%EA%B4%80%EB%A6%AC%ED%95%98%EA%B8%B0
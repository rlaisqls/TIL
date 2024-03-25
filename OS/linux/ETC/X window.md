
X Window는 컴퓨터 그래픽 사용자 인터페이스(GUI)를 제공하기 위한 Unix, Linux 계열 운영 체제에서 사용되는 시스템이다. X Window 시스템은 네트워크 환경에서 그래픽 화면을 표시하고 입력 장치와 상호 작용할 수 있는 기능을 제공한다.

<img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/b622a5c8-4d94-4889-ab66-c9332400e0fd" height=400px>

X window의 구조라고 한다.

## 특징

- 클라이언트-서버 모델: X 클라이언트는 X 서버에서 동작하면서 서버에게 명령을 전달하고, X서버는 클라이언트에게 명령 요청의 결과를 디스플레이 장치에 출력해주거나 사용자 입력을 클라이언트에게 제공해주는 역할을 한다. 따라서 디스플레이 장치에 독립적이다.

- 모듈화: X Window 시스템은 모듈화되어 있으며, 다양한 그래픽 라이브러리와 툴킷을 사용하여 응용 프로그램을 개발할 수 있다. 이로 인해 다양한 스타일과 기능을 가진 응용 프로그램을 개발할 수 있으며, 사용자는 선호도에 맞게 시스템을 사용할 수 있다.

- 다중화면: 다중 화면을 지원하며 여러 개의 모니터에서 동시에 작업할 수 있다. 사용자는 화면 간에 창을 이동하거나 작업을 병렬로 수행할 수 있다.

## X window 데스크톱 환경 종류

- KDE(K Desktop Environment) 2015(1)
    - Qt 라이브러리를 사용
- GNOME(GNU Network Object Model Environment)
    - GTK 라이브러리 사용
    - GNU 프로젝트의 일부이며, 리눅스 계열에서 가장 많이 쓰인다.

## X server 종류

- XFree86
    - Intel x86계열의 유닉스 계열 운영체계에서 동작하는 X 서버이다. 
    - XFree86은 X11R6가 발전하는데 많은 공헌을 한 X386의 영향을 받았다.

- Xorg
    - X.org에서 XFree86의 4.4rc2 버전을 바탕으로 개발한 것이다.
    - 레드햇계열 및 한소프트 리눅스에서 사용되고 있다.

## X window 소프트웨어

- Evince(에빈스) 2017(2)
    - 문서 뷰어 프로그램
    - 지원 파일 형식 :PDF,PS,XPS,TIFF 등
- LibreOffice(리브레 오피스) 2016(1)
- 오피스 프로그램
    - MS Office 등의 오피스 프로그램과 호환
    - Writer(워드), Calc(스프레드시트/엑셀), Impress(프레젠테이션/파워포인트), Base(DB 관리) 등의 프로그램 지원
- Cheese Photo Booth(치즈) : 웹캠 프로그램 • Rhythmbox(리듬박스) : 오디오 플레이어
- Shotwell(샷웰) : 사진 관리 프로그램

## 관련 명령어 

- `tartx`: X 윈도 구동
    - `startx--:1`: 두 번째 윈도 터미널에 X 윈도를 구동
    - 명령어 오류 발생 시 **Xconfigurator**을 실행하여 설정
- `xhost`: X 윈도 서버의 호스트 접근 제어를 하기 위한 명령어
    - `xhost + 192.168.100.100` : 해당 호스트에 대한 접근을 허용
- `xauth`
    - X 서버 연결에 사용되는 권한 부여 정보(`.Xauthority` 파일의 `MIT-MAGIC-COOKIEs` 값) 편집/출력 명령어
    - `xauth list $DISPLAY` : 현재 MIT-MAGIC-COOKIEs 값을 출력
    - `xauth add $DISPLAY . ‘쿠키 값’` : .Xauthority 파일에 MIT-MAGIC-COOKIEs 값을 추가

---
참고
- https://www.x.org/wiki/guide/concepts/
- https://en.wikipedia.org/wiki/X_Window_System
- https://jhnyang.tistory.com/48
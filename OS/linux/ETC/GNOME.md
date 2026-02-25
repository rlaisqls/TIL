
GNOME(GNU Network Object Model Environment)은 Linux 및 Unix 계열 운영체제를 위한 데스크톱 환경이다. GTK 툴킷 기반으로, Ubuntu, Fedora, RHEL, Debian 등 주요 배포판에서 기본 DE로 쓰인다.

1997년 KDE가 사용하던 Qt 라이브러리의 라이선스 문제를 해결하기 위해 시작된 프로젝트다. 완전한 자유 소프트웨어 데스크톱을 목표로 Miguel de Icaza와 Federico Mena가 만들었고, GNU 프로젝트의 공식 데스크톱 환경이 되었다.

## 소프트웨어 스택

GNOME은 여러 계층의 컴포넌트로 구성된다.

```
 GNOME Shell (UI, JavaScript/GJS)
      ↓
   Mutter (윈도우 매니저 / Wayland 컴포지터)
      ↓
   GTK (위젯 툴킷)
      ↓
  GLib / GIO (유틸리티, I/O, D-Bus)
      ↓
  Display Protocol (Wayland / X11)
```

- **Mutter**: 윈도우 매니저이자 Wayland 컴포지터. 창 배치, 워크스페이스 관리를 처리한다. X11 세션에서는 윈도우 매니저로, Wayland 세션에서는 컴포지터로 동작한다.
- **GNOME Shell**: Mutter 위에서 돌아가는 UI 레이어. 상단 패널, Activities Overview, 알림 시스템 등을 담당한다. JavaScript(GJS)와 Clutter로 작성되어 있어서 확장도 JS로 만든다.
- **GTK**: 버튼, 입력창 같은 위젯을 제공하는 UI 툴킷. 현재 GTK4가 최신이다.
- **GLib/GIO**: 데이터 구조, 이벤트 루프, 파일 I/O, D-Bus 통신 등을 담당하는 저수준 라이브러리.

## 디스플레이 프로토콜

GNOME 42부터 Wayland이 기본 세션이다.

X11에서는 디스플레이 서버(Xorg)와 윈도우 매니저(Mutter)가 별개 프로세스로 돌아간다. 클라이언트-서버 구조라 네트워크 투명성이 있지만, 모든 클라이언트가 서로의 입력을 볼 수 있는 등 보안 모델이 취약하다.

Wayland에서는 Mutter가 컴포지터로서 디스플레이 서버 역할까지 직접 수행한다. 클라이언트 간 격리가 되고, 입력 지연이 낮으며, 프레임 동기화가 깔끔하다. 다만 NVIDIA 독점 드라이버 환경 등 일부 상황에서는 아직 X11 세션이 필요할 수 있다.

## GNOME Shell 워크플로우

GNOME Shell은 전통적인 데스크톱 메타포(태스크바 + 시작 메뉴)를 따르지 않는다.

- **Activities Overview**: `Super` 키를 누르면 열려 있는 모든 창이 한눈에 펼쳐진다. 여기서 앱 검색, 워크스페이스 전환이 가능하다. 마우스를 좌측 상단 코너에 밀어도 활성화된다.
- **동적 워크스페이스**: 워크스페이스를 수동으로 만들 필요가 없다. 항상 마지막에 빈 워크스페이스가 하나 유지되고, 비게 되면 자동으로 제거된다.
- **상단 패널**: 좌측 Activities, 중앙 시계/캘린더, 우측 시스템 상태(네트워크, 사운드, 전원). 하단 독이나 태스크바는 기본적으로 없다.

이 디자인은 "화면 공간을 최대한 앱에 할당하고, 필요할 때만 관리 UI를 불러온다"는 철학이다.

## 확장

GNOME Shell은 JavaScript 확장으로 커스터마이즈할 수 있다. `extensions.gnome.org`에서 커뮤니티 확장을 설치할 수 있고, CLI로도 관리 가능하다.

```bash
gnome-extensions list                                  # 설치된 확장 목록
gnome-extensions enable dash-to-dock@micxgx.gmail.com  # 활성화
gnome-extensions disable dash-to-dock@micxgx.gmail.com # 비활성화
```

Shell 버전에 강하게 의존하기 때문에 GNOME 메이저 버전 업그레이드 시 확장이 깨질 수 있다. GNOME 45에서 확장 시스템이 ESM(Extension System Modules)으로 전환되면서 import 방식이 바뀌었고, 이전 확장과 호환이 안 되는 경우가 많다.

## 설정 관리

GNOME 설정은 dconf(바이너리 키-값 저장소)에 저장되고, gsettings CLI로 읽고 쓴다.

```bash
# 다크 모드 활성화
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# 폰트 배율 조정
gsettings set org.gnome.desktop.interface text-scaling-factor 1.25

# 기본값으로 초기화
gsettings reset org.gnome.desktop.interface color-scheme
```

GUI로는 `dconf-editor`를 쓰면 모든 설정을 트리 형태로 탐색할 수 있다.

## 버전

6개월 릴리스 주기를 따른다.

- **GNOME 2 (2002~)**: 전통적인 패널+메뉴 방식. 안정적이라 오래 사랑받았다.
- **GNOME 3 (2011~)**: GNOME Shell 도입으로 UI를 전면 재설계. Activities Overview 기반 워크플로우가 논란이 컸고, 이에 반발한 포크(Cinnamon, MATE)가 생겼다.
- **GNOME 40 (2021)**: 버전 번호 체계 변경. 수평 워크스페이스, 터치패드 제스처 개선.
- **GNOME 42 (2022)**: 시스템 전역 다크 모드, libadwaita 도입. Wayland 기본 전환.
- **GNOME 43~47 (2022-2024)**: 빠른 설정 메뉴, 파일 관리자 GTK4 전환, Wayland 안정성 향상 등 점진적 개선.

## 다른 DE와 비교

- **KDE Plasma**: Qt 기반. 커스터마이즈 자유도가 높고 Windows와 비슷한 레이아웃이 기본값. GNOME이 "의견이 강한(opinionated)" 설계라면, KDE는 "사용자가 결정하는" 방향이다.
- **Xfce**: GTK 기반 경량 데스크톱. 전통적 레이아웃을 유지하면서 리소스를 적게 쓴다.
- **Cinnamon**: GNOME 3에 반발해서 Linux Mint가 포크한 것. GNOME 2 스타일 레이아웃에 현대적 기능을 결합했다.
- **MATE**: GNOME 2를 직접 포크해서 유지하는 프로젝트

---
참고

- <https://www.gnome.org/>
- <https://wiki.gnome.org/>
- <https://developer.gnome.org/documentation/>
- <https://gitlab.gnome.org/GNOME>
- <https://en.wikipedia.org/wiki/GNOME>

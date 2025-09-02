[Hammerspoon](https://www.hammerspoon.org)은 macOS용 데스크톱 자동화 및 시스템 컨트롤 도구로, Lua로 사용하여 macOS의 다양한 기능을 제어할 수 있게 해준다.

## 설치 및 설정

- **기본 설치**

    ```bash
    brew install --cask hammerspoon
    ```

- Spoon 설치 시스템
  - Spoon은 Hammerspoon의 모듈 시스템으로, 재사용 가능한 기능들을 패키지화한 것
  - [SpoonInstall](https://www.hammerspoon.org/Spoons/SpoonInstall.html): Spoon 관리를 위한 기본 도구
  - 예시

        ```lua
        hs.spoons.use("SpoonInstall", {
            config = {
                github_path = "~/.hammerspoon/Spoons/"
            }
        })
        ```

- 설정 파일 구조

    ```
    ~/.hammerspoon/
    ├── init.lua              # 메인 설정 파일
    ├── Spoons/              # Spoon 모듈들
    ├── modules/             # 사용자 정의 모듈
    └── assets/              # 이미지, 사운드 등 리소스
    ```

## 주요 API 모듈

- **hs.window**
  - 창 조작 및 관리 기능
  - 창 크기, 위치, 상태 제어
- **hs.hotkey**
  - 키보드 단축키 바인딩
  - 전역 및 조건부 단축키 설정
- **hs.application**
  - 애플리케이션 실행, 종료, 포커스 제어
  - 앱 상태 모니터링
- **hs.screen**
  - 멀티 모니터 환경 관리
  - 화면 해상도 및 배치 정보

## 예시

- 창 크기 조절 스크립트

    ```lua
    -- 창을 화면 왼쪽 절반으로 이동
    hs.hotkey.bind({"cmd", "alt"}, "Left", function()
        local win = hs.window.focusedWindow()
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()
        
        f.x = max.x
        f.y = max.y
        f.w = max.w / 2
        f.h = max.h
        win:setFrame(f)
    end)
    ```

- 애플리케이션 빠른 실행

    ```lua
    -- Cmd+Space로 특정 앱 실행/포커스
    hs.hotkey.bind({"cmd"}, "space", function()
        hs.application.launchOrFocus("Terminal")
    end)
    ```

- helloworld alert

    ```lua
    function hello()
        hs.alert.show('Hello, world!')
    end

    hs.hotkey.bind({'shift', 'cmd'}, 'H', hello)
    ```

## 유용한 툴

- <https://github.com/mogenson/PaperWM.spoon>

---
참고

- <https://www.hammerspoon.org/>
- <https://www.hammerspoon.org/Spoons/SpoonInstall.html>
- <https://johngrib.github.io/wiki/hammerspoon-tutorial-00/>

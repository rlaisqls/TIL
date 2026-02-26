
kanata는 Rust로 작성된 크로스플랫폼 키보드 리매퍼다. macOS의 Karabiner-Elements와 유사한 역할을 하며, Linux, macOS, Windows에서 모두 동작한다. 키 입력을 커널 레벨의 input 디바이스에서 가로채어 uinput을 통해 가상 키보드 이벤트를 생성한다.

## 설치

공식 릴리즈에서 x64 Linux 바이너리를 제공하지만, aarch64 환경에서는 소스에서 직접 빌드해야 한다.

```bash
cargo install kanata
```

## Linux 권한 설정

kanata는 `/dev/input/*` 장치를 읽고 `/dev/uinput`에 쓰기 위한 권한이 필요하다.

```bash
# input, uinput 그룹에 사용자 추가
sudo groupadd uinput
sudo usermod -aG input,uinput $USER

# udev 규칙 등록 (부팅 시 /dev/uinput 권한 자동 설정)
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' \
  | sudo tee /etc/udev/rules.d/99-uinput.rules

sudo udevadm control --reload-rules && sudo udevadm trigger
```

uinput 커널 모듈이 built-in인 경우 rmmod/modprobe로 재로드할 수 없다. 이때는 재부팅하거나 임시로 직접 권한을 부여한다.

```bash
sudo chown root:uinput /dev/uinput
sudo chmod 660 /dev/uinput
sudo chmod o+rw /dev/input/event5  # 대상 키보드 장치
```

> 그룹 변경은 재로그인 후 세션에 반영된다. 기존 세션에서 바로 적용하려면 `sg <group> -c "<command>"` 를 사용할 수 있으나, 이 경우 다른 보조 그룹(supplementary group)을 잃을 수 있다.

## 설정 파일 구조

kanata 설정은 `.kbd` 확장자의 Lisp 스타일 파일로 작성한다.

```scheme
(defcfg
  process-unmapped-keys yes             ;; 매핑되지 않은 키는 그대로 통과
  linux-dev /dev/input/by-id/usb-...   ;; 특정 장치 지정 (생략 시 자동 탐색)
)

;; 물리 키 정의
(defsrc
  caps \  bspc
)

;; 레이어 정의 (defsrc와 순서 일치)
(deflayer base
  lctl bspc S-grv
)
```

- `defsrc`: 가로챌 물리 키 목록
- `deflayer`: 각 키를 어떤 키로 출력할지 매핑
- `S-grv` : Shift+` (물결표 `~`)
- `_` : 해당 키를 그대로 통과

### 주요 키 이름

| 물리 키 | kanata 이름 |
|--------|------------|
| CapsLock | `caps` |
| Backspace | `bspc` |
| Backslash `\` | `\` |
| 물결표 `~` | `S-grv` |
| Left Ctrl | `lctl` |

## 장치 경로 지정

`/dev/input/by-id/` 경로는 재부팅 후에도 일정하게 유지되므로 설정 파일에 사용하기 적합하다.

```bash
ls /dev/input/by-id/
# usb-Logitech_PRO_X_60_F0CF6C9E-event-kbd -> ../event5
```

## systemd user 서비스 등록

```ini
[Unit]
Description=kanata keyboard remapper
After=local-fs.target

[Service]
Type=simple
ExecStart=/home/user/.cargo/bin/kanata --cfg /home/user/dotfiles/kanata/logitech-60.kbd
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
```

```bash
mkdir -p ~/.config/systemd/user
ln -sf ~/dotfiles/kanata/kanata.service ~/.config/systemd/user/kanata.service
systemctl --user daemon-reload
systemctl --user enable --now kanata.service
```

> `systemctl --user enable`만 실행하면 서비스 파일이 `linked` 상태로만 등록된다. `WantedBy=default.target` 설정과 함께 enable 명령을 실행해야 `default.target.wants/`에 심볼릭 링크가 생성되어 부팅 시 자동 시작된다.

## 강제 종료 단축키

kanata 실행 중 `lctl + spc + esc` 를 누르면 강제 종료된다. 이 키는 defsrc 기준(리매핑 전)의 입력이다.

---

참고
- https://github.com/jtroo/kanata
- https://github.com/jtroo/kanata/blob/main/docs/setup-linux.md


### V4L2와 /dev/video*

리눅스에서 웹캠은 V4L2(Video for Linux 2) 서브시스템으로 추상화된다. 유저 공간에서는 `/dev/video*` 캐릭터 디바이스로 보인다.

```bash
$ ls /dev/video*
/dev/video0  /dev/video1  /dev/video10
```

보통 가장 낮은 번호가 RGB 스트림이고 나머지는 메타데이터 채널이나 다른 포맷이 노출되는 것이다. 정확히 뭐가 뭔지 보려면 `v4l2-ctl --list-devices`.

```bash
sudo apt install -y v4l-utils
v4l2-ctl --list-devices
```

`cv2.VideoCapture(index)`가 V4L2를 호출해서 디바이스를 열 수 있다. index는 `/dev/video<index>`에 매핑된다.

```python
import cv2

cap = cv2.VideoCapture(0)   # /dev/video0
if not cap.isOpened():
    raise RuntimeError("카메라를 열 수 없습니다")
```

`isOpened()`가 False면 다른 프로세스가 점유 중이거나 (`lsof /dev/video0`로 확인), 유저가 video 그룹에 안 들어있는 경우이다.

### Tkinter after()

Tkinter는 단일 이벤트 루프라서 스레드를 사용하지 않고 `root.after(ms, callback)`로 주기 작업을 짤 수 있다. 미리보기는 100ms마다, 캡처는 30초마다 같은 루프 위에서 돌아간다.

```python
def _refresh_preview(self):
    ok, frame = self.cap.read()
    if ok:
        # 미리보기 갱신
        ...
    self.root.after(100, self._refresh_preview)

def _on_capture_tick(self):
    if not self.recording:
        return
    ok, frame = self.cap.read()
    if ok:
        self.writer.write(frame)
    self.root.after(30_000, self._on_capture_tick)
```

같은 `VideoCapture`를 두 콜백이 공유해도 둘 다 메인 스레드에서 직렬로 호출되니까 race condition은 없다.

정지할 때 `after_cancel(id)`를 안 해주면 정지 후에도 한 번 더 leftover 호출이 생긴다.

### BGR / RGB

OpenCV는 색상 순서가 BGR이다. PIL, matplotlib, Tk등은 RGB를 사용하므로 변환해주어야한다.

```python
rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
img = Image.fromarray(rgb)
```

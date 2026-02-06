
비디오 컨테이너에는 각 프레임(샘플)에 두 종류의 타임스탬프가 있다.

- **PTS (Presentation Time Stamp)**: 이 프레임을 화면에 **표시**해야 하는 시점
- **DTS (Decoding Time Stamp)**: 이 프레임을 **디코딩**해야 하는 시점

**두 개가 필요한이유**

B-frame(양방향 예측 프레임)이 있으면, 디코딩 순서와 표시 순서가 달라진다. B-frame은 앞뒤 프레임을 참조하므로, 참조 대상인 뒤쪽 프레임을 먼저 디코딩해야 한다.

```
표시 순서 (PTS 순):  I  B  B  P  B  B  P
디코딩 순서 (DTS 순): I  P  B  B  P  B  B

구체적 예시 (timescale=90000, 30fps):
프레임   표시 순서(PTS)   디코딩 순서(DTS)
  I        0               0
  B        3000            6000    ← 표시는 2번째지만 디코딩은 3번째
  B        6000            9000
  P        9000            3000    ← 표시는 4번째지만 디코딩은 2번째
  B        12000           15000
  B        15000           18000
  P        18000           12000
```

B-frame이 없으면 PTS와 DTS는 항상 같다. H.264 Baseline Profile 등 B-frame을 사용하지 않는 프로필에서는 DTS = PTS이다.

## MOV/MP4에서 타임스탬프 저장 방식

MOV/MP4는 PTS와 DTS를 직접 저장하지 않고, 간접적으로 계산한다.

### stts (Decoding Time to Sample) → DTS 계산

각 프레임의 duration(지속 시간)을 저장한다. DTS는 이 duration을 누적하여 계산한다.

```
stts entries: [{count=3, duration=3000}, {count=2, duration=6000}]

DTS 계산:
  frame 0: DTS = 0
  frame 1: DTS = 0 + 3000 = 3000
  frame 2: DTS = 3000 + 3000 = 6000
  frame 3: DTS = 6000 + 3000 = 9000
  frame 4: DTS = 9000 + 6000 = 15000
```

### ctts (Composition Time to Sample) → PTS 계산

PTS와 DTS의 차이(offset)를 저장한다.

```
PTS = DTS + ctts_offset
```

```
ctts entries: [{count=1, offset=0}, {count=2, offset=6000}, {count=1, offset=-3000}, ...]

frame 0: PTS = DTS(0)    + 0     = 0
frame 1: PTS = DTS(3000) + 6000  = 9000
frame 2: PTS = DTS(6000) + 6000  = 12000
frame 3: PTS = DTS(9000) + (-3000) = 6000
```

B-frame이 없으면 ctts box가 아예 없거나, 모든 offset이 0이다.

### ctts version 0 vs version 1

- **version 0**: offset이 unsigned 32-bit integer (음수 불가)
- **version 1**: offset이 signed 32-bit integer (음수 허용)

문제는 Apple이 version 0에도 음수 값을 저장하는 관행이 있다는 것이다.

```
Apple이 저장:  ctts offset = -10 (0xFFFFFFF6)
version 0 스펙대로 읽으면: 4,294,967,286 (unsigned)
version 1 스펙대로 읽으면: -10 (signed, 올바른 값)
```

FFmpeg은 version 0에서 큰 양수를 발견하면 "이건 사실 음수"라고 추정하고, DTS를 shift하여 보정한다. 이 보정 과정이 추가적인 타이밍 변화를 일으킬 수 있다.

```
ffmpeg -v debug -i input.mov 2>&1 | grep "Shifting DTS"
# "Shifting DTS by X because of negative CTTS" 로그가 나오면
# negative CTTS 보정이 적용된 것
```

### Edit List와의 관계

edit list는 raw 미디어의 특정 구간을 presentation 타임라인으로 매핑한다. PTS/DTS는 raw 미디어 기준의 타임스탬프이므로, edit list가 있으면 한 번 더 변환이 필요하다.

```
raw 미디어:       DTS/PTS 기준 (stts + ctts로 계산)
                         ↓ edit list 매핑
presentation:     화면에 보이는 시간
```

ffprobe가 출력하는 PTS 값은 이 edit list 매핑까지 적용한 값인데, edit list와 ctts의 해석 방식에 따라 플레이어마다 결과가 달라질 수 있다. 정확한 타이밍이 필요하면 stts/ctts를 직접 파싱하여 계산하는 것이 가장 정확하다.

### A/V 동기화

플레이어는 PTS를 기준으로 비디오와 오디오를 동기화한다.

```
시간 흐름 →

오디오 PTS:  [0ms] [20ms] [40ms] [60ms] [80ms] [100ms]
비디오 PTS:  [0ms]        [33ms]        [66ms]         [100ms]
```

플레이어:

1. 오디오를 기준 클록으로 사용 (오디오가 끊기면 더 눈에 띄므로)
2. 비디오 프레임의 PTS와 현재 오디오 시간을 비교
3. 비디오가 늦으면 → 프레임 드롭
4. 비디오가 빠르면 → 대기

---
참고

- <https://www.iso.org/standard/68960.html>
- <https://trac.ffmpeg.org/wiki/Encode/H.264>
- <https://developer.apple.com/documentation/quicktime-file-format/composition_offset_atom>

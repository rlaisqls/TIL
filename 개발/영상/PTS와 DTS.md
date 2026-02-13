
비디오 컨테이너에는 각 프레임(샘플)마다 두 종류의 타임스탬프가 붙어 있다.

- **PTS (Presentation Time Stamp)**: 이 프레임을 화면에 표시해야 하는 시점
- **DTS (Decoding Time Stamp)**: 이 프레임을 디코딩해야 하는 시점

타임스탬프가 두 개 필요한 이유는 B-frame(양방향 예측 프레임)에 있다. B-frame은 앞뒤 프레임을 모두 참조하기 때문에, 화면에 보여주는 순서와 디코더가 처리하는 순서가 달라질 수밖에 없다. 참조 대상이 되는 뒤쪽 P-frame을 먼저 디코딩해놓아야 그 사이의 B-frame을 복원할 수 있기 때문이다.

예를 들어 PTS 순서가 `I B B P B B P`인 영상이 있다면, 디코딩 순서는 `I P B B P B B`가 된다. timescale=90000, 30fps 기준으로 구체적인 숫자를 보면, PTS가 9000인 P-frame의 DTS는 3000이다. 표시는 4번째지만 디코딩은 2번째로 일어난다는 뜻이다.

B-frame이 없으면 PTS와 DTS는 항상 같다. H.264 Baseline Profile처럼 B-frame을 사용하지 않는 프로필에서는 DTS = PTS이다.

## MOV/MP4에서 타임스탬프 저장 방식

MOV/MP4는 PTS와 DTS를 직접 저장하지 않는다. 대신 두 개의 box를 조합해서 간접적으로 계산한다.

**stts (Decoding Time to Sample) → DTS 계산**

stts는 각 프레임의 duration(지속 시간)을 저장한다. DTS는 이 duration을 0부터 누적해서 구한다.

```
stts entries: [{count=3, duration=3000}, {count=2, duration=6000}]

DTS 계산:
  frame 0: DTS = 0
  frame 1: DTS = 0 + 3000 = 3000
  frame 2: DTS = 3000 + 3000 = 6000
  frame 3: DTS = 6000 + 3000 = 9000
  frame 4: DTS = 9000 + 6000 = 15000
```

**ctts (Composition Time to Sample) → PTS 계산**

ctts는 PTS와 DTS의 차이(offset)를 저장한다. 즉 `PTS = DTS + ctts_offset`으로 계산한다.

```
ctts entries: [{count=1, offset=0}, {count=2, offset=6000}, {count=1, offset=-3000}, ...]

frame 0: PTS = DTS(0)    + 0     = 0
frame 1: PTS = DTS(3000) + 6000  = 9000
frame 2: PTS = DTS(6000) + 6000  = 12000
frame 3: PTS = DTS(9000) + (-3000) = 6000
```

B-frame이 없으면 ctts box가 아예 없거나, 모든 offset이 0이다.

**ctts version 0 vs version 1**

ctts에는 두 가지 버전이 있다.

- **version 0**: offset이 unsigned 32-bit integer라서 음수를 표현할 수 없다
- **version 1**: offset이 signed 32-bit integer라서 음수가 허용된다

그런데 문제가 있다. Apple이 version 0에도 음수 값을 그냥 넣어버리는 관행이 있다는 것이다. 예를 들어 ctts offset으로 -10을 저장하면 바이트상으로는 `0xFFFFFFF6`인데, version 0 스펙대로 unsigned로 읽으면 4,294,967,286이 되어버린다.

FFmpeg은 version 0에서 비정상적으로 큰 양수를 발견하면 "이건 사실 음수"라고 추정하고, DTS를 shift해서 보정한다. 이 보정이 추가적인 타이밍 변화를 일으킬 수 있으므로 주의가 필요하다.

```bash
ffmpeg -v debug -i input.mov 2>&1 | grep "Shifting DTS"
# "Shifting DTS by X because of negative CTTS" 로그가 나오면
# negative CTTS 보정이 적용된 것
```

edit list는 raw 미디어의 특정 구간을 presentation 타임라인으로 매핑하는 역할을 한다. PTS/DTS는 raw 미디어 기준의 타임스탬프이므로, edit list가 있으면 한 번 더 변환을 거쳐야 한다.

ffprobe가 출력하는 PTS 값은 이 edit list 매핑까지 적용한 값인데, edit list와 ctts의 해석 방식에 따라 플레이어마다 결과가 달라질 수 있다. 정확한 타이밍이 필요하면 stts/ctts를 직접 파싱하는 것이 가장 확실하다.

## A/V 동기화

플레이어는 PTS를 기준으로 비디오와 오디오를 동기화한다. 보통 오디오를 기준 클록으로 사용한다.

플레이어는

- 비디오 프레임의 PTS와 현재 오디오 시간을 비교해서,
- 비디오가 늦으면 프레임을 드롭하고,
- 빠르면 잠시 대기하는 방식으로 동기화를 유지한다.

---
참고

- <https://www.iso.org/standard/68960.html>
- <https://trac.ffmpeg.org/wiki/Encode/H.264>
- <https://developer.apple.com/documentation/quicktime-file-format/composition_offset_atom>

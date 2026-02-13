
MOV/MP4 컨테이너에는 `elst`(Edit List)라는 box가 있다. 이 box는 원본 미디어 데이터를 직접 수정하지 않고, "어느 구간을 어떤 순서로 재생할지"를 지정하는 일종의 재생 지시서다.

예를 들어 10분짜리 원본 영상에서 앞뒤 1분씩 잘라내고 싶을 때, 실제 미디어 데이터는 10분 그대로 두고 edit list에 "1분~9분만 재생"이라고 적는 것이다. 재인코딩이 필요 없어서 빠르고, iOS 사진 앱이나 QuickTime의 "다듬기" 기능이 이 방식을 사용한다.

## 구조

`elst` box는 `edts`(Edit Box) 안에 들어있고, 트랙(trak)마다 하나씩 존재할 수 있다.

```
moov
 └─ trak (비디오 트랙)
     └─ edts
         └─ elst  ← Edit List
     └─ mdia
         └─ mdhd  ← Media Header (timescale 등)
         └─ minf
             └─ stbl  ← Sample Table (stts, ctts 등)
```

**elst box 바이너리 구조**

```
[4B size][4B 'elst'][1B version][3B flags][4B entry_count]

각 entry:
  version 0: [4B segment_duration][4B media_time][2B media_rate_int][2B media_rate_frac]
  version 1: [8B segment_duration][8B media_time][2B media_rate_int][2B media_rate_frac]
```

- **segment_duration**: 이 세그먼트가 재생될 시간 (movie timescale 기준)
- **media_time**: 미디어에서 재생을 시작할 시점 (media timescale 기준). `-1`이면 빈 구간(empty edit)
- **media_rate**: 재생 속도. 보통 `1.0`

**timescale 변환**

segment_duration과 media_time은 서로 다른 timescale을 사용한다. segment_duration은 movie timescale 기준(mvhd box), media_time은 media timescale 기준(mdhd box)이다.

```
실제 시간(초) = ticks / timescale

예시:
  movie timescale = 48000
  media timescale = 600
  segment_duration = 16948720 ticks → 16948720 / 48000 = 353.098초
  media_time = 9715 ticks → 9715 / 600 = 16.192초
```

## 동작 방식

edit list는 raw 미디어의 특정 구간을 presentation 타임라인으로 매핑한다. 위 예시에서 media_time=16.2s, duration=353s라면, 원본의 16.2초~369.2초 구간이 재생 시간 0초~353초로 재매핑된다.

**Empty Edit**

`media_time = -1`인 entry는 빈 구간(empty edit)으로, 해당 시간 동안 아무것도 재생하지 않는다. 주로 오디오-비디오 간 시작 시점 오프셋을 맞추기 위해 사용된다. 예를 들어 첫 번째 entry가 `media_time=-1, duration=0.5s`이고 두 번째가 `media_time=0s, duration=10s`이면, 0.5초 빈 화면 뒤에 미디어가 재생된다.

## edit list 존재 여부 확인

```bash
# mediainfo로 빠른 확인
# Duration ≠ Source duration 이면 edit list 존재
mediainfo input.mov | grep -E "Duration|Source duration"

# ffprobe로 확인 (edit list 적용된 duration 표시)
ffprobe input.mov

# ffmpeg에서 edit list 무시하고 raw 미디어 접근
ffmpeg -ignore_editlist 1 -i input.mov ...
```

---
참고

- <https://developer.apple.com/documentation/quicktime-file-format/edit_list_box>
- <https://www.iso.org/standard/68960.html>
- <https://wiki.multimedia.cx/index.php/QuickTime_container>

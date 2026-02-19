영상의 프레임레이트는 크게 두 가지로 나뉜다.

**CFR (Constant Frame Rate)** - 고정 프레임레이트

모든 프레임이 균일한 간격으로 배치된다. 30fps라면 각 프레임 간격은 정확히 1/30초(33.33ms)이다.

**VFR (Variable Frame Rate)** - 가변 프레임레이트

프레임 간격이 일정하지 않다. 화면 변화가 많으면 프레임을 자주 찍고, 변화가 없으면 프레임을 생략한다. 스마트폰 카메라가 대표적인 VFR 소스이다.

## MOV/MP4에서 프레임 타이밍이 저장되는 방식

**stts box (Sample-to-Time)**

각 프레임의 duration(지속 시간)을 저장한다. CFR이면 모든 프레임의 duration이 같으므로 entry가 1개지만, VFR이면 duration이 다른 프레임들이 있으므로 entry가 여러 개다.

```
CFR 30fps (timescale=600):
  stts entries: [{count=9000, duration=20}]  ← 1개 entry로 표현 가능
  → 모든 프레임이 20 ticks (= 20/600 = 33.33ms)

VFR (timescale=600):
  stts entries: [
    {count=90, duration=20},    ← 90프레임: 33.33ms 간격
    {count=1,  duration=2400},  ← 1프레임:  4초 간격 (gap!)
    {count=150, duration=20},   ← 150프레임: 33.33ms 간격
    ...
  ]
```

---
참고

- <https://trac.ffmpeg.org/wiki/VFR>
- <https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput>
- <https://handbrake.fr/docs/en/latest/technical/video-vfr-cfr.html>

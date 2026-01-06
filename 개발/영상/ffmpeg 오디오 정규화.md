
## Limiter, Compressor

```bash
ffmpeg -y -i input.wav \
	-af "alimiter=limit=0.3:attack=1:release=20,acompressor=threshold=-20dB:ratio=8:attack=2:release=30" \
	output.m4a
```

리미터(alimiter)는 일정 크기 이상의 소리를 물리적으로 잘라낸다.

- `limit=0.3`: 피크를 약 -10dB 수준으로 제한. 낮을수록 더 강하게 자른다.
- `attack=1`: 어택 1ms. 피크를 얼마나 빠르게 감지할지.
- `release=20`: 릴리즈 20ms. 피크가 지나간 후 원래대로 돌아오는 시간.

컴프레서(acompressor)는 리미터보다 부드럽게 동작한다. 임계값 이상의 소리를 비율에 따라 압축한다.

- `threshold=-20dB`: -20dB 이상의 소리를 압축 대상으로 삼는다.
- `ratio=8`: 8:1 비율로 압축. 임계값 초과분 8dB를 1dB로 줄인다고 생각하면 된다.
- `attack=2`: 어택 2ms
- `release=30`: 릴리즈 30ms

## speechnorm

음성에 특화된 정규화. 다이나믹 레인지를 줄여서 작은 소리도 크게 들리게 한다.

```bash
ffmpeg -y -i input.m4a \
	-af "speechnorm=e=12.5:r=0.0001:l=1" \
	output.wav
```

- `e=12.5`: 확장 계수. 높을수록 작은 소리를 더 증폭한다.
- `r=0.0001`: 복구율. 낮을수록 피크 후 빠르게 정상 볼륨으로 돌아온다.
- `l=1`: 채널 링크. 스테레오 채널 동기화.

## dynaudnorm

오디오를 짧은 구간(프레임)으로 나눠서 각 구간의 볼륨을 동적으로 조절한다.

```bash
ffmpeg -y -i input.m4a \
	-af "dynaudnorm=f=150:g=15:p=0.95:m=10" \
	output.wav
```

- `f=150`: 프레임 길이 150ms. 이 단위로 볼륨을 분석한다.
- `g=15`: 가우시안 필터 크기. 프레임 간 전환을 부드럽게 만든다.
- `p=0.95`: 타겟 피크. 1.0에 가까울수록 최대 볼륨에 가깝게 정규화한다.
- `m=10`: 최대 게인 10dB. 너무 조용한 구간이 과도하게 증폭되는 걸 방지한다.

음악이나 일반 오디오에는 잘 동작하지만, 음성에서는 문제가 생길 수 있다. 큰 피크가 나오면 그 프레임의 게인을 급격히 줄이는데, 피크 직후의 음성까지 같이 작아질 수 있기 때문이다.

---
참고

- <https://ffmpeg.org/ffmpeg-filters.html#Audio-Filters>
- <https://tech.ebu.ch/docs/r/r128.pdf>
- <https://github.com/slhck/ffmpeg-normalize>

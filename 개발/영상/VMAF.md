VMAF(Video Multi-Method Assessment Fusion)는 Netflix가 개발한 비디오 품질 평가 지표이다.

> <https://github.com/Netflix/vmaf>

세 가지 기본 지표를 추출하고 SVM(Support Vector Machine)으로 함친다.

- **VIF (Visual Information Fidelity)**: 자연 이미지 통계 기반 품질 측정
- **DLM (Detail Loss Metric)**: 세부 정보 손실 측정
- **Motion**: 프레임 간 움직임 정보

이 지표들을 인간의 주관적 평가 데이터로 학습된 모델에 입력하여 최종 점수를 산출한다. (100에 가까울수록 원본과 동일)

```bash
# ffmpeg로 VMAF 계산
ffmpeg -i distorted.mp4 -i reference.mp4 \
	-lavfi libvmaf="model=version=vmaf_v0.6.1" \
	-f null -
```

```python
# Python (ffmpeg-python)
import ffmpeg

(ffmpeg.input("distorted.mp4").output("reference.mp4", lavfi="libvmaf").run())
```

해석

- 93 이상: 원본과 구분 불가
- 80~93: 좋음
- 70~80: 보통
- 70 미만: 품질 저하 인지 가능

영상 인코딩 품질 비교 (코덱, 비트레이트 설정), 스트리밍 서비스의 트랜스코딩 품질 모니터링, ABR(Adaptive Bitrate) 래더 최적화 등 목적으로 활용할 수 있다.

- [Netflix 기술 블로그](https://netflixtechblog.com/vmaf-the-journey-continues-44b51ee9ed12)

---
참고

- <https://netflixtechblog.com/vmaf-the-journey-continues-44b51ee9ed12>
- <https://github.com/Netflix/vmaf>


OpenAI에서 공개한 Whisper는 다양한 언어를 인식할 수 있는 범용 음성 인식 모델이다. 입력으로 오디오 데이터를 받아 텍스트로 변환한다. 하지만 기본 Whisper 모델은 속도가 느리고 리소스를 많이 사용하는 단점이 있다.

이를 개선하기 위한 프로젝트들이 다음과 같다.

⸻

# [CTranslate2](https://github.com/OpenNMT/CTranslate2)

- CTranslate2는 Facebook의 fairseq에서 영감을 받아 만들어진 변환기(Transformer) 모델을 위한 고성능 추론 엔진이다.
- ONNX 모델을 최적화된 형식으로 변환한 후, CPU나 GPU에서 빠르게 실행할 수 있도록 설계되었다.
- Whisper의 디코더 부분이 Transformer 기반이기 때문에, Whisper 모델의 디코딩 속도를 빠르게 만들기 위해 CTranslate2가 사용된다.

- 특징
  - 다양한 하드웨어 백엔드 지원 (CPU, GPU, ARM 등)
  - float16, int8 양자화(quantization)를 통한 추론 최적화
  - 배치 처리 및 다중 스레드 지원

⸻

# [Faster-Whisper](https://github.com/SYSTRAN/faster-whisper/tree/master)

- Whisper 모델의 추론 속도를 극대화하기 위해 만들어진 Python 라이브러리.
- 핵심은 Whisper의 디코더를 CTranslate2로 대체하여 속도를 높이는 방식이다.

- 구조

  - Encoder는 기존 Whisper의 PyTorch 모델 그대로 사용
  - Decoder는 CTranslate2로 변환하여 빠르게 실행
  - 모델을 CTranslate2 형식으로 먼저 변환 필요

- 장점

  - PyTorch보다 최대 4~5배 빠른 속도
  - GPU 뿐 아니라 CPU-only 환경에서도 훨씬 빠른 성능
  - 동일한 결과를 유지하면서 속도 향상 가능

⸻

# [WhisperX](https://github.com/m-bain/whisperX/tree/main)

- Whisper 기반 ASR 결과를 더욱 **정교하게 정렬(alignment)**하고, 화자 분리(speaker diarization) 기능을 추가한 확장 도구
- Faster-Whisper 또는 기본 Whisper를 백엔드로 사용 가능

기능

1. 고속 음성 인식 (ASR)

    - Faster-Whisper와 통합되어 빠른 음성 인식 처리

2. 정렬 (Alignment)

    - ASR 결과의 단어별 시간 정보를 정밀하게 재정렬
    - OpenAI Whisper는 기본적으로 문장 단위의 시간만 제공

3. 화자 분리 (Speaker Diarization)

    - pyannote-audio를 사용해 화자 정보 분석
    - 결과에 화자 태그(예: SPEAKER 1, SPEAKER 2 등)를 부여

---

참고

- <https://github.com/m-bain/whisperX/tree/main>
- <https://github.com/SYSTRAN/faster-whisper/tree/master>
- <https://github.com/OpenNMT/CTranslate2>

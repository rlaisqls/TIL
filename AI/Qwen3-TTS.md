
Qwen3-TTS는 Alibaba Qwen 팀에서 개발한 다국어, 제어 가능한 스트리밍 Text-to-Speech 모델이다. 500만 시간 이상의 음성 데이터로 학습되었으며, 3초 음성 복제, 자연어 기반 음성 디자인, 실시간 스트리밍 합성을 지원한다.

기존 TTS 모델들은 semantic tokenizer의 표현력 부족 또는 acoustic tokenizer의 과도한 저수준 디테일로 인한 LLM 모델링 어려움과 장기 에러 누적 문제를 겪었다. Qwen3-TTS는 이 문제를 해결하기 위해 두 가지 tokenizer와 dual-track LM 아키텍처를 제안한다.

## Speech Tokenizer

Qwen3-TTS는 서로 다른 특성을 가진 두 가지 speech tokenizer를 제공한다. 25Hz는 품질에 최적화되어 있고, 12Hz는 속도에 최적화되어 있어 용도에 따라 선택할 수 있다.

**Qwen-TTS-Tokenizer-25Hz**

Qwen2-Audio를 기반으로 구축된 25Hz single-codebook tokenizer이다. 2단계 학습 프레임워크를 사용한다.

> **Codebook**은 토큰들의 사전이다. 음성의 다양한 소리를 숫자 코드로 매핑해둔 표로, 예를 들어 "아" 소리는 코드 42, "으" 소리는 코드 158 같은 식이다. **Single-codebook**은 하나의 사전만 사용하는 방식이다.

- **Stage 1**: Qwen2-Audio에 resampling layer와 vector quantization(VQ) layer를 추가하여 ASR 태스크로 continual pretraining을 수행한다
- **Stage 2**: convolution 기반 mel-spectrogram decoder를 추가하여 audio token으로부터 mel-spectrogram을 재구성한다. 이 reconstruction objective가 acoustic 정보를 token representation에 주입한다

> **ASR(Automatic Speech Recognition)** 은 TTS의 반대로, 음성을 텍스트로 변환하는 기술이다 (예: 음성 받아쓰기).

> **Mel-spectrogram**은 음성의 주파수 성분을 시간에 따라 시각화한 것이다. 음성을 이미지처럼 표현한 중간 형태로, 최종적으로 **waveform**(실제 음성 파형)으로 변환된다.

스트리밍 디코딩을 위해 sliding-window block attention 메커니즘을 사용한다. Diffusion Transformer(DiT)와 Flow Matching을 결합하여 코드 시퀀스를 mel-spectrogram으로 변환하고, 수정된 BigVGAN이 waveform을 재구성한다. DiT의 receptive field는 4블록(현재 블록 + 3블록 lookback + 1블록 lookahead)으로 제한된다.

> **DiT(Diffusion Transformer)** 는 확산 모델과 Transformer를 결합한 구조다. 노이즈에서 시작해 점진적으로 깨끗한 출력을 만든다. **Flow Matching**은 데이터 분포를 학습하는 생성 모델 기법으로, DiT와 함께 사용되어 고품질 mel-spectrogram을 생성한다.

25Hz tokenizer는 초당 25개의 토큰을 생성한다. 1초 음성 = 25개 토큰이므로, 10초 음성은 250개 토큰으로 표현된다.

**Qwen-TTS-Tokenizer-12Hz**

12.5Hz multi-codebook tokenizer로, Mimi 아키텍처의 semantic-acoustic disentangled quantization 전략을 기반으로 한다. 음성을 두 개의 discrete code sequence로 분해한다.

> **Multi-codebook**은 여러 사전을 계층적으로 사용하는 방식이다. 첫 번째 사전은 의미를, 나머지 사전들은 세부 음향을 담당한다.

- **Semantic codebook**: 고수준 의미 콘텐츠 캡처
- **Acoustic codebook**: 음향 디테일, 운율 등 모델링 (15-layer RVQ 사용)

> **RVQ(Residual Vector Quantization)** 는 잔차 벡터 양자화다. 첫 번째 codebook이 대략적인 소리를 표현하고, 이후 codebook들이 남은 디테일을 점점 더 정밀하게 표현하는 방식이다.

WavLM을 teacher로 사용하여 첫 번째 semantic codebook layer가 의미적으로 정렬된 feature를 학습하도록 가이드한다. GAN 기반 프레임워크로 학습하며, multi-scale mel-spectrogram reconstruction loss로 시간-주파수 일관성을 강화한다.

> **GAN(Generative Adversarial Network)** 은 생성자와 판별자가 경쟁하며 학습하는 구조다.

fully causal encoder/decoder를 사용하여 look-ahead(미래 출력을 고려하지 않고 실시간 처리한다는 뜻) 없이 12.5Hz로 토큰을 방출한다. 이 설계로 ultra-low-latency 스트리밍이 가능하다.

**Tokenizer 성능 비교**

LibriSpeech test-clean에서 Qwen-TTS-Tokenizer-12Hz의 재구성 성능:

- **PESQ_WB**: 3.21 (Mimi 2.88, SpeechTokenizer 2.60)
- **STOI**: 0.96 (Mimi 0.94)
- **UTMOS**: 4.16 (Mimi 3.87)
- **Speaker Similarity**: 0.95 (Mimi 0.87)

12.5Hz의 낮은 프레임레이트에서도 SOTA 품질을 달성한다.

## 모델 아키텍처

Qwen3-TTS는 Qwen3 LM을 backbone으로 사용하며, dual-track representation을 통해 실시간 합성을 수행한다.

> **Backbone**은 모델의 핵심 뼈대가 되는 신경망이다. Qwen3-TTS에서는 Qwen3 LM(대규모 언어 모델)이 backbone이다.

**Dual-Track 설계**

텍스트 토큰과 음향 토큰을 채널 축으로 연결(concatenate)한다. 텍스트 토큰을 받으면 즉시 대응하는 음향 토큰을 예측하고, Code2Wav 모듈이 waveform으로 변환한다. 한 트랙은 전체 운율 계획을 관리하고, 다른 트랙은 실시간 오디오 출력을 처리한다.

**Qwen3-TTS-25Hz 아키텍처**

Single-level speech token을 사용한다. Backbone이 텍스트 feature와 이전 speech token을 통합하여 linear head를 통해 현재 speech token을 예측한다. 결과 시퀀스는 chunk-wise DiT 모듈에서 고품질 waveform으로 재구성된다.

**Qwen3-TTS-12Hz 아키텍처**

RVQ 토큰을 사용하며 hierarchical prediction scheme을 채택한다.

- Backbone: aggregated codebook feature를 입력받아 zeroth codebook(semantic) 예측
- **MTP(Multi-Token Prediction) 모듈**: 모든 residual codebook(acoustic) 생성

이 전략으로 음향 디테일을 캡처하면서 single-frame instant generation으로 latency를 최소화한다.

## 학습 방법

**Pre-training (3단계)**

- **S1 (General Stage)**: 500만 시간 이상의 다국어 음성 데이터로 학습. 다국어 텍스트에서 음성으로의 monotonic mapping 확립
- **S2 (High-Quality Stage)**: 데이터 품질을 계층화하는 파이프라인으로 고품질 데이터만 선별하여 continual pretraining. S1의 noisy data로 인한 hallucination 완화
- **S3 (Long-Context Stage)**: 최대 토큰 길이를 8,192에서 32,768로 증가. 긴 음성 데이터 upsampling. 10분 이상의 연속 음성 생성 가능

**Post-training (3단계)**

- **Stage 1 (DPO)**: Direct Preference Optimization으로 human preference에 정렬. 다국어 음성 샘플에 대한 preference pair 구성
- **Stage 2 (GSPO)**: Rule-based rewards와 GSPO를 활용하여 태스크 전반의 capability와 stability 향상
- **Stage 3 (Speaker Fine-tuning)**: Base model에 경량 speaker fine-tuning. 특정 음성 채택과 자연스러움, 표현력, 제어 가능성 향상

> **DPO(Direct Preference Optimization)** 는 "A와 B 중 어떤 음성이 더 좋은가"라는 비교 데이터로 모델을 학습시키는 기법이다.

모든 데이터는 ChatML 포맷으로 구성하여 제어 가능한 음성 생성을 지원한다.

## 주요 기능

**Voice Cloning**

두 가지 방식의 음성 복제를 지원한다.

- **Speaker embedding 방식**: Reference speech에서 speaker embedding을 추출하여 실시간 복제
- **In-context learning 방식**: Text-speech pair를 통해 운율을 더 잘 보존

3초의 reference audio만으로 0.95의 speaker similarity를 달성한다. 3초면 "안녕하세요, 저는 홍길동입니다" 정도의 짧은 문장이다.

**Voice Design**

자연어 설명으로 완전히 새로운 음성 페르소나를 생성한다. Qwen3 텍스트 모델의 강력한 텍스트 이해 능력을 활용한다.

학습 중 probabilistically activated thinking pattern을 도입하여 복잡한 설명에 대한 instruction following 능력을 향상시켰다.

(예를 들어 "25세 남성, 따뜻하고 전문적인 톤"이라고 입력하면 그에 맞는 새로운 목소리를 생성한다. 실존하지 않는 가상의 목소리를 만들어냄.)

**Custom Voice Control**

9개의 고품질 프리셋 음성을 제공하며, instruction 기반 스타일 제어가 가능하다.

- Vivian (밝고 약간 엣지있는 여성, 중국어)
- Serena (따뜻하고 부드러운 여성, 중국어)
- Dylan (젊은 베이징 남성)
- Ryan (역동적인 남성, 영어)
- Aiden (밝은 미국 남성)
- Ono_Anna (발랄한 일본 여성)
- Sohee (따뜻한 한국 여성) 등

## 스트리밍 효율성

**First-Packet Latency**

Qwen3-TTS-12Hz-0.6B 기준:

- **Concurrency 1**: LM TTFP 93ms + Tokenizer Decode 4ms = **97ms**
- **Concurrency 3**: 179ms
- **Concurrency 6**: 299ms

Qwen3-TTS-25Hz-1.7B 기준:

- **Concurrency 1**: 125ms + 25ms = 150ms
- **Concurrency 6**: 523ms

12Hz 변형이 25Hz보다 훨씬 낮은 latency를 보인다. 12Hz tokenizer는 pure left-context streaming codec decoder를 사용하여 future context를 기다리지 않고 즉시 waveform을 방출할 수 있기 때문이다.

**RTF (Real-Time Factor)**

- Qwen3-TTS-12Hz-0.6B: 0.288 (concurrency 1)
- Qwen3-TTS-12Hz-1.7B: 0.313 (concurrency 1)
- Qwen3-TTS-25Hz-1.7B: 0.253 (concurrency 1)

(RTF 0.288은 실시간보다 약 3.5배 빠르게 음성을 만들어낸다는 뜻)

**패킷 설계**

- 25Hz: 8토큰/패킷, 320ms 오디오. DiT의 lookahead 요구로 16토큰 생성 후 합성 시작
- 12Hz: 4토큰/패킷, 320ms 오디오. 스케줄링 오버헤드 감소와 저지연 유지 균형

## 실험 결과

**Zero-Shot Voice Cloning (Seed-TTS test set)**

- Qwen3-TTS-12Hz-1.7B: **WER 0.77 (zh) / 1.24 (en)**
- CosyVoice 3: WER 0.71 (zh) / 1.45 (en)
- MiniMax-Speech: WER 0.83 (zh) / 1.65 (en)
- Seed-TTS: WER 1.12 (zh) / 2.25 (en)

> **WER(Word Error Rate)** 는 단어 오류율이다. 생성된 음성을 다시 텍스트로 변환했을 때 원본과 얼마나 다른지 측정하며, 낮을수록 좋다. WER 1.24%는 100단어 중 약 1단어만 틀린다는 뜻이다.

영어에서 SOTA WER 달성. 12Hz 변형이 25Hz보다 일관되게 더 나은 content accuracy를 보인다. 이는 coarser temporal resolution이 autoregressive model의 long-term dependency 모델링에 유리함을 시사한다.

**다국어 음성 생성**

10개 언어 평가에서:

- **Content Consistency (WER)**: 10개 중 6개 언어에서 최저 WER (중국어, 영어, 이탈리아어, 프랑스어, 한국어, 러시아어)
- **Speaker Similarity**: **모든 10개 언어에서 최고 점수** (MiniMax, ElevenLabs 대비)

**Cross-Lingual Voice Transfer**

zh-to-ko 생성에서 CosyVoice3 대비 66% 에러율 감소 (4.82 vs 14.4). 도전적인 언어 쌍에서 뛰어난 일반화 능력을 보인다.

**Controllable Speech Generation (InstructTTSEval)**

Voice Design 시나리오에서 Qwen3-TTS-12Hz-1.7B-VD가 오픈소스 모델 중 SOTA:

- **APS**: 85.2 (zh) / 82.9 (en)
- **DSD**: 81.1 (zh) / 82.4 (en)
- **RP**: 65.1 (zh) / 68.4 (en)

Target Speaker 시나리오에서 GPT-4o-mini-tts 대비 +28% APS 향상 (중국어).

**Long-Form Generation**

200~2000단어 텍스트 100개로 평가:

- Qwen3-TTS-25Hz-1.7B: **WER 1.517 (zh) / 1.225 (en)**
- VibeVoice: WER 22.619 (zh) / 1.780 (en)
- Higgs-Audio-v2: WER 5.505 (zh) / 6.917 (en)

10분 이상의 연속 음성을 chunk 기반 시스템의 boundary artifact 없이 일관된 운율로 생성한다. Long-form에서는 25Hz 변형이 12Hz보다 더 안정적인데, semantic token이 extended sequence의 stability 유지에 유리하기 때문이다.

## 모델 변형

**12Hz 시리즈**

- **Qwen3-TTS-12Hz-1.7B-Base**: Voice Clone 지원
- **Qwen3-TTS-12Hz-1.7B-VoiceDesign**: 자연어 음성 디자인
- **Qwen3-TTS-12Hz-1.7B-CustomVoice**: 프리셋 음성 + instruction control
- **Qwen3-TTS-12Hz-0.6B-Base/CustomVoice**: 경량 버전

**25Hz 시리즈**

- **Qwen3-TTS-25Hz-1.7B-Base**: Voice Clone 지원
- **Qwen3-TTS-25Hz-1.7B-VoiceEditing**: Voice Clone + Instruction Following
- **Qwen3-TTS-25Hz-1.7B-CustomVoice**: 프리셋 음성 + instruction control
- **Qwen3-TTS-25Hz-0.6B-Base/CustomVoice**: 경량 버전

**지원 언어**: 중국어, 영어, 일본어, 한국어, 독일어, 프랑스어, 러시아어, 포르투갈어, 스페인어, 이탈리아어 (10개)

## 사용법

**설치**

```bash
conda create -n qwen3-tts python=3.12 -y
conda activate qwen3-tts
pip install -U qwen-tts

# FlashAttention 2 (선택)
pip install -U flash-attn --no-build-isolation
```

**Voice Clone 예제**

```python
import soundfile as sf
from qwen_tts import Qwen3TTSModel

model = Qwen3TTSModel.from_pretrained(
    "Qwen/Qwen3-TTS-12Hz-1.7B-Base",
    device_map="cuda:0",
    dtype=torch.bfloat16,
)

wavs, sr = model.generate_voice_clone(
    text="합성할 텍스트",
    language="Korean",
    ref_audio="reference.wav",
    ref_text="레퍼런스 오디오의 텍스트",
)
sf.write("output.wav", wavs[0], sr)
```

> `ref_audio`는 복제하고 싶은 목소리의 샘플 파일이고, `ref_text`는 그 샘플에서 말하는 내용의 텍스트다.

**Voice Design 예제**

```python
model = Qwen3TTSModel.from_pretrained(
    "Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign",
    device_map="cuda:0",
)

wavs, sr = model.generate_voice_design(
    text="Hello, I am a synthesized voice.",
    language="English",
    instruct="A confident 25-year-old male with a warm, professional tone",
)
```

---

참고

- <https://github.com/QwenLM/Qwen3-TTS>
- <https://huggingface.co/collections/Qwen/qwen3-tts>
- <https://github.com/QwenLM/Qwen3-TTS/blob/main/assets/Qwen3_TTS.pdf>

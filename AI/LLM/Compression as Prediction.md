- 좋은 압축기는 좋은 예측기다. 압축률과 예측 성능은 같은 것을 다르게 측정한 값이다.
- 산술부호화에서 심볼 `x`의 코드 길이는 `-log_2 p(x)` 비트이다. 즉 **총 압축 비트 수 = 모델의 negative log-likelihood**가 된다.
  - 언어모델의 학습 목표(cross entropy 최소화)가 곧 압축률 최대화이ㅓ다.
  - 역으로, 확률분포를 명시적으로 갖지 않는 압축기(gzip 등)도 "예측기"로 쓸 수 있다.

- **Kolmogorov 복잡도 / Solomonoff 귀납** 데이터를 생성하는 가장 짧은 프로그램이 최선의 설명이라는 관점
- **Hutter Prize** <http://prize.hutter1.net/>

- **Language Modeling Is Compression** (DeepMind, ICLR 2024) <https://arxiv.org/abs/2309.10668>
  - Chinchilla 70B를 무손실 압축기로 쓰면 ImageNet 패치를 43.4%(PNG 58.5%), LibriSpeech를 16.4%(FLAC 30.3%)로 압축한다.
  - 논문에 이미 "임의의 압축기를 조건부 생성 모델로 쓸 수 있다"는 절이 있다.
  - 스케일링 법칙, 토크나이제이션, in-context learning을 압축 관점으로 재해석한다.
- **"Low-Resource" Text Classification: A Parameter-Free Classification Method with Compressors** (Findings of ACL 2023) <https://aclanthology.org/2023.findings-acl.426/>
  - gzip + kNN으로 학습 파라미터 0개로 OOD 벤치마크에서 BERT를 이겼다는 결과, NCD(Normalized Compression Distance)를 거리 함수로 쓴다.
  - 단, 재현 검증에서 문제가 지적됐다: k=2 tie-breaking을 "둘 중 하나만 맞으면 정답"으로 세어 top-2 정확도를 보고했고, 일부 데이터셋에 test-train 누출이 있었다. <https://kenschutte.com/gzip-knn-paper/>, <https://kenschutte.com/gzip-knn-paper2/>
  - bag-of-words kNN과 비교하면 gzip의 우위가 크지 않다는 후속 논문도 있다. <https://arxiv.org/abs/2307.15002>

- **gzip Predicts Data-dependent Scaling Laws** <https://arxiv.org/abs/2405.16684> 데이터의 "복잡도"를 압축률로 측정

- **ts_zip / nncp** (Fabrice Bellard) <https://bellard.org/ts_zip/> LLM을 확률 모델로 삼아 산술부호화하는 무손실 텍스트 압축기. xz보다 훨씬 작게 줄인다.

---
참고

- <https://nathan.rs/posts/gzip-lm/>
- <https://arxiv.org/abs/2309.10668>
- <https://aclanthology.org/2023.findings-acl.426/>
- <http://prize.hutter1.net/>
- <https://bellard.org/ts_zip/>

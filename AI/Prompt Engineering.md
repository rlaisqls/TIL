
#### Multi-head Attention

- Head는 하나의 어텐션 매커니즘을 의미, 입력 텍스트의 해석을 하나의 관점이 아닌 여러 관점에 집중

- Head의 예시
  - 문법적인 요소, 시제에 집중
  - Entity (사란, 장소, 물건 등)의 관계에 집중
  - 문장 내에서 일어나는 환동에 집중
  - Word Rhyme(단어의 운율)의 집중

Query, Key, Value 벡터를 각각 h번 Linear projection으로 변환

- Linear Projection(선형 투영)은 선형 대수학에서 나오는 개념, 여기서는 고차원의 벡터를 저차원으로 나눌 때 사용한다.

#### Long context prompting tips

1. 긴 문서나 입력을 프롬프트의 상단에 배치 (지시사항, 질문, 예시보다 더)
2. 질문을 마지막에 배치하거나, 마지막에 질문을 다시 상기시키기
3. xml tag를 이용해 구조화 (`<example></example>` 등)
4. 문서를 기반으로 응답을 생성할 때 인용하여 답변하라고 하는 것

#### 프롬프트를 평가하는 다양한 방법

- 사람이 평가
- 코드를 사용해 응답을 자동으로 평가하고 채점
- LLM을 이용해서 자동으로 평가하고 채점

#### Chain-of-Thought

Chain of dirt: 모델이 문제를 해결할 떄 단계별로 생각 과정을 거쳐 해결하도록 하는 방법. (입력, 사고 과정, 결과)의 예시를 프롬프트에 추가

예시를 사용하지 않는 방법

- Zero shot: 예시 없이 "차근차근 생각해보자"와 같이 추론 단계를 추출하고, 다음 단계에서 정답을 이끌어내는 방식도 있음
- Re2(Re-Reading) 기법: "Read the question again"과 같이 다시 읽으라고 지시하는 방식
- Step back prompting: 구체적인 내용으로부터 고차원적인 개념과 기본 원칙을 추출해서 활용하는 기법. 질문을 받았을 떄 이 질문에 대한 의도가 무엇인지 한발짝 물러나 생각.

예시를 직접 생성하도록 하는 방법

- Auto-CoT: 여러 예시를 생성해 클러스터링, 클러스터에서 예시를 뽑아 예시 집합 구성
- LLM이 가진 사전 지식에 의존적일 수 있음

#### Skeleton-of-Thought

- 응답의 전체적인 구조를 잡은 후, 각 부분을 동시에 상세화
  - 뼈대 단계 (Skeleton stage)에서 먼저 답변의 주요 요점들을 간단히 나열한 후, 요점 확장 단계 (Point-expanding stage)를 통해 병렬적으로 확장

    <img height="400px" src="https://github.com/user-attachments/assets/2d10fb28-2aa8-467e-a706-d729c2f1f66e">

#### Self-Criticism

- 모델은 여러 선택지가 주어졌을 때 가장 정답일 것 같은 답을 선택하는 능력은 뛰어남.
- 하지만 "None of the above(모든 답변이 틀림)"의 선택지가 추가되면 성능이 저하됨
- 단순히 올바른지를 묻는 것보다, 올바른지를 판단할 피드백과 기준을 충분히 제공해야함
  - 가능한 구체적이고, 실행 가능한 피드백

- Self-Refine: 초기 응답에서 반복적인 피드백으로 개선하는 접근법
  - 수학적 추론 작업보다 "선호도 기반 작업"에서 높은 성능을 보임
  - Self-Consistency 기법보다 높은 성능을 보임

- Reflextion: 언어적인 자기 성찰 피드백을 통해 자신의 응답을 개선하는 기법
  - 자기 성찰 피드백을 외부 메모리에 저장하여 앞으로 작업을 수행할 때 반영함
  - 여러 모듈이 상호작용
    - Actor: 텍스트와 행동을 생성
    - Ecaluator: Actor가 생성한 출력의 품질을 편가
    - Self-reflaction: 자기 성찰을 통해 피드백을 생성하는 역할
    - Memory: 피드백 저장

- CR (Cumulative Readoning): 큰 문제를 분해해서 해결하고, 중간 결과를 모아 다음 문제를 해결하는데 사용
  - Proposer: 현재의 문맥에 기반해 다음 단계나 추론을 제안
  - Verifier: Proposer가 제안한 것을 검토
  - Reporter: 누적된 맥락을 바탕으로 추론이 결론에 도달했다면 솔루션 제시

- RCoT (Reversing Chain of Thought)
  - 문제 재구성: 문제에 대해 생성한 솔루션 기반으로 문제를 재구성
  - 불일치 감지: 재구성된 문제와 원래 문제를 세밀하게 비교해 사실적 불일치 감지
  - 감지된 불일치를 세밀한 피드백으로 구성해서 LLM이 솔루션을 수정하도록 도움

- CoVe(Chain of verification)
  - 초기 답변 생성
  - 검증 계획 수립, 실행: 주어진 질문과 초기 답변으로 검증 질문 생성. 생성된 각각의 검증 질문에 순차적으로 답변 생성
    - 검증 계획, 실행을 하나로 수행할 수도 있고 각각 나눠서 생성, 답변할 수도 있음
  - 검증 과정의 오류를 반영해 최종 답변 생성

#### Ensembling

하나의 프롬프트와 LLM만이 아니라, 여러개의 프롬프트로 응답을 얻은 후 결합하여 최종 응답을 만드는 기법

- 하나의 프롬프트로 모든 질문을 답변하기 어렵기에 어려개의 전문화된 프롬프트를 만들고, 이를 이용해 질문 처리
- 앙상블 방법으로는 Random Forest 분류기를 사용 (Few-shot + LLM을 이용한 분류기도 사용 가능)

- Bucket Allocation
  - 유사성 기반: K-Means 알고리즘으로 유사한 예시를 묶어 구성
  - 다양성 기반: 유사한 예시들의 클러스터로부터 하나씩 뽑아 구성

- SC (Self-Consistency): 기존 CoT는 Greedy Decoding으로 한번에 하나의 추론 경로만 생성됨, 반면 이 기법은 여러가지 다양한 추론 경로를 생성한 뒤 가장 일관된 답을 선택
  - 과정
    - Sampling: 하나의 최적 경로가 아닌 여러 다양한 경로로 텍스트 생성
      - Temperature를 조절, Top-K(후보 단어를 K개 까지 고려하도록), Nucleus(모델이 단어를 선택한느 누적 확률 P를 조정) 등의 방법이 있음
    - Marginalize: 여러 추론 경로가 생성된 후 가장 일관된 답변 선택
  - 여러 추론 경로를 생성하기 때문에 계산 비용이 증가됨
  - 일관성 있는 답변이 옳다는 확신을 불가능

- USC(Universal Self-Consistency)
  - SC는 답변 형식이 같아야 하는데, USC는 서로 달라도 적용 가능
  - 모든 답변을 하나의 프롬프트에 넣어서 답변을 선택하는 과정이 추가됨
  - 샘플 수가 많아지면 장문에서 성능이 저하될 수 있음
  - 응답 선택 지시문에 일관성, 구체도 등 선택 기준을 여러가지로 조정하면 성능을 향상시킬 수 있음

#### Flow Engineering

- 프롬프트 뿐만 아니라 작업의 워크플로우를 설계해서 개선 ([Alapha Codium](https://arxiv.org/abs/2401.08500))

- GoT: LLM의 생각을 Graph로 표현해 LLM의 성능 개선
  - CoT는 중간 추론을 선형적으로 표현(백트래킹 어려웠음)
  - 그래프와 선의 중간인 ToT(Tree of Thought)라는 기법도 있음

- LangGraph: Flow Engineering, GoT를 구현

#### Auto Prompt Engineering

- 프롬프트를 자동으로 개선

- [DSPy](https://github.com/stanfordnlp/dspy): Prompt 설계를 Programming 하듯이 설계하고, RAG, Fine tunning, Agent Loop에서도 사용 가능
  -

---
참고

- <https://www.ncloud-forums.com/topic/362/>

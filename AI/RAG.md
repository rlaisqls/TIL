RAG(Retrieval-Augmented Generation)는 대규모 언어 모델의 출력을 최적화하여 응답을 생성하기 전에 학습 데이터 소스 외부의 신뢰할 수 있는 지식 베이스를 참조하도록 하는 절차이다.

---

### Advanced RAG

단순히 문서를 조회 -> LLM 응답을 하는 Naive한 기본 RAG에서, 아래 방법들을 적용해 답변 품질을 개선할 수 있다.

메타데이터 활용

- 데이터에 대한 추가적인 정보를 제공하여 검색 결과의 정확도를 높인다.

고도화된 Chunking 전략

- semantic chunking: 문맥적으로 관련된 내용을 하나의 청크로 묶는다.
- small to big: RAG에서 Chunk 를 retrieval 할때, 그 Chunk의 위와 아랫부분을 확장해서 같이 리턴하는 방법으로, 더 상세한 컨택스트를 리턴할 수 있다.
- sentence window: 문장 단위로 청크를 나누는 방식으로, 문장 간의 유사성을 분석하여 관련 있는 문장들을 한데 모아 청킹한다.

Hybrid Search

- 키워드 검색과 벡터 검색을 병행한다.

Pre-Retrieval

- Query Rewrite: 사용자의 자연어 쿼리를 데이터베이스 검색에 적합한 형태로 변환한다.
- Query Expansion: 입력된 쿼리에 관련된 추가 키워드를 더해 검색 결과를 풍부하게 만든다. 이를 통해 사용자가 입력하지 않은 연관된 정보를 함께 검색할 수 있다.
- Query Transformation: 특정 문맥이나 패턴을 기반으로 쿼리 자체를 변환하여 검색 성능을 향상시킨다.

Post-Retrieval

- Reranker: 검색된 결과와 쿼리의 연관성을 다시 판단하여, 더 정확한 결과가 우선으로 제공되도록 한다.
- Reorder: 추가적인 평가를 통해 검색 결과의 순서를 재배치한다.

### Modular RAG

검색 소스, 시나리오 다양화

- 특정 시나리오에 맞춘 맞춤형 검색
- 외부 검색 엔진, 텍스트/테이블 데이터, 지식 그래프 등 다양한 데이터 소스 활용

메모리 모듈

- LLM 자체 메모리 기능 활용해 현재 입력과 가장 유사한 기억을 찾아 개선

추가 생성 모듈

- 검색된 내용의 중복/잡음 문제 대응
- LLM이 검색용 문서를 별도 생성

검증 모듈

- 검색 정보의 신뢰성 평가
- 문서와 질의 간 관련성 검증

---
참고

- <https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://aws.amazon.com/ko/what-is/retrieval-augmented-generation/&ved=2ahUKEwizx6nJnKmJAxXjslYBHag0BRYQFnoECBMQAQ&usg=AOvVaw2Bqe12ux-trf1WzMUKTCVW>
- <https://modulabs.co.kr/blog/retrieval-augmented-generation/>
- <https://towardsdatascience.com/advanced-rag-01-small-to-big-retrieval-172181b396d4>
- <https://discuss.pytorch.kr/t/rag-1-2/3135>
- Langchain LAG

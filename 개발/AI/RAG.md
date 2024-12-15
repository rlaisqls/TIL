RAG(Retrieval-Augmented Generation)는 대규모 언어 모델의 출력을 최적화하여 응답을 생성하기 전에 학습 데이터 소스 외부의 신뢰할 수 있는 지식 베이스를 참조하도록 하는 절차이다.

RAG를 이용해서 높은 품질의 응답을 얻기 위해서는 아래와 같은 고려 사항이 있다.

- 데이터 품질: 신뢰 할 수 있으며 잘 정리된 데이터가 필요하다. 기업에서 사용 할 경우 신뢰 할 수 있는 데이터는 찾을 수 있을 것이다. 문제는 데이터가 JSON, 일반 텍스트, PDF, 이미지 등 다양한 형태로 저장되어 있다는 점이다. 전처리를 통해서 데이터 품질을 높이는 작업이 필요하다.

- 검색엔진 최적화: RAG의 R은 Retrieval 이다. 적절한 인덱싱 방법 및 검색 전략을 사용해서 관련 문서를 효과적으로 가져올 수 있어야 한다.

- 문서 선택 최적화: RAG는 검색을 기반으로 하기 때문에 관련성이 있는 여러 문서가 리턴된다. 이 중에서 가장 관련성이 높은 정보를 RAG에 전달해야 한다.

- 질문 전처리: 질문을 명확하고 구체적으로 정제하여 검색 품질을 향상 시킬 수 있다.

- 결과 통합: 검색 문서에서 얻은 정보를 적절하게 통합하여 자연스러운 답변을 생성해야 한다.

---
참고

- <https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://aws.amazon.com/ko/what-is/retrieval-augmented-generation/&ved=2ahUKEwizx6nJnKmJAxXjslYBHag0BRYQFnoECBMQAQ&usg=AOvVaw2Bqe12ux-trf1WzMUKTCVW>
- <https://modulabs.co.kr/blog/retrieval-augmented-generation/>
- Langchain LAG

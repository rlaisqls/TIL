### Stuffing

- 모든 관련 데이터를 프롬프트에 context로 채워 넣어 모델에 전달
- 제일 심플하지만 데이터가 많으면 답변 품질이 낮아질 수 있음

### Map Reduce

- 각 데이터 chunk에 대해 요약 등 초기 처리(map), 이후 초기출력들을 조합(reduce)해 최종적인 프롬프트를 실행

### Refine

- 첫번째 데이터 청크에서 초기 프롬프트를 실행하여 출력 생성.
- 앞 단계 출력 + 다음 문서 조합하여 다시 출력 생성

### Map Rerank

- 각 데이터 Chunk에 대해 초기 프롬프트를 실행하고 답변이 얼마나 확실한지에 대한 점수를 부여
- 점수에 기반하여 응답의 순위가 매겨 가장 높은 점수를 반환

---
참고

- <https://medium.com/@abonia/summarization-with-langchain-b3d83c030889>

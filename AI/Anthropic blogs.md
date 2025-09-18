### A postmortem of three recent issues 2025-09-17

글: <https://www.anthropic.com/engineering/a-postmortem-of-three-recent-issues>
해커뉴스: <https://news.ycombinator.com/item?id=45281139>

8월~9월 초 claude 모델의 성능 저하에 대한 포스트 모템
서버 부하로 인해 모델 품질을 줄인 것은 아니고, 여러 문제가 겹쳐서 생긴 현상이라고 함
모델을 어느 플랫폼에서 사용하냐에 따라 오류 발생률이 달랐다는 점이 개인적으로 신기함 (API, Bedrock, Vertex AI 등..)

1. 컨텍스트 서버 라우팅 오류
    - sonnet 모델은 기본 200k token 크기의 컨텍스트를 제공하고, 8월 초부터 선택적으로 1M context를 사용할 수 있게 되었음
    - 그러나, 1M context를 선택하지 않은 요청도 1M context로 라우팅되었음
    - (짧은 컨텍스트 요청에 1M context를 사용하면 품질이 저하된다고 합니다 해커뉴스 댓글)
    - claude code 유저 중 30%는 적어도 한 번은 요청이 잘못 라우팅되었을 것
    - 8월 5일~9월 3일까지 0.8%~16% 비율로 발생
2. 출력 손상 (영어 응답 중간에 "สวัสดี" 같은 문자 출현)
    - TPU 설정에 오류가 있었음
    - 8월 25~28일까지 Opus 4, Opus 4.1 요청에 영향
3. 확률 높은 토큰(top K)가 간헐적으로 고려에서 제외됨
    - 토큰 선택 개선 코드가 XLA:TPU 컴파일러의 잠재적 버그를 일으킴
    - 모델은 bf16(16bit)로 확률을 계산하고, 벡터 프로세서는 fp32(32bit)를 기본으로 사용,
    - TPU 컴파일러(XLA)는 일부 작업을 FP32로 변환하여 런타임 최적화함
    - '가장 높은 토큰 확률'을 모델 계산 값, 32bit 변환된 값끼리 비교했을 때 불일치
    - 8월 25일~9월 12일까지  Haiku 3.5, Opus 3, Sonnet 4에서 발생

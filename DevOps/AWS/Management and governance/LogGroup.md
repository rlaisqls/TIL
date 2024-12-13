- CloudWatch 로그 기능: 하위 개념 Log Group > Log Stream

- [S3](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/S3Export.html), [OpenSearch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CloudWatchLogs-OpenSearch-Dashboards.html)로 연동하여 분석 가능

- LogGroup으로 로그 보내는 법
  - CloudWatch agent: CW agent로 메트릭과 로그를 함께 보낼 수 있음 [(문서)](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
  - AWS CLI: [put-log-events](https://docs.aws.amazon.com/cli/latest/reference/logs/put-log-events.html) command 사용
  - Programmatically: [PutLogEvents API](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html) 사용

### cli 조회 명령어

- [start-live-tail](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CloudWatchLogs_LiveTail.html):
  - 실시간으로 조회 가능

- filter-log-events:
  - 필터링 조건을 적용할 수 있음 (특정 텍스트, 시간 범위 등)
  - 여러 로그 스트림에서 동시에 검색 가능
  - 복잡한 쿼리와 검색에 더 적합
  - 메트릭 필터링 지원
  - 성능 오버헤드가 약간 더 큼

- get-log-events:
  - 특정 로그 스트림에서 로그 이벤트를 직접 가져옴
  - 단일 로그 스트림에 대해 더 직접적이고 빠른 접근
  - 필터링 기능이 제한적
    -로드가 더 가볍고 빠름

---
참고

- <https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html>

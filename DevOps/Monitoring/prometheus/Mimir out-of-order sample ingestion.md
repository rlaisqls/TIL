
> <https://grafana.com/blog/2022/09/07/new-in-grafana-mimir-introducing-out-of-order-sample-ingestion/>

1. Ingestion 단계
    - Prometheus TSDB는 **Head Block**이라는 메모리 상의 데이터 구조를 갖고 있으며, 일반적으로는 여기에 in-order 샘플을 압축 형태로 저장한다. 최대 120개의 샘플이 하나의 압축 청크로 관리된다. Grafana Mimir는 이 Head Block을 **공유하여 메모리 사용량을 줄이고**, 동시에 out-of-order 샘플도 함께 저장할 수 있도록 설계했다.
    - OOO(Out-of-Order) 샘플은 in-order 샘플과 **격리된 영역에 비압축 상태로 메모리에 저장**되며, 최대 30개까지 허용된다. 이는 압축이 되지 않은 채로 유지되므로 메모리 사용량을 제어하기 위함이다.
    - 만약 샘플이 in-order인지 아닌지를 ingestion 전에 판단할 수 없다면, ingestion 이후 확인한 결과가 out-of-order일 경우 **WBL에 기록**된다.

      <img height=1000px src="https://github.com/user-attachments/assets/d811a5ca-173c-42f5-b20f-9ee8962fb828">

2. Query 단계

    - Prometheus TSDB는 쿼리 시 "Block Reader"라는 추상화를 통해 메모리(HB) 및 디스크의 데이터를 통합적으로 다룬다.
    - Mimir는 이 구조를 그대로 활용하되, **Head Block을 두 개의 Reader로 분리**하여 운영한다:
    - 하나는 in-order 샘플만 읽는 reader
    - 다른 하나는 out-of-order 샘플만 읽는 reader
    - 두 reader는 쿼리 시 병합되어 최종 응답을 생성하며, 이 때 **시간적으로 겹치는 청크는 병합하여 반환**된다.
    - 다만, 병합은 in-flight 방식으로, 쿼리 중에 메모리에서 직접 수행되며 디스크에 재저장되거나 청크가 새로 생성되지는 않는다.

3. Compaction 단계

    - 기존 Prometheus는 2시간 간격으로 Head Block의 가장 오래된 in-order 데이터를 디스크 블록으로 compact한다.
    - Mimir는 이에 더해, **in-order 블록 compact 이후 WBL에 남아있는 out-of-order 샘플들도 compact**하여 디스크 블록으로 저장한다.
    - Out-of-order 샘플은 여러 시간대에 걸쳐 있을 수 있으므로, 하나의 compact 동작으로 다수의 디스크 블록이 생성될 수 있다.
    - 이 과정을 통해 WBL에 기록되었던 데이터는 object storage로 이전되며, 관련된 임시 파일과 메타데이터는 정리된다.

- Config 옵션
  - `out_of_order_time_window` 옵션으로 수용할 수 있는 out-of-order 샘플의 최대 허용 시간 차이를 정의할 수 있다.
  - 기본값은 `0`으로, 기존 Prometheus와 마찬가지로 out-of-order 샘플은 모두 거부된다.
  - 이 값을 예를 들어 `1h`로 설정하면, 현재 시점 기준 1시간 이내의 과거 샘플은 수용된다.

- 고려사항
  - Out-of-order 샘플이 많아질수록 ingestion 처리 비용이 증가하고, 경우에 따라 Ingester에서 CPU 사용량이 최대 50%까지 증가할 수 있다
  - 쿼리 시 병합 작업이 in-memory에서 실행되므로, 메모리 사용량이 증가할 수 있다.

Cortex와 Mimir는 Prometheus의 확장성과 장기 저장 한계를 극복하기 위해 설계된 오픈소스 시계열 데이터베이스이다.

## Cortex

- Cortex는 Cloud Native Computing Foundation(CNCF)의 인큐베이팅 프로젝트로, 커뮤니티 중심의 개발이 이루어진다.
- Amazon DynamoDB, Google Bigtable, Apache Cassandra 등 다양한 백엔드 저장소를 지원한다.
- 수평 확장이 가능하며, 데이터 복제를 통해 고가용성을 제공한다.
- 여러 테넌트의 데이터를 분리하여 저장하고 쿼리할 수 있다.

## Mimir

- Mimir는 Cortex에서 분기되어 Grafana Labs에 의해 개발되었으며, Cortex의 복잡성을 줄이고 성능을 향상시키는 데 중점을 두었다.
- 모든 컴포넌트를 단일 바이너리로 컴파일하여 배포 및 관리가 간편하다.
- 쿼리 샤딩 및 병렬 처리를 통해 고카디널리티 데이터에 대한 쿼리 성능을 향상시켰다.
  - 특히, `split-and-merge` compactor 알고리즘을 도입하여, 대규모 데이터 처리에 유리한 구조를 갖춘다.
- S3, GCS, Azure Blob Storage 등 오브젝트 스토리지를 활용하여 비용 효율적인 장기 저장을 지원한다.
- 고급 테넌트 격리 기능과 품질 보장(QoS) 제어를 제공하여, 다양한 사용자의 요구를 충족시킨다.

## 공통 컴포넌트

둘 모두 Prometheus의 수집-저장-조회 모델을 확장 가능하고 고가용성으로 구현하기 위해 다수의 독립적인 마이크로서비스 기반 컴포넌트들로 구성되어 있다.

### Distributor

-Distributor는 Cortex와 Mimir 아키텍처의 프론트라인(frontline)에 위치한 stateless 컴포넌트이다. 주된 역할은 외부 metric source(Prometheus 또는 remote write를 지원하는 시스템)로부터 time-series 데이터를 수신하고 검증하는 것이다.

- Distributor는 동일 metric을 복수 개의 Ingester에 복제(replication)하여 전송할 수 있는 기능을 가지고 있다. 따라서 일부 Ingester가 장애를 일으키더라도 전체 시스템이 중단되지 않는다. 단, 복제된 데이터 중 단 하나의 복제본만 최종 저장되도록 하기 위해 일관성 제어(consistency enforcement) 알고리즘이 .

stateless 구조이므로 장애 발생 시 새로운 인스턴스가 즉시 동일 기능을 수행할 수 있으며, 수평 확장이 매우 용이하다.

### Ingester

Ingester는 Cortex/Mimir에서 가장 중요한 데이터 저장 전담 컴포넌트로서, **stateful**하게 설계되어 있다. 다음 기능을 함께 수행한다.

- **WAL (Write-Ahead Log)**: 데이터를 메모리에 반영하기 전에 디스크에 로그로 먼저 기록하는 구조이다. 이는 장애 발생 시 데이터를 복구할 수 있는 근거를 제공하며, 내구성(durability)을 보장하는 메커니즘이다.
- **WBL (Write-Behind Log)**: [out-of-order](./Mimir out-of-order sample ingestion.md) 샘플 기능을 사용하는 경우, WBL 방식이 활성화된다.
  - <https://grafana.com/blog/2022/09/07/new-in-grafana-mimir-introducing-out-of-order-sample-ingestion/>
- **Object Storage로의 Persist**: 일정 기준 (시간, 데이터 양 등)에 도달한 시계열 데이터는 장기 저장을 위해 S3, GCS, Azure Blob 등의 Object Storage로 압축 및 변환되어 저장된다. 이를 통해 메모리 부하를 줄이고 장기 조회가 가능하게 된다.
- **실시간 데이터 제공**: Object Storage는 쿼리 시 latency가 높은 단점이 있으므로, 최근 몇 분에서 수 시간 내의 metric(아직 compact되지 않았고 메모리에 상주하거나 WAL을 통해 즉시 접근 가능한 구조의 데이터)에 대한 조회는 Ingester가 직접 응답한다.

### Hash Ring

Cortex와 Mimir의 **Hash Ring**은 internal key-value store 기반으로 구현된 분산 로드 밸런싱 메커니즘이다. 이는 각 Ingester나 Distributor 등의 인스턴스가 처리할 데이터의 영역을 분할하는 핵심 컴포넌트로, 다음과 같은 구조적, 기능적 특징을 가진다.

- **Consistent Hashing 기반**: 데이터 샤딩(sharding)을 위해 Consistent Hashing 알고리즘을 사용하며, 이를 통해 각 시계열(metric series)의 해시 값에 따라 책임지는 인스턴스를 결정한다.
  - <https://medium.com/@kedarnath93/what-is-consistent-hashing-how-grafana-mimir-uses-it-ed60c77d7402>
- **내장형 KV store**: Mimir는 Hash Ring을 etcd 같은 외부 시스템 없이도 운영할 수 있도록 `memberlist`라는 Go 기반 라이브러리를 이용해 자체적으로 내장된 ring을 구성한다. 이를 통해 설치 복잡성을 줄이고 운영 유연성을 높인다.
- **Gossip Protocol 사용**: memberlist 기반 ring은 인스턴스 간의 상태 동기화를 Gossip Protocol로 수행하여, 중앙 집중 장애 지점을 제거하고 자연스러운 상태 전파를 유도한다.

### Query Scheduler

Query Scheduler는 Cortex/Mimir에서 **선택적(optional)**으로 사용 가능한 stateless 컴포넌트이다. 주된 역할은 복잡하고 무거운 PromQL 쿼리를 효율적으로 분산 실행하기 위한 일종의 오케스트레이터이다.

- 기본적으로 Query Frontend만 사용 시 단일 인스턴스가 병렬 분산 쿼리를 직접 분할, 조합, 실행 계획을 구성해야 한다. 그러나 부하가 커지면 Query Frontend의 병목이 발생할 수 있는데, Query Scheduler를 도입하면 이러한 병목을 회피할 수 있다.
- Query Scheduler는 하나의 쿼리를 여러 개의 sub-query로 나눈 뒤 각 Querier로 분산 전송하며, 동시에 실행되는 쿼리 수, 리소스 사용량, 우선순위 등을 제어할 수 있다. 이는 멀티 테넌트 환경이나 다수의 복잡한 쿼리가 동시에 들어오는 상황에서 매우 유용하다.

Query Scheduler는 운영 비용이 추가되지만, 복잡한 쿼리 처리 환경에서는 매우 유용한 확장 컴포넌트이다.

---

참고

- <https://medium.com/@kedarnath93/what-is-consistent-hashing-how-grafana-mimir-uses-it-ed60c77d7402>
- <https://monitoring2.substack.com/p/big-prometheus>

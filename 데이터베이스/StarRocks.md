StarRocks는 MPP 기반 OLAP DB이다. 2020년 초에 Apache Doris 0.13을 포크한 DorisDB에서 시작했다. 처음에는 Elastic License였는데 2022년 말 Apache 2.0으로 바꿨고, 2023년 2월 CelerData가 Linux Foundation에 기증했다. 상용 버전은 지금도 CelerData가 만든다. FE(Java)가 SQL 파싱·옵티마이저·메타데이터를 맡고 BE(C++)가 실행과 스토리지를 맡는 구조, MySQL 프로토콜, Stream Load·Routine Load와 Label, tablet·Rowset·버전 모델까지 뼈대는 Doris와 같다.

포크 이후 StarRocks는 옵티마이저와 실행 엔진부터 다시 만들었다. Cascades 계열 CBO와 벡터화·pipeline 실행 엔진을 일찍 갖췄고, 그래서 복잡한 조인이나 다중 테이블 쿼리에 강하다는 평가를 받는다.

## Shared-nothing과 Shared-data

```
shared-nothing:  FE ── BE(로컬 디스크에 데이터 + tablet 메타)
shared-data:     FE ── CN(상태 없음, 로컬 디스크는 캐시) ── S3(데이터 + tablet 메타 + txn log)
```

3.0부터 compute-storage 분리 모드(shared-data)가 들어왔다. BE 대신 CN(Compute Node)을 쓴다. CN은 BE가 하는 일을 다 하지만 데이터를 영구 보관하지는 않는다. 그래서 몇 초 만에 붙이거나 뗄 수 있다. 데이터 파일 형식(segment)은 shared-nothing과 같고 놓이는 곳만 S3·GCS·Azure Blob·HDFS 같은 원격 스토리지로 바뀐다.

FE의 카탈로그(DB, 테이블, 파티션 정의)는 두 모드 모두 FE가 BDB JE(Berkeley DB Java Edition)로 들고 있다. 모든 FE가 메모리에 전체 사본을 가진다.

Doris cloud 모드와 가장 큰 차이는 tablet 메타를 두는 곳이다.

- Doris는 Rowset 메타를 meta-service를 거쳐 FoundationDB에 넣는다.
- StarRocks는 별도 메타 저장소가 없다. tablet마다 메타 파일을 오브젝트 스토리지에 직접 쓴다. 테이블을 만들 때도 tablet마다 메타 파일을 하나씩 써야 해서, tablet이 많으면 오브젝트 스토리지 지연 때문에 테이블 생성이 느려진다.

## 버전과 tablet 메타

shared-data의 tablet 메타는 MVCC로 관리된다. 적재 트랜잭션 하나가 데이터 파일을 만들고, 그 트랜잭션이 publish되면 **"지금 이 tablet을 이루는 파일 목록"을 담은 새 버전의 메타**가 생긴다.

```
Load Txn 1        file-1, file-2 생성     → Meta V1 {1, 2}
Load Txn 2        file-3, file-4 생성     → Meta V2 {1, 2, 3, 4}
Load Txn 3        file-5 생성             → Meta V3 {1, 2, 3, 4, 5}
Compaction Txn 4  file-1~4 → file-6       → Meta V4 {5, 6}
```

- 적재는 먼저 데이터 파일과 txn log를 쓰고 commit한다. FE가 publish를 지시하면 CN이 txn log를 이전 버전 메타에 적용해서 새 버전 메타 파일을 만든다.
- 파티션의 visible version은 적재가 성공할 때마다 단조 증가한다. 쿼리는 그 버전의 메타가 가리키는 파일만 읽는다.
- compaction도 트랜잭션이다. V4가 생겨도 V1~V3을 읽는 쿼리가 있을 수 있어서 file-1~4는 바로 못 지운다. **어떤 버전의 tablet 메타도 참조하지 않게 되었을 때** vacuum이 지운다. 옛 메타 파일과 txn log도 vacuum이 정리한다.
- 반대로 말하면 compaction이 돌지 않으면 데이터 파일은 절대 지워지지 않는다. 덮어쓰기나 삭제를 해도 옛 파일이 계속 참조되기 때문이다.

Doris는 Rowset을 `[2-20]`처럼 버전 구간으로 부르고 경로를 이어 붙여 읽는다. StarRocks shared-data는 버전마다 전체 파일 목록을 메타에 담아 두므로 "버전 N의 메타 하나"만 읽으면 된다.

## Data Cache

shared-data에서 CN의 로컬 디스크는 캐시다. 자주 읽는 데이터는 캐시와 로컬 디스크에서 바로 읽고, 차가운 데이터는 오브젝트 스토리지에서 가져온다.

테이블 속성으로 캐시 범위를 정한다.

| 속성 | 기본값 | 의미 |
|---|---|---|
| `datacache.enable` | `true` | 로컬 디스크 캐시 사용 여부 |
| `datacache.partition_duration` | 없음 | 이 기간(`7 DAY`, `12 HOUR` 등) 안의 파티션만 캐시한다. 오래된 파티션은 캐시를 오염시키지 않는다 |

캐시가 잘 맞지 않으면 compaction도 느려진다. compaction은 입력 파일을 읽어야 하는데 캐시에 없으면 원격에서 읽어야 하기 때문이다. compaction profile의 `read_remote_mb` 비율이 30%를 넘으면 캐시 문제를 의심하라고 문서에 나와 있다.

## 적재

적재 방식과 Label은 Doris와 같다. Stream Load(HTTP 동기), Broker Load(외부 스토리지 비동기), Routine Load(Kafka 상시 구독), `INSERT INTO ... SELECT`가 있고, 적재마다 DB 안에서 유일한 Label이 붙어서 같은 Label로 다시 보내면 거부된다.

적재 하나가 버전 하나를 만들기 때문에 작은 적재가 잦으면 버전이 쌓인다. 이 문제를 줄이려고 **Merge Commit**이 있다.

- 짧은 시간 창 안에 들어온 여러 Stream Load 요청을 트랜잭션 하나로 합친다. 버전 수, 작은 파일 수, Leader FE의 트랜잭션 관리 부담이 같이 줄어든다.
- 동기 모드는 합친 트랜잭션이 commit된 뒤에 응답한다. 비동기 모드(`merge_commit_async`)는 데이터를 받자마자 응답하므로 적재 성공을 보장하지 않는다.
- 한 테이블에 Stream Load가 동시에 여러 개 들어올 때 쓰는 기능이다. 동시성이 1이면 오히려 손해다.

Doris의 group commit과 같은 문제를 푸는 기능이다.

## Compaction

### Shared-nothing: BE가 tablet별로

BE가 tablet마다 compaction 대상을 고른다. Doris처럼 cumulative와 base로 나누는 정책도 있지만 기본은 **size-tiered**다(`enable_size_tiered_compaction_strategy = true`, Primary Key 테이블 제외).

크기를 기준으로 레벨을 나누고 같은 레벨의 Rowset끼리 합친다.

| 파라미터 | 기본값 | 의미 |
|---|---|---|
| `size_tiered_min_level_size` | 128KB | 가장 작은 레벨의 크기 |
| `size_tiered_level_multiple` | 5 | 인접한 레벨 사이의 크기 배수 |
| `size_tiered_level_num` | 7 | 레벨 수 |

128KB, 640KB, 3.2MB, 16MB... 순으로 레벨이 올라간다. 작은 Rowset은 작은 것끼리 합쳐서 다음 레벨로 올라가고, 이미 커진 Rowset은 작은 것 하나 때문에 다시 쓰지 않는다. Doris 노트의 "크기 레벨" 기준을 정책 전체로 일반화한 것이다.

Primary Key 테이블은 update compaction이라는 별도 경로를 탄다. 10초마다(`update_compaction_check_interval_seconds`) 검사하고, tablet당 최소 120초 간격을 두고, 한 번에 결과 1GB(`update_compaction_result_bytes`)까지 합친다. 이쪽도 `enable_pk_size_tiered_compaction_strategy = true`가 기본이다.

적재가 compaction을 앞지르면 tablet 버전 수가 `tablet_max_versions`(기본 1000)를 넘고, 그 뒤 쓰기 요청은 실패한다. Doris의 `-235`와 같은 상황이다.

### Shared-data: FE가 파티션별로

shared-data에서는 **Leader FE의 compaction scheduler**가 전체를 지휘한다.

```
1. FE    publish 결과를 보고 파티션별 Compaction Score 계산
2. FE    Max Score가 높은 파티션부터 고름
3. FE    파티션마다 compaction 트랜잭션 시작, tablet 단위 subtask를 CN에 배분
4. CN    subtask 실행 (동시 실행 수 = compact_threads)
5. FE    subtask 결과를 모아 commit → publish → 새 버전 메타
```

Compaction Score는 파티션 안 파일이 얼마나 덜 합쳐졌는지를 나타낸다. tablet마다 점수가 있고, 파티션의 Max Score(MaxCS)가 스케줄링 기준이다.

| Max Score | 상태 |
|---|---|
| 10 미만 (`lake_compaction_score_selector_min_score`) | 다 합쳐짐. 대상에서 빠짐 |
| 100 초과 (`lake_ingest_slowdown_threshold`) | 비정상. 적재 commit을 일부러 늦춘다 |
| 2000 초과 (`lake_compaction_score_upper_bound`) | 적재 트랜잭션을 거부한다 |

Doris처럼 갑자기 에러가 나는 대신 점수가 오르면 적재 속도부터 줄여서 backpressure를 거는 구조다.

주요 파라미터는 다음과 같다.

| 위치 | 파라미터 | 기본값 | 의미 |
|---|---|---|---|
| FE | `lake_compaction_max_tasks` | -1 | 동시 compaction 작업 수. -1이면 CN 수 × 16, 0이면 compaction 끔 |
| CN | `compact_threads` | 4 | CN의 compaction 스레드. CPU 코어의 25% 정도 권장 |
| CN | `max_cumulative_compaction_num_singleton_deltas` | 500 | 한 번에 합치는 segment 수 상한. 운영에서는 100 권장 |
| CN | `lake_pk_compaction_max_input_rowsets` | 500 | Primary Key 테이블 한 번에 합치는 Rowset 수 상한 |

확인과 조작은 SQL로 한다.

```sql
-- 파티션별 점수 (MaxCS: 10 미만 정상, 100 초과 높음, 500 초과 개입 필요)
SELECT * FROM information_schema.partitions_meta;

-- compaction 트랜잭션 목록 (CommitTime/FinishTime이 NULL이면 진행 중이거나 멈춤)
SHOW PROC '/compactions';

-- tablet 단위 진행률
SELECT * FROM information_schema.be_cloud_native_compactions;

-- 수동 실행 / 취소
ALTER TABLE t COMPACT p20261023;
CANCEL COMPACTION WHERE TXN_ID = 12345;
```

compaction이 밀렸는지는 쿼리 profile에서 `PhySegmentsCount / TabletCount`가 10을 넘는지로도 본다. 적재 쪽에서는 적재 간격을 10초 이상, 배치를 100행 이상으로 잡으라고 권장한다.

## Primary Key 테이블

테이블 종류는 Duplicate Key, Aggregate, Unique Key, Primary Key가 있다. Unique Key는 읽을 때 merge하는 방식(Merge-on-Read)이고, 업데이트가 잦으면 Primary Key 테이블을 쓴다.

```sql
CREATE TABLE orders (
    order_id    BIGINT NOT NULL,
    dt          DATE   NOT NULL,
    merchant_id INT    NOT NULL,
    state       TINYINT,
    revenue     INT
)
PRIMARY KEY (order_id, dt, merchant_id)
PARTITION BY date_trunc('day', dt)
DISTRIBUTED BY HASH (merchant_id)
ORDER BY (dt, merchant_id)
PROPERTIES ("enable_persistent_index" = "true");
```

**Delete + Insert**

- primary index는 HashMap이다. key는 인코딩한 primary key 값이고, value는 그 행의 위치 `(rowset_id, segment_id, rowid)`다.
- 적재가 commit되면 index에서 같은 키의 옛 행을 찾아 **DelVector**에 지움 표시를 하고, 새 행은 새 파일에 쓴 뒤 새 버전 메타를 만든다. 이 단계를 apply라고 부른다. DelVector는 segment 파일마다 하나씩 있다.
- 읽을 때는 DelVector에 표시된 행만 건너뛴다. 여러 버전을 merge할 필요가 없으니 조건과 인덱스를 스토리지까지 그대로 내려보낼 수 있다. Doris Unique Key Merge-on-Write의 delete bitmap과 같은 아이디어다.
- commit은 됐지만 아직 apply되지 않은 버전이 `tablet_max_pending_versions`(기본 1000)를 넘으면 적재가 막힌다.

**Primary index 메모리**

- index는 적재할 때만 쓴다. 그래서 적재가 있을 때만 해당 tablet의 index를 메모리에 올리고, 오래 적재가 없으면 내린다.
- 전부 메모리에 둘 때의 크기는 `(primary key 바이트 + 9) × 행 수 × replica 수 × 1.5`로 어림한다. 인코딩한 primary key는 기본 128바이트가 상한이다.
- `enable_persistent_index = true`면 index 대부분을 디스크에 두고 일부만 메모리에 올린다. shared-data에서는 3.1.4부터 CN 로컬 디스크에, 3.3.2부터는 `"persistent_index_type" = "CLOUD_NATIVE"`로 오브젝트 스토리지에 둘 수 있다.

**정렬 키 분리**

3.0부터 정렬 키(`ORDER BY`)를 primary key와 따로 정한다. 위 예시처럼 유일성은 `order_id`로 보장하고, prefix index는 자주 필터하는 `dt, merchant_id`로 잡는다.

**적재로 갱신하기**

- `__op` 컬럼으로 행마다 동작을 정한다. 0이면 UPSERT, 1이면 DELETE다. CDC 스트림을 그대로 받을 때 쓴다.
- partial update(`partial_update = true`)로 일부 컬럼만 갱신한다. row 모드(기본)는 컬럼이 많고 배치가 작은 실시간 갱신에, column 모드(`partial_update_mode = column`)는 컬럼은 적고 행이 많은 배치 갱신에 맞는다.
- 조건부 update(`merge_condition = <컬럼>`)는 새 행의 그 컬럼 값이 기존 값보다 **크거나 같을 때만** 덮어쓴다. 순서가 뒤바뀐 이벤트가 새 값을 덮는 걸 막는다. DELETE에는 적용되지 않고, 3.1.3부터 partial update와 같이 쓸 수 있다.

## 삭제

Doris와 마찬가지로 크게 둘로 나뉜다.

**1. 메타데이터 단위 삭제: DROP, TRUNCATE, 파티션 보존 기간**

파티션이나 테이블을 통째로 버린다. 데이터 파일을 읽지 않으므로 바로 끝난다. 문서도 빨리 지워야 하면 `DELETE`보다 이쪽을 쓰라고 권한다.

TTL은 파티션 단위다. 3.4부터는 dynamic partition 대신 expression partitioning을 권장한다. 적재할 때 필요한 파티션을 알아서 만들고, 보존 조건도 같이 건다.

```sql
CREATE TABLE logs (...)
PARTITION BY date_trunc('day', event_time)
PROPERTIES (
    "partition_live_number" = "30"                                         -- 최근 30개 파티션만 유지
    -- "partition_retention_condition" = "event_time >= CURRENT_DATE() - INTERVAL 3 MONTH"  -- 3.5+
);
```

`partition_retention_condition`에는 파티션 컬럼만 쓸 수 있다.

**2. 행 단위 삭제: 테이블 종류마다 다름**

- **Duplicate Key / Aggregate / Unique Key**: `DELETE`는 조건(delete predicate)을 버전으로 남기고, 지운 행은 segment에 "삭제됨"으로 표시만 해 둔다. 실제로 사라지는 건 compaction 이후다. 그 전까지는 쿼리가 느려지고, 조건이 많을수록 더 느려진다. Aggregate와 Unique Key는 **key 컬럼만** 조건에 쓸 수 있고, Duplicate Key는 아무 컬럼이나 쓸 수 있다. 서브쿼리는 안 된다.
- **Primary Key**: 2.3부터 완전한 `DELETE ... WHERE`를 지원한다. 아무 컬럼, `AND`·`OR`, 서브쿼리를 다 쓸 수 있다. 내부적으로는 조건에 맞는 행을 찾아 DelVector에 표시하는 것이라 delete predicate가 쌓이지 않는다. 대신 파티션을 지정해서 지울 수는 없다.
- Primary Key 테이블에서는 적재할 때 `__op = 1`로 보내는 것도 삭제다.

정리하면 Doris와 같다. 오래된 데이터는 파티션 보존 기간으로 버리고, 행 단위 삭제가 잦다면 Primary Key 테이블을 쓴다.

## 비동기 Materialized View

StarRocks가 특히 공을 들인 기능이다.

```sql
CREATE MATERIALIZED VIEW mv_daily_revenue
REFRESH ASYNC EVERY (INTERVAL 1 HOUR)
PARTITION BY dt
AS SELECT dt, merchant_id, sum(revenue) AS revenue
   FROM orders GROUP BY dt, merchant_id;
```

- **원본**: 내부 테이블뿐 아니라 외부 카탈로그(Hive, Hudi, Iceberg, Paimon, Delta Lake, JDBC), 다른 MV, view도 원본이 될 수 있고, 여러 테이블을 조인할 수 있다.
- **파티션 단위 갱신**: 원본 테이블의 한 파티션이 바뀌면 MV의 대응 파티션만 다시 계산한다. `partition_refresh_number`로 한 번에 갱신할 파티션 수를 나눈다.
- **쿼리 자동 rewrite**: 원본 테이블에 날린 쿼리를 옵티마이저가 MV로 바꿔 읽는다. 대상은 SPJG(select-project-join-group by) 형태의 쿼리다.
  - 조인 rewrite: inner·outer·semi·anti 조인을 지원하고, 쿼리가 MV보다 테이블을 더 조인하거나(query delta) 덜 조인해도(view delta) 맞춰 쓴다.
  - aggregation rollup: `GROUP BY a, b`로 만든 MV로 `GROUP BY a` 쿼리를 답한다.
  - union rewrite: MV에 없는 파티션은 원본에서 읽어 MV 결과와 합친다. MV가 덜 갱신됐어도 쓸 수 있다.
  - 세션 변수 `enable_materialized_view_rewrite`(기본 `true`)로 켜고 끈다.

그래서 StarRocks는 MV를 단순한 캐시가 아니라 웨어하우스 계층(ODS → DWD → DWS)을 만드는 ETL 도구로 쓰라고 권한다. 중첩 MV도 가능하지만 운영에서는 3단계 이하로 두라고 한다.

## Doris와의 방향성 차이

출발점은 같았지만 두 프로젝트는 다른 시장을 겨냥하며 갈라졌다.

**StarRocks: 레이크하우스 쿼리 엔진**

- 데이터를 StarRocks에 적재하지 않고 Iceberg·Hudi·Delta Lake·Paimon에 둔 채 External Catalog로 바로 쿼리하는 것을 주된 사용법으로 민다. 비교 대상은 Trino이고, CBO와 실행 엔진의 성능이 핵심 무기다.
- 비동기 MV와 자동 rewrite로 레이크 위의 쿼리를 가속하고, shared-data 모드로 저장은 S3에, 계산은 탄력적으로 늘리고 줄이는 구조를 앞세운다.
- 한 줄로 요약하면 "열린 포맷 위에서 Snowflake급 쿼리 성능"이다.

**Doris: 실시간 웨어하우스 + 로그/검색**

- 데이터를 Doris 안으로 실시간 적재해서 쓰는 것을 기본으로 둔다.
- 2.0 이후로 역인덱스와 전문 검색, 스키마가 바뀌는 JSON을 자동으로 컬럼화하는 `VARIANT` 타입, `time_series` compaction, 잦은 작은 적재를 묶는 group commit처럼 **로그와 observability**용 기능을 집중해서 넣었다. 비교 대상은 Elasticsearch와 ClickHouse다.
- 최근에는 벡터 인덱스와 하이브리드 검색까지 넣으면서 검색 엔진 쪽으로 더 나아가고 있다.

정리하면 StarRocks는 데이터가 레이크에 있고 그 위를 빠르게 쿼리하는 쪽, Doris는 데이터를 넣고 실시간으로 분석하고 검색하는 쪽을 향한다. 두 프로젝트 모두 서로의 기능을 따라 넣고 있어서 기능 목록만으로는 차이가 점점 줄어든다. 그래도 "어떤 워크로드를 먼저, 깊게 챙기는가"에서는 여전히 이 차이가 드러난다.

---
참고

- [StarRocks Architecture](https://docs.starrocks.io/docs/introduction/Architecture/)
- [StarRocks Compaction for shared-data clusters](https://docs.starrocks.io/docs/administration/management/compaction/)
- [Best practices for StarRocks compaction in shared-data architectures](https://starrocks.io/blog/best-practices-for-starrocks-compaction-in-shared-data-architectures)
- [StarRocks BE parameters (stats/storage)](https://docs.starrocks.io/docs/administration/configuration/BE_parameters/stats_storage/)
- [StarRocks Primary Key table](https://docs.starrocks.io/docs/table_design/table_types/primary_key_table/)
- [StarRocks Load to Primary Key tables](https://docs.starrocks.io/docs/loading/Load_to_Primary_Key_tables/)
- [StarRocks DELETE](https://docs.starrocks.io/docs/sql-reference/sql-statements/table_bucket_part_index/DELETE/)
- [StarRocks Expression partitioning](https://docs.starrocks.io/docs/table_design/data_distribution/expression_partitioning/)
- [StarRocks Stream Load (Merge Commit)](https://docs.starrocks.io/zh/docs/loading/StreamLoad/)
- [StarRocks Feature support for shared-data clusters](https://docs.starrocks.io/docs/deployment/shared_data/feature-support-shared-data)
- [StarRocks Asynchronous materialized views](https://docs.starrocks.io/docs/using_starrocks/async_mv/Materialized_view/)
- [StarRocks Query rewrite with materialized views](https://docs.starrocks.io/docs/using_starrocks/async_mv/use_cases/query_rewrite_with_materialized_views/)
- [StarRocks Catalog overview](https://docs.starrocks.io/docs/data_source/catalog/catalog_overview/)

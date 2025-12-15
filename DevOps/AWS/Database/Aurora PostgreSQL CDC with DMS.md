
PostgreSQL은 모든 변경사항을 WAL(Write-Ahead Log)에 먼저 기록한다. 이 WAL에는 물리적 변경(어떤 페이지의 어떤 바이트가 바뀌었는지)과 논리적 변경(어떤 테이블의 어떤 row가 INSERT/UPDATE/DELETE 되었는지) 정보가 모두 담겨 있다.

Logical Replication은 이 WAL에서 논리적 변경만 추출해서 외부로 스트리밍하는 기능이다. 물리적 복제와 달리 테이블 단위로 선택적 복제가 가능하고, 다른 버전의 PostgreSQL이나 아예 다른 시스템(Kafka, DMS 등)으로 데이터를 보낼 수 있다.

### Replication Slot

그런데 한 가지 문제가 있다. WAL은 디스크 공간을 아끼기 위해 주기적으로 삭제된다. 만약 CDC consumer가 잠시 멈춰있는 동안 WAL이 삭제되면 데이터 유실이 발생한다. 이 문제를 해결하는 것이 **Replication Slot**이다. Slot은 "이 consumer는 여기까지 읽었다"는 북마크 역할을 하면서, 동시에 PostgreSQL에게 "이 위치 이후의 WAL은 삭제하지 마라"고 알려준다.

```sql
-- slot 상태 확인
SELECT slot_name,
       plugin,           -- 사용 중인 output plugin (pgoutput, test_decoding 등)
       slot_type,        -- physical 또는 logical
       active,           -- 현재 연결된 consumer가 있는지
       restart_lsn,      -- 이 위치부터 WAL 보존
       confirmed_flush_lsn  -- consumer가 확인한 마지막 위치
FROM pg_replication_slots;
```

`restart_lsn`과 `confirmed_flush_lsn`의 차이가 클수록 consumer가 뒤처져 있다는 뜻이다. 이 gap이 커지면 WAL 파일이 계속 쌓여서 디스크가 가득 찰 수 있다. ([AWS 문서](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.pglogical.handle-slots.html) 참고)

### Aurora에서 Logical Replication 활성화

Aurora PostgreSQL에서 logical replication을 사용하려면 DB Cluster Parameter Group에서 설정이 필요하다:

```
rds.logical_replication = 1    # 재시작 필요
max_replication_slots = 10     # 동시에 사용할 slot 수
max_wal_senders = 10           # WAL을 전송하는 프로세스 수
wal_sender_timeout = 30000     # ms 단위, DMS는 최소 10초 필요
```

`rds.logical_replication`을 켜면 `wal_level`이 자동으로 `logical`로 설정된다. 일반 PostgreSQL에서는 직접 `wal_level = logical`을 설정해야 하지만, Aurora/RDS에서는 이 파라미터가 숨겨져 있어서 `rds.logical_replication`으로 제어한다. ([Aurora 문서](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.Logical.html))

## Aurora의 공유 스토리지 아키텍처

일반 PostgreSQL이나 RDS PostgreSQL과 달리, Aurora는 compute와 storage가 분리되어 있다.

```
일반 PostgreSQL/RDS:
┌──────────────┐     ┌──────────────┐
│   Primary    │     │   Standby    │
│  ┌────────┐  │     │  ┌────────┐  │
│  │ Engine │  │     │  │ Engine │  │
│  └────────┘  │     │  └────────┘  │
│  ┌────────┐  │ WAL │  ┌────────┐  │
│  │Storage │──┼────►│  │Storage │  │  ← 각자 스토리지 보유
│  └────────┘  │     │  └────────┘  │
└──────────────┘     └──────────────┘

Aurora:
┌──────────┐    ┌──────────┐    ┌──────────┐
│  Writer  │    │ Reader 1 │    │ Reader 2 │
│  Engine  │    │  Engine  │    │  Engine  │
└────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │
     └───────────────┼───────────────┘
                     │
            ┌────────▼────────┐
            │  Shared Cluster │
            │     Volume      │  ← 모두 같은 스토리지 공유
            │  (6 copies/3AZ) │
            └─────────────────┘
```

**Replication slot은 스토리지에 저장된다.** 일반 PostgreSQL에서는 Primary의 로컬 스토리지에 slot 정보가 있으므로, Failover가 발생하면 새 Primary(이전 Standby)에는 slot이 없다. CDC를 처음부터 다시 시작해야 한다.

반면 Aurora는 스토리지가 공유되므로 Failover 후에도 slot이 그대로 남아있다. Writer 인스턴스가 바뀌어도 slot 정보는 Cluster Volume에 있기 때문이다. ([Artie 블로그](https://www.artie.com/blogs/postgres-replication-slot-101-how-to-capture-cdc-without-breaking-production)에서 이 차이를 잘 설명하고 있다)

PostgreSQL 17에서 `sync_replication_slots` 파라미터가 추가되어 Standby로 slot을 동기화할 수 있게 되었지만, Aurora를 쓴다면 이미 해결된 문제다.

## AWS DMS로 CDC 구성하기

DMS(Database Migration Service)는 원래 DB 마이그레이션 용도지만, CDC 기능이 있어서 지속적인 데이터 복제에도 사용할 수 있다.

### DMS의 동작 방식

DMS는 내부적으로 replication slot을 생성하고 `pgoutput` 또는 `test_decoding` 플러그인을 사용해서 변경사항을 읽어온다. Source endpoint 설정에서 확인할 수 있다:

```
ExtraConnectionAttributes: "PluginName=pgoutput"
```

`pgoutput`은 PostgreSQL 10+에서 기본 제공되는 플러그인이고, `test_decoding`은 더 오래된 버전에서 사용한다. Aurora PostgreSQL 10.x 이상이면 `pgoutput`을 쓰면 된다. ([DMS 문서](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.Prerequisites))

### Failover 시 DMS 동작

Aurora에서 Failover가 발생하면:

1. DMS Task가 연결 끊김을 감지한다
2. `RecoverableErrorCount` 설정에 따라 재연결을 시도한다 (기본값 -1은 무제한)
3. Aurora cluster endpoint는 새 Writer를 가리키게 된다
4. DMS가 재연결에 성공하면, 보존된 slot에서 마지막 위치부터 CDC를 재개한다

여기서 중요한 건 "Resume"과 "Restart"의 차이다:

- **Resume**: 마지막 checkpoint에서 계속. Failover 후 자동으로 이렇게 동작한다.
- **Restart**: Task를 완전히 처음부터 시작. Full Load부터 다시 해야 한다.

DMS 콘솔에서 수동으로 "Stop" 후 "Start"를 누르면 Restart가 되므로 주의해야 한다. Failover 복구를 기다리거나, "Resume" 옵션을 명시적으로 사용해야 한다. ([AWS Knowledge Center](https://repost.aws/knowledge-center/dms-restart-resume-failed-task))

### DMS 메시지 포맷

DMS가 Kafka로 보내는 메시지는 이런 형태다:

```json
{
  "data": {
    "id": 1,
    "name": "alice",
    "updated_at": "2024-01-15T10:30:00Z"
  },
  "metadata": {
    "timestamp": "2024-01-15T10:30:00.123456Z",
    "record-type": "data",
    "operation": "update",
    "partition-key-type": "schema-table",
    "schema-name": "public",
    "table-name": "users",
    "transaction-id": 12345
  }
}
```

`metadata.operation`은 `insert`, `update`, `delete`, `load`(Full Load 시) 중 하나다.

## VS Debezium

### 메시지 포맷 차이

Debezium은 "envelope" 형식을 사용한다:

```json
{
  "before": { "id": 1, "name": "old_name" },
  "after": { "id": 1, "name": "new_name" },
  "source": {
    "version": "2.4.0",
    "connector": "postgresql",
    "name": "my-connector",
    "ts_ms": 1705312200000,
    "db": "mydb",
    "schema": "public",
    "table": "users",
    "lsn": 123456789
  },
  "op": "u",
  "ts_ms": 1705312200123
}
```

가장 큰 차이는 **before 데이터**다. Debezium은 UPDATE/DELETE 시 변경 전 데이터를 포함할 수 있다. 이게 가능하려면 테이블에 `REPLICA IDENTITY FULL`이 설정되어 있어야 한다:

```sql
ALTER TABLE users REPLICA IDENTITY FULL;
```

기본값인 `REPLICA IDENTITY DEFAULT`는 primary key만 before에 포함한다. DMS는 before 데이터를 아예 지원하지 않는다.

### Tombstone 메시지

Debezium은 DELETE 시 두 개의 메시지를 보낸다:

1. `op: "d"`인 삭제 이벤트 (before 데이터 포함)
2. 같은 key에 대해 value가 null인 tombstone 메시지

Kafka의 log compaction은 이 tombstone을 보고 해당 key의 이전 메시지들을 정리한다. DMS는 tombstone을 보내지 않으므로, log compaction을 쓰려면 추가 처리가 필요하다.

### Kafka Connect SMT 호환성

Debezium은 Kafka Connect 기반이라 다양한 SMT(Single Message Transform)를 활용할 수 있다:

```yaml
# Debezium의 envelope을 풀어서 after 데이터만 추출
transforms: unwrap
transforms.unwrap.type: io.debezium.transforms.ExtractNewRecordState
transforms.unwrap.drop.tombstones: false
transforms.unwrap.delete.handling.mode: rewrite
```

DMS 메시지는 Debezium 포맷이 아니라서 이런 SMT를 직접 쓸 수 없다. MongoDB Kafka Connector처럼 custom CDC handler를 지원하는 sink라면 DMS 포맷을 처리하는 handler를 구현해야 한다:

```java
public class DmsCdcHandler extends CdcHandler {
    @Override
    public Optional<WriteModel<BsonDocument>> handle(SinkDocument doc) {
        BsonDocument value = doc.getValueDoc().orElse(new BsonDocument());
        String operation = value.getDocument("metadata")
                                .getString("operation").getValue();
        BsonDocument data = value.getDocument("data");

        return switch (operation) {
            case "insert", "load" -> Optional.of(new InsertOneModel<>(data));
            case "update" -> {
                BsonDocument filter = new BsonDocument("_id", data.get("id"));
                yield Optional.of(new ReplaceOneModel<>(filter, data,
                    new ReplaceOptions().upsert(true)));
            }
            case "delete" -> {
                BsonDocument filter = new BsonDocument("_id", data.get("id"));
                yield Optional.of(new DeleteOneModel<>(filter));
            }
            default -> Optional.empty();
        };
    }
}
```

### 운영 관점 비교

**DMS의 장점:**

- AWS 완전관리형. 인프라 운영 부담 없음
- Aurora/RDS와 같은 VPC에서 네트워크 구성이 간단
- CloudWatch 통합 모니터링

**Debezium의 장점:**

- 풍부한 메시지 포맷 (before, schema 정보 등)
- Kafka Connect 생태계 활용 (SMT, 다양한 sink connector)
- 오픈소스라 커스터마이징 자유도 높음
- 여러 DB를 하나의 Kafka Connect 클러스터로 처리 가능

어느 쪽이 나은지는 상황에 따라 다르다. before 데이터가 필요하거나 Kafka Connect 생태계를 적극 활용해야 하면 Debezium이, 운영 부담을 줄이고 싶으면 DMS가 낫다.

## 운영 시 주의사항

### Idle Slot 문제

사용하지 않는 slot이 남아있으면 WAL이 계속 쌓인다. Aurora는 스토리지가 자동 확장되지만 비용이 늘어나고, 너무 많이 쌓이면 성능에도 영향을 줄 수 있다.

```sql
-- lag이 큰 slot 찾기
SELECT slot_name,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) as lag,
       active
FROM pg_replication_slots
ORDER BY pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn) DESC;

-- 사용하지 않는 slot 삭제
SELECT pg_drop_replication_slot('unused_slot_name');
```

DMS Task를 삭제하면 slot도 같이 삭제되지만, Task가 에러 상태로 남아있으면 slot은 그대로 유지된다. 주기적으로 확인이 필요하다.

### Major Version Upgrade

Aurora PostgreSQL을 major upgrade(예: 13 → 14)하기 전에 **모든 logical replication slot을 삭제**해야 한다. Slot이 남아있으면 upgrade가 실패한다. ([AWS 문서](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.html))

### 모니터링

DMS Task의 상태는 CloudWatch에서 확인할 수 있다:

- `CDCLatencySource`: Source에서 변경을 읽어오는 지연 (초)
- `CDCLatencyTarget`: Target에 적용하는 지연 (초)
- `CDCThroughputRowsSource`: 초당 읽어온 row 수

`CDCLatencySource`가 계속 증가하면 DMS가 변경 속도를 따라가지 못하는 것이다. DMS 인스턴스 크기를 늘리거나, 병렬 처리 설정을 조정해야 한다.

PostgreSQL 쪽에서도 slot lag을 모니터링해야 한다:

```sql
SELECT slot_name,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) as lag
FROM pg_replication_slots
WHERE slot_type = 'logical';
```

이 값이 수 GB 이상으로 커지면 WAL 디스크 사용량을 확인하고 원인을 파악해야 한다.

---

참고

- [AWS DMS PostgreSQL Source](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html)
- [Aurora PostgreSQL Logical Replication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.Logical.html)
- [Managing Logical Replication Slots for Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.pglogical.handle-slots.html)
- [Aurora Storage Architecture](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.StorageReliability.html)
- [Postgres Replication Slot 101 - Artie](https://www.artie.com/blogs/postgres-replication-slot-101-how-to-capture-cdc-without-breaking-production)
- [DMS Task Resume/Restart - AWS Knowledge Center](https://repost.aws/knowledge-center/dms-restart-resume-failed-task)
- [Debezium PostgreSQL Connector](https://debezium.io/documentation/reference/stable/connectors/postgresql.html)


CDC 엔진은 데이터베이스의 변경 로그를 읽어 표준화된 메시지 포맷으로 변환하는 역할을 한다. Debezium은 Kafka Connect 기반의 오픈소스 CDC 엔진 중 하나이다.

Debezium PostgreSQL Connector는 PostgreSQL의 Logical Decoding을 통해 WAL(Write-Ahead Log)을 읽고, 이를 Debezium Envelope 포맷으로 변환하여 Kafka로 전송한다. INSERT, UPDATE, DELETE, TRUNCATE 작업을 실시간으로 스트리밍하며, 초기 스냅샷 기능도 제공하므로 데이터 동기화나 이벤트 소싱에 적합하다.

## 기본 개념

Debezium이 어떻게 PostgreSQL의 변경 데이터를 캡처하는지 이해하려면, 먼저 PostgreSQL의 핵심 개념들을 알아야 한다.

### Logical Decoding

PostgreSQL의 Logical Decoding은 WAL(Write-Ahead Log)에 기록된 변경 사항을 읽기 쉬운 형태로 변환하는 기능이다.

PostgreSQL은 데이터 무결성을 위해 모든 변경 사항을 먼저 WAL에 기록한다. Logical Decoding은 이 WAL 데이터를 해석하여 어떤 테이블의 어떤 행이 어떻게 변경되었는지를 알려준다.

```sql
-- Logical Decoding 활성화를 위한 설정
ALTER SYSTEM SET wal_level = 'logical';
```

### Replication Slot

Replication Slot은 PostgreSQL이 특정 Consumer를 위해 WAL 세그먼트를 보존하도록 하는 메커니즘이다.

PostgreSQL은 일정 시간이 지나면 WAL 세그먼트를 삭제한다. 그런데 Debezium이 잠시 중단되었다가 재시작하면 어떻게 될까? Replication Slot이 없다면 그 사이의 변경 사항을 놓칠 수 있다. Slot은 Consumer가 어디까지 읽었는지 추적하고, 아직 읽지 않은 WAL을 보존한다.

```sql
-- Replication Slot 생성
SELECT pg_create_logical_replication_slot('debezium_slot', 'pgoutput');
```

### Output Plugin

Output Plugin은 WAL 변경 사항을 특정 포맷으로 변환하는 역할을 한다.

- pgoutput: PostgreSQL 10 이상에서 기본 제공되는 플러그인이다. PostgreSQL 커뮤니티에서 관리하며 별도 설치가 필요 없다. 단, Generated Column의 값을 캡처하지 못하는 제한이 있다.
- decoderbufs: Debezium 커뮤니티에서 관리하는 Protobuf 기반 플러그인이다. 별도 설치가 필요하지만, 일부 환경에서는 pgoutput보다 더 나은 성능을 보일 수 있다.

## 커넥터 동작 방식

Debezium PostgreSQL Connector는 두 단계로 동작한다: 스냅샷과 스트리밍이다.

### 스냅샷

커넥터가 처음 시작되면 데이터베이스의 현재 상태를 캡처하는 스냅샷을 수행한다. 스냅샷 과정은 다음과 같다:

1. 설정된 격리 수준으로 트랜잭션 시작
2. 현재 트랜잭션 로그 위치(LSN) 기록
3. 대상 테이블 스캔 및 READ 이벤트 생성
4. 트랜잭션 커밋
5. 오프셋에 완료 상태 기록

**스냅샷 모드**

| 모드 | 동작 |
|------|------|
| `initial` (기본값) | Kafka 오프셋이 없을 때만 스냅샷 수행 |
| `always` | 시작할 때마다 스냅샷 수행 |
| `initial_only` | 스냅샷만 수행하고 스트리밍 안 함 |
| `no_data` | 스냅샷 없이 스트리밍만 수행 |
| `when_needed` | 오프셋 없거나 위치를 찾을 수 없을 때만 스냅샷 |
| `configuration_based` | 속성 기반으로 동작 제어 |
| `custom` | 커스텀 Snapshotter 구현 사용 |

### Incremental Snapshot

Initial Snapshot은 전체 테이블을 한 번에 읽고, 완료될 때까지 스트리밍이 시작되지 않는다. 대용량 테이블에서는 오래 걸린다.

Incremental Snapshot은 테이블을 청크 단위로 나눠서 점진적으로 읽는다. 일반적으로 "Incremental backup"은 "이전 백업 이후 변경분만"을 의미하지만, Debezium의 "Incremental"은 "한 번에 전부 안 읽고 조금씩"이라는 의미다. 용어가 혼란스럽지만 결국 전체 테이블을 다시 읽는다. 다만 스트리밍과 병렬로 실행되므로 CDC 이벤트를 놓치지 않고, 중단되더라도 재개가 가능하며, Ad-hoc으로 특정 테이블만 다시 스냅샷할 수도 있다.

```yaml
# Incremental Snapshot 설정
incremental.snapshot.chunk.size: 1024 # 청크당 행 수
read.only: true # PostgreSQL 13+ 읽기 전용 모드
```

### 스트리밍

스냅샷이 완료되면 커넥터는 Replication Protocol을 통해 실시간 변경 사항을 수신한다. 커넥터는 PostgreSQL 클라이언트처럼 동작하며, 각 이벤트의 LSN(Log Sequence Number) 위치를 기록한다.

장애가 발생하면 커넥터는 마지막으로 기록한 LSN부터 다시 시작하므로 데이터 손실 없이 복구할 수 있다.

## PostgreSQL 설정

### WAL 설정

Logical Decoding을 사용하려면 `wal_level`을 `logical`로 설정해야 한다:

```sql
-- postgresql.conf 또는 ALTER SYSTEM
wal_level = logical
max_wal_senders = 4
max_replication_slots = 4
```

설정 변경 후 PostgreSQL 재시작이 필요하다.

### 사용자 권한

Debezium 전용 Replication 사용자를 생성하는 것이 좋다. Superuser 권한 대신 필요한 권한만 부여한다:

```sql
-- Replication 사용자 생성
CREATE USER debezium WITH REPLICATION LOGIN PASSWORD 'secret';

-- 스키마와 테이블 읽기 권한
GRANT USAGE ON SCHEMA public TO debezium;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium;

-- pgoutput 사용 시 Publication 생성 권한
GRANT CREATE ON DATABASE mydb TO debezium;
```

### Publication 설정 (pgoutput)

pgoutput 플러그인 사용 시 Publication을 생성해야 한다:

```sql
-- 모든 테이블 대상
CREATE PUBLICATION debezium_pub FOR ALL TABLES;

-- 특정 테이블만
CREATE PUBLICATION debezium_pub FOR TABLE users, orders;
```

### REPLICA IDENTITY

`REPLICA IDENTITY` 설정은 UPDATE와 DELETE 시 어떤 컬럼 값을 제공할지 결정한다:

| 설정 | 동작 |
|------|------|
| `DEFAULT` | PK 컬럼의 이전 값만 제공. PK 없는 테이블은 UPDATE/DELETE 이벤트 없음 |
| `NOTHING` | 이전 값 제공 안 함 |
| `FULL` | 모든 컬럼의 이전 값 제공. PK 없는 테이블도 DELETE 가능 |
| `INDEX name` | 지정한 인덱스 컬럼의 이전 값만 제공 |

```sql
-- FULL로 설정 (권장)
ALTER TABLE users REPLICA IDENTITY FULL;
```

`FULL`로 설정하면 `before` 필드에서 변경 전 데이터를 확인할 수 있어 Sink Connector와의 연동이 수월해진다.

## 커넥터 구성

### 필수 속성

```yaml
connector.class: io.debezium.connector.postgresql.PostgresConnector
database.hostname: localhost
database.port: 5432
database.user: debezium
database.password: secret
database.dbname: mydb
topic.prefix: fulfillment
```

### 주요 속성

**연결 설정**

```yaml
database.hostname: postgres-server
database.port: 5432
database.user: debezium
database.password: secret
database.dbname: inventory
```

**캡처 대상 설정**

```yaml
# 포함할 테이블 (정규식)
table.include.list: public.users,public.orders

# 제외할 테이블
table.exclude.list: public.audit_log

# 포함할 컬럼
column.include.list: public.users.id,public.users.name

# 제외할 컬럼
column.exclude.list: public.users.password
```

**Replication 설정**

```yaml
# Replication Slot 이름
slot.name: debezium_slot

# Publication 이름 (pgoutput)
publication.name: debezium_pub

# Output Plugin
plugin.name: pgoutput
```

**스냅샷 설정**

```yaml
# 스냅샷 모드
snapshot.mode: initial

# 스냅샷 격리 수준
snapshot.isolation.mode: repeatable_read

# 특정 테이블 스냅샷 쿼리 오버라이드
snapshot.select.statement.overrides: public.large_table
snapshot.select.statement.overrides.public.large_table: SELECT * FROM public.large_table WHERE created_at > '2024-01-01'
```

**토픽 설정**

```yaml
# 토픽 접두사
topic.prefix: fulfillment

# 트랜잭션 메타데이터 토픽
topic.transaction: fulfillment.transaction
```

## 데이터 변경 이벤트

### 이벤트 구조

Debezium은 변경 이벤트를 Envelope 구조로 전송한다:

```json
{
  "before": { "id": 1, "name": "old_name", "email": "old@example.com" },
  "after": { "id": 1, "name": "new_name", "email": "new@example.com" },
  "source": {
    "version": "2.4.0",
    "connector": "postgresql",
    "name": "fulfillment",
    "ts_ms": 1705312200000,
    "snapshot": "false",
    "db": "mydb",
    "schema": "public",
    "table": "users",
    "txId": 12345,
    "lsn": 123456789
  },
  "op": "u",
  "ts_ms": 1705312200123
}
```

**필드 설명**

| 필드 | 설명 |
|------|------|
| `before` | 변경 전 행 데이터 (REPLICA IDENTITY에 따라 다름) |
| `after` | 변경 후 행 데이터 |
| `source` | 소스 데이터베이스 메타데이터 |
| `op` | 작업 유형 |
| `ts_ms` | 커넥터 처리 시간 |

### 작업 유형

| op 값 | 의미 |
|-------|------|
| `c` | CREATE (INSERT) |
| `u` | UPDATE |
| `d` | DELETE |
| `r` | READ (스냅샷) |
| `t` | TRUNCATE |
| `m` | MESSAGE |

### 토픽 명명

기본 토픽 이름 형식: `{topic.prefix}.{schema}.{table}`

예: `fulfillment.public.users`

Topic Routing SMT를 사용하면 커스텀 토픽 이름을 설정할 수 있다.

### Tombstone 메시지

DELETE 시 Debezium은 두 개의 메시지를 전송한다:

1. DELETE 이벤트 (op: `d`, before 데이터 포함)
2. Tombstone 메시지 (value가 null, Log Compaction 시 삭제용)

이 Tombstone 메시지는 Kafka Sink Connector들이 DELETE를 처리하는 데 중요하다.

### 트랜잭션 메타데이터

트랜잭션 메타데이터를 활성화하면 트랜잭션 경계(BEGIN/END)와 함께 상세 정보를 제공한다:

```json
{
  "status": "END",
  "id": "12345:123456789",
  "ts_ms": 1705312200000,
  "event_count": 5,
  "data_collections": [
    { "data_collection": "public.users", "event_count": 3 },
    { "data_collection": "public.orders", "event_count": 2 }
  ]
}
```

## SMT(Single Message Transform)

Debezium은 다양한 SMT를 제공하여 메시지를 변환할 수 있다.

### ExtractNewRecordState

가장 많이 사용되는 SMT이다. Envelope 구조를 평탄화하여 `after` 데이터만 추출한다:

```yaml
transforms: unwrap
transforms.unwrap.type: io.debezium.transforms.ExtractNewRecordState
transforms.unwrap.drop.tombstones: false
transforms.unwrap.delete.handling.mode: rewrite
```

**delete.handling.mode 옵션**

| 모드 | 동작 |
|------|------|
| `drop` | DELETE 이벤트 삭제 |
| `none` | Tombstone만 유지 |
| `rewrite` | `__deleted` 필드 추가 |

### Topic Routing

토픽 이름을 동적으로 변경한다:

```yaml
transforms: route
transforms.route.type: io.debezium.transforms.ByLogicalTableRouter
transforms.route.topic.regex: (.*)\.(.*)\.(.*)
transforms.route.topic.replacement: $1_$3
```

### Outbox Event Router

Outbox 패턴 구현을 위한 SMT이다:

```yaml
transforms: outbox
transforms.outbox.type: io.debezium.transforms.outbox.EventRouter
transforms.outbox.table.field.event.key: aggregate_id
transforms.outbox.table.field.event.payload: payload
```

## 모니터링

Debezium은 JMX를 통해 메트릭을 노출한다.

### 스냅샷 메트릭

- `TotalNumberOfEventsSeen`: 캡처한 총 이벤트 수
- `NumberOfEventsFiltered`: 필터링된 이벤트 수
- `RemainingTableCount`: 남은 테이블 수
- `SnapshotRunning`: 스냅샷 진행 여부
- `SnapshotCompleted`: 스냅샷 완료 여부

### 스트리밍 메트릭

- `MilliSecondsBehindSource`: 소스 대비 지연 시간
- `NumberOfCommittedTransactions`: 커밋된 트랜잭션 수
- `LastTransactionId`: 마지막 트랜잭션 ID
- `SourceEventPosition`: 현재 LSN 위치

## 제한 사항

Debezium PostgreSQL Connector를 사용할 때 알아야 할 제한 사항들이 있다:

- **DDL 변경 미지원**: Logical Decoding은 스키마 변경을 캡처하지 않는다
- **UTF-8 필수**: 확장 ASCII 문자는 문제를 일으킬 수 있다
- **Generated Column**: pgoutput은 Generated Column 값을 캡처하지 못한다
- **Uncommitted 변경**: Logical Decoding은 커밋 전 변경 사항도 발행할 수 있어, Master 장애 시 부작용이 발생할 수 있다

### DDL 변경과 기본값

DDL 변경이 CDC에 캡처되지 않는다는 것은 단순히 `ALTER TABLE` 문이 안 온다는 의미가 아니다. 기본값이 적용되는 경우에도 CDC 이벤트가 발생하지 않는다.

```sql
ALTER TABLE users ADD COLUMN status varchar(20) DEFAULT 'active';
```

이 DDL을 실행하면 기존 행들에 `status = 'active'`가 적용된다. 하지만 CDC 이벤트는 발생하지 않는다.

**PostgreSQL 11 이후**

기존 행을 실제로 UPDATE하지 않는다. 기본값은 `pg_attribute` 메타데이터에만 저장되고, 행을 읽을 때 해당 컬럼이 NULL이면 기본값을 반환한다 (lazy evaluation). 실제 행 변경이 없으므로 WAL에 DML이 기록되지 않고, CDC 이벤트도 없다.

**PostgreSQL 11 이전**

Table rewrite가 발생하여 전체 테이블이 재작성된다. 하지만 이건 내부적인 물리적 재작성이라 개별 UPDATE로 WAL에 기록되지 않는다. 마찬가지로 CDC 이벤트가 없다.

결과적으로 Sink 테이블에는 새 컬럼이 없고, 기본값도 적용되지 않은 상태가 된다.

### 스키마 변경 대응 방법

**1. Sink에 동일한 DDL 수동 적용**

가장 단순한 방법이다. Source에 DDL을 적용할 때 Sink에도 동일한 DDL을 적용한다.

```sql
-- Source
ALTER TABLE users ADD COLUMN status varchar(20) DEFAULT 'active';

-- Sink (수동 실행)
ALTER TABLE users ADD COLUMN status varchar(20) DEFAULT 'active';
```

단점은 수동 작업이 필요하고, 타이밍을 맞추기 어렵다는 것이다.

**2. Incremental Snapshot 재수행**

스키마 변경 후 해당 테이블의 스냅샷을 다시 수행한다:

```sql
-- Signaling 테이블에 스냅샷 요청
INSERT INTO debezium_signal (id, type, data)
VALUES ('ad-hoc-1', 'execute-snapshot', '{"data-collections": ["public.users"]}');
```

전체 테이블을 다시 읽으므로 새 컬럼과 기본값이 모두 반영된다. 단, 대용량 테이블에서는 부담이 크다.

**3. 스키마 마이그레이션 도구 연동**

Flyway나 Liquibase 같은 마이그레이션 도구를 사용한다면, Source와 Sink 모두에 마이그레이션을 적용하는 파이프라인을 구성할 수 있다:

```
Migration Tool → Source DB DDL
             → Sink DB DDL (동시 또는 순차)
```

**4. 컬럼 추가는 nullable로**

새 컬럼을 추가할 때 `NOT NULL DEFAULT` 대신 nullable로 추가하면, 기존 행에 영향 없이 새 행부터 값이 들어간다:

```sql
-- 이렇게 하면 기존 행은 NULL, 새 행부터 애플리케이션에서 값 설정
ALTER TABLE users ADD COLUMN status varchar(20);
```

Sink에서 NULL 처리 로직만 있으면 스키마 불일치 문제를 피할 수 있다.

## 정리

Debezium PostgreSQL Connector는 PostgreSQL의 Logical Decoding을 활용하여 실시간 CDC를 구현한다.

주요 특징:

- **Replication Slot**: WAL 세그먼트 보존으로 장애 시 복구 가능
- **스냅샷 + 스트리밍**: 초기 상태 캡처 후 실시간 변경 스트리밍
- **Envelope 포맷**: `before`, `after`, `source`, `op` 필드를 포함하는 표준 구조
- **Tombstone**: DELETE 처리를 위한 null 값 메시지
- **SMT**: 메시지 변환을 위한 다양한 트랜스포머

DMS와 비교했을 때, Debezium은 Kafka Connect 생태계와의 호환성이 높고 `before` 데이터와 Tombstone을 지원하여 Sink Connector와의 연동이 수월하다. 다만 직접 운영해야 하는 부담이 있다.

---

참고

- [Debezium PostgreSQL Connector Documentation](https://debezium.io/documentation/reference/stable/connectors/postgresql.html)
- [PostgreSQL Logical Decoding](https://www.postgresql.org/docs/current/logicaldecoding.html)
- [Debezium SMT - ExtractNewRecordState](https://debezium.io/documentation/reference/stable/transformations/event-flattening.html)

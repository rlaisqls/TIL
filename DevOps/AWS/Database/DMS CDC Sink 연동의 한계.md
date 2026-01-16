
AWS DMS를 CDC 파이프라인으로 사용할 때, Kafka Connect 기반의 Sink Connector들과 연동하기 어려운 이유를 정리한다.

## DMS 메시지 포맷

DMS가 Kinesis/Kafka로 보내는 CDC 메시지는 자체 포맷을 사용한다:

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

## Debezium 포맷과의 차이

Kafka Connect 생태계의 CDC Handler들은 대부분 Debezium 포맷을 기준으로 만들어져 있다:

```json
{
  "before": { "id": 1, "name": "old_name" },
  "after": { "id": 1, "name": "new_name" },
  "source": {
    "version": "2.4.0",
    "connector": "postgresql",
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

| 항목 | DMS | Debezium |
|------|-----|----------|
| Operation 표기 | `insert`, `update`, `delete` | `c`, `u`, `d`, `r` |
| 데이터 위치 | `data` | `after` |
| Before 데이터 | 미지원 | `before` 필드 |
| 메타데이터 위치 | `metadata` | `source` |
| Tombstone | 미지원 | DELETE 시 자동 전송 |

## Sink Connector 연동 문제

### MongoDB Sink Connector

MongoDB Kafka Connector는 CDC Handler를 통해 insert/update/delete를 자동 처리한다:

```yaml
change.data.capture.handler: com.mongodb.kafka.connect.sink.cdc.debezium.rdbms.postgres.PostgresHandler
```

내장된 CDC Handler 목록:
- `DebeziumPostgresHandler`
- `DebeziumMySqlHandler`
- `DebeziumMongoDbHandler`
- `QlikRdbmsHandler`
- `MongoDbChangeStreamHandler`

**DMS 포맷용 Handler는 없다.** CDC Handler 없이 사용하면:

```yaml
# Upsert만 가능
document.id.strategy: com.mongodb.kafka.connect.sink.processor.id.strategy.ProvidedInValueStrategy
writemodel.strategy: com.mongodb.kafka.connect.sink.writemodel.strategy.ReplaceOneDefaultStrategy
```

이 경우 **DELETE 처리가 불가능**하다. Tombstone 메시지가 없으면 `delete.writemodel.strategy`가 트리거되지 않는다.

### JDBC Sink Connector

Confluent JDBC Sink도 Debezium의 `ExtractNewRecordState` SMT와 함께 쓰도록 설계되어 있다:

```yaml
transforms: unwrap
transforms.unwrap.type: io.debezium.transforms.ExtractNewRecordState
transforms.unwrap.drop.tombstones: false
transforms.unwrap.delete.handling.mode: rewrite
```

DMS 포맷에는 이 SMT를 적용할 수 없다.

### Elasticsearch Sink Connector

Debezium 메시지의 tombstone을 받아 document를 삭제하는 로직이 내장되어 있다. DMS는 tombstone을 보내지 않으므로 DELETE 동기화가 안 된다.

## 해결 방법

### 1. 커스텀 CDC Handler 구현

MongoDB Sink의 경우 `CdcHandler`를 상속받아 DMS 포맷을 처리할 수 있다:

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

JAR로 빌드하여 Kafka Connect 플러그인 경로에 배포해야 한다.

### 2. SMT로 포맷 변환

DMS → Debezium 포맷으로 변환하는 커스텀 SMT 구현:

```java
public class DmsToDebeziumTransform implements Transformation<SinkRecord> {
    @Override
    public SinkRecord apply(SinkRecord record) {
        // DMS 포맷을 Debezium envelope로 변환
        // operation: "insert" → op: "c"
        // data → after
        // delete 시 tombstone 메시지 생성
    }
}
```

### 3. 스트림 처리 레이어 추가

Kafka Streams나 Flink로 중간에서 변환:

```
DMS → Kinesis → Redpanda → Flink(변환) → Redpanda → Sink Connector
```

아키텍처가 복잡해지고 운영 포인트가 늘어난다.

### 4. Debezium으로 전환

Kafka Connect 생태계를 적극 활용해야 한다면 Debezium Source Connector를 쓰는 게 가장 깔끔하다:

```
PostgreSQL → Debezium Source → Kafka/Redpanda → MongoDB Sink
```

Aurora를 사용한다면 Failover 시에도 Replication Slot이 보존되므로, DMS의 장점이었던 "재연결 시 Resume"이 Debezium에서도 동일하게 동작한다.

## 정리

| 항목 | DMS | Debezium |
|------|-----|----------|
| Sink 생태계 호환성 | 낮음 (커스텀 구현 필요) | 높음 (표준) |
| Before 데이터 | 미지원 | 지원 |
| Tombstone | 미지원 | 지원 |
| DELETE 동기화 | 커스텀 구현 필요 | 자동 |
| SMT 활용 | 불가 | 가능 |
| Aurora Failover | Resume 가능 | Resume 가능 |
| 운영 부담 | AWS 관리형 | 직접 운영 |

DMS는 AWS 관리형이라 운영이 편하지만, Kafka Connect 기반 Sink들과 연동하려면 추가 개발이 필요하다. 다양한 Sink로 CDC 데이터를 보내야 하는 경우 Debezium이 더 적합하다.

---

참고

- [MongoDB Kafka Connector - CDC Handlers](https://www.mongodb.com/docs/kafka-connector/current/sink-connector/fundamentals/change-data-capture/)
- [Debezium - ExtractNewRecordState SMT](https://debezium.io/documentation/reference/stable/transformations/event-flattening.html)
- [AWS DMS - Kinesis Target](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.Kinesis.html)

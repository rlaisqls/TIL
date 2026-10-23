Apache Doris는 MPP 기반 실시간 OLAP DB이다. FE(Java)가 SQL 파싱·옵티마이저·메타데이터·트랜잭션을 맡고, BE(C++)가 벡터화 실행과 열 지향 스토리지를 맡는다. compute-storage 분리(cloud) 모드에서는 데이터가 S3에 있고, Rowset 같은 메타는 meta-service를 통해 FoundationDB(FDB)에 들어간다.

> 코드 근거는 apache/doris master [`eb7a508`](https://github.com/apache/doris/tree/eb7a508d5e29bef12d616ea1084d1367b9e16354) (2026-10-23) 기준이다.

```
App/Pod 로그 ─▶ Vector (파싱·VRL 변환)
                 ├─▶ doris sink ──Stream Load──▶ Doris
                 └─▶ kafka sink ─▶ AutoMQ ─Routine Load─▶ Doris
```

- [Vector](https://vector.dev/)는 Rust로 만든 observability 데이터 파이프라인이다. Doris 커뮤니티가 만든 `doris` sink가 HTTP Stream Load로 NDJSON을 밀어 넣는다.
- AutoMQ는 Kafka 브로커의 로컬 디스크 저장을 S3(+WAL)로 바꾼 Kafka 호환 스트림이다. Doris가 느려지거나(compaction 지연 등) 죽어도 수집 쪽에 backpressure가 걸리지 않도록 버퍼 역할을 한다. Doris 입장에서는 그냥 Kafka라 `CREATE ROUTINE LOAD ... FROM KAFKA`로 붙인다.
- 모든 적재 작업에는 DB 안에서 유일한 **Label**이 붙는다. 같은 Label로 다시 적재하면 `Label Already Exists`로 거부되기 때문에 재시도해도 중복이 생기지 않는다. Routine Load는 Kafka offset을 적재 트랜잭션에 같이 커밋해서 exactly-once를 맞춘다.

## 데이터 모델

테이블을 만들 때 키 모델을 하나 고른다. 같은 키를 가진 행이 여러 번 들어왔을 때 어떻게 할지가 다르고, 그 "어떻게"는 적재(memtable), compaction, 쿼리 세 군데에서 일어난다.

```sql
CREATE TABLE logs   (ts DATETIME, msg STRING)            DUPLICATE KEY(ts) ...;
CREATE TABLE stats  (dt DATE, uid BIGINT, pv BIGINT SUM, last_ip VARCHAR(64) REPLACE)
                                                         AGGREGATE KEY(dt, uid) ...;
CREATE TABLE users  (uid BIGINT, name STRING, email STRING) UNIQUE KEY(uid) ...;
```

| 모델 | 같은 키가 또 오면 | 쓰임 |
|---|---|---|
| Duplicate | 그대로 둘 다 남긴다. 키는 정렬 기준일 뿐이다 | 로그, 이벤트 원본 |
| Aggregate | value 컬럼마다 정한 함수(`SUM`, `MAX`, `MIN`, `REPLACE`, `REPLACE_IF_NOT_NULL`, `HLL_UNION`, `BITMAP_UNION`)로 합친다 | 미리 집계해 둔 리포트 |
| Unique | 마지막 값 하나만 남긴다(upsert) | DB 테이블 미러, CDC 대상 |

Aggregate는 행이 들어오는 순간 다 합쳐지는 게 아니다. 같은 Rowset 안에서는 적재 때 합쳐지지만 Rowset끼리는 compaction이 합칠 때까지 따로 있다. 그래서 쿼리할 때도 한 번 더 합친다. Rowset이 많을수록 쿼리가 느려지는 이유가 이것이다.

### Unique: Merge-on-Read vs Merge-on-Write

Unique 테이블도 Segment는 불변이라 update를 제자리에서 할 수 없다. 같은 키의 새 행을 새 Rowset에 쓰고, 같은 키의 행이 여러 개 있으면 **마지막 것만 유효**하다고 본다. 삭제도 마찬가지로 "삭제됐다"는 표시(`__DORIS_DELETE_SIGN__ = 1`)를 가진 행을 새로 쓴다. 앞서 본 delete predicate가 데이터 없는 빈 Rowset이었던 것과 달리, 이건 행이 실제로 있는 Rowset이다.

```
[2-2] uid=7 name=a
[3-3] uid=7 name=b          ← update
[4-4] uid=7 __DORIS_DELETE_SIGN__=1   ← delete
```

그러면 "마지막 것"을 언제 고르느냐가 남는데, 읽을 때 고를 수도 있고 쓸 때 고를 수도 있다. 이게 두 구현이다.

**Merge-on-Read(MoR)**: 읽을 때 합친다.

- 쓰기는 그냥 append라 싸다.
- 읽을 때 모든 Rowset을 키 순서로 병합 정렬하면서 같은 키 중 버전이 가장 큰 행만 남긴다(`_unique_key_next_block`). 그 행이 delete sign이면 버린다([block_reader.cpp#L612-L624](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/iterator/block_reader.cpp#L612-L624)). 내부적으로는 모든 value가 `REPLACE`인 Aggregate와 같다.
- 병합해야 같은 키 중 무엇이 최신인지 알 수 있으므로, value 컬럼 조건은 병합 전에 내려보낼 수 없다. 그래서 Rowset이 쌓이면 읽기가 느려진다.

**Merge-on-Write(MoW)**: 쓸 때 합친다. 지금은 Unique 테이블의 기본값이다. `enable_unique_key_merge_on_write` 속성이 없으면 FE가 `"true"`를 넣는다([PropertyAnalyzer.java#L2186](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/common/util/PropertyAnalyzer.java#L2186)).

- Segment마다 **primary key 인덱스**(키 → row id)와 그 위의 bloom filter를 같이 쓴다.
- 새 행을 쓸 때 키마다 기존 Rowset들의 PK 인덱스를 찾는다([lookup_row_key](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/base_tablet.cpp#L519)). 먼저 bloom filter로 없는 키를 빠르게 거르고, 있을 수도 있으면 인덱스에서 seek한다([segment.cpp#L1290-L1297](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/segment/segment.cpp#L1290-L1297)).
- 찾으면 **옛 행의 위치**를 delete bitmap에 표시한다([base_tablet.cpp#L889-L891](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/base_tablet.cpp#L889-L891)). sequence column이 있고 옛 행의 sequence 값이 더 크면, 반대로 **새 행**을 표시한다([#L815-L834](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/base_tablet.cpp#L817-L834)).
- 읽을 때는 병합 없이 Segment를 그대로 읽고(`_direct_next_block`, Duplicate와 같은 경로), 읽을 행 집합에서 bitmap만 뺀다(`_row_bitmap -= delete_bitmap`)([segment_iterator.cpp#L838-L842](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/segment/segment_iterator.cpp#L838-L842)). 그래서 value 컬럼 조건 pushdown, zone map, inverted index를 다 쓸 수 있다.

| \ | MoR | MoW |
|---|---|---|
| 합치는 시점 | 읽을 때 | 쓸 때 |
| 쓰기 비용 | append | 키마다 PK 인덱스 조회 |
| 읽기 | 병합 정렬 필요 | bitmap 빼고 그냥 읽기 |
| value 조건 pushdown | 불가 | 가능 |
| 맞는 상황 | 쓰기가 압도적, 조회 드묾 | 실시간 분석, CDC 미러 |

**"버전이 가장 큰 것만 쓰면 되지 않나? bitmap은 왜 필요한가"**

MoR이 바로 그렇게 한다. 문제는 어떤 행이 "마지막"인지가 그 행만 봐서는 알 수 없다는 점이다. 같은 키를 가진 다른 행이 다른 Rowset에 있는지 전부 대조해야 한다. 그래서 읽을 때마다 모든 Rowset을 키 순서로 맞춰 병합해야 하고, 그 전에는 행을 하나도 버릴 수 없다.

```
[2-2] uid=7 name=a
[3-3] uid=7 name=b
SELECT * FROM users WHERE name = 'a'
```

- 병합 전에 `name = 'a'`로 먼저 거르면 `[3-3]`의 행이 빠지고 `[2-2]`의 옛 행만 남아 잘못된 결과가 나온다. 그래서 MoR은 value 조건을 병합 뒤에야 적용할 수 있다. 결국 키 순서 병합 + 전체 읽기를 매 쿼리마다 한다.
- bitmap은 "이 행은 마지막이 아니다"라는 대조 결과를 쓸 때 **한 번만 계산해서 저장**해 둔 것이다. 그러면 읽을 때는 행 하나하나를 독립적으로 판단할 수 있다. `[2-2]`의 row가 bitmap에 있으니 버리면 되고, 다른 Rowset을 볼 필요가 없다. 그래서 Segment별로 병렬로 읽고, 조건을 먼저 걸고, 인덱스로 건너뛸 수 있다.

즉 "마지막만 유효"라는 규칙은 둘 다 같다. 그 규칙을 판정하는 비용을 매 읽기마다 내느냐(MoR), 쓸 때 한 번 내고 결과를 bitmap으로 남기느냐(MoW)의 차이다. 읽기가 쓰기보다 훨씬 많은 OLAP에서는 후자가 이득이라 기본값이 MoW다.

**delete bitmap의 구조와 저장 위치**

키는 `(rowset_id, segment_id, version)`, 값은 그 Segment에서 지워진 row id들의 roaring bitmap이다([tablet_meta.h#L469-L494](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/tablet_meta.h#L475-L494)). 주석의 예: 버전 `[1,1]`인 rowset 1의 segment 1, row 1에 `key1`이 있다. 버전 `[2,2]` 적재에 `key1`이 또 오면 `{1, 1, 2} -> {1}`이 기록된다. "rowset 1·segment 1의 row 1은 버전 2에서 덮어써졌다"는 뜻이다.

- **version이 키에 들어 있는 이유**: 읽을 때 읽을 버전 이하의 bitmap만 합쳐서 쓴다(`get_agg({rowset, seg, version})`)([beta_rowset_reader.cpp#L165-L178](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/rowset/beta_rowset_reader.cpp#L165-L178)). 그래서 버전 1을 읽는 쿼리에는 버전 2의 덮어쓰기가 보이지 않는다. 일종의 MVCC다.
- **저장 위치**: shared-nothing에서는 tablet meta(`TabletMetaPB.delete_bitmap`, `DeleteBitmapPB`)에 들어가 BE의 RocksDB에 저장된다([olap_file.proto#L831-L837](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/gensrc/proto/olap_file.proto#L831-L837)). cloud 모드에서는 FDB에 저장된다. 키 형식은 두 가지다([keys.h#L51](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-store/keys.h#L51), [#L111](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-store/keys.h#L111)).
  - v1: `"delete_bitmap" ${tablet_id} ${rowset_id} ${version} ${segment_id}` → roaring bitmap
  - v2: `"delete_bitmap" ${tablet_id} ${rowset_id}` → `DeleteBitmapStoragePB`
- 동시 적재를 위해 파티션 단위 `delete_bitmap_lock` 키와 `delete_bitmap_pending` 키도 있다([keys.h#L49-L50](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-store/keys.h#L49-L50)).

### MoW 동시성: 적재끼리, 적재와 compaction

delete bitmap은 "이 키가 이미 어디 있는가"를 보고 만든다. 그런데 적재가 진행되는 동안 다른 적재가 publish되거나 compaction이 Rowset을 갈아 끼울 수 있다. 그래서 bitmap을 세 번에 나눠 계산하고, 각 단계에서 "지난번 이후 새로 생긴 Rowset"만 다시 본다.

**1. 적재 시작(flush)**: writer를 만들 때 그 시점의 최대 버전과 Rowset id 목록을 스냅샷으로 잡는다([rowset_builder.cpp#L147-L169](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/rowset_builder.cpp#L147-L169)). memtable을 Segment로 flush할 때마다 이 스냅샷 Rowset들만 대상으로 bitmap을 계산한다([beta_rowset_writer.cpp#L1350-L1351](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/rowset/beta_rowset_writer.cpp#L1350-L1351)).

**2. commit**: Segment가 여러 개면 Segment끼리의 중복을 먼저 계산한다. 이게 끝났다는 표시로 `{rowset_id, INVALID_SEGMENT_ID, 0}` 키에 `ROWSET_SENTINEL_MARK`를 넣어 둔다([base_tablet.cpp#L454-L456](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/base_tablet.cpp#L454-L456)). 그다음 현재 Rowset 목록을 스냅샷과 비교한다([base_tablet.cpp#L1562-L1568](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/base_tablet.cpp#L1562-L1568)).
- `to_add`: 스냅샷 이후 새로 보이는 Rowset이다. 이것만 다시 찾는다.
- `to_del`: 스냅샷에는 있었는데 compaction으로 사라진 Rowset이다. 그 Rowset을 가리키던 bitmap 항목을 지운다.

결과 bitmap과 "이번에 확인한 Rowset id 목록"을 txn manager에 저장한다.

**3. publish**: 진짜 버전을 받는 순간이다. 같은 비교를 한 번 더 한다([base_tablet.cpp#L1769-L1773](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/base_tablet.cpp#L1769-L1773)). commit과 publish 사이에 publish된 다른 적재와 compaction 결과가 `to_add`로 잡힌다. publish는 MoW tablet이면 `rowset_update_lock`을 잡고 한 번에 하나씩 진행한다([engine_publish_version_task.cpp#L535-L538](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/task/engine_publish_version_task.cpp#L535-L538)). 마지막으로 tablet bitmap에 합칠 때 임시 버전 0(`TEMP_VERSION_COMMON`)을 실제 버전으로 바꾼다. sentinel 항목은 이때 버린다([tablet.cpp#L2657-L2661](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/tablet.cpp#L2657-L2661)). flush 시점에는 진짜 버전을 몰라서 0을 넣어 둔 것이다(주석 [base_tablet.cpp#L872-L879](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/base_tablet.cpp#L872-L879)).

```
적재 A: flush(스냅샷 v10) ──── commit(v10~v12 확인) ──── publish(v13, v12~ 확인)
적재 B:          flush ── commit ── publish(v12)  ← A의 commit/publish에서 to_add로 잡힘
compaction:   [2-10] → [2-10]'           ← A 입장에선 [2-10]이 to_del, [2-10]'이 to_add
```

**compaction과 동시 적재**([compaction.cpp#L1913](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/compaction.cpp#L1913) `modify_rowsets`)

compaction은 적재를 막지 않는다. 대신 output을 커밋할 때 세 부류의 bitmap을 output의 새 row id로 옮긴다.

1. **compaction 시작 전 bitmap**: lock 없이 input Rowset의 bitmap 전체를 `RowIdConversion`으로 옮긴다([compaction.cpp#L1936-L1945](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/compaction.cpp#L1936-L1945)).
2. **commit은 됐지만 아직 publish 안 된 적재**: 여기부터는 `rowset_update_lock`과 header lock을 잡는다([compaction.cpp#L2018-L2020](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/compaction.cpp#L2018-L2020)). 그 적재가 compaction input을 **전부** 확인한 상태라면 그 적재의 bitmap도 output으로 옮긴다. 확인한 Rowset 목록에 output id도 넣어 준다([compaction.cpp#L2042-L2058](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/compaction.cpp#L2042-L2058)). 그러면 그 적재가 publish할 때 input은 `to_del`로 빠지고 output은 이미 확인한 것으로 간주된다. input 중 일부를 못 본 적재는 건드리지 않는다. publish 때 output이 `to_add`로 잡혀 처음부터 다시 찾는다([compaction.cpp#L2034-L2039](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/compaction.cpp#L2034-L2039)).
3. **compaction 도중 publish된 적재**: 같은 lock 안에서 compaction 시작 이후 버전의 bitmap을 한 번 더 옮긴 다음, Rowset 교체까지 끝낸다([compaction.cpp#L2063-L2073](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/compaction.cpp#L2063-L2073)). publish도 같은 lock을 잡으므로 그 사이에 끼어들 수 없다.

**partial update 충돌**

일부 컬럼만 update하는 적재는 옛 행의 나머지 컬럼을 읽어 새 행을 완성해야 한다. 이때 문제가 생긴다. 코드 주석의 예시([base_tablet.cpp#L839-L843](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/base_tablet.cpp#L839-L843))는 이렇다. 버전 5와 6이 같은 행을 update했는데 6은 쓸 때 4까지만 봤다. 그러면 6은 4의 값으로 행을 완성했으므로 5의 update가 사라진다. 그래서 publish 때 충돌한 키가 있으면 5의 원래 컬럼과 6이 update한 컬럼을 다시 읽어 새 행을 만든다. 그 새 행을 같은 Rowset에 Segment로 추가하고, 옛 행 둘은 bitmap에 표시한다([base_tablet.cpp#L852-L885](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/base_tablet.cpp#L852-L885), [base_tablet.cpp#L1924-L1938](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/base_tablet.cpp#L1924-L1938)). 실패에 대비해 bitmap 사본에서 작업한다.

**sequence column과 delete**

sequence column이 있으면 PK 인덱스 조회가 key와 sequence 값을 같이 비교한다. 새 행의 sequence가 기존 행보다 **작으면** `KEY_ALREADY_EXISTS`를 돌려주고([segment.cpp#L1335-L1341](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/segment/segment.cpp#L1335-L1341)) 새 행 쪽을 bitmap에 표시한다([base_tablet.cpp#L817-L833](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/base_tablet.cpp#L817-L833)). 같으면 새 행이 이긴다. 이 비교는 `__DORIS_DELETE_SIGN__`을 따로 보지 않는다. 그래서 delete sign 행도 sequence가 작으면 그냥 무시된다(코드상 추론이고, 이 경우만 따로 다루는 테스트는 못 찾았다). 반대로 sequence가 큰 delete가 먼저 들어오면 그 delete 행이 tombstone처럼 남아, 이후 들어오는 더 작은 sequence의 upsert를 막는다. `regression-test/suites/unique_with_mow_c_p0/test_delete_sign.groovy`가 이 시나리오를 다룬다. sequence 1, 10, 2를 넣고, sequence 10으로 delete한 다음 3을 넣어도 결과가 비어 있다.

앞서 본 "MoW는 버전이 1000개를 넘으면 승격"도 이 bitmap이 버전마다 쌓여 tablet 메타가 커지는 걸 막으려는 것이다.

### CDC: `WITH MERGE` / `DELETE ON`

CDC 스트림은 insert·update·delete가 섞여 온다. 적재 문법의 merge type이 이걸 받는다([DorisParser.g4#L1425](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-sql-parser/src/main/antlr4/org/apache/doris/nereids/DorisParser.g4#L1425)).

```sql
CREATE ROUTINE LOAD db.cdc_job ON users
WITH MERGE
COLUMNS(uid, name, email, op),
DELETE ON op = 'd'
FROM KAFKA (...);
```

| merge type | 동작 |
|---|---|
| `APPEND`(기본) | 전부 일반 upsert |
| `DELETE` | 들어오는 행 전부 삭제 |
| `MERGE` | `DELETE ON` 조건이 참인 행은 삭제, 나머지는 upsert |

실체는 숨은 컬럼 `__DORIS_DELETE_SIGN__`([Column.java#L55](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-catalog/src/main/java/org/apache/doris/catalog/Column.java#L55))에 값을 채우는 것이다. `MERGE`면 `DELETE ON` 식의 결과를, `DELETE`면 상수 1을 넣는다([NereidsLoadScanProvider.java#L96-L103](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/nereids/load/NereidsLoadScanProvider.java#L96-L103)). 그래서 Unique 테이블에서만 된다. 다른 모델에 쓰면 `load by MERGE or DELETE is only supported in unique tables.`로 거부한다([NereidsDataDescription.java#L1145-L1148](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/nereids/load/NereidsDataDescription.java#L1145-L1148)). `MERGE`인데 `DELETE ON`이 없거나, 반대로 `MERGE`가 아닌데 `DELETE ON`이 있어도 에러다([#L1041-L1051](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/nereids/load/NereidsDataDescription.java#L1041-L1051)).

CDC는 같은 키의 이벤트가 순서가 뒤바뀌어 도착할 수 있다. 이때는 sequence column(`"function_column.sequence_col"`)을 지정해서, 적재 순서가 아니라 그 컬럼 값이 큰 쪽이 이기게 한다. 적재 문법의 `ORDER BY <col>`도 같은 역할이다([DorisParser.g4#L807](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-sql-parser/src/main/antlr4/org/apache/doris/nereids/DorisParser.g4#L807)).

## Rowset과 버전

tablet(버킷 하나)의 데이터는 Rowset 단위로 쌓이고, Rowset은 **버전 구간**으로 부른다.

- tablet을 만들면 버전 `[0-1]`인 빈 초기 Rowset 하나가 생긴다. 0번과 1번 두 개가 있는 게 아니라 0~1을 덮는 Rowset 하나다. `Tablet::create_initial_rowset(req_version)`이 `Version version(0, req_version)`으로 만들고, `req_version`은 1 이상이어야 한다([tablet.cpp#L1971-L1976](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/tablet.cpp#L1971-L1976)). 새 파티션의 visible version이 1이라 `[0-1]`이 된다.
- 적재 한 번이 Rowset 하나, 버전 하나다. 그래서 `[2-2]`, `[3-3]`, `[4-4]`... 순으로 쌓인다.
- compaction으로 합쳐지면 이름이 구간이 된다. `[2-2]`부터 `[20-20]`까지 합치면 `[2-20]`이다.
- 쿼리가 "버전 40까지"를 읽으면 `[0-20] + [21-40]`처럼 구간을 이어 붙인 경로를 찾아서 읽는다. 경로에 Rowset이 많을수록 merge할 게 많아서 느려진다. 이 정도를 나타내는 게 compaction score다.

Rowset 메타에는 그 Rowset을 쓸 때의 스키마(schema_version)도 같이 저장된다. `ADD/DROP COLUMN`(light schema change)은 FE 메타만 바꾸고, 옛 Rowset은 컬럼 unique id로 매핑해서 읽는다. 실제로 컬럼이 물리적으로 추가되거나 지워지는 건 compaction이 최신 스키마로 다시 쓸 때다.

## 인덱스와 Rollup

Segment를 읽을 때는 "읽을 행" bitmap을 전체로 시작해서 인덱스로 좁혀 나간 다음, 남은 행에 대해서만 필요한 컬럼을 읽는다. 열 지향이라 쿼리가 쓰는 컬럼만 읽는 건 기본이다.

```
전체 행
 → prefix(short key) 인덱스로 key 범위 자르기     _get_row_ranges_by_keys
 → delete bitmap 빼기(MoW)
 → zone map / bloom filter로 페이지 건너뛰기
 → inverted index 결과와 AND                     _row_bitmap &= ...
 → 남은 행의 필요한 컬럼만 읽고 predicate 평가
```

([segment_iterator.cpp#L705-L743](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/segment/segment_iterator.cpp#L705-L743), [#L937](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/segment/segment_iterator.cpp#L937))

**prefix 인덱스**는 정렬 키 앞부분으로 만드는 sparse 인덱스다. 앞 36바이트, 최대 3개 컬럼까지만 쓴다([FeConstants.java#L34-L35](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/common/FeConstants.java#L34-L35)). 그래서 `WHERE`가 정렬 키의 **앞쪽 컬럼**을 걸 때만 효과가 있다. `DUPLICATE KEY(ts, uid)` 테이블에 `WHERE uid = 7`이면 prefix 인덱스를 못 쓴다.

**inverted index**는 Segment마다 "컬럼 값 → row id 목록"을 따로 만들어 둔 것이다(`INDEX idx(msg) USING INVERTED`). 정렬 순서와 상관없이 아무 컬럼에나 걸 수 있다. 결과 row id bitmap을 읽을 행 bitmap과 AND해서, 걸리는 행이 없는 페이지는 아예 읽지 않는다. `MATCH_ANY` 같은 전문 검색뿐 아니라 `=`, `IN`, 범위 조건에도 쓴다. 데이터를 중복 저장하지 않으므로 view나 별도 테이블 없이 비정렬 컬럼 조회를 빠르게 하는 수단이다.

**Rollup(동기 materialized view)**은 특정 컬럼만 골라 **다른 정렬 키**로 중복 저장하는 기능이다.

```sql
-- 원본: 컬럼 수십 개, DUPLICATE KEY(ts, uid, ...)
ALTER TABLE events ADD ROLLUP r_uid (uid, ts, event_type);
```

- 같은 테이블 안에 또 하나의 "index"로 생긴다. 파티션마다 별도 tablet을 가지는 물리 데이터다([DorisParser.g4#L518-L521](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-sql-parser/src/main/antlr4/org/apache/doris/nereids/DorisParser.g4#L518-L521)).
- 적재할 때 원본과 모든 rollup에 **같은 트랜잭션으로** 쓴다. 그래서 동기식이고 항상 원본과 일치한다. 그 대신 rollup 수만큼 쓰기와 compaction, 저장 공간이 늘어난다.
- 쿼리는 원본 테이블 이름으로 한다. 어느 index를 읽을지는 옵티마이저가 고르는데, 그 과정은 이렇다.
  1. 쿼리에 나온 OLAP 테이블마다 base가 아닌 visible index를 모두 후보로 만든다. `CREATE MATERIALIZED VIEW`로 만든 건 원래 SQL을 쓰고, rollup은 정의 SQL이 없으니 `SELECT <컬럼들> FROM t`(Aggregate 테이블이면 `GROUP BY` 포함)를 **조립해서** 동기 MV와 똑같이 취급한다([InitMaterializationContextHook.java#L114-L122](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/nereids/rules/exploration/mv/InitMaterializationContextHook.java#L114-L122), [#L256-L282](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/nereids/rules/exploration/mv/InitMaterializationContextHook.java#L256-L282)).
  2. 비동기 MV와 같은 MV 재작성 규칙으로, 쿼리를 그 MV로 바꿔 쓸 수 있는지 본다. 필요한 컬럼이 다 있어야 하고 조건이나 집계를 보정할 수 있어야 한다. 바꿔 쓸 수 있으면 대안 plan으로 memo에 들어간다.
  3. 대안들 중 비용(CBO)이 가장 낮은 걸 고른다.
- 비용 모델이 rollup을 구분하는 기준은 생각보다 단순하다([CostModel.java#L119-L152](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/nereids/cost/CostModel.java#L119-L152), [#L178-L202](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/nereids/cost/CostModel.java#L178-L202)).
  - scan 비용은 **행 수**다. 읽는 컬럼 수는 들어가지 않는다. 그래서 집계 MV처럼 행 수가 줄어드는 index가 확실히 유리하다. Aggregate 모델 index에는 작은 보너스도 있다.
  - 컬럼만 줄이고 순서를 바꾼 Duplicate rollup은 행 수가 원본과 같아서 scan 비용이 같다. 차이는 filter 비용에서 난다. index의 정렬 키 앞에서부터, `컬럼 비교연산 상수` 형태 조건에 걸린 컬럼이 연속으로 몇 개인지 센다. 그 개수만큼 filter 비용을 깎는다. 즉 **prefix가 조건에 맞는 rollup이 이긴다**. 여기서 "prefix"는 앞쪽 key 컬럼 전부이고, BE prefix 인덱스의 36바이트 제한은 반영하지 않는다([MaterializedIndexMeta.java#L178-L188](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/catalog/MaterializedIndexMeta.java#L178-L188)).
  - `USE_MV` 힌트를 주면 그 index의 비용을 음의 무한대로 만들어 강제로 고르게 한다.
  - 위 예에서 `SELECT event_type FROM events WHERE uid = 7`은 `r_uid`의 첫 key가 `uid`라 filter 비용이 깎여 `r_uid`를 고른다. 반면 조건 없이 `SELECT uid FROM events`만 하면 행 수가 같으니 비용에 차이가 없다. "컬럼이 적어서" 고르는 게 아니라는 점에 주의.
- Aggregate처럼 집계까지 미리 해 둘 수도 있다(`CREATE MATERIALIZED VIEW ... AS SELECT uid, SUM(pv) ... GROUP BY uid`). 지금은 이게 동기 MV이고, rollup은 그 특수한 경우(집계 없이 컬럼과 순서만 바꾼 것)다.
- 여러 테이블 조인 결과를 주기적으로 갱신하는 **비동기 MV**(`CREATE MATERIALIZED VIEW ... BUILD ... REFRESH ...`)는 다른 기능이다. 별도 테이블로 생기고 원본과 시차가 있다.

| | 중복 저장 | 정렬 바꾸기 | 컬럼 줄이기 | 쓰기 비용 |
|---|---|---|---|---|
| inverted index | 인덱스만 | X | X | 인덱스 빌드 |
| Rollup / 동기 MV | 데이터 | O | O | 적재가 rollup 수만큼 |

## Cumulative / Base Compaction

버전 축은 **cumulative point**를 기준으로 둘로 나뉜다.

```
version:  0 ─────────── 20 │ 21  22  23 ... 40
          [ base 영역      ] │ [ cumulative 영역 ]
                    cumulative point
```

흐름

```
생성       [0-1]
적재       [0-1] [2-2] [3-3] ... [20-20]
cumu       [0-1] [2-20]
적재       [0-1] [2-20] [21-21] ... [40-40]
cumu       [0-1] [2-20] [21-40]
승격       [2-20]이 promotion size를 넘음 → point = 21
base       [0-20] [21-40]
```

BE의 compaction 스케줄러는 cumulative를 `cumulative_compaction_rounds_for_each_base_compaction_round`(기본 9)번 돌리고 base를 한 번 돌리는 걸 반복한다([olap_server.cpp#L684-L697](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/olap_server.cpp#L684-L697)). 아래 설정 기본값은 모두 [config.cpp](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/common/config.cpp#L514-L570)에 있다.

### Cumulative compaction

point 뒤에 있는 작은 Rowset들을 자주 합친다. 후보 score가 `cumulative_compaction_min_deltas`(5)를 넘어야 돌고, 한 번에 `cumulative_compaction_max_deltas`(1000)까지 넣는다. point 뒤를 한 번에 전부 합치지는 않고, 연속된 구간 하나를 골라 합친다([pick_input_rowsets](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_policy.cpp#L251)). 구간을 끊는 기준은 다음과 같다.

| 기준 | 동작 | 코드 |
|---|---|---|
| 개수 상한 | score가 max를 넘으면 뒤에서부터 잘라낸다 | [#L282-L297](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_policy.cpp#L282-L297) |
| delete predicate | 앞에 모은 게 있으면 거기서 끊고, 없으면 delete Rowset을 건너뛴다. 주석: *"we should compact those version before handling them over to base compaction"* | [#L303-L314](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_policy.cpp#L303-L314) |
| 크기 레벨 | 크기를 2의 거듭제곱 레벨로 바꾼다. 맨 앞 Rowset의 레벨이 나머지 합의 레벨보다 크면 빼고, 같거나 작아질 때까지 반복한다. 1KB 미만은 레벨 0, 상한은 promotion size의 절반 | [#L355-L361](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_policy.cpp#L355-L361), [`_level_size`](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_policy.cpp#L425-L431) |
| 버전 구멍 | 버전이 끊긴 곳에서 멈춘다. shared-nothing에서 replica에 버전이 빠지면 clone으로 복구된 뒤에 합친다 | [#L88-L91](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_policy.cpp#L88-L91) |

크기 레벨 예시: 앞에 600MB짜리가 있고 뒤에 10MB가 5개 있으면, 600MB의 레벨(512MB)이 나머지 50MB의 레벨(32MB)보다 크다. 그래서 600MB는 빼고 10MB 5개만 합친다. 600MB를 작은 것 몇 개 때문에 다시 쓰지 않으려는 것이다.

**promotion size**는 base 크기에 비례하되 범위를 정해 둔다([_calc_promotion_size](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_policy.cpp#L127-L140)).

```
promotion_size = clamp(base_size × compaction_promotion_ratio(0.05),
                       compaction_promotion_min_size_mbytes(128MB),
                       compaction_promotion_size_mbytes(1024MB))
```

compaction이 끝나면 point를 옮길지 정한다([update_cumulative_point](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_policy.cpp#L147-L175)).

- 입력에 delete 버전이 있었으면 무조건 output 뒤로 옮긴다.
- output 크기가 promotion size 이상이면 옮긴다.
- MoW 테이블은 크기가 작아도 output이 `compaction_promotion_version_count`(1000)개 버전을 넘게 덮으면 옮긴다. 버전이 많으면 delete bitmap이 커져 tablet 메타 저장이 느려지기 때문이라고 주석에 적혀 있다.

### Base compaction

base Rowset과 point 아래로 승격된 Rowset을 드물게 합친다([pick_rowsets_to_compact](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/base_compaction.cpp#L138-L240)). 넣을 Rowset은 score 합이 `base_compaction_max_compaction_score`(20, MoW는 200) 안에서 자른다. 그다음 아래 중 **하나라도** 맞으면 돈다.

| 조건 | 기본값 | 코드 |
|---|---|---|
| 입력 Rowset 수 > `base_compaction_min_rowset_num` | 5 | [#L196](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/base_compaction.cpp#L196) |
| cumulative 쪽 합 / base 크기 > `base_compaction_min_data_ratio` | 0.3 | [#L212-L223](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/base_compaction.cpp#L212-L223) |
| base Rowset이 만들어진 지 `base_compaction_interval_seconds_since_last_operation` 초 경과 | 86400(1일) | [#L231-L240](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/base_compaction.cpp#L231-L240) |

예외도 있다. 입력이 `[0-1]`과 `[2-y]` 두 개뿐이면 건너뛴다. 주석에 *"[0-1] has no data"*라고 적혀 있다([#L175-L179](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/base_compaction.cpp#L175-L179)). 데이터 전체를 다시 쓰므로 비싸지만, 승격되는 Rowset이 이미 크게 뭉쳐 있어서 자주 돌 필요가 없다.

Duplicate 테이블은 큰 Rowset을 base에서도 빼 준다. 입력에 delete predicate가 없으면 맨 앞에서부터 `base_compaction_dup_key_max_file_size_mbytes`(1GB) 이상인 Rowset을 입력에서 제외한다([base_compaction.cpp#L115-L136](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/base_compaction.cpp#L115-L136)). 같은 키를 합칠 일이 없으니 이미 큰 파일을 다시 쓸 이유가 없다. 반대로 delete predicate가 하나라도 있으면 이 생략을 하지 않고 전부 다시 쓴다. 지울 행이 큰 파일 안에도 있을 수 있기 때문이다.

둘로 나누는 이유는 LSM의 tiered/leveled 절충과 같다. 매 적재마다 전체를 다시 쓰면 쓰기 증폭이 터지고, 작은 것만 계속 합치면 읽기 경로가 길어진다. 최근 데이터는 싸게 자주, 충분히 커진 덩어리만 드물게 base로 흡수한다.

### time_series 정책

append-only 로그 테이블에는 `"compaction_policy" = "time_series"`를 쓴다. 미병합 데이터가 `time_series_compaction_goal_size_mbytes`(1GB)를 넘거나, 파일이 2000개를 넘거나, 1시간이 지나면 합친다([cumulative_compaction_time_series_policy.cpp#L100](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_time_series_policy.cpp#L100)). compaction이 끝나면 크기와 상관없이 point를 output 뒤로 옮긴다. 즉 결과를 바로 승격한다([#L434-L450](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_time_series_policy.cpp#L434-L450)).

base compaction은 **delete 버전이 있을 때만** 돈다. base score 계산에서 time_series면 `(base_rowset_exist && has_delete) ? score : 0`을 돌려준다([tablet.cpp#L1156-L1160](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/tablet.cpp#L1156-L1160)). 로그는 업데이트가 없으니 base를 다시 쓸 이유가 없고, delete predicate를 적용할 때만 필요하다.

### 버전 상한과 stale Rowset

tablet 버전 수가 `max_tablet_version_num`(2000, time_series는 `time_series_max_tablet_version_num` 20000)을 넘으면 적재가 `-235` 에러로 막힌다([config.cpp#L953-L955](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/common/config.cpp#L953-L955)). 적재가 compaction보다 빠를 때 생긴다. 배치를 키워 적재 횟수를 줄이거나 compaction 스레드를 늘린다.

합쳐진 옛 Rowset은 실행 중인 쿼리가 읽고 있을 수 있어서 바로 지우지 않고 stale로 둔다. `tablet_rowset_stale_sweep_time_sec`(600초)이 지나면 지운다([config.cpp#L402](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/common/config.cpp#L402)).

## Cloud 모드: compaction과 delete bitmap

shared-nothing에서는 tablet의 주인이 BE 하나라서, compaction과 publish를 BE 프로세스 안의 lock(`rowset_update_lock`)으로 직렬화하고 결과를 로컬 tablet meta에 저장하면 됐다. cloud 모드는 BE가 stateless다. 같은 tablet을 여러 BE가 만질 수 있으므로 이 조정을 **meta-service(FDB)**가 대신한다.

**compaction 작업 잡기: job + lease**

1. BE가 meta-service에 `start_tablet_job`을 보낸다. 요청에는 input 버전 범위, 만료 시각(`compaction_timeout_seconds` 86400초), lease(`lease_compaction_interval_seconds` 20초 × 4)가 들어간다([cloud_cumulative_compaction.cpp#L230-L232](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/cloud/cloud_cumulative_compaction.cpp#L230-L232)).
2. tablet 하나의 진행 중인 job들은 FDB 키 하나(`job_tablet_key` → `TabletJobInfoPB`)에 모여 있다. 만료됐거나 lease가 끊긴 job은 먼저 치운 다음 충돌을 검사한다([meta_service_job.cpp#L264-L279](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service_job.cpp#L264-L279)).
3. 충돌 규칙([meta_service_job.cpp#L281-L391](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service_job.cpp#L281-L391)):
   - MoW 테이블의 schema change(STOP_TOKEN)가 있으면 모든 compaction을 거부한다([meta_service_job.cpp#L285-L294](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service_job.cpp#L285-L294)).
   - 버전 범위가 겹치는 compaction끼리는 `JOB_TABLET_BUSY`로 거부한다. 겹치는 범위를 돌려주므로 BE가 다른 범위로 다시 시도할 수 있다. 즉 범위만 안 겹치면 같은 tablet에서 cumulative 여러 개가 병렬로 돈다.
   - BE의 캐시가 낡았으면(compaction 횟수가 FDB보다 적으면) `STALE_TABLET_CACHE`로 거부한다([meta_service_job.cpp#L224-L235](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service_job.cpp#L224-L235)).
4. BE는 도는 동안 주기적으로 lease를 갱신한다. BE가 죽으면 lease가 끊겨 다른 BE가 그 범위를 다시 잡을 수 있다.
5. 두 BE가 같은 tablet에 동시에 job을 등록하면 둘 다 같은 `job_tablet_key`를 읽고 쓰므로 FDB 트랜잭션 충돌이 난다. meta-service는 `KV_TXN_CONFLICT`를 받으면 핸들러 전체를 지수 backoff(+ 랜덤 drift)로 다시 실행한다([meta_service.h#L1105-L1150](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service.h#L1105-L1150)). 다시 실행할 때는 이긴 쪽의 job이 이미 키에 들어 있다. 그래서 진 쪽은 위 충돌 규칙에 걸려 `JOB_TABLET_BUSY`를 받는다. 재시도 횟수를 넘기면 `KV_TXN_CONFLICT_RETRY_EXCEEDED_MAX_TIMES`를 돌려주고, BE도 conflict를 따로 재시도한다([cloud_meta_mgr.cpp#L617-L633](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/cloud/cloud_meta_mgr.cpp#L617-L633)).

**커밋: FDB 트랜잭션 하나**

`process_compaction_job`이 한 트랜잭션 안에서 이렇게 한다. 주석: *"1. update tablet stats 2. move compaction input rowsets to recycle 3. change tmp rowset to formal rowset 4. remove compaction job"*([meta_service_job.cpp#L1130-L1139](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service_job.cpp#L1130-L1139)).

- tablet stats(행 수, 크기, compaction 횟수, **cumulative point**)를 갱신한다. cloud 모드에서 cumulative point는 FDB의 `TabletStatsPB`에 있다. 낡은 제안으로 point를 되돌리는 건 거부한다([meta_service_job.cpp#L836-L921](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service_job.cpp#L836-L921)).
- input Rowset 메타를 지우고 recycle 키를 만든다. input의 delete bitmap도 지운다([meta_service_job.cpp#L1327-L1381](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service_job.cpp#L1327-L1381)). 실제 파일은 바로 지우지 않는다. recycler가 `compacted_rowset_retention_seconds`(3시간) 뒤에 지운다([config.h#L100-L105](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/common/config.h#L100-L105)). 그 사이에 옛 버전을 읽던 쿼리가 끝날 시간을 주는 것이다. shared-nothing의 stale sweep(600초)과 같은 역할이다.
- output Rowset을 임시 키에서 정식 키로 옮기고 job을 지운다.

**delete bitmap lock**

MoW에서 적재와 compaction이 bitmap을 동시에 고치지 못하게 FDB에 `delete_bitmap_lock` 키를 둔다. 키에 partition id 자리가 있지만 호출하는 쪽이 전부 `-1`을 넣어서 실제로는 **테이블 단위** lock이다([meta_service_job.cpp#L652](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service_job.cpp#L652)).

| 잡는 쪽 | lock id |
|---|---|
| 적재 | 자기 txn id |
| compaction | -1 |
| schema change | -2 |

([meta_service.h#L47-L48](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service.h#L47-L48))

- 적재: FE가 publish 전에 lock을 잡고, txn commit 때 `lock_id == txn_id`인지 확인한 다음 lock을 푼다.
- compaction: 옛 버전 bitmap 변환은 lock 없이 해 둔다. 그다음 lock을 잡고, Rowset을 다시 동기화해 그사이 늘어난 증분만 계산하고, `commit_tablet_job`에서 lock을 푼다([cloud_tablet.cpp#L1434-L1491](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/cloud/cloud_tablet.cpp#L1434-L1491)).
- lock 만료는 10초(`delete_bitmap_lock_expiration_seconds`)다. 그 안에 끝내지 못해 적재가 lock을 가져가면 compaction 커밋이 `LOCK_EXPIRED`로 실패한다([meta_service_job.cpp#L672-L698](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service_job.cpp#L672-L698)). compaction은 이 lock을 갱신하지 않는다. lease 갱신(`LEASE`)은 job 키의 lease만 고치고 lock은 건드리지 않는다([meta_service_job.cpp#L1113-L1127](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service_job.cpp#L1113-L1127)). BE의 lock 관련 호출도 잡기(`get_delete_bitmap_update_lock`)와 풀기 두 가지뿐이다. 그 대신 lock을 **마지막 순간에만** 잡는다. 무거운 병합과 옛 bitmap 변환이 다 끝난 다음, 증분 계산 직전에 잡는다([cloud_tablet.cpp#L1432-L1435](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/cloud/cloud_tablet.cpp#L1432-L1435)). 그래서 lock을 쥐는 구간이 짧고, 10초 만료로 충분하다는 설계다. 잡을 때 `LOCK_CONFLICT`가 나면 BE가 backoff하며 재시도한다([cloud_meta_mgr.cpp#L2331-L2360](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/cloud/cloud_meta_mgr.cpp#L2331-L2360)).

`delete_bitmap_pending ${tablet_id}`는 적재가 써 둔 bitmap 키 목록이다. 적재가 실패하거나 재시도하면, 다음 bitmap 갱신 때 이 목록을 보고 옛 시도가 남긴 키를 지운다. compaction은 이걸 남기지 않는다. 주석: *"no need to record pending key for compaction, because delete bitmap will attach to new rowset"*([meta_service.cpp#L4445](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service.cpp#L4445)).

**저장 형식 v1 / v2**

| | 키 | 값 |
|---|---|---|
| v1 | `delete_bitmap ${tablet} ${rowset} ${version} ${segment}` | roaring bitmap 하나. 크면 여러 키로 쪼갬 |
| v2 | `delete_bitmap ${tablet} ${rowset}`(versioned 키) | `DeleteBitmapStoragePB`: 그 Rowset이 만든 삭제 전부. 89000바이트를 넘으면 object storage 파일로 빼고 위치만 저장 |

([cloud.proto#L2031-L2035](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/gensrc/proto/cloud.proto#L2031-L2035), [keys.h#L51](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-store/keys.h#L51), [#L111](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-store/keys.h#L111))

BE 설정 `delete_bitmap_store_write_version`/`read_version`으로 고르고(1 = v1, 2 = v2, 3 = 둘 다), 기본값은 1이다. 코드에서 확인한 v2의 필요성은 하나다. 인스턴스가 versioned write/read를 켜면 meta-service가 v1 읽기·쓰기를 거부한다([meta_service.cpp#L4339-L4344](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-service/meta_service.cpp#L4339-L4344)). versioned write란 메타 키를 `0x03` 키 공간에 쓰는 것이다. 이 공간의 키에는 FDB versionstamp(커밋 시각에 해당)가 붙어서 같은 키의 여러 버전이 남는다([keys.h#L92-L111](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/cloud/src/meta-store/keys.h#L92-L111)). 같은 키 목록에 `snapshot_data_migrator`, `snapshot_chain_compactor` 같은 job이 있는 걸 보면, 메타데이터 스냅샷(특정 시점 복원)을 위한 공간으로 보인다. v1 bitmap 키는 `0x01` 단일 버전 공간에 있고 version·segment마다 키가 따로라서 이 방식에 맞지 않는다. 그래서 Rowset당 값 하나인 v2를 새로 만든 것으로 보인다. 스냅샷 용도와 FDB 값 크기 제한(큰 값은 파일로 빼기)이 동기라는 건 키 구성과 코드에서 추론한 것이고, 설계 문서로 확인하지는 못했다.

**읽을 때**: BE는 Rowset을 동기화할 때 MoW tablet이면 delete bitmap도 받아 메모리의 tablet bitmap에 합친다. 자기가 publish하면서 계산한 bitmap은 캐시에서 재사용하고, 나머지는 meta-service에서 증분만 받아 온다([cloud_meta_mgr.cpp#L896-L917](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/cloud/cloud_meta_mgr.cpp#L896-L917), [cloud_meta_mgr.cpp#L1227-L1252](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/cloud/cloud_meta_mgr.cpp#L1227-L1252)).

## 삭제

삭제는 여러 종류가 있지만 크게 둘로 나뉜다.

**1. 메타데이터 단위 삭제: DROP TABLE, DROP PARTITION, TRUNCATE, TTL**

tablet이나 파티션을 통째로 버린다. 데이터 파일을 읽거나 다시 쓸 필요가 없어서 compaction과 상관없이 즉시 끝난다.

- 휴지통(recycle bin) 개념이 있다. drop하면 메타에서 휴지통으로 옮겨지기만 해서 조회 대상에서는 바로 빠진다. 데이터는 `catalog_trash_expire_second`(86400초, 1일) 동안 남아 있고 그동안 `RECOVER`로 되살릴 수 있다([Config.java#L730-L733](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-common/src/main/java/org/apache/doris/common/Config.java#L730-L733)). `FORCE`를 붙이면 휴지통을 거치지 않는다([InternalCatalog.java#L1071](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/datasource/InternalCatalog.java#L1071)). cloud 모드에서는 recycler가 나중에 S3 객체와 FDB 메타를 정리한다.
- TTL은 행 단위가 아니다. dynamic partition이 `dynamic_partition.start` 범위 밖의 오래된 파티션을 drop하는 방식이다. 이때도 `forceDrop=false`로 drop하므로 휴지통을 거친다([DynamicPartitionScheduler.java#L649](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/clone/DynamicPartitionScheduler.java#L649)). 그래서 로그 테이블은 시간으로 파티셔닝한다.

**TRUNCATE와 DROP의 차이**

| | `DROP TABLE` | `TRUNCATE TABLE [PARTITION ...]` |
|---|---|---|
| 테이블 정의 | 사라진다 | 남는다(id, 스키마, 속성, 권한 그대로) |
| 데이터 | 테이블째 휴지통으로 | 파티션 단위로 갈아 끼운다 |
| 휴지통 | 테이블이 들어감 | 옛 파티션이 들어감 |
| 범위 지정 | 테이블 전체 | 특정 파티션만도 가능 |

TRUNCATE는 내부적으로 데이터를 지우지 않는다. 같은 스키마로 **새 id를 가진 빈 파티션**을 만들고([InternalCatalog.java#L3872-L3890](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/datasource/InternalCatalog.java#L3872-L3890)), 옛 파티션과 바꿔 끼운 다음 옛 것을 휴지통으로 보낸다([#L4015-L4043](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/datasource/InternalCatalog.java#L4015-L4043)). tablet이 통째로 새것이 되니 버전도 `[0-1]`부터 다시 시작한다. `TRUNCATE ... FORCE`면 휴지통을 거치지 않고, 이때 데이터가 없는 파티션은 아예 건너뛴다([#L3808-L3811](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/datasource/InternalCatalog.java#L3808-L3811)).

**2. 행 단위 삭제: compaction과 연관됨**

조건에 맞는 행만 지워야 하므로 읽은 다음 걸러내야 한다. 바로 지우지 않고 "삭제 표시"만 남겼다가 compaction이 물리적으로 지운다.

> **한눈에 보기**
>
> 1. 적재할 때마다 Rowset이 하나씩 쌓이고, 이미 쓴 파일은 고치지 않는다. 왼쪽(버전이 작은 쪽)일수록 오래된 데이터다.
> 2. 파일이 많아지면 합친다. cumulative는 최근의 작은 파일끼리만 자주 합치고, 왼쪽의 큰 파일은 입력에 넣지 않는다. 이걸 "앞을 안 본다"고 한다. base는 가끔 0번부터 전부 합친다.
> 3. `DELETE uid=7`은 데이터를 지우지 않는다. "이 버전 이전의 uid=7은 무시"라는 메모만 새 버전으로 남기고, 쿼리할 때마다 그 메모로 걸러낸다.
> 4. 메모를 버리려면 0번부터 전부 합치며 uid=7을 빼야 한다. 중간부터만 합치고 메모를 버리면 앞쪽 파일의 uid=7을 막아 줄 게 없어서 다시 보인다.
>
> ```
> [0-10: uid=7] [11-20: uid=7] [21: 메모]
> [11-21]만 합치고 메모를 버리면 → [0-10: uid=7] [11-21]  ← uid=7 부활
> ```
>
> 5. 그래서 cumulative(앞을 안 봄)는 메모를 그대로 넘기고, base(앞부터 다 봄)만 실제로 지우고 메모를 버린다. base가 0번부터 시작할 수 없으면 합치지 않고 메모를 계속 둔다.

Segment는 불변이다. 한 번 쓴 파일은 고치지 않고, compaction이 새 Segment를 만들고 옛 것을 지울 뿐이다. 그래서 `DELETE FROM t WHERE ...`도 기존 파일을 건드리지 않는 **쓰기 작업**으로 처리된다. 테이블 모델에 따라 두 가지 길로 갈린다([DeleteFromCommand.java#L212-L218](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/nereids/trees/plans/commands/DeleteFromCommand.java#L212-L218)).

| 테이블 | DELETE가 만드는 것 |
|---|---|
| Duplicate, Aggregate, Unique MoR | **delete predicate**: 조건문만 담은 빈 Rowset |
| Unique MoW(기본) | **delete sign 행**: 지울 행을 찾아 `__DORIS_DELETE_SIGN__ = 1`로 다시 적재한다([#L544-L545](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/nereids/trees/plans/commands/DeleteFromCommand.java#L544-L545)). `enable_mow_light_delete`를 켜면 MoW도 predicate 방식을 쓴다 |

Aggregate와 Unique MoR은 delete predicate에 key 컬럼만 쓸 수 있다. value 컬럼은 여러 Rowset에 걸쳐 아직 합쳐지지 않은 값이라, 조건을 걸면 결과가 합치는 시점에 따라 달라지기 때문이다([#L378-L392](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/fe/fe-core/src/main/java/org/apache/doris/nereids/trees/plans/commands/DeleteFromCommand.java#L378-L392)).

**delete predicate가 저장되는 방식**

DELETE도 버전 하나를 받아 Rowset을 만든다. 다만 데이터가 없어서 Segment 파일이 없다. 주석에도 *"If it is push delete, the broker_scan_range is not set"*이라고 적혀 있다([push_handler.cpp#L251](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/load/delta_writer/push_handler.cpp#L251)). 조건문은 `DeletePredicatePB`로 만들어져([#L135-L148](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/load/delta_writer/push_handler.cpp#L135-L148)) 그 빈 Rowset의 **메타**에 들어간다([#L208](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/load/delta_writer/push_handler.cpp#L208), [rowset_meta.h#L254](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/rowset/rowset_meta.h#L254)). Rowset 메타는 cloud 모드에서는 FDB에, shared-nothing에서는 BE의 tablet meta(RocksDB)에 있다. 즉 "어떤 행이 없어졌다"는 정보가 데이터 파일이 아니라 메타에만 있다.

```
[0-1] [2-2] [3-3] [4-4: segment 없음, delete_predicate = "uid = 7"] [5-5]
```

**조회할 때 적용되는 방식**

1. 쿼리 시작 시 `DeleteHandler::init`이 읽을 버전 이하의 delete Rowset을 모으고, 각 조건에 그 Rowset의 버전을 `filter_version`으로 붙인다([delete_handler.cpp#L614-L632](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/delete/delete_handler.cpp#L614-L632)).
2. Rowset마다 리더를 만들 때, **그 Rowset보다 나중 버전**의 조건만 건다(`filter_version > rowset.end_version`)([beta_rowset_reader.cpp#L137-L142](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/rowset/beta_rowset_reader.cpp#L137-L142), [delete_handler.cpp#L687-L692](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/delete/delete_handler.cpp#L687-L692)). 위 예시에서 `uid = 7` 조건은 `[2-2]`, `[3-3]`에만 걸리고, DELETE 뒤에 적재한 `[5-5]`의 `uid = 7`은 그대로 보인다.
3. 조건은 **뒤집어서** "남길 행" predicate로 만든다(`opposite = true`)([#L139-L157](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/delete/delete_handler.cpp#L139-L157)). `WHERE a = 1 AND b = 2`는 드모르간으로 `a != 1 OR b != 2`가 된다.
4. **페이지 단위로 건너뛰기**: 컬럼 페이지의 zone map(min/max)을 보고 페이지 전체가 삭제 조건에 해당하면 그 페이지를 아예 읽지 않는다. 예를 들어 `uid = 7`인데 페이지의 min = max = 7이면 건너뛴다([column_reader.cpp#L810-L816](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/segment/column_reader.cpp#L810-L816)). 다만 조건이 여러 컬럼에 걸치면(OR가 되면) 이 최적화는 쓰지 않는다.
5. **행 단위로 걸러내기**: 일반 WHERE 조건을 평가한 다음 delete 조건으로 한 번 더 거른다. 이때 걸러진 행 수는 통계 `rows_vec_del_cond_filtered`로 보인다([segment_iterator.cpp#L2718-L2722](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/segment/segment_iterator.cpp#L2718-L2722)).
6. delete 조건이 하나라도 있으면 그 Rowset은 condition cache를 쓰지 않는다([beta_rowset_reader.cpp#L143-L145](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/rowset/beta_rowset_reader.cpp#L143-L145)).

그래서 DELETE를 자주 하면 조건이 쌓여 모든 쿼리에 필터가 붙고 느려진다. 이걸 물리적으로 정리하는 게 compaction이다. 조건은 과거 데이터 전체에 적용해야 하는데 cumulative 영역에는 과거 데이터가 없다. 그래서 cumulative는 delete Rowset에서 끊고 point를 넘기며, 실제로 지우는 건 base compaction이 한다. base도 0번 버전부터 시작하지 않는 입력에 delete predicate가 끼어 있으면 *"Some rowsets cannot apply delete predicates"*로 포기한다([base_compaction.cpp#L160-L173](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/base_compaction.cpp#L160-L173)).

- compaction 자체도 삭제를 만든다. 합쳐진 옛 Rowset은 stale로 잠시 남겼다가 지운다. cloud 모드에서는 이것도 recycler가 S3에서 지운다.

**compaction이 delete Rowset을 만났을 때**

cumulative는 delete predicate를 **적용하지 않는다**. compaction reader를 만들 때 cumulative면 delete 조건을 아예 읽지 않고 바로 반환한다([tablet_reader.cpp#L455-L460](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/tablet_reader.cpp#L455-L460)). 그 대신 delete Rowset을 base 쪽으로 넘긴다.

```
[0-1] [2-2] [3-3: delete uid=7] [4-4] [5-5] ...   point = 2
```

1. point부터 후보를 훑다가 `[3-3]`에서 delete를 만나 멈춘다. 모인 건 `[2-2]` 하나다([cumulative_compaction_policy.cpp#L303-L314](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_policy.cpp#L303-L314)).
2. delete를 만났으면 score가 모자라도 바로 진행하는데, 겹치지 않는 Rowset 하나뿐이면 합칠 게 없으니 비운다([#L335-L345](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction_policy.cpp#L335-L345)).
3. 입력이 비었는데 delete를 만났으므로 point를 `delete 버전 + 1 = 4`로 올린다. 주석: *"we meet a delete version, should increase the cumulative point to let base compaction handle the delete version"*([cumulative_compaction.cpp#L210-L224](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/cumulative_compaction.cpp#L210-L224)).
4. 이제 `[2-2]`와 `[3-3]`은 base 영역이고, cumulative는 `[4-4]`부터 다시 쌓인다.

앞에 Rowset이 여러 개 있었다면(`[2-2]`, `[3-3]`, `[4-4: delete]`) `[2-3]`으로 합친 뒤 point를 그 뒤로 옮긴다. 다음 라운드에서 delete Rowset을 건너뛰면서 point가 또 넘어간다. 어느 쪽이든 `uid = 7`인 행은 **아직 파일에 그대로 있다**. 쿼리 때 필터로 가려질 뿐이고, 실제로 사라지는 건 base compaction이 `[0-1]`부터 delete 버전까지를 한꺼번에 다시 쓸 때다. (`enable_delete_when_cumu_compaction`을 켜면 cumulative도 predicate를 적용하지만 기본값은 `false`다.)

**앞쪽(base) Rowset은 언제 다시 쓰나**

delete predicate는 그보다 옛 데이터 전체, 즉 `[0-1]`부터 적용해야 한다. 앞쪽을 빼고 합치면서 조건을 적용하면, output에서 조건이 사라지는데 빠진 앞쪽 Rowset의 행은 그대로 남아 **지운 행이 다시 보인다**.

```
[0-4: uid=7] [5-20: uid=7] [21: delete uid=7]
[5-21]만 합치며 적용 → [0-4] [5-21]  ← 조건이 없어져 [0-4]의 uid=7이 되살아남
```

그래서 "앞쪽(큰 Rowset)은 안 건드린다"는 생략은 **조건을 적용하지 않는 compaction에서만** 성립한다.

| compaction | 앞쪽 생략 | 이유 |
|---|---|---|
| cumulative | 항상 한다(point 뒤만 보고, 크기 레벨로 앞쪽 큰 것도 뺀다) | delete를 적용하지 않고 조건을 base로 넘긴다. 조건이 살아 있으니 안전하다 |
| Duplicate base, delete 없음 | 맨 앞의 1GB 이상 Rowset을 뺀다 | 지울 게 없고 합칠 키도 없다 |
| base, delete 있음 | 하지 않는다 | Duplicate의 큰 파일 생략도 꺼진다([base_compaction.cpp#L121-L125](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/base_compaction.cpp#L121-L125)). 0번부터 시작하지 못하면 아예 포기한다([#L146-L173](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/base_compaction.cpp#L146-L173)) |

즉 **조건을 버리는 순간에만** 0번부터 전부 읽어야 한다.

그래서 앞쪽을 건드리지 못하면 삭제도 물리적으로 일어나지 않는다. 그런 경우는 이렇다.

| 경우 | 이유 |
|---|---|
| 앞쪽 Rowset이 cold storage(S3)로 cooldown됨 | 로컬 compaction은 remote Rowset을 후보에서 뺀다([tablet.cpp#L1306](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/tablet.cpp#L1306)). 입력이 0번에서 시작하지 못해 base가 포기한다. cold data compaction(기본 1800초 주기)에 맡겨진다 |
| `disable_auto_compaction = true` 테이블 | compaction 자체가 돌지 않는다 |
| Unique MoW의 옛 행이 base 영역에, 새 행이 cumulative 영역에 있음 | base 입력에 새 행이 없으니 옛 행이 병합으로 없어지지 않는다. bitmap으로 가려진 채 남아 있다가 새 행이 승격된 뒤의 base에서 사라진다 |
| delete Rowset만 하나 새로 생기고 적재가 없음 | base 트리거(Rowset 5개 초과, 크기 비율 0.3 초과)를 못 채운다. base Rowset 생성 후 1일 조건으로 결국 돈다 |

이미 base로 넘어간 데이터에 나중에 DELETE가 와도 문제없다. delete Rowset은 항상 그 데이터보다 큰 버전을 받고, 조건은 "자기보다 옛 버전 Rowset 전부"에 걸리기 때문이다. 지울 행이 base Rowset, 중간 Rowset 여기저기에 섞여 있어도 각 Rowset을 읽을 때 같은 조건이 붙는다. base compaction도 같은 reader를 쓴다. 그래서 입력이 `[0-20] [21: delete] [22-30]`처럼 delete 뒤 버전까지 섞여 있어도, 조건은 `[0-20]`에만 걸리고 `[22-30]`의 같은 키 행은 살아남는다. 그 결과 output `[0-30]`에는 predicate가 남을 필요가 없다.

어느 경우든 쿼리 결과는 맞다. delete predicate나 bitmap이 읽을 때 가려 주기 때문이다. 남는 건 디스크 공간과 매 쿼리의 필터 비용이다.

**모델별로 compaction이 실제로 지우는 것**

| 모델 | cumulative | base |
|---|---|---|
| Duplicate | 키 순서로 이어 붙이기만 한다. 지우는 것 없음 | delete predicate에 걸리는 행을 버린다 |
| Aggregate / Unique MoR | 같은 키를 합친다(집계, 최신 값). delete sign 행은 **남긴다** | delete predicate 적용 + delete sign 행 제거 |
| Unique MoW | MoR과 같이 키 순서로 병합해 같은 키를 합친다. delete sign 행은 남긴다 | delete predicate 적용 + delete sign 행 제거 |

- cumulative에서 delete sign 행을 남기는 이유: base 영역에 같은 키의 옛 행이 아직 있다. 지금 sign 행을 버리면 다음 읽기나 base compaction 때 그 옛 행이 다시 살아난다. 코드 주석: *"If delete sign is applied on cumu compaction, it will lose effect when doing base compaction"*. delete sign 제거는 base/full compaction에서만 하고, `enable_prune_delete_sign_when_base_compaction`(기본 `true`)으로 켜져 있다([tablet_reader.cpp#L462-L476](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/tablet/tablet_reader.cpp#L462-L476)).
- compaction은 키를 PK 인덱스로 다시 찾지 않는다. 쿼리와 달리 compaction reader는 MoW에서도 MoR과 같은 키 순서 병합 경로(`_unique_key_next_block`)를 탄다. MoW가 병합 없는 `_direct_next_block`을 쓰는 건 `READER_QUERY`일 때뿐이다([block_reader.cpp#L612-L620](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/iterator/block_reader.cpp#L612-L620)). 입력 Rowset들 안에서 같은 키는 병합하면서 하나로 합쳐진다.
- 그러면 bitmap은 어떻게 되나. 입력 범위 **밖**의 더 새로운 적재가 입력 Rowset의 행을 덮어썼다면, 그 옛 행은 병합에서 살아남아 output에 들어간다. 그런데 output에서는 row id가 새로 매겨지므로 옛 표시가 엉뚱한 행을 가리키게 된다. 그래서 `RowIdConversion`으로 옛 (rowset, segment, row) → 새 위치 대응표를 만들고, input의 bitmap 표시를 output의 새 row id로 옮긴다. 주석: *"New loads are not blocked, so some keys of input rowsets might be deleted during the time"*([compaction.cpp#L1917-L1945](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/compaction.cpp#L1917-L1945)). compaction이 도는 동안 커밋된 적재도 같은 방식으로 옮긴다([#L2041-L2052](https://github.com/apache/doris/blob/eb7a508d5e29bef12d616ea1084d1367b9e16354/be/src/storage/compaction/compaction.cpp#L2041-L2052)).

정리하면 메타데이터 삭제는 싸고 즉시 끝나고, 행 단위 삭제는 compaction이 돌 때까지 비용이 남는다. 오래된 데이터를 지우는 게 목적이면 `DELETE`보다 파티션 drop이나 truncate가 낫다.

---
참고

- [Doris Compaction principles](https://doris.apache.org/docs/4.x/admin-manual/trouble-shooting/compaction-principles/)
- [Doris Compaction (2.1)](https://doris.apache.org/docs/2.1/admin-manual/trouble-shooting/compaction/)
- [Doris – Vector integration](https://doris.apache.org/docs/dev/connection-integration/data-integration/vector/)
- [Vector Doris sink](https://vector.dev/docs/reference/configuration/sinks/doris/)

LSM 트리는 로그파일 기반으로 작성되는 방식의 파일 구조이다. LSM 트리는 Append-only 방법이어서 쓰기작업의 효울성이 좋다.

<img src="https://github.com/user-attachments/assets/78524848-9757-49ca-a543-7f7f4a53b5a3" style="height: 300px"/>

## 작동 방식

### 쓰기 작업

LSM 트리는 데이터를 disk에 바로 쓰지 않고, 정렬된 메모리 테이블(memTable)과 로그파일에 먼저 쓴다.

메모리 테이블은 주로 레드-블랙 트리를 사용하여 키-값 쌍을 기반으로 정렬된 구조를 유지한다.

Memtable이 설정된 임계값에 도달하면, 그 내용은 디스크에 파일로 저장됩니다. 이때 데이터는 정렬된 상태로 저장되기 떄문에, 이 파일을 SSTable(Sorted String Table)이라고 부른다.

- SSTable은 불변성을 지니며, 한 번 기록된 후에는 변경되지 않는다. 이 구조는 데이터 일관성을 보장하며 압축이 진행되는 중에도 쓰기 연산을 지속할 수 있도록 한다.

- SSTable은 장애 발생 시 복구를 위한 기반 데이터로도 사용된다.
  
SSTables는 Append-only이기 때문에 쓰기가 효율적이고, 블록 내의 블록과 키를 찾기 위해 이진 검색과 인덱스 파일 읽기가 효율적이다. 또한 키를 개별적으로 저장하는 대신, 모든 개별 레코드가 아닌 데이터의 일부에 대해서만 인덱스 항목을 유지하는 선택적 또는 희소 인덱스를 유지함으로써 속도를 높인다.

### SSTable 압축

SSTable의 크기가 임계치를 넘어서면, 해당 테이블을 두고 새 SSTable을 생성하여 저장한다.

그리고 조건이 충족되면 백그라운드에서 압축 과정을 수행한다. 압축 알고리즘은 보통 크기 계층 압축과 레벨 기반 압축으로 나뉜다.

- 크기 계층 압축(Size-Tiered Compaction): 이 방식은 SS-Table의 크기를 기준으로 병합한다. 2048 게임과 비슷한 느낌이다.

    <img src="https://github.com/user-attachments/assets/a52243cc-41eb-40c4-a8d2-0fa094cfaab9" style="height: 300px"/>

  - 큰 단위로 압축이 이루어지기 때문에 쓰기 증폭(Write Amplification)을 최소화하는데 도움이 되지만, 큰 SS-Table을 병합할 때 많은 시간과 자원이 필요하다.
  - 또한, 쓰기 작업이 자주 일어나지 않는 경우 병합 대상이 없어 압축이 이루어지지 않고 SS-Table의 수만 증가하게 되어 읽기 성능이 저하될 수 있다.

- 레벨 기반 압축(Level-Based Compaction): 이 방식은 SS-Table을 레벨에 따라 분류하고, 레벨별로 병합을 수행한다. 레벨 별 크기가 2제곱수로 증가하면 크기 계층 압축과 동일해진다.

  - 주로 작은 단위로 압축이 자주 이루어지기 때문에 쓰기 증폭(Write throughput)이 커질 수 있지만, 크기 계층 압축에 비해 읽기 성능은 향상될 수 있다.

### 읽기 작업

읽기 작업시에는 memtable -> SSTable 하위~상위 순서로 접근하여 데이터를 가져온다. SStable이 많을 때, 제일 처음 쌓인 데이터를 읽어야한다면 시간이 오래 걸릴 수 있다.

따라서 특정 키가 데이터 세트에 존재할 가능성이 있는지 빠르게 확인할 수 있게 해주는 Bloom filter를 사용해 불필요한 레벨 검색을 줄인다. Bloom filter는 확률적 자료구조로, false positive(실제로는 없지만 있다고 판단)는 가능하지만 false negative(실제로는 있지만 없다고 판단)는 불가능하다.
  
### 삭제 작업

LSM 트리의 삭제 작업은 marking만 해놓는다. 실제론 Compaction 작업에서 데이터가 지워진다.

## 예시

LSM Tree를 사용하는 다양한 DB들이 있다.

- [Apache Cassandra](https://github.com/apache/cassandra)
- [Apache HBase](https://github.com/apache/hbase)
- [LevelDB](https://github.com/google/leveldb)
- [RocksDB](https://github.com/facebook/rocksdb)
- [ScyllaDB](https://github.com/scylladb/scylladb)
- [BadgerDB](https://github.com/dgraph-io/badger)
- [CockroachDB](https://github.com/cockroachdb/cockroach)

---
참고

- <https://www.scylladb.com/glossary/log-structured-merge-tree>
- <https://www.slideshare.net/tomitakazutaka/cassandra-compaction>
- <https://cassandra.apache.org/doc/stable/cassandra/operating/compaction/index.html>
- <https://www.cs.umb.edu/~poneil/lsmtree.pdf>
- <https://github.com/facebook/rocksdb/wiki/Compaction>
- <https://hbase.apache.org/book.html#compaction>
- <https://medium.com/rate-labs/%EB%85%BC%EB%AC%B8-%EB%A6%AC%EB%B7%B0-from-wisckey-to-bourbon-a-learned-index-for-log-structured-merge-trees-c63abd3d061e>


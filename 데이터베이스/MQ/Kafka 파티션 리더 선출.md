- Kafka는 분산 시스템이다. 파티션마다 리더가 있고, 리더만 읽기/쓰기를 처리한다.
- Kafka에서 각 파티션은 여러 브로커에 복제된다. 복제본(replica) 중 하나가 리더, 나머지는 팔로워다.
- 프로듀서와 컨슈머는 리더하고만 통신한다.

## 컨트롤러

컨트롤러라는 특별한 브로커 하나는 다음 역할들을 담당한다:

- 파티션 리더 선출
- 브로커 장애 감지
- 파티션 재할당 조율

컨트롤러 자체도 선출된다. 여러 브로커가 동시에 컨트롤러가 되려고 경쟁하고, 하나만 성공한다.

ZooKeeper 모드에서는 `/controller` znode를 먼저 생성한 브로커가 컨트롤러가 된다. ephemeral node라서 해당 브로커가 죽으면 자동으로 삭제되고, 다른 브로커가 다시 경쟁한다.

KRaft 모드에서는 Raft 합의 알고리즘으로 컨트롤러 쿼럼 중 리더를 선출한다. ZooKeeper 의존성이 없어서 운영이 단순해진다.

## ISR (In-Sync Replicas)

리더 선출을 이해할 때 ISR 개념이 중요하게 쓰인다. ISR은 "리더와 동기화된 복제본 집합"이다. 팔로워가 리더의 데이터를 제때 복제하고 있으면 ISR에 포함된다. 뒤처지면 ISR에서 빠진다.

```
Partition 0:
  Replicas: [1, 2, 3]     ← 전체 복제본 (브로커 ID)
  ISR:      [1, 2]        ← 동기화된 복제본만
  Leader:   1
```

위 상황에서 broker 3은 복제가 뒤처져서 ISR에서 제외된 상태다.

ISR 판단 기준은 `replica.lag.time.max.ms`다. 이 시간 내에 리더에게 fetch 요청을 보내지 않으면 ISR에서 제외된다. 기본값은 30초.

왜 ISR이 중요할까? 리더가 죽으면 ISR 안에서만 새 리더를 뽑기 때문이다. ISR에 없는 복제본은 데이터가 뒤처져 있으니, 리더가 되면 최신 데이터를 잃을 수 있다.

## 리더 선출 과정

### 클러스터 시작 시

클러스터가 처음 시작되면:

1. 브로커들이 올라온다
2. 컨트롤러가 선출된다
3. 컨트롤러가 각 파티션의 replica 목록을 확인한다
4. replica 목록의 첫 번째 브로커를 리더로 지정한다 (preferred replica)
5. LeaderAndIsr 요청을 통해 모든 브로커에게 알린다

```
# 파티션 생성 시 replica 할당 예시
Partition 0: replicas=[1,2,3] → Leader=1 (preferred)
Partition 1: replicas=[2,3,1] → Leader=2 (preferred)
Partition 2: replicas=[3,1,2] → Leader=3 (preferred)
```

라운드 로빈으로 리더가 분산되도록 replica 목록 순서를 다르게 배치한다.

### 리더 브로커 장애 시

리더가 죽으면 어떻게 될까? 실제 과정을 따라가보자.

```
상황: Broker 1(Leader)이 죽음
Partition 0:
  Replicas: [1, 2, 3]
  ISR:      [1, 2]
  Leader:   1 (dead)
```

1. 장애 감지: 컨트롤러가 broker 1의 장애를 감지한다
   - ZooKeeper 모드: `/brokers/ids/1` znode 삭제 감지
   - KRaft 모드: heartbeat timeout

2. 영향받는 파티션 식별: broker 1이 리더인 모든 파티션을 찾는다

3. 새 리더 선출: ISR에서 살아있는 첫 번째 브로커를 선택한다

   ```
   ISR: [1, 2] → 1은 죽음 → 2가 새 리더
   ```

4. 메타데이터 업데이트: 새로운 리더 정보를 저장한다

   ```
   Partition 0:
     ISR:    [2]       ← 1 제거됨
     Leader: 2         ← 새 리더
   ```

5. 브로커들에게 전파: LeaderAndIsr 요청으로 모든 브로커에게 알린다

6. 클라이언트 갱신: 프로듀서/컨슈머가 메타데이터를 갱신하고 새 리더로 연결한다

전체 과정은 보통 수백 밀리초에서 수 초 내에 완료된다.

## Unclean Leader Election

만약 ISR에 살아있는 복제본이 하나도 없다면?

```
Partition 0:
  Replicas: [1, 2, 3]
  ISR:      [1]        ← 리더만 ISR에 있었음
  Leader:   1 (dead)
```

broker 1이 죽었는데 ISR에 1밖에 없었다. broker 2, 3은 있지만 데이터가 뒤처져 있다.

두 가지 선택지가 있다:

1. 파티션을 사용 불가 상태로 두기 (`unclean.leader.election.enable=false`, 기본값)

- ISR에 있던 브로커가 복구될 때까지 기다린다
- 데이터 유실 없음
- 가용성 희생

2. ISR 밖에서 리더 선출 (`unclean.leader.election.enable=true`)

- broker 2나 3이 리더가 된다
- 서비스 계속 가능
- 복제되지 않은 메시지 유실

어떤 것을 선택할지는 상황에 따라 다르다. 금융 데이터처럼 손실이 치명적이면 false. 로그처럼 일부 유실이 괜찮으면 true.

## Preferred Replica Election

시간이 지나면 리더 분포가 불균형해질 수 있다. 장애 복구 후 원래 리더가 돌아와도 자동으로 리더가 되지 않기 때문이다.

```
# 장애 전
Partition 0: Leader=1
Partition 1: Leader=2
Partition 2: Leader=3

# Broker 1 장애 후 복구
Partition 0: Leader=2  ← 1이 원래 리더였는데 2가 유지됨
Partition 1: Leader=2
Partition 2: Leader=3

# Broker 2에 리더가 몰림
```

이를 해결하는 것이 preferred replica election이다.

`auto.leader.rebalance.enable=true`로 설정하면 컨트롤러가 주기적으로 확인해서, preferred replica(replica 목록의 첫 번째)가 리더가 아닌 파티션의 리더를 재조정한다.

수동으로도 할 수 있다:

```bash
kafka-leader-election.sh --bootstrap-server localhost:9092 \
	--election-type PREFERRED \
	--all-topic-partitions
```

## KRaft

Kafka 3.3부터 ZooKeeper 없이 KRaft 모드로 운영 가능하다. 리더 선출 원리는 동일하지만 구현이 다르다.

- 단일 컨트롤러 대신 여러 컨트롤러가 쿼럼을 이룬다. Raft 프로토콜로 합의한다.

- 메타데이터를 저장할 때 ZooKeeper 대신 내부 토픽 `__cluster_metadata`에 저장한다. 컨트롤러들이 이 토픽을 복제한다.

- 장애 감지시 ZooKeeper session 대신 브로커 간 직접 heartbeat를 사용한다. `broker.heartbeat.interval.ms`와 `broker.session.timeout.ms`로 제어한다.

선출 로직 자체는 동일하다. ISR에서 새 리더를 뽑고, LeaderAndIsr로 전파한다.

---
참고

- <https://kafka.apache.org/documentation/#replication>
- <https://developer.confluent.io/courses/architecture/broker-replication/>
- <https://kafka.apache.org/documentation/#kraft>

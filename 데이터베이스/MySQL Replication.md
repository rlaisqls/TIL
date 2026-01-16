
데이터베이스에서 데이터를 복제하는 방식은 크게 동기 방식과 비동기 방식이 있다.

- 동기 방식: Master 노드에 데이터 변경이 발생할 경우 Slave 노드까지 (동시에) 적용되는 것을 보장한다.
  - 따라서 Master 노드에 장애가 발생하더라도 (데이터 정합성 문제 없이) Slave 노드를 이용하여 서비스를 이어갈 수 있다.
- 비동기 방식: Master 노드의 변경과 Slave 노드로의 적용이 시차를 두고 동기화됨
  -  Master 노드에서 변경된 데이터가 아직 Slave에 반영되지 못했을 가능성이 있다. 곧 바로 Slave 노드를 이용하여 서비스를 이어갈 경우 데이터 정합성에 문제가 발생할 수 있다.

이러한 두 가지 방식은 성능과 데이터 정합성(정확성)이라는 두 가지 요소 중 어느 것을 중요하게 취급할 것인지에 따라 선택하여 사용하게 된다. 동기와 비동기 방식의 장점을 적절히 취하여 [Semi-Sync](https://hoing.io/archives/3633) 방식을 사용하는 경우도 있다.
(MySQL 도 Semi-Sync Replication 을 Plug-in 방식으로 사용할 수 있다.)

이렇게 동기/비동기의 관점 뿐 아니라 Replication을 구현하는 방식은 아주 다양할 수 있다.

같은 동기 방식이라도 모든 변경 데이터마다 Slave의 적용에 대한 응답을 수신하는 방식이 있을 수 있고, 또는 트랜잭션 도중 발생되는 변경에 대해서는 비동기로 작동하다가 Commit 단계에서만 Slave의 응답을 수신하도록 할 수도 있다.

비동기 방식의 경우에도 파일의 로그를 별도의 스레드(프로세스)가 읽어서 Slave 로 전송하는 방식이 있을 수 있고, 트랜잭션을 수행하는 스레드가 직접 Slave 로 변경 사항을 전송하도록 구현될 수도 있을 것이다.

## MySQL Replication 동작 원리

MySQL의 Replication은 기본적으로 비동기 복제 방식을 사용하고 있다.

Master 노드에서 변경되는 데이터에 대한 이력을 로그(Binary Log)에 기록하면, Replication Master Thread가 (비동기적으로) 이를 읽어서 Slave 쪽으로 전송하는 방식이다.

MySQL에서 Replication을 위해 반드시 필요한 요소는 다음과 같다.

- Master에서의 변경을 기록하기 위한 Binary Log
- Binary Log를 읽어서 Slave 쪽으로 데이터를 전송하기 위한 Master Thread
- Slave에서 데이터를 수신하여 Relay Log에 기록하기 위한 I/O Thread
- Relay Log를 읽어서 해당 데이터를 Slave에 Apply(적용)하기 위한 SQL Thread

위의 구성 요소들은 아래 그림에서 보는 Flow 대로 데이터 복제를 수행한다.

<img width="701" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/55e87870-70ab-43d2-99a2-5afb6dfb40f1">

1. 클라이언트(Application)에서 Commit을 수행한다.
2. Connection Thead는 스토리지 엔진에게 해당 트랜잭션에 대한 Prepare(Commit 준비)를 수행한다.
3. Commit 을 수행하기 전에 먼저 Binary Log 에 변경사항을 기록한다.
4. 스토리지 엔진에게 트랜잭션 Commit 을 수행한다.
5. Master Thread는 시간에 구애받지 않고(비동기적으로) Binary Log 를 읽어서 Slave 로 전송한다.
6. Slave의 I/O Thread는 Master 로부터 수신한 변경 데이터를 Relay Log 에 기록한다. (기록하는 방식은 Master 의 Binary Log 와 동일하다)
7. Slave 의 SQL Thread는 Relay Log에 기록된 변경 데이터를 읽어서 스토리지 엔진에 적용한다.

데이터를 다른 노드로 복제해야 하는 상황에서 과연 SQL을 전송하여 Replay 하는 방식으로 복제할 것인가, 또는 변경되는 Row 데이터를 전송하여 복제할 것인가를 고민해볼 수 있다. 전자를 SBR(Statement Based Replication)이라고 하고, 후자를 RBR(Row Based Replication)이라고 한다. SBR은 로그의 크기가 작을 것이고, RBR은 데이터 정합성에 있어서 유리할 것이다. 사용자는 SQL의 성격이나 변경 대상 데이터 양에 따라 SBR 또는 RBR를 선택하여 사용할 수 있다.

SBR 과 RBR 을 자동으로 섞어서 사용할 수 있는 방식은 MBR(Mixed Based Replication)이라고 한다. 평상 시에는 SBR 로 동작하다가 [비결정성(Non-Deterministic) SQL](https://mariadb.com/kb/en/library/unsafe-statements-for-statement-based-replication/#unsafe-statements)을 만나면 자동으로 RBR 방식으로 전환하여 기록하는 방식이다. Binary Log 의 크기와 데이터의 정합성에 대한 장점을 모두 취한 방식이라고 보면 된다.

## Master Thread

- MySQL Replication에서는 Slave Thread가 Client이고 Master Thread가 Server 이다. 즉, **Slave Thread가 Master Thread 쪽으로 접속을 요청하기 때문에 Master에는 Slaver Thread가 로그인할 수 있는 계정과 권한(REPLICATION_SLAVE)이 필요하다.**

- Master 쪽으로 동시에 다수의 Slave Thread가 접속할 수 있으므로 Slave Thread 당 하나의 Master Thread가 대응되어 생성된다. Master Thread는 한가지 역할만을 수행하는데, **이는 Binary Log 를 읽어서 Slave 로 전송하는 것이다. 이 때문에 Binlog Sender 또는 Binlog Dump 라고도 불린다.**

- Master 입장에서 Slave의 접속은 여느 Client 의 접속과 다를 바가 없다. 따라서, 해당 접속이 Replication Slave Thread 로부터의 접속인지 일반 Application 의 접속인지 구분할 수 있는 방법이 없다. 로그인 과정도 일반 Client와 동일하게 처리되기 때문이다.

- Master가 특정 접속을 Slave Thread 로 인식하여 Binary Log 를 전송하려면, Slave 로부터의 특정 명령 Protocol을 통해 '난 다른 Client랑 다르게 Replication Slave 야' 와 같이 알려주어야 한다. Slave Thread는 Master에 접속 후 Binary Log 의 송신을 요청하는 명령어(Protocol)를 전송하는데 이는 `COM_BINLOG_DUMP` 와 `COM_BINLOG_DUMP_GTID` 이다. 전자는 Binary Log 파일명과 포지션에 의해, 후자는 GTID에 의해 Binary Log 의 포지션을 결정한다. (GTID 는 MySQL 5.6 에 추가된 기능)

- Slave는 위의 Protocol을 통한(실제 SQL 은 아님) 소통 이후에 COM_QUERY 라는 Protocol을 통해 실제 데이터(SQL) 송신을 요청하게 된다.

## Slave I/O Thread

- Slave I/O Thread는 Master로부터 연속적으로 수신한 데이터를 Relay Log 라는 로그 파일에 순차적으로 기록한다. Relay Log 파일의 Format 은 Master 측의 Binary Log Format 과 정확하게 일치한다. 인덱스 파일도 똑같이 존재하고 파일 명에 6 자리 숫자가 붙는 것도 동일하다.

- Relay Log 는 Replication 을 시작하면 자동으로 생성된다. Relay Log 의 내용을 확인하기 위해서는 SHOW RELAYLOG EVENTS 명령어를 사용한다.

- Relay Log 파일의 이름은 기본적으로 `'호스트명-relay-bin'` 이며, 이는 호스트 이름이 변경될 경우 오류가 발생할 수 있으므로 relay_log 옵션을 이용하여 사용자가 의도한대로 정하는 편이 좋다.

## Slave SQL Thead

- Slave SQL Thread는 Relay Log 에 기록된 변경 데이터 내용을 읽어서 스토리지 엔진을 통해 Slave 측에 Replay(재생)하는 Thread 이다. 아무래도 Relay Log 를 기록하는 I/O Thread 보다는 실제 DB 의 내용을 변경하는 SQL Thread가 처리량과 연산이 많게 마련이다.

- **이는 SQL Thread가 Replication 처리의 병목 지점이 될 수 있다는 것을 의미한다.**

- Master 측에서는 많은 수의 Thread가 변경을 발생시키고 있는데 반해, Slave 에서는 하나의 SQL Thread가 DB 반영 작업을 수행한다면 병목이 되는 것은 당연하다. 이의 해결을 위해 등장한 것이 MySQL 5.7 에서 대폭 개선된 MTS(Multi Thread Slave)이다. 이는 Slave 에서의 SQL Thread가 병렬로 데이터베이스 갱신을 수행할 수 있도록 개선된 기능이다. (해당 기능에 대한 자세한 내용은 향후 별도 주제로 다루도록 하겠다.)

## MySQL Replication 을 이용한 다양한 구성

- MySQL의 Replication이 사용하는 복제 방식을 이용하면 아주 다양한 방식으로 시스템을 구성할 수 있다. 아래 그림들은 실제로 사용 가능한 다양한 구성 예들을 모아본 것이다.
MySQL Replication 은 다음의 몇 가지 특징을 가지기 때문에 좀 더 다양한 방식으로 구성할 수 있다는 것을 알 수 있다.

  - Slave는 또 다른 MySQL 서버의 Master 가 될 수 있다.
  - 하나의 Master 가 가질 수 있는 Slave 는 다수일 수 있다. (다단 구성 가능)
  - 두 개의 MySQL 서버가 서로의 Master 또는 Slave 가 될 수 있다.
  - 하나의 Slave 가 Multi Master 를 가질 수 있다. (N:1 - MySQL 5.7 이상)

- 단, 아래의 구성 중 Dual Master의 경우 양쪽 서버에서 데이터 변경이 가능하고 서로 복제가 가능한 방식이지만, 어쨌건 비동기 방식의 복제이므로 데이터의 부정합이 발생할 가능성은 여전히 존재한다는 것을 주의하자. (Application 작성 시 이 부분에 대한 대응 방안이 필요하다.)

<img width="672" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/d74be1c6-267f-4ae1-948e-6a0b53ef58f9">

---
참고
- https://dev.mysql.com/doc/refman/5.7/en/replication.html
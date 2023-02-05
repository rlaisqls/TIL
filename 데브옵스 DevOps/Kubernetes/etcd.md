# etcd

etcd는 key:value 형태의 데이터를 저장하는 스토리지이다. Kubernetes는 기반 스토리지(backing storage)로 etcd를 사용하고 있고, 모든 데이터를 etcd에 보관한다. 클러스터에 어떤 노드가 몇 개나 있고 어떤 파드가 어떤 노드에서 동작하고 있는지 등의 정보가 etcd에 저장되는 것이다.

## RSM(Replicated state machine)

etcd는 분산 컴퓨팅 환경에서 서버가 몇 개 다운되더라도 정상적으로 동작하는 Replicated state machine(RSM)방식으로 구현되었다.

<img src="https://user-images.githubusercontent.com/81006587/216806152-99c672d1-32f4-4103-ade6-f20b5ce827e9.png" height=200px>

RSM은 위 그림과 같이 command가 들어있는 log 단위로 데이터를 처리한다. 데이터를  write하는 것을 `log append`라고 부르고, 머신은 받은 log를 순서대로 처리하는 특징을 갖는다.

또한, RSM은 똑같은 데이터를 여러 서버에 계속해서 복제하며 데이터를 유지한다. 그리고 데이터 복제 과정에 발생할 수 있는 여러 가지 문제를 해결하고, 데이터의 정합성이 지켜지도록 하기 위해 (Consensus를 확보하기 위해) Raft 알고리즘을 사용한다.

> Consensus를 확보한다는 것은 RSM이 아래 4가지 속성을 만족한다는 것과 같은 의미이다.

|속성|설명|
|-|-|
|Safety|항상 올바른 결과를 리턴해야 한다|
|Available|일부 서버가 다운되더라도 항상 응답해야 한다.|
|Independent from timing|네트워크 지연이 발생해도 로그의 일관성이 깨져서는 안된다.|
|Reactivity|모든 서버에 복제되지 않았더라도 조건을 만족하면 빠르게 요청에 응답해야 한다.|

---

Raft를 구현한 etcd의 동작애 대해 알아보자. 우선 이해를 위해 필요한 주요 용어들은 아래와 같다.

- Quorum
    - Quorum(쿼럼)이란 우리말로는 정족수라는 뜻을 가지며, 의사결정에 필요한 최소한의 서버 수를 의미한다. 예를 들어, RSM을 구성하는 서버의 숫자가 3대인 경우 쿼럼 값은 2(3/2+1)가 된다.
    - etcd는 하나의 write 요청을 받았을 때, 쿼럼 숫자만큼의 서버에 데이터 복제가 일어나면 작업이 완료된 것으로 간주하고 다음 작업을 받아들일 수 있는 상태가 된다.

- State
    - Etcd를 구성하는 서버는 State를 가지며 이는 Leader, Follower, Candidate 중 하나가 된다. 각 서버는 상태에 따라 다른 동작을 수행한다.

- Heartbeat
    - Etcd의 Leader 서버는 다른 모든 서버에게 heartbeat를 주기적으로 전송하여, Leader가 존재함을 알린다.
    - 만약 Leader가 아닌 서버들이 일정 시간(election timeout) 동안 heartbeat를 받지 못하게 되면 Leader가 없어졌다고 간주하고 다음 행동을 시작한다.

- term
    - heartbeat가 몇초동안 오지 않았는지를 새는 숫자이다.

## 리더 선출(Leader election)

<img src="https://user-images.githubusercontent.com/81006587/216811482-d8a7ab9a-fd41-4120-9061-bd7368cb1084.png" height=300px>

3개의 서버를 이용해서 etcd 클러스터를 최초 구성했을 때, 각 서버는 모두 `follower` 상태(state)이며, `term`이 0으로 설정된다. 현재 etcd 클러스터는 리더가 없는 상태이다.

이때,

1. term이 0이기 때문에 etcd 서버 중 한대에서 election timeout이 발생하게 된다.
2. timeout이 발생한 서버는 자신의 상태를 candidate로 변경하고 term 값을 1 증가시킨 다음에 클러스터에 존재하는 다른 서버에게 RequestVote RPC call을 보낸다.
3. RequestVote를 받은 각 서버는 자신이 가진 term 정보와 log를 비교해서 candidate보다 자신의 것이 크다면 거절하는데, 현재는 term이 모두 1이므로 RequestVote에 대해서 OK로 응답한다.

Candidate는 자기 자신을 포함하여 다른 서버로부터 받은 OK 응답의 숫자가 quorum과 같으면 leader가 된다. Leader가 된 서버는 클러스터의 다른 서버에게 `heartbeat`를 보내는데, 이 Append RPC call에는 leader의 term과 보유한 log index 정보가 들어있다.

Leader가 아닌 서버는 Append RPC call을 받았을 때 자신의 term보다 높은 term을 가진 서버의 call 인지 확인하고, 자신의 term을 받은 term 값으로 업데이트한다. 이로써 etcd 클러스터는 leader가 선출되었고, 외부로부터 유입되는 write와 read 요청을 받아들일 준비가 되었다.

## 로그 복제(Log replication)

클러스터가 구성되고 leader가 선출된 이후, 사용자로부터 write 요청을 받았다고 해보자.

각 follower 서버는 자신이 가지고 있는 log의 lastIndex 값을 가지고 있고, leader는 follower가 새로운 log를 써야 할 nextIndex까지 알고 있다.

사용자로부터 log append 요청을 받은 leader는 자신의 lastIndex 다음 위치에 로그를 기록하고 lastIndex 값을 증가시긴다. 그리고 다른 heartbeat interval이 오면 각 forllower 서버의 nextIndex에 해당하는 log를 RPC call로 보낸다. (AppendEntry RPC call)

<img src="https://user-images.githubusercontent.com/81006587/216811781-2d9de0fe-667d-45aa-b943-fd868fba0f82.png" height=300px>

첫 번째 follower(이하 F1) 자신의 entry(메모리)에 leader로부터 받은 log를 기록했고 두 번째 follower(이하 F2)는 아직 기록하지 못했다고 가정하자. 

F1은 log를 잘 받았다는 응답을 leader에게 보내주게 되고, leader는 F1의 nextIndex를 업데이트한다. F2가 아직 응답을 주지 않았거나 주지 못하더라도, leader 자신을 포함해서 쿼럼 숫자만큼의 log replication이 일어났기 때문에 commit을 수행한다.

Commit이란, log entry에 먼저 기록된 데이터를 서버마다 가지고 있는 db(파일시스템)에 write 하는 것을 의미한다. 이제부터 사용자가 etcd 클러스터에서 x를 read하면 1이 return 된다. Follower들은 leader가 특정 로그를 commit한 사실을 알게 되면, 각 서버의 entry에 보관 중이던 log를 commit 한다.

## 리더가 다운된 경우(Leader down)

사용자의 write 요청에 따라 쿼럼 숫자만큼 log의 복제와 commit이 완료된 이후, leader가 다운(down)된다면 etcd는 어떻게 동작할까? 로그 복제(Log replication) 상황 이후에 leader 서버의 etcd 프로세스가 알 수 없는 이유로 다운되었다고 가정해보자.

Follower들은 leader로부터 election timeout동안 heartbeat를 받지 못한다. 그 사이에 F1이나 F2중 하나가 타임아웃되면 다른 서버들에게 RequestVote RPC call을 보내 본인이 leader 자격이 있는지를 확인한다. (term 값이 다른 서버보다 크고 최신 로그를 가지고 있어야함)

F2는 위에서 잠시 다운되어서 최신 로그 데이터를 가지고 있지 않기 때문에, 리더가 되는 것에 실패하고, 이후 F1이 타임아웃되었을때 다시 검증 과정을 거친 뒤 새로운 leader가 된다. F1이 새로운 leader가 된 상태에서 write 요청을 받게 되더라도 쿼럼 숫자만큼의 etcd 서버가 running 중이므로 etcd 클러스터는 정상 동작한다.

> 이때, 새로운 leader를 뽑지 못하고 계속해서 election을 하게 된다면 사용자의 요청을 처리하지 못해 etcd 클러스터의 가용성이 떨어질 수 있다. Raft 알고리즘은 이런 상황을 대비해 randomize election timeout과 preVote라는 방법을 사용할 수 있다. Etcd에서는 preVote가 구현되어 있다. (https://github.com/etcd-io/etcd/pull/6624/files).

F1이 새로운 leader가 된 상태에서 구 leader가 복구되면, F1에게 heartbeat를 보내거나 F1으로부터 heartbeat를 받을 텐데, lastIndex 값이 더 작고 term도 낮으므로 자기 자신을 follower로 변경하고 term 숫자를 높은 쪽에 맞추게 된다.

## 런타임 재구성(Runtime reconfiguration)

Etcd의 기본인 리더 선출(leader election)과 로그 복제(log replication)에 대해 살펴보았다. 이번에는 etcd 클러스터가 동작 중인 가운데 etcd 서버(멤버)가 추가/삭제되는 런타임 재구성(Runtime reconfiguration) 상황도 살펴보자.

### 멤버 추가

Etcd에는 snapshot이라는 개념이 있는데, etcd 서버가 현재까지 받아들인 모든 log를 entry에서만 관리하는 것이 아니라 파일시스템에 백업해 놓는 것을 말한다. 얼마나 자주 snapshot을 생성할 것이냐는 etcd 클러스터를 생성하면서 옵션으로 지정할 수 있고, 디폴트 값은 100,000이다.

새로운 4번째 서버를 추가하는 요청이 수신되었다면 즉시 클러스터의 일부로 취급되고, Quorum이 다시 계산된다. leader는 추가된 멤버가 가능한 한 빨리 같은 log를 보유할 수 있도록 snapshot을 보내준다. 이 snapshot은 현재 파일시스템에 백업으로 보유하고 있는 snapshot 중 가장 최신의 것과 leader의 현재 log entry를 합쳐 생성한 새로운 snapshot이며, 새로운 서버는 snapshot을 이용해 db를 만듦으로써 leader가 보낼 Append RPC call을 문제없이 받아들일 수 있는 상태가 된다.

하지만 이떄 스냅샷의 크기가 너무 크다면 리더의 네트워크에 부하가 생겨 heart beat를 제때 전달하지 못할 수 있다. 그럼 기존에 있던 Flower들이 election timeout이 되어 재선거를 진행하고, 그동안 클러스터는 요청을 처리할 수 없는 상태가 된다.

이러한 문제를 해결하기 위해 etcd애는 leaner라는 별도의 상태가 또 존재한다. Learner는 etcd 클러스터의 멤버이지만 쿼럼 카운트에서는 제외하는 특별한 상태로 etcd 3.4.0부터 구현되었다. (https://etcd.io/docs/v3.3.12/learning/learner/)

Learner는 etcd의 promote API를 사용하여 일반적인 follower로 변경할 수 있다. Learner가 아직 log를 모두 따라잡지 못한 경우에는 거절된다.

<img src="https://user-images.githubusercontent.com/81006587/216813590-b7472bbb-cb6f-41ce-b036-3f5bf025dc70.png" height=200px>

### 멤버 삭제

Etcd 클러스터에서 특정 서버를 삭제하는 요청도 etcd 멤버 추가에서 다룬 것과 같이 log를 복제하는 방식으로 진행된다.

> 멤버 삭제 요청을 받았지만 그 멤버를 삭제했을때 started 상태인 서버의 수가 quorum보다 작아질 것으로 예상되는 경우엔 leader는 클라이언트의 멤버 삭제 요청을 거절한다. 하지만 다른 경우에는 write 진행중 노드를 삭제해도 quorum을 충족할 수 있기 때문에 그냥 삭제해버린다.

단, leader가 leader를 제거하라는 요청을 받았을 때는 특별하게 동작한다. 이 경우에는 leader가 새로운 config log를 commit 시키는 데 필요한 log replication 숫자를 셀 때 자기 자신을 제외한다. 자신을 제외한 쿼럼 숫자만큼의 log replication이 확인되면 leader 자신이 삭제된 설정 Cnew를 commit 하고 클라이언트에게 OK 응답을 보낸다.

Commit 이후에는 leader의 자리를 내려놓게 되고 더는 heartbeat를 보내지 않는다. 이것을 Raft와 etcd에서는 `step down`이라고 한다. 클러스터를 구성하는 나머지 서버 중 누군가 election timeout이 발생하면 candidate가 되어 RequestVote RPC call 전송을 통해 새로운 leader를 선출하고 다음 term을 계속해나간다.

Leader가 클라이언트의 멤버 삭제 요청을 처리할 때 자기 자신을 제외한 쿼럼 숫자만큼의 log replication을 수행했기 때문에, 새로운 leader의 선출 성공이 보장된다.

> 만약 아직 step down을 시작하지 않은 상태에서 write 요청을 받는다면, entry에 존재하는 가장 최신의 config에 자신이 없다 하더라도 여전히 leader 역할을 수행한다.

## etcd의 유지보수 방법

etcd가 메모리와 파일시스템을 어떻게 사용하는지, 그리고 예기치 못한 사고를 대비하는 백업 및 복구 방법에 대해 알아보자.

### 로그 리텐션(Log retention)

<img src="https://user-images.githubusercontent.com/81006587/216815208-af04f75d-751a-414d-a086-9beb4208b7a2.png" height=350px>

Etcd 프로세스는 기본적으로 log entry를 메모리에 보관한다. 하지만 모든 log entry를 별다른 조치 없이 계속하여 메모리에 보관하면 서버 스펙이 아무리 훌륭하더라도 언젠가는 반드시 OOM이 발생할 것이므로 주기적으로 log entry를 파일시스템에 저장(snapshot) 하고, memory를 비우는 작업(truncate)을 수행한다.

만약 truncate한 log를 사용해야 할 일이 발생하면(예를 들어, 특정 follower의 log catch 속도가 너무 느려서 leader의 메모리에 없는 log를 요구할 경우) leader는 최근의 snapshot 파일을 follower에게 전송한다(**etcd 멤버 추가** 참조).

<img src="https://user-images.githubusercontent.com/81006587/216815371-4928f831-132e-4e12-b806-05e357b91aed.png" height=300px>

위 그림은 etcd의 log retention을 쉽게 관찰할 수 있도록 snapshot-count를 1000으로 변경하고 write 테스트를 수행했을 때의 로그를 보여준다. 1000번의 write가 일어날 때마다 메모리를 확인한뒤 snapshot을 만들고 메모리에 lastIndex–5,000까지의 log만 메모리에 보관하고 나머지는 비운다. (5,000은 옵션을 통해 조정할 수 없는 값이다).

## 리비전 및 컴팩션(Revision and Compaction)

Etcd 프로세스에 의해 commit된 데이터는 db(파일시스템)에 보관된다. (**로그 복제(Log replication)** 참조). Etcd는 하나의 key에 대응되는 value를 하나만 저장하고 있는 것이 아니라 etcd 클러스터가 생성된 이후 **key의 모든 변경사항**을 파일시스템에 기록하는데, 이것을 `revision`이라고 한다.

<img src="https://user-images.githubusercontent.com/81006587/216815479-aa7411c0-f7b9-4b67-bd64-ba9b4f33506d.png" height=300px>

Etcd는 db에 데이터를 저장할 때 revision 값과 함께 저장한다. 위 그림을 살펴보면, x라는 key에 대해서 value를 달리해서 여러 번 write를 했을 때 하나의 공간에 계속하여 덮어쓰는 것이 아니라 history를 계속하여 저장하는 구조이다.

불필요한 revision의 과도한 리소스 사용을 피하고자 etcd는 `compaction`(압축) 기능을 제공한다. Compaction으로 삭제한 revision 데이터는 다시 조회가 불가능해진다.

> Compactor records latest revisions every 5-minute, until it reaches the first compaction period 
https://etcd.io/docs/v3.4/op-guide/maintenance/

공식 문서를 보면, 매 5분동안의 최신 revision만 남기고 삭제하는 것이 기본 설정이라는 것을 알 수 있다.

## 자동 컴팩션(Auto compaction)

Etcd는 운영자가 별도로 조치하지 않아도 일정 revision 또는 주기를 가지고 자동으로 revision을 정리하는 auto compaction을 지원한다. Auto compaction은 2가지 모드(revision, periodic)가 있으며 어떤 모드를 선택했느냐에 따라 auto-compaction-retention 옵션이 가지는 의미가 달라진다.

### Revision 모드
<img src="https://user-images.githubusercontent.com/81006587/216817159-e90f414b-ab4c-4deb-961f-eda41744a0b3.png" height=300px>

Auto-compaction-mode revision으로 지정하면 위에서 말했던 것처럼 5분마다 최신 revision – auto-compaction-retention까지만 db에 남기고 compaction한다. Auto-compaction-retention의 값이 1,000이고 5분마다 500 revision의 데이터가 생성된다고 가정하면 5분마다 500 revision이 계속하여 compaction된다.

### Periodic 모드

<img src="https://user-images.githubusercontent.com/81006587/216817237-70b225a7-f505-46d2-885d-0adafe9e3132.png" height=300px>
(https://etcd.io/docs/v3.4/op-guide/maintenance/#auto-compaction)

Auto-compaction-mode를 periodic으로 지정하는 경우 auto-compaction-retention에 주어진 값을 시간으로 인식한다. Auto-compaction-retention이 8h일 때 이를 10으로 나눈 값이 1h가 적기 때문에, 1h 단위로 compaction이 일어난다. 1시간마다 100 revision이 생성된다고 가정하면 1시간마다 가장 오래된 100 revision을 compaction한다.

## 단편화 제거(Defragmentation)

<img src="https://user-images.githubusercontent.com/81006587/216817421-ab41f8ac-6247-49d0-af52-e2090be6d38a.png" height=300px>

Compaction을 통해 etcd 데이터베이스에서 revision을 삭제했다고 해서, 파일시스템의 공간까지 확보되는 것은 아니다. Revision 삭제로 인해 발생한 fragmentation(단편화)을 정리해 주어야 디스크 공간이 확보된다. RDB에서 TRUNCATE를 하지 않고 DELETE를 하는 것만으로는 disk 공간이 확보되지 않는 것과 비슷하다. Defragmentation(단편화 제거) 작업을 해야지만 revision 삭제로 인해 etcd 데이터베이스에 발생한 fragmentation을 정리해 디스크 공간을 확보할 수 있다. Defragmentation는 compaction과 달리 자동(auto) 기능이 제공되지 않고 있다. Defragmentation 시 주의해야 할 점은, 진행되는 동안 모든 read/write가 block 된다는 것이다. 하지만 몇 ms 단위의 시간에 일어나는 일이라, kubernetes를 위한 etcd 클러스터가 defragmentation으로 인해 read/write 작업이 timeout될 가능성은 적다.

Etcd가 허용하는 db의 max size는 etcd_quota_backend_bytes라는 옵션으로 조절할 수 있으며, 디폴트 값은 2G이다. 만약 leader의 db 사이즈가 2G를 넘으면 “database space exceeded”라는 메시지와 함께 더 이상 write 요청을 받아들이지 않는 read-only 모드로 동작하게 된다. 따라서, etcd가 많은 key:value를 사용할 것으로 예상이 된다면 별도의 크론잡(CronJob)을 개발하여 defragmentation을 주기적으로 수행해 주거나, etcd_quota_backend_bytes 옵션을 넉넉하게 부여하여 (max 8G) etcd 클러스터의 가용성에 문제가 생기는 일이 없도록 해야 할 것이다.

## 백업 및 복구(Backup and Restore)

<img src="https://user-images.githubusercontent.com/81006587/216819552-36a15e47-5ea0-4acc-9ffc-6aa1bae547e3.png" height=300px>

Etcd는 예기치 못한 사고로 인해 etcd 데이터베이스가 유실되는 경우를 대비하기 위한 backup API를 제공한다. 여기서의 snapshot은 로그 리텐션(Log retention)에서 다루었던 snapshot과는 다른 것이다. Database backup snapshot은 etcd 프로세스가 commit한 log가 저장된 데이터베이스 파일의 백업이다. 바꿔 말하면, etcd의 backup은 etcd 데이터 파일경로(data dir)에 존재하는 db 파일을 백업하는 것입니다. compaction이 일어나거나 defragmentation된 적 없는 db에 대해서 백업하면, 불필요하게 많은 용량을 백업에 사용하게 될 수도 있다.

단순하게 etcd 데이터 파일 경로(data dir)에 존재하는 db 파일을 복제(copy)한 것과 etcd의 API를 이용한 백업 파일 간에는 차이가 있다. 위 그림과 같이 etcdctl snapshot save 명령으로 만들어진 db 파일은 무결성 해시(hash)를 포함하고 있어서 추후 etcdctl snapshot restore 명령으로 복구할 때 파일이 변조됐는지 체크가 가능하다. 만약 피치 못할 사정으로 단순 복사로 만들어진 백업 파일로부터 복구를 진행해야 한다면, –skip-hash-check 옵션을 추가하여 복구를 진행해야 한다.

<img src="https://user-images.githubusercontent.com/81006587/216819720-b52aa248-df81-40c3-b1f3-5688ecf59a5b.png" height=300px>

Backup 파일로부터 etcd를 복구하는 것은 두 단계로 나누어 진행할 수 있다. 먼저 db 파일을 호스트 OS의 특정 경로(dir)에 옮겨두고, 새로운 etcd를 시작시키면 된다. 단, etcd 서버와 클러스터가 새로운 메타데이터를 가지고 시작할 수 있게 정보를 주어야 하고, etcd 클러스터는 새로운 메타데이터로 db를 덮어쓰기(overwrite)하고 동작을 시작한다.

etcd의 메타데이터에는 etcd 클러스터를 식별하기 위한 uuid와 etcd 클러스터에 속한 멤버의 uuid가 저장되어 있다. 만약 이전 메타데이터를 유지한 채 백업 파일로부터 새로운 etcd 클러스터를 생성한다면, 망가진 줄 알았던 etcd 서버가 다시 살아나게 될 때 구성이 꼬여 오동작할 가능성이 크다.

---

참고

- https://etcd.io/docs/
- https://tech.kakao.com/2021/12/20/kubernetes-etcd/
- https://github.com/ongardie/dissertation
- https://raft.github.io/raft.pdf
# Datadog이 동작하는 방법

## 1. Datedog Agent가 하는 일 (Application에서 서버로)

 Datedog 사용은 아래와 같은 흐름으로 진행된다.

> ☝🏻  **Datadog 사용 흐름 3단계**<br>1. 서버에 Datadog agent를 설치한다. (api키 입력)<br>2. agent가 서버나 애플리케이션의 정보를 수집하여  Datedog 서버로 보낸다.<br>3. 유저가 웹에서 대시보드를 확인한다.

Datadog Agent가 어떤 일을 하는지, Agent는 어떤 구조로 구성되어있는지 알아보자.

### Datadog agent

- 서버에 설치된 *agent는* 해당 서버의 시스템 정보를 수집하여 Datadog 서버로 전송한다.
- 추가적인 설정을 통해 DB, 메모리 스토어 등에서 추가적인 메트릭을 수집할 수 있다. (APM)

<img width="699" alt="image" src="https://user-images.githubusercontent.com/81006587/234476696-1f8a3f7c-e06a-45e6-b3b0-95729761237a.png">


## SNMP

**SNMP**(**Simple Network Management Protocol**)는 네트워크에서 관리되는 장치에 대한 정보를 수집하고 구성하고 해당 정보를 수정하여 장치 동작을 변경하기 위한 프로토콜이다.

다시말해, **각 호스트로부터 여러 관리 정보를 수집하여 관리하는 프로토콜**이다. (모니터링)

SNMP는 Datadog의 Agent와 아주 연관이 큰 개념이다.

<img width="703" alt="image" src="https://user-images.githubusercontent.com/81006587/234476748-7e96e8e5-85cf-44ba-8a12-19dd57d586d1.png">

### Datadog과  SNMP

<img width="536" alt="image" src="https://user-images.githubusercontent.com/81006587/234476827-6cf55976-6192-4b51-b150-0f3ba1c580a1.png">


SNMP의 개념에 Datadog 구조를 대입해보면 위와 같다. 하위 Agent는 구동하는 Application, Master Agent는 Datadog Agent, Trap은  DogStatsD, Manager는 Datadsg Sass에 대응하는 것을 볼 수 있다. 

Datadog의 상세 구조에 맞추어 자세히 나타내자면 아래와 같다.

<img width="614" alt="image" src="https://user-images.githubusercontent.com/81006587/234476853-6260d1a3-a3e3-492e-b0b7-f7b5bf060bff.png">

---

## 2. 서버, 유저 사이의 데이터 파이프라인

[https://www.infoq.com/presentations/datadog-metrics-db/#downloadPdf/](https://www.infoq.com/presentations/datadog-metrics-db/#downloadPdf/)

<img width="515" alt="image" src="https://user-images.githubusercontent.com/81006587/234476881-f1e3cb60-4d33-4e42-8682-d7227f4670ec.png">

| 이름 | 설명 | 방향 |
| --- | --- | --- |
| Metrics Sources  | 유저의 서버에서 DataStores로 보내야하는 메트릭 소스 | 유저→서버 |
| Slack/Email/PagerDuty etc | Slack, Email 등으로 받는 경고 또는 보고 알림 | 서버→유저 |
| Customer Browser | 유저가 브라우저를 접속했을때 보는 정보 | 서버→유저 |

> Metric Sources가 DB로 Intake 될때는, 데이터를 수집할때마다 전송하는 것이 아니라 **1~2분 단위로 묶여**서 전송된다. 이 시간을 늘려 최적화하는 것도 가능하다.

> Datadog 데이터는 **아주 많은 캐시 서버**를 가지고있다.

<img width="702" alt="image" src="https://user-images.githubusercontent.com/81006587/234476949-d4966676-96dc-48ff-aef4-07ad35c4409c.png">


## 3. 데이터를 저장하는 방법

앞서 Metrics Source는 세가지 유형으로 처리된다고 얘기했다. (DB, Tag 처리후 DB, S3에 저장)

이때 Datadog에서 데이터를 S3, DB로 나눠 저장하는 이유는 저장 용량과 조회 속도 때문이다.

Datadog에서는 **아주 많은 서버 정보와 로그 데이터**가 저장되어 매일 한 유저당 약 10TB정도의 용량이 필요하다. 이 많은 양의 데이터를 저장하기 위해선 일반적인 DB보다 조금 느리더라도 대용량 데이터를 견딜 수 있는 저장소가 필요했는데, 이를 위해 쓰이는 것이 S3이다.

하지만 S3는 인덱싱을 통한 빠른 조회가 힘들기 때문에 일부 정보는 빠른 스토리지 저장소(DRAM, SSD)에 NoSQL을 사용하여 저장하는 방식을 택한다.

**저장소별 장단점**

<img width="332" alt="image" src="https://user-images.githubusercontent.com/81006587/234476993-30348479-9634-4ec4-8938-614d4f85b9c6.png">

| 종류 | 특징|
| --- | --- |
| DRAM | 비싸지만 빠르고 처리량이 높다. |
| SSD | 덜 비싸지만 덜 빠르다. (DRAM과 S3의 중간) |
| S3 | 약간 느리지만 장기적으로 대용량의 데이터를 저장할 수 있다. |

### Hybrid Data Storage

Datadog의 저장 데이터 유형은 크게 5가지가 있고, 그에 따라 적합한 용도의 저장소에 저장된다.

유형별 선택한 저장소와 DB목록은 다음과 같다.

<img width="531" alt="image" src="https://user-images.githubusercontent.com/81006587/234477115-e6615e87-28d7-49e5-8ad5-24dde0f1b1bb.png">

> 연, 월, 일별로 유지할 데이터를 구분하여서 다른 저장소에 저장함

> [Level DB](https://github.com/google/leveldb)(Indexed Database), Redis, [RocksDB](http://rocksdb.org), [SQLite](https://www.sqlite.org/index.html), [Cassandra](https://cassandra.apache.org/_/index.html), [Parquet](https://parquet.apache.org/)와 같은  NoSQL DB를 많이 사용함 (주로 Open source기반)

## 4. Datadog의 동기화 처리

서비스의 상태, 또는 경고에 대한 데이터를 전송하는 서비스에서는 동기화가 매우 중요하다. 많은 저장 시스템 중 하나가 몇 밀리초 동안 먹통이 된다면, 서버의 이벤트와 경고를 놓칠 수 있다. 

Datadog에서 이벤트를 놓치는 것은 큰 문제를 야기할 수 있다.

메트릭 데이터베이스의 좋은 점은 동기화가 우리에게 중요하지만 전통적인 동기화 메커니즘으로 할 필요는 없다는 것이다. Datadog의 파이프라인 아키텍처는 마치 심장박동과 같은 방식으로 동기화를 체크한다.

<img width="553" alt="image" src="https://user-images.githubusercontent.com/81006587/234477175-23760fce-89c5-4f53-a026-4a2f03c32527.png">

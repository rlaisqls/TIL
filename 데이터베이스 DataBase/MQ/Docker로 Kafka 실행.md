
kafka는 보통 zookeeper라는 모듈과 함꼐 실행된다. 최근엔 의존성을 분리해나가고 있다고는 하지만, 우선은 zookeeper와 함께 구성해보자.

(그래야 레퍼런스가 많기 때문이다.)

kafka와 zookeeper 이미지를 각각 올려야 하니까 docker compose를 활용해서 올려준다. 테스트용이므로 zookeeper와 kafka는 각 하나의 클러스터를 지니도록 할 것이다.

```yml
version: '2'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_SERVER_ID: 1
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
      ZOOKEEPER_INIT_LIMIT: 5
      ZOOKEEPER_SYNC_LIMIT: 2
    ports:
      - "22181:2181"

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    ports:
      - "29092:29092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
```

### zookeeper

- ZOOKEEPER_SERVER_ID
    - zookeeper 클러스터에서 유일하게 주키퍼를 식별할 아이디를 지정한다. (다중 클러스터 설정)

- ZOOKEEPER_CLIENT_PORT
    - 컨테이너 내부에서zookeeper와 kafka가 통신할 port_client_port (defailt 2181)

- ZOOKEEPER_TICK_TIME
    - zookeeper 동기화를 위한 기본 틱 타임

- ZOOKEEPER_INIT_LIMIT:
    - 주키퍼 초기화를 위한 제한 시간
    - 주키퍼 클러스터는 쿼럼이라는 과정을 통해서 마스터를 선출하게 된다. 이때 주키퍼들이 리더에게 커넥션을 맺을때 지정할 초기 타임아웃 시간이다.
    - 타임아웃 시간은 이전에 지정한 ZOOKEEPER_TICK_TIME 단위로 설정된다. (다중 클러스터 설정)

- ZOOKEEPER_SYNC_LIMIT:
    - 주키퍼 리더와 나머지 서버들의 최대 싱크횟수
    - 이 횟수내에 싱크응답이 들어오는 경우 클러스터가 정상으로 구성되어 있는 것으로 인식된다.

### kafka

- depends_on
    - kafka는 zookeeper에 의존하고 있어서, zookeeper가 먼저 올라와 있어야 잘 작동하기 때문에 depends_on 설정을 해준다.

- KAFKA_BROKER_ID
    - kafka 브로커 아이디를 지정한다. (다중 클러스터 설정)

- KAFKA_ZOOKEEPER_CONNECT
    - kafka가 zookeeper에 커넥션하기 위한 대상을 지정한다.
    - 여기서는 zookeeper(서비스이름):2181(컨테이너내부포트) 로 대상을 지정했다.

- KAFKA_ADVERTISED_LISTENERS 
    - 외부에서 접속하기 위한 리스너 설정을 한다.

- KAFKA_LISTENER_SECURITY_PROTOCOL_MAP
    - 보안을 위한 프로토콜 매핑이디.
    - KAFKA_ADVERTISED_LISTENERS 과 함께 key/value로 매핑된다.

- KAFKA_INTER_BROKER_LISTENER_NAME
    - 도커 내부에서 사용할 리스너 이름을 지정한다.
    - 이전에 매핑된 PLAINTEXT가 사용되었다.

- KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS
    - 카프카 그룹이 초기 리밸런싱할때 컨슈머들이 컨슈머 그룹에 조인할때 대기 시간이다.

## 명령어

작성한 명령어로 컨테이너를 올린다.

```js
docker-compose up
```

토픽을 생성한다.

```js
kafka-topics --create --topic test --bootstrap-server localhost:29092
```

생성된 토픽의 정보를 확인한다.

```js
 kafka-topics --describe --topic test --bootstrap-server localhost:29092
```

producer로 생성한 토픽에 메세지를 보낸다. `first`와 `second`라는 text를 적어주었다.

```js
kafka-console-producer --topic test --bootstrap-server localhost:29092
>first
>second
```

만든 서버의 "test" topic에 대한 consumer에 접속하면 두 메세지가 성공적으로 전달된 것을 볼 수 있다.

```js
kafka-console-consumer --topic test --from-beginning --bootstrap-server localhost:29092 
```

```
first
second
```
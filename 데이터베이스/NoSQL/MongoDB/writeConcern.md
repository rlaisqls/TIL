
- writeConcern은 MongoDB에서 쓰기 작업이 몇 개의 노드에 복제되어야 성공으로 간주할지를 결정하는 설정들이다.
- writeConcern이 높으면 쓰기 지연(latency)이 증가하는 대신, write를 마칠 때 데이터가 안전하게 보관됨을 더 강하게 보장할 수 있다.
- w, wtimeout, r 세 필드를 설정할 수 있다.

### w (Write Acknowledgment)

쓰기 작업이 몇 개의 노드에 반영되어야 확인(acknowledgment)을 받을지 지정하는 옵션이다.

레플리카 셋의 노드 수보다 높은 w 값을 설정하면 쓰기가 실패한다.

- **w: 0** - 쓰기 확인을 기다리지 않는다.
  - 가장 빠른 성능을 제공한다.
  - 네트워크 오류나 서버 장애 시 데이터 손실 가능성이 매우 높다.
  - 로그나 임시 데이터처럼 손실이 허용되는 경우에만 사용해야 한다.

  ```javascript
  db.logs.insertOne(
    { timestamp: new Date(), message: "system event" },
    { writeConcern: { w: 0 } }
  )
  ```

- **w: 1** - 프라이머리 노드에만 쓰기가 완료되면 확인한다.
  - MongoDB의 기본값이다.
  - 프라이머리 노드 장애 시 데이터가 손실될 수 있다.
  - 적당한 성능과 안정성을 제공한다.

  ```javascript
  db.users.insertOne(
    { name: "Alice", email: "alice@example.com" },
    { writeConcern: { w: 1 } }
  )
  ```

- **w: "majority"** - 레플리카 셋의 과반수 노드에 쓰기가 완료되면 확인한다.
  - 데이터 내구성을 보장하는 권장 설정이다.
  - 단일 노드 장애에도 데이터가 보존된다.
  - 프로덕션 환경에서 가장 많이 사용된다.

  ```javascript
  db.orders.insertOne(
    { orderId: "ORD-001", amount: 10000, status: "pending" },
    { writeConcern: { w: "majority" } }
  )
  ```

- **w: \<number\>** - 지정된 수의 노드에 쓰기가 완료되면 확인한다.
  - 특정 개수의 복제본이 필요한 경우 사용한다.
  - 레플리카 셋의 노드 수보다 큰 값을 지정하면 타임아웃이 발생한다.

  ```javascript
  db.transactions.insertOne(
    { txId: "TX-001", amount: 50000 },
    { writeConcern: { w: 3 } }
  )
  ```

### wtimeout

쓰기 확인을 기다리는 최대 시간을 밀리초 단위로 지정하는 옵션이다.

- 지정된 시간 내에 쓰기가 완료되지 않으면 에러를 반환한다.
- 기본값은 무제한 대기이다.
- 네트워크 지연이나 노드 장애로 인한 무한 대기를 방지한다.

```javascript
db.events.insertOne(
  { eventId: "EVT-001", type: "user_action" },
  {
    writeConcern: {
      w: "majority",
      wtimeout: 5000  // 5초 타임아웃
    }
  }
)
```

타임아웃이 발생해도 쓰기 작업 자체는 계속 진행된다. 하지만 클라이언트는 확인을 받지 못한다.

### j (Journal)

쓰기 작업이 디스크의 저널(journal)에 기록될 때까지 대기할지를 결정하는 옵션이다.

- **j: true** - 저널에 기록된 후 확인한다.
  - 서버가 갑자기 종료되어도 데이터 손실을 방지한다.
  - 디스크 I/O가 추가되어 성능이 저하될 수 있다.
  - 금융 거래나 중요한 데이터에 사용해야 한다.

  ```javascript
  db.payments.insertOne(
    { paymentId: "PAY-001", amount: 100000, currency: "KRW" },
    { writeConcern: { w: "majority", j: true } }
  )
  ```

- **j: false** - 메모리에만 기록되면 확인한다.
  - MongoDB의 기본값이다.
  - 서버 장애 시 마지막 몇 초간의 데이터가 손실될 수 있다.

---

참고

- <https://www.mongodb.com/docs/manual/reference/write-concern/>
- <https://www.mongodb.com/docs/manual/core/replica-set-write-concern/>

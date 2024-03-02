
Event를 사용할 때 기본적으로 사용하는 `@EventListener`는 **event를 publishing 하는 코드 시점에 바로 publishing*한다. 하지만 우리가 퍼블리싱하는 event는 대부분 메인 작업이 아닌 서브의 작업이 많고 비동기로 진행해도 되는 경우도 많다. 다른 도메인 로직인 경우도 있다. 이럴 경우 조금 애매해지기도 한다.

아래 예를 보자. 아래코드는 `@Transactional`로 메서드가 하나의 트랜잭션으로 묶여있다. 이 메서드를 실행했을때, 1번과 2번이 정상적으로 마무리되고 3번이 발생하는 도중에 예외처리가 발생하면 어떻게 될까?

3번이 실패했으면 같은 트랜잭션으로 묶여있는 1번도 함께 롤백될 것이다. 하지만 2번은 발행된 이벤트를 listen하는 별도의 구현체가 이후의 동작을 수행하기 때문에, rollback이 이루어지지 않고 결과적으로 불일치가 발생할 수 밖에 없게 된다.

```java
@Transactional
public void function() {

    aaaRepository.save() // 1. A 저장

    applicationEventPublisher.publishEvent(); // 2. A에 의한 이벤트 발생

    bbbRepository.save() // 3. B 저장

}
```

이러한 문제를 해결하기 위해서 @TransactionEventListener가 나온 것이다. @TransactionEventListener는 Event의 실질적인 발생을 트랜잭션의 종료를 기준으로 삼는것이다.

## @TransactionalEventListener 옵션

@TransactionalEventListener를 이용하면 트랜잭션의 어떤 타이밍에 이벤트를 발생시킬 지 정할 수 있다. 옵션을 사용하는 방법은 TransactionPhase을 이용하는 것이며. 아래와 같은 옵션을 사용할 수 있다.

- AFTER_COMMIT (기본값) : 트랜잭션이 성공적으로 마무리(commit)됬을 때 이벤트 실행
- AFTER_ROLLBACK : 트랜잭션이 rollback 됐을 때 이벤트 실행
- AFTER_COMPLETION : 트랜잭션이 마무리 됬을 때(commit or rollback) 이벤트 실행
- BEFORE_COMMIT : 트랜잭션의 커밋 전에 이벤트 실행

---

참고

- https://www.baeldung.com/transaction-configuration-with-jpa-and-spring
- https://stackoverflow.com/questions/51097916/transactionaleventlistener-doesnt-works-where-as-eventlistener-works-like-cha
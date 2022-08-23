# 🤔 QuerydslPredicateExecutor

QuerydslPredicateExecutor는 스프링 데이터에서 제공하는 Querydsl 기능이다. <a href="https://docs.spring.io/spring-data/commons/docs/current/reference/html/#core.extensions.querydsl">(공식 문서)</a>

```java
public interface QuerydslPredicateExecutor<T> {

    Optional<T> findById(Predicate predicate);

    Iterable<T> findAll(Predicate predicate); 

    long count(Predicate predicate);

    boolean exists(Predicate predicate);

    // … more functionality omitted.
}
```

Where절의 조건에 해당하는 내용(Predicate)을 파라미터로 받아 해당 조건에 따른 결과를 반환하는 인터페이스이다.

```java
@Test
void querydslPredicateExecute() {
    QMember member = QMember.member;
    Iterable<Member> result = memberRepository.findAll(member.age.between(10, 40).and(member.username.eq("member1")));
    for (Member m : result) System.out.println("m = " + m);
}
```

이 코드를 실행하면 아래와 같은 쿼리가 나간다.

```sql
select
     member1 
from
    Member member1 
where
    member1.age between ?1 and ?2 
    and member1.username = ?3
```

Predicate의 구현체인 BooleanExpression을 사용하면 and나 or 조건을 걸 수 있다.

하지만 QuerydslPredicateExecutor는 아래와 같은 한계점이 있다.

1. join이 불가능하다.(묵시적 조인만 가능하다.)
2. 클라이언트가 Querydsl에 의존해야 한다. 서비스 클래스가 Querydsl이라는 구현 기술에 의존해야 한다.
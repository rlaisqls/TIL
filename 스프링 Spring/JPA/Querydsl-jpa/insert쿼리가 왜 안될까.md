# 🤔 insert쿼리가 왜 안될까

JPA에서 일시적인 상태에서 관리되는 상태로 가는 모든 엔티티는 EntityManager 에 의해 자동으로 처리된다. EntityManager 는 주어진 엔터티가 이미 존재하는지 확인한 다음, 삽입을 할지 또는 업데이트해야 할지를 결정한다.

이러한 자동 관리로 인해 JPA 스펙에서 지원하는 명령문은 SELECT, UPDATE, DELETE 이렇게 총 세개밖에 없다. (단, 하이버네이트 구현체는 insert into select를 지원한다고 한다.)

Querydsl 문법도 JPA에 기반을 두고 있기 때문에 insert문이 작동되지 않는다.

참고:
https://www.baeldung.com/jpa-insert
https://www.inflearn.com/questions/34751
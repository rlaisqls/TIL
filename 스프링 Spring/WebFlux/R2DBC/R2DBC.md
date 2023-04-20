# ⚡️ R2DBC

R2DBC는 Reactive Relational Database Connectivity의 줄임말이다. R2DBC는 관계형 데이터베이스 접근을 위해 구현해야 할 리액티브 API를 선언하는 스펙이다.

JDBC는 완전한 블로킹 API이었고, RDBMS는 NoSQL에 비해 자체 리액티브 클라이언트를 가지고 있는 경우가 적어서 비동기 통신을 하기 힘들었다.

반면에 R2DBC는 Non-Blocking 관계형 데이터베이스 드라이버와 잘 동작하도록 하는 것을 목적으로 만들어졌다. 쿼리를 소켓에 기록하고 스레드는 응답이 수신될 때까지 다른 작업을 계속 처리하여 리소스 오버헤드를 줄이는 방식으로 적은 스레드, 하드웨어 리소스로 동시 처리를 제어할 수 있도록 한다.

하지만, R2DBC는 개념적으로 쉬운 것을 목표로 하므로, 기존에 JDBC나 JPA에서 쉽게 사용했던 여러 기능을 제공하지 않는다고 한다. Spring Data의 Overview를 보면 다음과 같은 문구가 있다.

> Spring Data R2DBC aims at being conceptually easy. In order to achieve this, it does NOT offer caching, lazy loading, write-behind, or many other features of ORM frameworks. This makes Spring Data R2DBC a simple, limited, opinionated object mapper.

## 장점

- reactive한 비동기 처리로, 성능을 높일 수 있다.
- Spring에서 R2DBC를 위한 Spring Data R2DBC를 공식적으로 지원해준다.

## 단점

- 기술측면에서 숙련도가 높지 않다. JPA만큼 커뮤니티가 크지 않다.
- Type safe한 쿼리를 작성할 방법이 많이 없다. (jdsl 등 여러 라이브러리들이 만들어지고는 있다.)
- Hibernate/Spring data jpa는 정말 잘 만들어져있으며 제공하는 기능도 많다. 반면 spring data r2dbc는 부가 기능이 많이 없고, 관련 라이브러리나 데이터가 부족한 편이다.

관련 글 : [R2DBC 사용](R2DBC%E2%80%85%EC%82%AC%EC%9A%A9.md)

---

참고

- https://spring.io/projects/spring-data-r2dbc
- https://docs.spring.io/spring-data/r2dbc/docs/current/reference/html/
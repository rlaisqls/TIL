# DB 커넥션 풀

일반적인 데이터 연동과정은 웹 어플리케이션이 필요할 때마다 데이터베이스에 연결하여 작업하는 방식이다. 하지만 이런 식으로 필요할 때마다 연동해서 작업할 경우 데이터베이스 연결에 시간이 많이 걸리는 문제가 발생한다.

예를들어 거래소의 경우, 동시에 몇천명이 동시에 거래 및 조회 기능을 사용하는데 매번 데이터베이스와 커넥션을 맺고 푸는 작업을 한다면 굉장히 비효율적일 것이다.

이 문제를 해결하기 위해 현재는 웹 어플리케이션이 실행됨과 동시에 연동할 데이터베이스와의 연결을 미리 설정해 두고, 필요할 때마다 미리 연결해 놓은 상태를 이용해 빠르게 데이터베이스와 연동하여 작업하는 방식을 사용한다.

이렇게 미리 데이터베이스와 연결시킨 상태를 유지하는 기술을 커넥션 풀(Connection Pool, CP)이라고 한다.

## 커넥션 풀 사이즈 설정

이론적으로 필요한 최소한의 커넥션 풀 사이즈를 알아보면 다음과 같다.

> PoolSize = Tn × ( Cm -1 ) + 1 <br><br> Tn : 전체 Thread 갯수 <br> Cm : 하나의 Task에서 동시에 필요한 Connection 수

위와 같은 식으로 설정을 한다면 데드락을 피할 수는 있겠지만 여유 커넥션풀이 하나 뿐이라 성능상 좋지 못하다.

따라서 커넥션풀의 여유를 주기위해 아래와 같은 식을 사용하는것을 권장한다.

> PoolSize = Tn × ( Cm - 1 ) + ( Tn / 2 ) <br><br> thread count : 16 <br> simultaneous connection count : 2 <br> pool size : 16 * ( 2 – 1 ) + (16 / 2) = 24

## Spring에서의 커넥션 풀

자바에서는 기본적으로 DataSource 인터페이스를 사용하여 커넥션풀을 관리한다.

Spring에서는 사용자가 직접 커넥션을 관리할 필요없이 자동화된 기법들을 제공하는데 SpringBoot 2.0 이전에는 tomcat-jdbc를 사용하다, 2.0 이후 부터는 **HikariCP**를 기본옵션으로 채택하고있다.

## Hikari CP

![image](https://user-images.githubusercontent.com/81006587/230904793-ca2415c1-8dc6-425e-9fab-5e8975c7e591.png)

[HikariCP 벤치마킹 페이지](https://github.com/brettwooldridge/HikariCP-benchmark)를 보면 다른 커넥션풀 관리 프레임워크보다 성능이 월등히 좋음을 알 수 있다. HikariCP가 빠른 성능을 보여주는 이유는 커넥션풀의 관리 방법에 있다.

히카리는 Connection 객체를 한번 Wrappring한 `PoolEntry`로 Connection을 관리하며, 이를 관리하는 `ConcurrentBag`이라는 구조체를 사용하고 있다.

`ConcurrentBag`은 `HikariPool.getConnection() -> ConcurrentBag.borrow()`라는 메서드를 통해 사용 가능한(idle) Connection을 리턴하도록 되어있다.

이 과정에서 커넥션생성을 요청한 스레드의 정보를 저장해두고 다음에 접근시 저장된 정보를 이용해 빠르게 반환을 해준다.

## Spring 설정

스프링에서는 yml 파일로 hikari CP의 설정 값을 조정해줄 수 있다.

```yml
spring:
 datasource:
   url: jdbc:mysql://localhost:3306/world?serverTimeZone=UTC&CharacterEncoding=UTF-8
   username: root
   password: your_password
   hikari:
     maximum-pool-size: 10
     connection-timeout: 5000
     connection-init-sql: SELECT 1
     validation-timeout: 2000
     minimum-idle: 10
     idle-timeout: 600000
     max-lifetime: 1800000

server:
 port: 8000
```

각 설정의 의미는 아래와 같다.

options
- maximum-pool-size: 최대 pool size (defailt 10)
- connection-timeout: (말 그대로)
- connection-init-sql: SELECT 1
- validation-timeout: 2000
- minimum-idle: 연결 풀에서 HikariCP가 유지 관리하는 최소 유휴 연결 수
- idle-timeout: 연결을위한 최대 유휴 시간
- max-lifetime: 닫힌 후 pool 에있는 connection의 최대 수명(ms).
- auto-commit: auto commit 여부 (default true)
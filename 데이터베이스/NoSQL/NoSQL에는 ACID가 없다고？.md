
관계형 데이터베이스는 <a href="https://github.com/rlaisqls/TIL/blob/main/%EB%8D%B0%EC%9D%B4%ED%84%B0%EB%B2%A0%EC%9D%B4%EC%8A%A4%E2%80%85DataBase/DB%EC%84%A4%EA%B3%84/%ED%8A%B8%EB%9E%9C%EC%9E%AD%EC%85%98%E2%80%82ACID%EC%99%80%E2%80%82%EA%B2%A9%EB%A6%AC%EC%88%98%EC%A4%80.md">트랜잭션 ACID 원칙</a>을 철저히 지켜서 데이터의 무결성을 지키려 한다. 

<img src="https://user-images.githubusercontent.com/81006587/206946271-bfc2d2d2-642a-4df2-aac0-15cad814cc0b.png" height=400px>

관계형 데이터베이스는 위의 ACID 원칙을 지키기 위해 위와 같은 절차를 진행하게된다. 각 비율은 수행 작업의 비중을 의미한다.

그래프를 보면 정보유지를 위한 자원을 정말 많이 사용한다는것을 알 수 있다 실질적으로 데이터를 넣고 빼고 하는 부분은 오직 12프로인 Useful Work 만 사용하면되는데 말이다.

따라서 RDBMS가 아닌 NoSQL은, 이러한 전통적인 ACID 원칙을 철저하게 지키지 않는 대신 다른 방법을 통해 속도를 향상시키고 데이터 안전성을 챙긴다.

# BASE 속성

이러한 NoSQL의 특성과 원칙을 나타내는 BASE원칙이라는 것이 있다. Basically Available, Soft state, Eventually Consistence의 약자로, 가용성과 성능을 중시하는 분산 시스템의 NoSQL 특성을 얘기한다.

자세한 설명은 다음과 같다.

|속성|특성|세부 설명|
|-|-|-|
|Basically<br>Available|가용성|– 데이터는 항상 접근 가능하다.<br>– 다수 스토리지에 복사본 저장|
|Soft-state|독립성|– 즉각적인 일관성이 없기 때문에 데이터 값은 시간이 지남에 따라 변경될 수 있다.|
|Eventually<br>Consistency|일관성|– 데이터의 일관성이 깨지더라도, 일정 시간 경과 시 데이터의 일관성 복구|
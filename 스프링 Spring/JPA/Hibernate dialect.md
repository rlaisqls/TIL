
- 하이버네이트가 데이터베이스와 통신을 하기 위해 사용하는 언어를 Dialect라고 한다.
- 모든 데이터베이스에는 각자의 고유한 SQL언어가 있는데, 관계형 데이터베이스끼리 형태나 문법이 어느정도 비슷하긴 하지만, 완전히 똑같지는 않다.
    - 예를 들어 Oracle 쿼리 구문과 MySQL 쿼리구문은 다르다.
- 하지만, 하이버네이트는 한 데이터베이스관리시스템(DBMS)에 국한되지않고, 다양한 DBMS에 사용 가능하다.
    - 즉 내부적으로 각자 다른 방법으로 처리하고 있는 것이다.
    - 그렇기 때문에특정 벤더(DBMS)에 종속적이지 않고, 얼마든지 대체가능하다.
- JPA에서는 아래와 같이 Dialect라는 추상화된 언어 클래스를 제공하고 각 벤더에 맞는 구현체를 제공하고 있다.

![image](https://user-images.githubusercontent.com/81006587/209959785-be3c3467-c9bb-4bb2-ba94-c4a2005cd86d.png)

```yml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/test
    username: username
    password: password
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    database-platform: org.hibernate.dialect.MySQL5InnoDBDialect # 여기
```

yml 파일에서 설정하는 저 코드가 dialect를 설정하는 부분이다.
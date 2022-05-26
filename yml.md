mysql
```
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/blog?serverTimezone=Asia/Seoul
    username: root
    password: 
  jpa:
    hibernate:
      ddl-auto: update
      naming:
        physical-strategy: org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
      use-new-id-generator-mappings: false
    show-sql: false
    format_sql: true

implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
runtimeOnly 'mysql:mysql-connector-java'
//implementation 'org.mariadb.jdbc:mariadb-java-client:2.4.0'
//runtimeOnly 'org.mariadb.jdbc:mariadb-java-client'
```


H2
```
spring:
  datasource:
    url: jdbc:h2:tcp://localhost/~/
    username: sa
    password:
      driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: update
      naming:
        physical-strategy: org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
      use-new-id-generator-mappings: false
    show-sql: false
    format_sql: true
    database-platform: org.hibernate.dialect.PostgreSQLDialect
```

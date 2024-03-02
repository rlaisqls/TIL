
## Spring 6.0에서 달라지는 점

- Java 17기반으로 변경
- 일부 Java EE API 지원 종료 (javax등)
- XML이 점차적으로 Spring에서는 사라지게 될 것
- RPC 지원 종료
- 새로운 <a href="./AOT.md">AOT</a> 엔진 도입
- @Inject 같은 JSR에서 지원하던 어노테이션들이 jakarta.annotation 패키지의 어노테이션으로 변경
- HttpMethod가 enum에서 class로 변경
- Jakarta EE 9+로의 마이그레이션으로 인한 변경
    - Hibernate ORM 5.6.x 버전부터 hibernate-core-jakarta 사용
    - javax.persistence에서 jakarta.persistence로 변경
    - Tomcat 10, Jetty 11, Undertow 2.2.14 (undertow-servlet-jakarta도 포함)으로 업그레이드 필요
    - javax.servlet에서 jakarta.servlet으로 변경 필요 (import)

- Commons FileUpload, Tiles, FreeMarker JSP support 같은 서블릿 기반 기능이 지원 종료됨
    - multipart file 업로드 혹은 FreeMarker template view는 StandardServletMultipartResolver 사용을 권장
    - 이외에는 Rest 기반 웹 아키텍처 사용

- Spring MVC와 Spring WebFlux에서 더 이상 type 레벨에서의 @RequestMapping을 자동 탐색하지 않음
    - interface의 경우에는 @RequestMapping을 붙여도 더 이상 탐색되지 않음
    - 따라서 Class에 붙이거나 interface에도 사용하고 싶으면 @Controller도 붙여야 함
    - spring-cloud-openfeign에서도 이것 때문에 interface레벨 @RequestMapping 지원 종료(Git Issue)

- URL에서 마지막으로 나오는 / 매칭해주는 trailing slash matching configuration 기본적으로 지원하지 않음 (옵션 추가 시 사용 가능)


## Spring Boot 2.x -> 3.0 달라지는 점
- 최소 요구사항 변경 (M4 기준)
    - Gradle 7.5
    - Groovy 4.0
    - Jakarta EE 9
    - Java 17
    - Kotlin 1.6
    - Hibernate 6.1
    - Spring Framework 6 사용
  
- AOT maven, gradle 플러그인 제공
- native 지원 기능 확대
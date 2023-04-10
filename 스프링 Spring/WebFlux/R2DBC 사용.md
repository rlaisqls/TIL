# R2DBC 사용

R2DBC를 사용하기 위해서는 의존성을 먼저 추가해주어야 한다. 데이터베이스에 맞는 R2DBC driver와 그 구현체의 의존성을 추가해주자.

```kotlin
implementation("org.springframework.boot:spring-boot-starter-webflux")
implementation("org.springframework.boot:spring-boot-starter-data-r2dbc")
implementation("com.github.jasync-sql:jasync-r2dbc-mysql:2.0.8")
```

그리고 yml 설정을 해준다.

```yml
spring:
  r2dbc:
    url: r2dbc:pool:mysql://localhost:3306/test
    username: user
    password: user
```

## Configurations

R2DBC에서 중요한 인터페이스를 간략하게 살펴보고 넘어가자.

Spring의 특징인 auto configuration을 통해 자동으로 등록되는 bean이기도 하다.

### io.r2dbc.spi.ConnectionFactory

데이터베이스 드라이버와 Connection을 생성하는 인터페이스이다.

드라이버 구현체에서 이를 구현해서 사용하게 된다. Jasync-sql을 사용하면 JasyncConnectionFactory 클래스가 구현체로 사용된다. 

### org.springframework.r2dbc.core.DatabaseClient

ConnectionFactory 를 사용하는 non-blocking, reactive client이다. 아래와 같이 사용할 수 있다.

```java
DatabaseClient client = DatabaseClient.create(factory);
Mono<Actor> actor = client.sql("select first_name, last_name from t_actor")
    .map(row -> new Actor(row.get("first_name", String.class),
         row.get("last_name", String.class)))
    .first();
```

## Relational Mapping 지원

또한, R2dbc에서는 Annotation을 통한(JPA style의) Relational mapping을 지원하지 않는다 [(관련 이슈)](https://github.com/spring-projects/spring-data-r2dbc/issues/356)

그러므로 Lazy loading, Method name을 통한 Join 등이 불가능하다. 아래는 Spring data r2dbc의 공식 페이지 설명과 이슈 내용이다.

> Spring Data R2DBC aims at being conceptually easy. In order to achieve this, it does NOT offer caching, lazy loading, write-behind, or many other features of ORM frameworks. This makes Spring Data R2DBC a simple, limited, opinionated object mapper.

> The reason we cannot provide the functionality yet is that object mapping is a synchronous process as we directly read from the response stream. Issuing sub-queries isn’t possible at that stage.<br><br>Other object mapping libraries work in a way, that they collect results and then issue queries for relation population. That correlates basically with collectList() and we’re back to all disadvantages of blocking database access including that auch an approach limits memory-wise consumption of large result sets.<br><br>Joins can help for the first level of nesting but cannot solve deeper nesting. We would require a graph-based approach to properly address relationships.
    
그러므로 Join이 필요한 상황이라면 직접 Query를 작성해야만 한다고 한다.

## Repository 정의하기

Spring Data 프로젝트는 리액티브 패러다임을 지원하는 `ReactiveCrudRepository`(R2dbcRepository)를 제공하므로 `ReactiveCrudRepository` 인터페이스를 상속하는 인터페이스를 만들어 주면 쉽게 Spring Data R2DBC를 사용할 수 있다. 

> `ReactiveSortingRepository` 또한 존재한다. 하지만 Paging은 지원하지 않는다.

```kotlin
interface PostRepository : ReactiveCrudRepository
interface PostRepository : ReactiveSortingRepository
```

## Service

이를 이용해 Service logic을 구현하면 다음과 같다. 코드 상으로만 본다면 JPA를 사용할 때와 거의 유사한 흐름대로 작성되며, Input/Ouput만 Reactive type으로 이루어진다. (내부 동작은 당연히 다르다.)

```kotlin
@Service
class PostService(
    private val postRepository: PostRepository
) {

    fun getAll(): Flux<PostResponse> {
        return postRepository.findAll()
                       .map(PostResponse::from)
    }

    fun getOne(Long postId): Mono<PostResponse> {
        return postRepository.findById(postId)
                       .map(PostResponse::from)
    }

    fun save(SavePostRequest request): Mono<Void> {
        return postRepository.save(request.toEntity())
                       .then()
    }

}
```

---

참고

- https://www.sipios.com/blog-tech/handle-the-new-r2dbc-specification-in-java
- https://docs.spring.io/spring-data/r2dbc/docs/current/reference/html/
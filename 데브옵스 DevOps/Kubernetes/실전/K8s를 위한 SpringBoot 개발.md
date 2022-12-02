# ⚓ K8s를 위한 SpringBoot 개발

참고: https://velog.io/@airoasis/Kubernetes-를-위한-Spring-Boot-개발-feat.-무중단-배포운영

## Dockerize

Spring Boot Application을 dockerize 하는 방법은 대표적으로 Jib, Buildpacks, Dockerfile 세가지가 있다. 이 중 Jib는 build time이 빠르고 (효율적인 layering), image 사이즈가 가장 작아진다는 장점을 가지고있다. Jib의 사용법은 간단하다. 아래와 같이 `build.gradle`에 <a href="https://github.com/GoogleContainerTools/jib/tree/master/jib-gradle-plugin">jib gradle plugin</a>을 추가하면 된다.

```groovy
plugins {
  id 'com.google.cloud.tools.jib' version '3.2.0'
}
```

그리고 `./gradlew jib`을 통해 image를 빌드 할 수 있다.

로컬 kubernetes 개발 환경에서 <a href="https://skaffold.dev/">skaffold</a> 를 사용한다면 아래와 같이 `jib: {}`만 추가하면 알아서 로컬 kubernetes에 빌드/배포해준다.

```yml
apiVersion: skaffold/v2beta27
kind: Config
build:
  local:
    push: false
  artifacts:
    - image: example/image-name
      context: ./example-app
      jib: {}
```

아래는 Github Actions를 사용하여 이미지를 build 하고 AWS ECR에 image를 push 하는 코드의 일부이다

```yml
- name: Set up JDK 11
  uses: actions/setup-java@v1
  with:
    java-version: 11
- name: Grant execute permission for gradlew
  run: chmod +x gradlew
- name: Build and Push with Gradle
  id: build-and-push-to-ecr
  run: ./gradlew jib -x test --image $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
```

> Java 11 이상 사용을 권장한다. Java 8 은 containerize 된 환경에 최적화되지 않아 JVM이 효율적으로 운영되지 못한다.

## Health Check APIs

Kubernetes 의 readiness, liveness 설정을 위해 SpringBoot application 의 health check API 가 필요하다. SpringBoot Actuator 에서 이 기능을 제공한다. 아래와 같이 `build.gradle` 에 dependency로 추가만 하면 된다.

```groovy
dependencies {
  implementation 'org.springframework.boot:spring-boot-starter-actuator'
}
```

> Spring Boot 2 부터는 Actuator의 /health 와 /info 를 제외한 모든 endpoint가 disable 되어 있다. 만약 다른 endpoint 도 사용하고 싶다면 application.properties 에 추가적인 설정이 필요하다. 그렇지 않다면 그냥 dependenty 만 추가하고 그 외 추가적인 설정이나 개발은 필요없다.

kubernetes 의 readiness 설정을 하지 않으면 rolling update 시 또는 autoscale을 통해 <u>새로 pod가 생길때 SpringBoot application이 완전히 뜨기 전에 request가 들어가고 이렇게 들어온 request는 ingress가 `503`을 리턴</u>하게 된다. 또한 liveness 설정이 없으면 예기치못한 상황으로 SpringBoot application이 죽었을 때 서비스가 **새로 시작하지 않고 계속 죽어있게 된다.**

## Graceful shutdown

운영환경에서 Pod가 termination 되는 상황은 rolling update로 배포를 하거나 Kubernetes autoscale을 통해 늘어난 Pod가 줄어들 때 등이 있을 수 있다. 이때 Kubernetes는 SIGTERM 시그널을 보내고 Pod안의 SpringBoot Application은 종료가 된다. 하지만 SpringBoot의 default 설정은 시그널을 받자마자 종료되도록 되어 있고, 만약 종료될 때 들어온 request가 완료되기 전에 SpringBoot Application이 내려가면 해당 request를 보낸 쪽에서는 HTTP STATUS `503`을 받게 된다.

> 실제 운영환경(또는 load testing)에서 이 문제는 application log 에서는 확인하지 못하고 kubernetes ingress 에서 503 확인이 가능하다.

이를 graceful하게 처리하기 위해서는 graceful shutsown 설정을 해야한다. 이것 또한 간단하다. `application.yml` 파일에 아래와 같이 추가하면 된다. (단, Spring Boot 2.3 부터 가능한 option이다.)

```yml
server:
  shutdown: graceful
```

해당 설정이 추가되면 tomcat이 종료 시그널을 받았을때 처리중인 request가 있다면 이를 모두 처리하고 application이 종료된다. 하지만 들어온 request가 종료될 때까지 무한정 기다리는 것은 아니다. default설정은 30초간 기다리고 그때까지 종료하지 못한다면 강제종료된다. (일반적인 경우는 default 설정이면 충분하다.)

이 설정은 아해와 같이 변경 가능하다.

```yml
spring:
  lifecycle:
    timeout-per-shutdown-phase: 1m
```

## Loading HikariCP

SpringBoot 2부터는 **Hikari가 default DataSouce 구현체**이다. `spring-boot-starter-data-jpa`나 `spring-boot-starter-jdbc`를 사용한다면 별도의 설정없이 Hikari를 사용하게 된다. Hikari는 Connection Pool (HikariCP)을 사용하여 DB connection을 관리하는데 Spring Boot application이 설정/개발에 따라 Hikari connection pool을 Spring Boot 이 시작할 때 바로 만들지 않고, DB 관련 request가 처음 들어와서 처리 할 때 그제서야 Hikari를 initialize 하면서 connection pool을 생성하기도 한다. (경험으로는 Hibernate를 사용하면 application 이 올라갈때 바로 connection pool을 생성하고 MyBatis는 그렇지 않았다)

사실 이러한 과정은 일반적인 상황에서는 문제가 되지 않는다. 하지만 요청이 폭발하는 상황에서 kubernetes가 autoscale을 통해 새로운 pod를 생성하고 이렇게 생성된 pod가 바로 많은 요청을 받는 상황에서는 몇초간 latency가 매우 높아진다.

우선 현재 Spring Boot application이 언제 connection pool을 생성하는지 확인하려면 `application.properties` 에 아래와 같이 설정을 추가하여 hikari log를 남기고, application을 실행해 보자. (테스트 후 반드시 해당 설정을 제거하자. 특히 운영환경에서는...)

```yml
logging:
  level:
    com:
      zaxxer:
        hikari: DEBUG
```

만약 application이 시작하면서 Hikari 설정 관련 log가 나오면서 connection pool이 생성된다면 문제가 되지 않는다. 하지만 그렇지 않다면 아래와 같이 connection pool을 application이 시작할때 만들어주어 몇초동안 latency가 급격히 높아지는 현상을 줄일 수 있다.

```java
@Component
public class HikariLoader implements ApplicationRunner {

    private final HikariDataSource hikariDataSource;

    public HikariLoader(HikariDataSource hikariDataSource) {
        this.hikariDataSource = hikariDataSource;
    }

    @Autowired
    public void run(ApplicationArguments args) throws SQLException {
        hikariDataSource.getConnection();
    }
}
````

> 메소드에 `@Autowired`를 붙이면 field injection이 끝난 후 빈을 객체화 할때 실행된다. 그렇게 하면, 해당 메소드의 인자가 자동으로 주입되어, 원하는 정보를 설정하도록 할 수 있다. 


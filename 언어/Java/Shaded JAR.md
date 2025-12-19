Shaded JAR은 애플리케이션 코드와 모든 의존성을 하나의 JAR 파일로 합친 패키징 방식이다. Fat JAR, Uber JAR이라고도 부른다.

Java 애플리케이션은 보통 여러 라이브러리에 의존한다. 이 의존성들을 어떻게 패키징하느냐에 따라 JAR의 종류가 나뉜다.

**Non-shaded JAR (Thin JAR)**

프로젝트 코드만 포함한다. 의존성은 별도로 제공해야 한다.

```
mongo-kafka-connect-2.0.1.jar (394KB)
└── 커넥터 코드만 포함
    └── 실행하려면 MongoDB Driver 등 의존성 필요
```

**Shaded JAR (Fat JAR / Uber JAR)**

프로젝트 코드와 모든 의존성을 하나로 합친다.

```
mongo-kafka-connect-2.0.1-all.jar (8.3MB)
├── 커넥터 코드
├── MongoDB Driver 4.7.x
├── BSON 라이브러리
└── 기타 의존성들...
```

## Shading의 동작 원리

Maven Shade Plugin이나 Gradle Shadow Plugin이 하는 일은 다음과 같다.

1. 모든 의존성 JAR 파일을 압축 해제한다
2. 모든 `.class` 파일과 리소스를 하나의 JAR로 합친다
3. (선택) 패키지명을 변경(relocate)하여 충돌을 방지한다

```xml
<!-- Maven Shade Plugin 설정 예시 -->
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-shade-plugin</artifactId>
  <configuration>
    <relocations>
      <relocation>
        <pattern>org.mongodb</pattern>
        <shadedPattern>com.example.shaded.mongodb</shadedPattern>
      </relocation>
    </relocations>
  </configuration>
</plugin>
```

relocate를 적용하면 클래스의 패키지명이 변경된다.

```
원본: org.mongodb.driver.MongoClient
변경: com.example.shaded.mongodb.driver.MongoClient
```

이렇게 하면 다른 버전의 MongoDB Driver가 클래스패스에 있어도 패키지명이 달라서 충돌이 발생하지 않는다.

## POM과 클래스패스의 차이

의존성 버전을 교체하려 할 때 이 개념을 이해해야 한다.

**POM 파일**은 빌드 시점에 Maven이 의존성을 자동으로 다운로드할 때 참조하는 명세서이다.

```xml
<dependency>
  <groupId>org.mongodb</groupId>
  <artifactId>mongodb-driver-sync</artifactId>
  <version>[4.7,4.7.99]</version>  <!-- 4.7.x 버전 범위 지정 -->
</dependency>
```

**클래스패스**는 런타임에 JVM이 실제로 클래스를 찾는 경로이다.

```java
import com.mongodb.client.MongoClient;  // JVM은 클래스패스에서 이 클래스를 찾는다
```

JVM은 클래스를 로드할 때 POM을 참조하지 않는다. 클래스패스에 있는 JAR들에서 해당 클래스를 찾을 뿐이다.

## 의존성 버전 교체하기

이 차이를 활용하면 라이브러리가 요구하는 의존성 버전을 우회할 수 있다.

**문제 상황**: Kafka Connect용 MongoDB 커넥터가 Driver 4.7.x를 요구하지만, IRSA(IAM Roles for Service Accounts) 지원을 위해 Driver 4.8+ 버전이 필요하다.

```yaml
# 방법 1: Shaded JAR 사용 (실패)
- type: jar
  url: .../mongo-kafka-connect-2.0.1-all.jar
# → Driver 4.7.x가 내장되어 있어서 교체 불가능
```

```yaml
# 방법 2: Non-shaded JAR + 직접 의존성 지정 (성공)
- type: jar # 커넥터 코드만 다운로드 (POM 의존성 해결 안 함)
  url: .../mongo-kafka-connect-2.0.1.jar
- type: maven # 원하는 Driver 버전 직접 지정
  group: org.mongodb
  artifact: mongodb-driver-sync
  version: 4.11.5
```

`type: jar`로 다운로드하면 Maven 의존성 해결을 우회한다. POM에 4.7.x가 명시되어 있어도 무시되고, 클래스패스에 우리가 직접 넣은 4.11.5가 사용된다.

왜 동작할까? 커넥터 코드는 `com.mongodb.client.MongoClient` 같은 클래스를 import한다. Driver 4.7.x와 4.11.5 모두 같은 패키지 구조를 가지고 있고(하위 호환성), JVM은 클래스패스에서 해당 클래스를 찾기만 하면 된다.

## 주의사항

**Non-shaded JAR의 의존성 관리**

Non-shaded JAR을 사용하면 모든 의존성을 직접 챙겨야 한다. POM 파일에 명시된 의존성들이 자동으로 따라오지 않기 때문이다.

```xml
<!-- mongo-kafka-connect-2.0.1.pom의 의존성 -->
<dependencies>
  <dependency>
    <groupId>org.apache.kafka</groupId>
    <artifactId>connect-api</artifactId>
    <scope>runtime</scope>
  </dependency>
  <dependency>
    <groupId>org.mongodb</groupId>
    <artifactId>mongodb-driver-sync</artifactId>
    <scope>runtime</scope>
  </dependency>
  <dependency>
    <groupId>org.apache.avro</groupId>
    <artifactId>avro</artifactId>
    <scope>runtime</scope>
  </dependency>
</dependencies>
```

이 의존성들을 어떻게 해결하는지 확인해야 한다.

1. **플랫폼이 제공하는 의존성**: Kafka Connect 같은 플랫폼 위에서 동작하는 플러그인이라면, 플랫폼이 공통 라이브러리를 제공한다. `connect-api`는 Kafka Connect 런타임에 이미 포함되어 있다.
2. **환경에 이미 있는 의존성**: `avro`처럼 Schema Registry나 다른 컴포넌트가 사용하는 라이브러리는 이미 클래스패스에 있을 수 있다.
3. **직접 설치해야 하는 의존성**: 플랫폼에 없는 라이브러리는 직접 설치해야 한다. MongoDB Driver가 이 경우다.

```
Kafka Connect 런타임 (플랫폼 제공)
├── kafka-clients
├── connect-api        ← POM에 명시되어 있지만 이미 있음
├── connect-runtime
├── avro               ← 환경에 따라 이미 있을 수 있음
└── 기타 공통 라이브러리...

직접 설치 필요
└── mongodb-driver-sync ← 플랫폼에 없음, 반드시 설치
```

의존성이 누락되면 런타임에 `ClassNotFoundException`이 발생한다. Non-shaded JAR을 사용할 때는 POM 파일을 확인하고, 각 의존성이 어디서 제공되는지 파악해야 한다.

**relocate 없는 Shaded JAR의 위험성**

의존성을 합치기만 하고 relocate를 하지 않으면, 클래스패스에 같은 클래스가 두 개 존재할 수 있다. 어떤 것이 로드될지는 클래스로더 순서에 따라 달라지므로 예측하기 어렵다.

**버전 호환성 확인**

Non-shaded JAR로 의존성을 교체할 때는 API 호환성을 확인해야 한다. 메이저 버전이 다르면 API가 변경되어 런타임 에러가 발생할 수 있다.

```
4.7.x → 4.11.x: 마이너 버전 업그레이드, 대부분 호환
4.x → 5.x: 메이저 버전 업그레이드, API 변경 가능성 높음
```

---
참고

- <https://maven.apache.org/plugins/maven-shade-plugin>
- <https://github.com/johnrengelman/shadow>

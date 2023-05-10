# Spring에서 aspectj weaving사용하기

Spring은 객체지향적으로 AOP 기술을 구현하기 위해 프록시 패턴의 관점을 선택했다. 이러한 패턴의 추상적인 관점을 구체화하기 위해, Java에서 기본적으로 제공해주고 있는 JDK Dynamic Proxy(프록시 패턴의 관점의 구현체)를 기반으로 추상적인 AOP 기술을 객체 모듈화하여 설계하였다.

또한 Spring은 성숙한 AOP 기술을 제공해주기 위해 Spring 2.0 부터 `@AspectJ`애노테이션 방식을 지원하였고, Aspect를 구현하는데 있어 `AspectJ5` 라이브러리에 포함된 일부 애노테이션을 사용할 수 있다. AspectJ의 강력한 AOP 기술을 Spring에서 쉽게 구현할 수 있기 때문에 개발자는 비즈니스 개발에 보다 집중할 수 있다.

물론, `@AspectJ` 애노테이션 방식을 통해 구현된 Aspect는 IoC 컨테이너에서 Bean으로 자동으로 관리해주고 있고 Bean 또한 가능하다.

## weaving을 바꿔야하는 이유

Spring AOP가 사용하는 프록시 메커니즘엔 크게 두가지의 단점이 있다.

### 자기호출

Spring AOP는 클라이언트가 특정 메소드를 호출할 시 호출된 메소드를 포인트컷으로 검증하고, 해당 타겟인 경우에 어드바이스 코드를 작동시킨다.

![image](https://github.com/team-aliens/DMS-Backend/assets/81006587/e593f675-c7f2-4eb4-8597-69a4ce56ff60)

여기서 중요한 점은 타깃(Proxy Bean)에 대한 메소드가 수행할 시점엔 어떠한 Aspect가 동작하지 않는다는 것이다. 이는 프록시 메커니즘을 기반으로 한 AOP 기술에서 발생할 수 있는 공통적인 문제로써, 이를 **자기 호출 문제**라 한다. Spring AOP에서 제공하는 CGLib(바이트 조작 기반)도 마찬가지로 JDK Dynamic Proxy를 기반으로 설계된 구조를 통해 동작하기 때문에 자기 호출 문제가 발생한다.

Spring에서 자기 호출의 문제에 대한 여러 해결 방안이 존재한다. 하지만 기존 코드에 다른 코드를 덧붙이거나 구조에 영향을 준다.

### 성능

두 번째 문제는 성능에 관련된 문제이다.

Spring AOP는 런타임 시점(메소드 호출 시점)에 타깃에 대한 메소드 호출을 가로채고 내부적인 AOP 프로세스에 의해 어드바이스를 타깃의 메소드와 하나의 프로세스로 연결한다.

![image](https://github.com/team-aliens/DMS-Backend/assets/81006587/5e39b829-806e-4877-a6f2-7681a81764ea)

이러한 형태를 사슬(Chain) 모양을 띄고 있다하여 어드바이스 체이닝이라 한다. 이 체이닝은 런타임시 순차적으로 어드바이스 코드를 실행을 하고 다음 클라이언트가 원하는 로직(타깃의 메소드)이 수행된다. 이 점은 프록시 패턴의 특징인 타깃에 대한 안정성을 보장 받을 수 있다는 측면이라 볼 수 있다.

하지만 Aspect가 늘어날수록 자연스레 실질적으로 수행될 타깃의 메소드는 늦어질 수밖에 없고, 이는 결과적으로 성능에 관한 문제로 직결된다.

## AspectJ의 바이트 코드 조작

프록시 메커니즘을 가지고 있던 문제는 AspectJ 위빙 방식으로 전환하면 모든 문제를 해결할 수 있다. 기본적으로 AspectJ는 바이트 코드을 기반으로 위빙하기 때문에 성능 문제와 더불어 자기 호출에 대한 문제를 해결할 수 있다.

## AspectJ weaving

Spring에서 AspectJ로 전환하기 위해선 4가지 조건이 필요하다.

- AspectJ 형식의 Aspect
- AspectJ Runtime
- AspectJ Weaver
- AspectJ Compiler(AJC)

### AspectJ 형식의 Aspect
우선 첫 번째는 AspectJ 형식으로 구현된 Aspect가 필요합니다.

- `.aj` 파일로 구현된 Aspect
- Java 파일로 구현된 Aspect(@AspectJ 애노테이션 기반)

`*.aj` 확장자를 띈 파일로 구현된 Aspect는 순수한 AspectJ의 Aspect이다.

```java
public aspect OriginalAspect{
    // 포인트컷
    pointcut pcd() : call(* ..*Service.method(..));

    // 어드바이스
    void around() : pcd() {// 포인트컷 정의
        proceed();
    }
}
```

이 `*.aj` 파일의 코드 스타일은 Java와 비슷하면서도 다르고, AspectJ의 모든 기능을 사용할 수 있습니다. 커스텀마이징이 가능한 만큼 고려할 사항도 많고, 초기 학습에 대한 진입 장벽이 높고 어렵다.

하지만 Java 형식으로도 AspectJ 형식의 Aspect를 구현할 수 있습니다.

흔히 Spring AOP에서 흔히 사용하고 있는 `@AspectJ` 애노테이션 스타일의 Aspect는 AspectJ5 라이브러리의 일부 애노테이션을 사용하는 방식으로 전형적인 AspectJ의 형식이다.

```java
@Aspect
@Component
public class SpringAOPAspect{
    ...
}
```

### AspectJ Runtime

그 다음 AspectJ Runtime이 필요하다.

AspectJ Runtime를 구성하기 위해선 AspectJ Runtime 라이브러리인 `aspectjrt.jar` 의존성만 추가시켜주면 된다. AspectJ로 구성된 애플리케이션을 실행하게 되면, `AspectJ Compiler(AJC)`엔 위빙할 객체의 정보가 포함되어 있고, AspectJ Runtime은 AJC에 포함된 객체의 정보를 토대로 위빙된 코드를 타깃에게 적용한다.

```kotlin
implementation("org.arpectj:aspectjrt:1.9.4")
```

### AspectJ Weaver

그리고 Aspect Weaver 라이브러리인 `aspectjweaver.jar`를 추가해줘야 한다.

Aspect Weaver 라이브러리는 `@Aspect`, `@Pointcut`, `@Before`, `@Around` 등 AspectJ 5 라이브러리에 속한 애노테이션들을 포함하고 있다.

AspectJ Weaver는 Aspect와 타깃의 바이트 코드를 위빙하고, 위빙된 바이트 코드를 컴파일러에게 제공하는 역할을 한다.

![image](https://github.com/team-aliens/DMS-Backend/assets/81006587/ab4c925f-9cce-499c-9160-8dd51d70db56)

### AspectJ Compiler

마지막으로 `AspectJ Compiler(AJC)`라는 컴파일러가 필요하다.

AJC는 Java Compiler를 확장한 형태의 컴파일러로써, AspectJ는 AJC를 통해 Java 파일을 컴파일하며, 컴파일 과정에서 타깃의 바이트 코드 조작(어드바이스 삽입)을 통해 위빙을 수행한다.

대표적으로 두가지 종류가 있다.

- AspectJ Development Tool(AJDT) : Eclipse에서 지원하는 툴(AJC가 내장되어있음)
- Mojo : AspectJ Maven Plugin

## Aspectj의 Weaving

AspectJ는 3 가지 위빙 방식을 지원한다.

- CTW(Compile Time Weaving)
  - AJC(AspectJ Compiler)를 이용해서, 소스 코드가 컴파일할 때 위빙한다.
  - 타깃의 코드가 JVM 상에 올라갈 때 바이트 코드를 직접 조작하여, 타깃의 메소드 내에 어드바이스 코드를 삽입시켜 주기 때문에 성능이 가장 좋다.
  - 컴파일 시점에만 바이트 코드를 조작하여 호출된 타깃의 메소드는 조작된 코드가 수행되기 때문에 정적인 위빙 방식이라 한다.
  
- PCW(Post Compile Weaving)
  - CTW가 컴파일 시점에 위빙을 한다면, PCW는 컴파일 직후의 바이너리 클래스에 위빙한다.
  - PCW는 주로 JAR에 포함된 소스에 위빙하는 목적으로 사용된다.
  
- LTW(Load Time Weaving)
  - LTW는 JVM에 클래스가 로드되는 시점에 위빙을 한다.
  - LTW는 RTW(Runtime Weaving)처럼 바이트 코드에 직접적으로 조작을 가하지 않기 때문에 컴파일 시간은 상대적으로 CTW와 PCW보다 짧지만, 오브젝트가 메모리에 올라가는 과정에서 위빙이 일어나기 때문에 런타임 시 위빙 시간은 상대적으로 느리다.
  - Weaving Agent가 꼭 필요하다.

---

참고
- https://www.baeldung.com/aspectj
- https://www.baeldung.com/spring-aop-vs-aspectj
- https://www.eclipse.org/lists/aspectj-users/msg02750.html
- https://gmoon92.github.io/spring/aop/2019/05/24/aspectj-of-spring.html

스프링은 서비스 추상화를 프록시 기술에도 동일하게 적용한다. 따라서 스프림은 일관된 방법으로 프록시를 만들 수 있게 도와주는 추상 레이어를 제공한다. **ProxyFactoryBean**은 프록시를 생성해서 빈 오브젝트로 등록하게 해주는 팩토리 빈이다. ProxyFactoryBean은 순수하게 프록시를 생성하는 작업만을 담당하고 프록시를 통해 제공해줄 부가기능은 별도의 빈에 둘 수 있다.

ProxyFactoryBean이 생성하는 프록시에서 사용할 부가기능은 **MethodInterceptor** 인터페이스를 구현해서 만든다. MethodInterceptor는 InvocationHanler와 비슷하지만 한가지 다른점이 있다. 

**InvocationHandler의 `invoke()` 메소드는 오브젝트에 대한 정보를 제공하지 않는다**. <br/> 따라서 타깃은 InvocationHandler를 구현한 클래스가 직접 알고 있어야 한다.

반면에 **MethodInterceptor의 `invoke()` 메소드는 ProxyFactoryBean으로부터 타깃 오브젝트에 대한 정보까지도 함께 제공**받는다.

그 차이 덕분에 MethodInterceptor는 `타깃 오브젝트에 상관없이 독립적`으로 만들어질 수 있다. 따라서 MethodInterceptor 오브젝트는 타깃이 다른 여러 프록시에서 함께 사용할 수 있고 싱글톤 빈으로도 등록 가능하다.

```java
@FunctionalInterface
public interface MethodInterceptor extends Interceptor {
	@Nullable
	Object invoke(@Nonnull MethodInvocation invocation) throws Throwable;
}
```

```java
public interface InvocationHandler extends Callback {
    Object invoke(Object var1, Method var2, Object[] var3) throws Throwable;
}
```

---

## 어드바이스: 타깃이 필요 없는 순수한 부가기능

- InvocationHandler를 구현했을 때와 달리 MethodInterceptor로는 메소드 정보와 함께 타깃 오브젝트가 담긴 `MethodInvocation` 오브젝트가 전달된다. MethodInvocation은 타깃 오브젝트의 **메소드를 실행할 수 있는 기능**이 있기 때문에 MethodInterceptor는 부가기능을 제공하는 데만 집중할 수 있다.

- MethodInvocation은 일종의 콜백 오브젝트로 `proceed()` 메소드를 실행하면 타겟 오브젝트의 메소드를 내부적으로 실행해주는 기능이 있다. 그렇다면 MethodInvocation 구현 클래스는 `일종의 공유 가능한 템플릿`처럼 동작하는 것이다. 바로 이 점이 JDK의 다이내믹 프록시를 직접 사용하는 코드와 스프링이 제공하는 프록시 추상화 기능인 ProxyFactoryBean을 사용하는 코드의 가장 큰 차이점이자 ProxyFactoryBean의 장점이다. 

- ProxyFactoryBean은 작은 단위의 템플릿/콜백 구조를 응용해서 적용했기 때문에 템플릿 역할을 하는 **MethodInterceptor 구현체를 싱글톤으로 두고 공유**할 수 있다. 마치 SQL 파라미터 정보에 종속되지 않는 JdbcTemplate이기 때문에 수많은 DAO 메소드가 하나의 JdbcTemplate 오브젝트를 공유할 수 있는 것과 마찬가지다. 

- 또한 ProxyFactoryBean에는 **여러 개의 부가기능을 제공해주는 프록시**를 만들 수 있다. 즉 여러 개의 MethodInterceptor 구현체를 ProxyFactoryBean에 추가해줄 수 있다. 따라서 **새로운 기능을 추가하더라도 새 프록시나 팩토리 빈을 추가해줄 필요가 없다**.

---

## 포인트컷 : 부가기능 적용 대상 메소드 선정 방법

- MethodInterceptor 오브젝트는 여러 프록시가 공유해서 사용할 수 있다. 그러기 위해서 MethodInterceptor 오브젝트는 타깃 정보를 갖고 있지 않도록 만들었고, 그 덕분에 MethodInterceptor를 스프링의 싱글톤 빈으로 등록할 수 있었다.

- 하지만, 적용 대상 정보를 갖고 있지 않기 때문에 그 Advice를 어느 곳에다 적용할지를 알 수 없다. 

- 스프링의 ProxyFactoryBean 방식은 두 가지 확장 기능인 부가기능(Advice)과 메소드 선정 로직(Pointcut)을 아래와 같은 유연한 구조로 설계하여, 기존의 장점을 그대로 가져갈 수 있도록 하였다.

	![image](https://user-images.githubusercontent.com/81006587/201669169-0c2d51c2-3748-4494-be57-cb3231e86793.png)

- Advice와 Pointcut은 모두 Proxy에 DI로 주입되어 사용된다. 두 가지 모두 여러 프록시에서 공유가 가능하도록 만들어지기 때문에 싱글톤 빈으로 등록 가능하다.

  1. Proxy는 클라이언트로부터 요청을 받으면 먼저 Pointcut에게 부가기능을 부여할 메소드인지 확인한다.

  2. Pointcut으로부터 부가기능을 적용할 대상 메소드인지 확인받으면, MethodInterceptor 타입의 Advice를 호출한다.

- 여기서 중요한 점은 MethodInterceptor가 타깃을 직접 호출하지 않는다는 것이다. 자신은 여러 타깃에 공유되어야하고 타깃 정보라는 상태를 가질 수 없기 때문에 일종의 템플릿 구조로 설계되어 있다. 어드바이스가 부가기능을 부여하는 중에 `타깃 메소드의 호출`이 필요하면 **프록시로부터 전달받은 `MethodInvocation` 타입 콜백 오브젝트의 `proceed()` 메소드를 호출**해주기만 하면 된다.

- 실제 위임 대상인 타깃 오브젝트의 레퍼런스를 갖고 있고, 이를 이용해 타깃 메소드를 직접 호출하는 것은 프록시가 메소드 호출에 따라 만드는 MethodInvocation 콜백의 역할이다. **재사용 가능한 기능**을 만들어두고 **바뀌는 부분(콜백 오브젝트 - 메소드 호출정보)만 외부에서 주입**해서 이를 작업 흐름(부가기능) 중에 사용하도록 하는 전형적인 템플릿/콜백 구조이다.

---

출처: 토비의 스프링 3.1

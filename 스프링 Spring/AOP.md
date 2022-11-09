# 🍃 AOP(Aspect Oriented Programming)

AOP란 Aspect Oriented Programming의 약자로 관점 지향 프로그래밍이라고 한다. 여기서 Aspect(관점)이란 흩어진 관심사들을 하나로 모듈화 한 것을 의미한다.

객체 지항 프로그래밍(OOP)에서는 주요 관심사에 따라 클래스를 분할한다. 이 클래스들은 보통 SRP(Single Responsibility Principle)에 따라 하나의 책임만을 갖게 설계된다. 하지만 클래스를 설계하다보면 로깅, 보안, 트랜잭션 등 여러 클래스에서 공통적으로 사용하는 부가 기능들이 생긴다. 이들은 주요 비즈니스 로직은 아니지만, 반복적으로 여러 곳에서 쓰이는 데 이를 흩어진 관심사(Cross Cutting Concerns)라고 한다.

AOP 없이 흩어진 관심사를 처리하면 다음과 같은 문제가 발생한다.

- 여러 곳에서 반복적인 코드를 작성해야 한다.
- 코드가 변경될 경우 여러 곳에 가서 수정이 필요하다.
- 주요 비즈니스 로직과 부가 기능이 한 곳에 섞여 가독성이 떨어진다.
- 따라서 흩어진 관심사를 별도의 클래스로 모듈화하여 위의 문제들을 해결하고, 결과적으로 OOP를 더욱 잘 지킬 수 있도록 도움을 주는 것이 AOP이다.

### AOP의 주요 개념
**Aspect :** Advice + PointCut로 AOP의 기본 모듈

**Advice :** Target에 제공할 부가 기능을 담고 있는 모듈

**Target :** Advice이 부가 기능을 제공할 대상 (Advice가 적용될 비즈니스 로직)

**JointPoint :** Advice가 적용될 위치. 메서드 진입 지점, 생성자 호출 시점, 필드에서 값을 꺼내올 때 등 다양한 시점에 적용 가능

**PointCut :** Target을 지정하는 정규 표현식

### Spring AOP

Spring AOP는 기본적으로 프록시 방식으로 동작한다. 프록시 패턴이란 어떤 객체를 사용하고자 할 때, 객체를 직접적으로 참조 하는 것이 아니라, 해당 객체를 대행(대리, proxy)하는 객체를 통해 대상객체에 접근하는 방식을 말한다.

Spring AOP는 왜 프록시 방식을 사용하는가? Spring은 왜 Target 객체를 직접 참조하지 않고 프록시 객체를 사용할까?

프록시 객체 없이 Target 객체를 사용하고 있다고 생각해보자. Aspect 클래스에 정의된 부가 기능을 사용하기 위해서, 우리는 **원하는 위치에서 직접 Aspect 클래스를 호출**해야 한다. 이 경우 Target 클래스 안에 부가 기능을 호출하는 로직이 포함되기 때문에, AOP를 적용하지 않았을 때와 동일한 문제가 발생한다. 여러 곳에서 반복적으로 Aspect를 호출해야 하고, 그로 인해 유지보수성이 크게 떨어진다.

그래서 Spring에서는 Target 클래스 혹은 그의 상위 인터페이스를 상속하는 프록시 클래스를 생성하고, 프록시 클래스에서 부가 기능에 관련된 처리를 한다. 이렇게 하면 Target에서 Aspect을 알 필요 없이 순수한 비즈니스 로직에 집중할 수 있다.


예를 들어 다음 코드의 logic() 메서드가 Target이라면,

```java
public interface TargetService{
    void logic();
}

@Service 
public class TargetServiceImpl implements TargetService{
    @Override 
    public void logic() {
        ...
    }
}
```
Proxy에서 Target 전/후에 부가 기능을 처리하고 Target을 호출한다.

```java
@Service 
public class TargetServiceProxy implements TargetService{ 
    // 지금은 구현체를 직접 생성했지만, 외부에서 의존성을 주입 받도록 할 수 있다.
    TargetService targetService = new TargetServiceImpl();
    ...

    @Override 
    public void logic() {
        // Target 호출 이전에 처리해야하는 부가 기능
        // Target 호출
        targetService.logic();
        // Target 호출 이후에 처리해야하는 부가 기능
    }
}
```

사용하는 입장에서는 Target 객체를 사용하는 것처럼 Proxy 객체를 사용할 수 있다.

```java
@Service 
public class UseService {
    // 지금은 구현체를 직접 생성했지만, 외부에서 의존성을 주입 받도록 할 수 있다.
    TargetService targetService = new TargetServiceProxy();
    ..
		
    public void useLogic() {
        //Target 호출하는 것처럼 부가 기능이 추가된 Proxy를 호출한다.
        targetService.logic();
    }
}
```

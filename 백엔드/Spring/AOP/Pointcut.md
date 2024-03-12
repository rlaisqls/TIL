
Pointcut은 Advice가 부가 기능을 제공할 대상을 특정하는 정규표현식이다. 즉, AOP를 적용할 대상을 정한다.

포인트컷에는 다양한 명시자를 이용할 수 있는데, 각 명시자마다 어떤 범위에서 Target을 정할지 어떤 것을 기준으로 할지 등의 의미가 조금씩 다르다.

아래 영어로 된 PointCut 명시자 설명이 있으니, 참고하면 좋을 것 같다.

|명시자|설명|
|-|-|
|execution| for matching method execution join points, this is the primary pointcut designator you will use when working with Spring AOP|
|within|limits matching to join points within certain types (simply the execution of a method declared within a matching type when using Spring AOP)|
|this|limits matching to join points (the execution of methods when using Spring AOP) where the bean reference (Spring AOP proxy) is an instance of the given type|
|target|limits matching to join points (the execution of methods when using Spring AOP) where the target object (application object being proxied) is an instance of the given type|
|args|limits matching to join points (the execution of methods when using Spring AOP) where the arguments are instances of the given types|
|@target|limits matching to join points (the execution of methods when using Spring AOP) where the class of the executing object has an annotation of the given type|
|@args|limits matching to join points (the execution of methods when using Spring AOP) where the runtime type of the actual arguments passed have annotations of the given type(s)|
|@within|limits matching to join points within types that have the given annotation (the execution of methods declared in types with the given annotation when using Spring AOP)|
|@annotation|limits matching to join points where the subject of the join point (method being executed in Spring AOP) has the given annotation|

# `execution`

```js
execution([접근지정자] 리턴타입 [클래스경로].메서드이름(파라미터)
```

**접근지정자* : public, private 등 접근지정자를 명시한다. (생략 가능)<br/>
**리턴타입** : 리턴 타입을 명시한다.<br/>
**클래스경로 및 메서드이름** : 클래스경로와 메서드 이름을 명시한다. (클래스 경로은 풀 패키지 경로로 명시해야한다. 생략 가능)<br/>
**파라미터** : 메서드의 파라미터를 명시한다.

`execution`은 접근지정자, 리턴타입, 클래스경로 등의 여러 속성을 정의하여 AOP를 적용할 대상을 구체적으로 지정한다. 원하는대로 표현식을 작성하면 원하는 클래스를 상세하게 특정할 수 있기
때문에 범용적으로 사용할 수 있다.

### Example

- 모든 public 메서드:
```js
execution(public * *(..))
```

- 'set'으로 시작하는 모든 메서드:
```js
execution(* set*(..))
```

- `AccountService` 인터페이스에 의해 정의된 모든 메서드:
```js
execution(* com.xyz.service.AccountService.*(..))
```

- service 패키지에 정의된 모든 메서드:
```js
execution(* com.xyz.service.*.*(..))
```

- service 패키지 또는 그 하위 패키지에 정의된 모든 메서드중, 두개의 인자를 가지고 있고 두번째 인자가 String 타입인 메서드:
```js
execution(* com.xyz.service..*.*(*,String))
```

# `within`

```js
within(패키지경로)
```

within은 특정 패키지 안에 있는 클래스에 AOP를 적용하도록 한다.

### Example

- service 패키지에 있는 모든 joinPoint(메서드):
```js
                
```

- service 패키지 또는 그 하위 패키지에 있는 joinPoint(메서드):
```js
within(com.xyz.service..*)
```

# `this`

```js
this(클래스경로)
```

`this`는 경로로 명시한 클래스와, 그 하위 클래스에 모두 AOP를 적용하도록 한다. `this instanceof AType`에 해당하는 경우를 뜻한다.

`this`는 바인딩 형식에서 더 일반적으로 사용된다.

### Example

- 프록시가 `AccountService` 인터페이스를 구현하는 joinPoint(메서드):
```js
this(com.xyz.service.AccountService)
```

# `target`

```js
target(클래스경로)
```

`target`은 딱 경로로 명시한 그 클래스인 객체에 대해 AOP를 적용하도록 한다.

### Example

- `AccountService` 클래스 안에 있는 joinPoint(메서드):
```js
target(com.xyz.service.AccountService)
```

# `args`

```js
args(클래스경로)
```

특정한 타입의 파라미터를 받는 joinPoint(메서드)에 대해 AOP를 적용한다. 콤마(`,`)를 찍고 여러 파라미터를 표현하는 것도 가능하다.

하지만 `args(클래스)`는 `execution(* *(클래스))`와 다르게 동작한다. args는 런타임에 전달된 인수가 해당 클래스인 경우 실행되고, execution는 해당 클래스를 인수로 받는다고 선언되어있는 메서드가 호출되었을 때 실행된다.

### Example

- `Serializable` 한개를 파라미터로 받는 메서드:
```js
args(java.io.Serializable)
```

- `Serializable`와 `Int`두개를 파라미터로 받는 메서드:
```js
args(java.io.Serializable, Int)
```

# `@target`, `@within`, `@annotation`, `@args`

위 네개의 명시자는 특정 어노테이션을 가지고 있는 클래스, 혹은 메서드에 AOP를 적용하도록 하는 명시자이다. 각각 상세한 의미를 가지고있지만 서로 비슷하여 헷갈릴 수 있으니 비교하며 알아보자.

|명시자|설명|
|-|-|
|@target|대상 객체에 해당 어노테이션이 직접 붙어있는 객체의 JoinPoint|
|@within|간접적으로라도 해당 어노테이션을 가지고있는 객체의 JoinPoint|
|@annotation|해당 어노테이션이 붙어있는 메서드 |
|@args|인수의 런타입 유형이 특정 어노테이션을 가지고있는 메서드|

크게 더 설명할 부분이 없으므로 예시는 생략한다.

# `bean`

```js
bean(빈 이름)
```

bean은 스프링에 등록된 빈의 이름으로 AOP 적용 대상을 명시한다.

### Example

- 이름이 `tradeService`인 빈:
```js
bean(tradeService)
```

- 이름이 `Service`로 끝나는 빈:
```js
bean(*Service)
```

---

참고: [https://docs.spring.io/spring-framework/docs/4.3.15.RELEASE/spring-framework-reference/html/aop.html#aop-pointcuts](https://docs.spring.io/spring-framework/docs/4.3.15.RELEASE/spring-framework-reference/html/aop.html#aop-pointcuts)

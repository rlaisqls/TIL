# 🍃 AOP Annotation Annotation

<a href="./AOP.md">AOP</a>란 Aspect Oriented Programming의 약자로 관점 지향 프로그래밍이라고 한다. AOP를 사용하면 기존 코드를 수정하지 않고 기존 코드에 동작을 추가할 수 있다.

AOP를 지정하기 위해선 AOP 동작을 메서드에 작성해야한다. 아래 어노테이션들을 이용해서 메서드의 실행 시점을 지정할 수 있다.

## Advice Annotation

|Annotation|설명|
|-|-|
|`@Before`|핵심관심사 시작 전에 실행|
|`@After`|메서드가 끝난 후 실행 (성공여부 상관 X)|
|`@AfterThrowing`|메서드 실행이 예외를 throw하여 종료될 때 실행|
|`@AfterReturning`|메서드 실행이 정상적으로 반환될 때 실행|
|`@Around`|핵심관심사의 메서드 실행 전 후로 실행 (성공여부 상관 X)|

## pointCut 지정

```java
@Around("execution(* com.xyz.service.*.*(..))")
```

Advice Annotation에는 value라는 이름의 String값을 입력해줘야한다.

<a href="./Pointcut.md">Pointcut</a>이 들어가는 자리이다. 저 자리에 표현식을 입력해줘야, 어떤 클래스의 어떤 메서드에 AOP를 적용할 것인지가 결정된다.

Pointcut은 내용이 생각보다 많고, 헷갈리는 부분이 있으므로 다른 문서로 나누었다. 자세한 내용을 알고싶다면 해당 문서를 읽어보면 좋다.

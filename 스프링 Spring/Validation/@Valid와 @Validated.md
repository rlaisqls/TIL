
`@Valid`는 JSR-303 표준 스펙(자바 진영 스펙)으로써 빈 검증기(Bean Validator)를 이용해 객체의 제약 조건을 검증하도록 지시하는 어노테이션이다. JSR 표준의 빈 검증 기술의 특징은 객체의 필드에 달린 어노테이션으로 편리하게 검증을 한다는 것이다.

Spring에서는 일종의 어댑터인 `LocalValidatorFactoryBean`이 제약 조건 검증을 처리한다. 이를 이용하려면 LocalValidatorFactoryBean을 빈으로 등록해야 하는데, SpringBoot에서는 아래의 의존성만 추가해주면 해당 기능들이 자동 설정된다.

```kotlin
// https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-validation
implementation(" group: org.springframework.boot:spring-boot-starter-validation")
```

예를 들어 `@NotNull` 어노테이션은 필드의 값이 null이 아님을 체크하고, @Min은 해당 값의 최솟값을 지정할 수 있도록 한다.

```java
	@NotNull
	private final UserRole userRole;

	@Min(12)
	private final int age;
```

그리고 컨트롤러의 메소드에 `@Valid`를 붙여주면, 유효성이 검증된다.

### @Valid의 동작 원리

모든 요청은 프론트 컨트롤러인 dispatcherServlet을 통해 컨트롤러로 전달된다. 전달 과정에서는 컨트롤러 메소드의 객체를 만들어주는 `ArgumentResolver`가 동작하는데, @Valid 역시 ArgumentResolver에 의해 처리된다.

예를 들어 `@RequestBody`를 사용한다고 하면, Json 메세지를 객체로 변환해주는 작업은 ArgumentResolver의 구현체인 `RequestResponseBodyMethodProcessor`가 처리하며, 이 내부에서 `@Valid`로 시작하는 어노테이션이 있을 경우에 유효성 검사를 진행한다. 

그리고 검증에 오류가 있다면 `MethodArgumentNotValidException` 예외가 발생하게 되고, 디스패처 서블릿에 기본으로 등록된 예외 리졸버(Exception Resolver)인 `DefaultHandlerExceptionResolver`에 의해 400 BadRequest 에러가 발생한다.

이러한 이유로 `@Valid`는 기본적으로 컨트롤러에서만 동작한다.

```
org.springframework.web.bind.MethodArgumentNotValidException: Validation failed for argument [0] in public org.springframework.http.ResponseEntity<java.lang.Void> com.example.testing.validator.UserController.addUser(com.example.testing.validator.AddUserRequest) with 2 errors: [Field error in object 'addUserRequest' on field 'email': rejected value [asdfad]; codes [Email.addUserRequest.email,Email.email,Email.java.lang.String,Email]; arguments [org.springframework.context.support.DefaultMessageSourceResolvable: codes [addUserRequest.email,email]; arguments []; default message [email],[Ljavax.validation.constraints.Pattern$Flag;@18c5ad90,.*]; default message [올바른 형식의 이메일 주소여야 합니다]] [Field error in object 'addUserRequest' on field 'age': rejected value [5]; codes [Min.addUserRequest.age,Min.age,Min.int,Min]; arguments [org.springframework.context.support.DefaultMessageSourceResolvable: codes [addUserRequest.age,age]; arguments []; default message [age],12]; default message [12 이상이어야 합니다]] 
	at org.springframework.web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor.resolveArgument(RequestResponseBodyMethodProcessor.java:141) ~[spring-webmvc-5.3.15.jar:5.3.15]
	at org.springframework.web.method.support.HandlerMethodArgumentResolverComposite.resolveArgument(HandlerMethodArgumentResolverComposite.java:122) ~[spring-web-5.3.15.jar:5.3.15]
```

## `@Validated`

`@Validated`는 JSR 표준 기술이 아니며 Spring 프레임워크에서 제공하는 어노테이션 및 기능이다. `@Validated`와 `@Valid`를 시영히먄 컨트롤러가 아니더라도 유효성 검증을 할 수 있다. 

유효성 검증에 실패하면 에러가 발생하는데, 로그를 확인해보면 `MethodArgumentNotValidException` 예외가 아닌 `ConstraintViolationException` 예외가 발생하는 것을 확인할 수 있다. 이는 앞서 잠깐 설명한대로 동작 원리가 다르기 때문이다.

```
javax.validation.ConstraintViolationException: getQuizList.category: 널이어서는 안됩니다 
    at org.springframework.validation.beanvalidation.MethodValidationInterceptor.invoke(MethodValidationInterceptor.java:120) ~[spring-context-5.3.14.jar:5.3.14] 
    at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:186) ~[spring-aop-5.3.14.jar:5.3.14] 
    at org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.proceed(CglibAopProxy.java:753) ~[spring-aop-5.3.14.jar:5.3.14] 
    at org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:698) ~[spring-aop-5.3.14.jar:5.3.14] 
    at com.mangkyu.employment.interview.app.quiz.controller.QuizController$$EnhancerBySpringCGLIB$$b23fe1de.getQuizList(<generated>) ~[main/:na] 
    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method) ~
```

## @Validated의 동작 원리

특정 ArgumnetResolver가 유효성을 검사하던 `@Valid`와 달리, `@Validated`는 **AOP 기반**으로 메소드 요청을 인터셉터하여 처리된다. @Validated를 클래스 레벨에 선언하면 해당 클래스에 유효성 검증을 위한 AOP의 어드바이스 또는 인터셉터(MethodValidationInterceptor)가 등록되고, 해당 클래스의 메소드들이 호출될 때 AOP의 포인트 컷으로써 요청을 가로채서 유효성 검증을 진행한다.

이러한 이유로 `@Validated`를 사용하면 컨트롤러, 서비스, 레포지토리 등 계층에 무관하게 스프링 빈이라면 유효성 검증을 진행할 수 있다.

Validated를 사용하면 group으로 [검증 순서를 지정](@GroupSequence.md)하는 것도 가능하다. 
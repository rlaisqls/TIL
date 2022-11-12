# 🍃 Custom Annotation

개발시 프레임워크를 사용하다보면 여러 Annotation들을 볼 수 있다. (ex: `@NotNull`, `@Controller`, `@Data` 등)

이러한 어노테이션을은 라이브러리에 미리 정의되어있는 것인데, 우리가 직접 이 어노테이션을 생성하여 AOP로 기능을 부여해줄 수 있다.

## Annotation class 정의

Annotation을 정의하고 싶다면, `@interface`를 클래스 키위드 뒤에 붙이면 된다.

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface MyAnnotation {
    String param() default "paramsPost.content";
    Class<?> checkClazz() default ParamsPost.class;
}
```

코틀린에선 아래와 같이 작성할 수 있다.

```kotlin
@Target(AnnotationTarget.METHOD)
@Retention(AnnotationRetention.RUNTIME)
annotation class MyAnnotation() {
    val param: String = "paramPost.content",
    val checkClazz: KClass<*> = ParamsPost.class
}
```

## Annotation을 위한 Annotation

Annotation을 정의할떄, Annotation의 성질을 정해줄 수 있는 Annotation들에 대해 알아보자.

## `@Retention`

해당 Annotation의 정보를 어느 범위까지 유지할 것인지를 설정한다. 즉, Annotation을 언제까지 작동시킬 것인지를 정하는 것이다.

#### RetentionPolicy의 종류

- **SOURCE :** <br/>
    Annotation을 사실상 주석처럼 사용하는 것이다. 컴파일러가 컴파일할때 해당 어노테이션의 메모리를 버린다.

- **CLASS** : <br/>
    컴파일러가 컴파일에서는 Annotation의 메모리를 가져가지만 실질적으로 런타임시에는 사라지게된다. 런타임시에 사라진다는 것은 리플렉션으로 선언된 Annotation 데이터를 가져올 수 없다는 뜻이다. (Default). <br/>
    Lombok의 `@Getter`, `@Setter`처럼 컴파일시 바이트코드를 생성한 후 사라지는 경우, 이 전략을 사용한다.

- **RUNTIME** : <br/>
    Annotation을 런타임시에까지 사용할 수 있다. JVM이 자바 바이트코드가 담긴 class 파일에서 런타임환경을 구성하고 런타임을 종료할 때까지 메모리에 살아있다. <br/>
    스프링에서 빈이나 Transaction 등록하는 것과 같은 동작은 모두    어플리케이션이 시작한 후에 실행되기 때문에, 그와 관련된 어노테이션은 이 전략을 사용한다.  

```java
/**
 * Contains the list of possible annotation's retentions.
 *
 * Determines how an annotation is stored in binary output.
 */
public enum class AnnotationRetention {
    /** Annotation isn't stored in binary output */
    SOURCE,
    /** Annotation is stored in binary output, but invisible for reflection */
    BINARY,
    /** Annotation is stored in binary output and visible for reflection (default retention) */
    RUNTIME
}
```

## `@Target`

해당 어노테이션이 사용되는 위치를 결정한다.

List로 여러가지를 선택할 수 있으며, 선언한 어노테이션이 이 어노테이션으로 명시하지 않은 곳에 붙어있을 경우 컴파일시 에러가 발생한다.

이름만 보면 이해할 수 있는 것들이 많기 때문에 설명은 생략하고 ENUM 파일을 읽어보자.

```java
public enum class AnnotationTarget {
    /** Class, interface or object, annotation class is also included */
    CLASS,
    /** Annotation class only */
    ANNOTATION_CLASS,
    /** Generic type parameter */
    TYPE_PARAMETER,
    /** Property */
    PROPERTY,
    /** Field, including property's backing field */
    FIELD,
    /** Local variable */
    LOCAL_VARIABLE,
    /** Value parameter of a function or a constructor */
    VALUE_PARAMETER,
    /** Constructor only (primary or secondary) */
    CONSTRUCTOR,
    /** Function (constructors are not included) */
    FUNCTION,
    /** Property getter only */
    PROPERTY_GETTER,
    /** Property setter only */
    PROPERTY_SETTER,
    /** Type usage */
    TYPE,
    /** Any expression */
    EXPRESSION,
    /** File */
    FILE,
    /** Type alias */
    @SinceKotlin("1.1")
    TYPEALIAS
}
```

## `@Inherited`

어노테이션이 붙은 클래스 뿐만 아니라 그 클래스를 상속받은 하위 클래스까지 모두 전파하도록 하는 어노테이션이다.

## `@Repeatable`

어노테이션을 여러번 중복해서 붙여도 괜찮다는 의미이다.

## `@Documented`

JavaDoc 생성 시 Document에 포함되도록하는 어노테이션이다.

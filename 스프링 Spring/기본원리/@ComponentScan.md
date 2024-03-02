
`@ComponentScan`은 객체를 패키지에서 Scan하여 빈으로 등록해주는 어노테이션이다.

보통은 `@Component`나 `@Service`, `@Application`등의 지정된 어노테이션을 가지고 있는 객체를 경로의 전체 패키지에서 탐색하여 등록하지만 Scan할 패키지나 어노테이션, 조건 등을 custom하여 마음대로 지정할 수도 있다.


기본적인 어노테이션들은 `@SpringBootApplication`에 달려있는 `@ComponentScan`에 의해 빈으로 등록된다.

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(excludeFilters = { @Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class),
		@Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class) })
public @interface SpringBootApplication {
    ...
}
```

`@ComponentScan`은 `BeanFactoryPostProcessor`를 구현한 `ComfigurationClassPostProcessor`에 의해 동작한다.

`BeanFactoryPostProcessor`는 다른 모든 Bean들을 만들기 이전에 `BeanFactoryPostProcessor`의 구현체들을 모두 적용한다. 즉, 다른 Bean들을 등록하기 전에 컴포넌트 스캔을해서 Bean으로 등록해준다.

`@Autowired`의 `BeanPostProcessor`와 비슷하지만, 실행 시점이 다르다. `@ComponentScan`은 Bean으로 등록해야하는 객체를 찾아 `BeanFactoryPostProcessor`의 구현체를 적용하여 Bean으로 등록해주는 과정이고 `@Autowired`는 등록된 다른 Bean을 찾아 `BeanPostProcessor`의 구현체를 적용하여 의존성 주입을 적용하는 역할을 하는 것이다.
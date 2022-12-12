# 🍃 Spring-MVC의 시작

> **주의**<br>여기에 등장하는 클래스와 인터페이스명들은 굉장히 긴 편이기 때문에, 읽고 이해하기 어렵거나 두려울 수 있습니다. (저는 약간 압도됨을 느꼈습니다.)<br>하지만 이는 이름만으로 구분할 수 있도록 하기 위한 엄청난 프로그래머분들의 노력이니, 꾹 견디며 열심히 공부해봅시다.

```java
public static void main(String... args) {}
```

java 개발자라면 위 코드는 익숙하다. java에서 main 메소드는 애플리케이션의 최초 시작점이다. 그런데 Spring-MVC로 개발한 웹 애플리케이션을 war로 빌드 후 Web Application Server(이하 WAS)로 실행하는 경우엔 main 메소드가 최초 시작점이 아닌 것을 알 수 있다. WAS 실행이 최초 시작점이라고 볼 수도 있겠다.

## ServletContainerInitializer

그렇다면 WAS는 어떻게 내가 만든 웹 애플리케이션을 실행할까? 바로 ServletContainerInitializer을 실행한다. 

이 인터페이스는 Spring-MVC가 아닌, servlet 3.0에 정의된 인터페이스다.

```java
public interface ServletContainerInitializer {
    void onStartup(Set<Class<?>> c, ServletContext ctx) throws ServletException;
}
```

ServletContainerInitializer의 구현체는 다양한 것들이 있는데, Spring 웹 애플리케이션을 실행하는 구현체는 `org.springframework.web` 아래에 있는 **`SpringServletContainerInitalizer`**이다. 

![image](https://user-images.githubusercontent.com/81006587/206980775-0934b60a-40b2-43f3-acc3-345f52df9ba8.png)


```java
@HandlesTypes(WebApplicationInitializer.class)
public class SpringServletContainerInitializer implements ServletContainerInitializer {

    @Override
    public void onStartup(@Nullable Set<Class<?>> webAppInitializerClasses, ServletContext servletContext)
            throws ServletException {

        List<WebApplicationInitializer> initializers = new LinkedList<>();

        if (webAppInitializerClasses != null) {
            for (Class<?> waiClass : webAppInitializerClasses) {
                if (!waiClass.isInterface() && !Modifier.isAbstract(waiClass.getModifiers()) &&
                        WebApplicationInitializer.class.isAssignableFrom(waiClass)) {
                    try {
                        initializers.add((WebApplicationInitializer)
                                ReflectionUtils.accessibleConstructor(waiClass).newInstance());
                    }
                    catch (Throwable ex) {
                        throw new ServletException("Failed to instantiate WebApplicationInitializer class", ex);
                    }
                }
            }
        }

        if (initializers.isEmpty()) {
            servletContext.log("No Spring WebApplicationInitializer types detected on classpath");
            return;
        }

        servletContext.log(initializers.size() + " Spring WebApplicationInitializers detected on classpath");
        AnnotationAwareOrderComparator.sort(initializers);
        for (WebApplicationInitializer initializer : initializers) {
            initializer.onStartup(servletContext);
        }
    }

}
```

### `SpringServletContainerInitalizer`의 onStartup이 하는 일

1. 파라미터로 받은 `Set<Class<?>>`을 반복해서 `WebApplicationInitializer`로 생성(newInstance)해 initializers list에 담는다.
2. initializers list를 정렬해 `WebApplicationInitializer#onStartup` 메소드를 실행한다.

## WebApplicationInitializer

위에서 등장했던 `WebApplicationInitializer`의 역할을 알아보자.



`ServletContainerInitializer`(in org.springframework.web) is the interface which allows a library/runtime to be notified of a web application's startup phase and perform any required programmatic registration of servlets, filters, and listeners in response to it.

The spring also has an implementation for it. That is `ServletContainerInitializer`, When you started a spring apllication, it will be **loaded and instantiated** and have its `onStartup` method **invoked** by any Servlet-compliant container <u>during container startup assuming the the spring-web moodule JAR is present on the classpath.

Assuming that one or more WebApplicationInitializer types are detected, they will be instantiated Then the `WebApplicationInitializer.onStartup(ServletContext)` method will be invoked on each instance, delegating the ServletContext such that each instance may register and configure servlets(Spring's DispatcherServlet(), listeners(Spring's ContextLoaderListener), or any other Servlet API features(filters).

<img src="https://user-images.githubusercontent.com/81006587/207032686-5801d83a-942b-416a-a144-d5007e657d5a.png" height=100px>

Below is the code for `SpringServletContainerInitializer`.

```java
@HandlesTypes(WebApplicationInitializer.class)
public class SpringServletContainerInitializer implements ServletContainerInitializer {

	@Override
	public void onStartup(@Nullable Set<Class<?>> webAppInitializerClasses, ServletContext servletContext)
			throws ServletException {

		List<WebApplicationInitializer> initializers = Collections.emptyList();

		if (webAppInitializerClasses != null) {
			initializers = new ArrayList<>(webAppInitializerClasses.size());
			for (Class<?> waiClass : webAppInitializerClasses) {                   //--------------------------------(1)
				// Be defensive: Some servlet containers provide us with invalid classes,
				// no matter what @HandlesTypes says...
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
			initializer.onStartup(servletContext);                                 //--------------------------------(2)
		}
	}

}
```

A brief description of the action it performs is as follows :

1. Repeat the Set <Class<?> received as a parameter to create a Web Application Initializer and put it in the `initializers`.
2. Sort the `initializers` and run the `WebApplicationInitializer#onStartup` method.

If then, what is WebApplicationInitializer?

# WebApplicationInitializer

`WebApplicationInitializer` is the Interface to be implemented in Servlet environments in order to configure the ServletContext programmatically.

As you can see from above, Implementations of this SPI will be **detected automatically by SpringServletContainerInitializer**, which itself is bootstrapped automatically by any Servlet container.

```java
public interface WebApplicationInitializer {

	/**
	 * Configure the given {@link ServletContext} with any servlets, filters, listeners
	 */
	void onStartup(ServletContext servletContext) throws ServletException;

}
```

<img src="https://user-images.githubusercontent.com/81006587/207042698-f80f3044-c253-4a8e-b1aa-048130c25f53.png" height=150px>

---

```java
  public class MyWebAppInitializer implements WebApplicationInitializer {
 
     @Override
     public void onStartup(ServletContext container) {
       // Create the 'root' Spring application context
       AnnotationConfigWebApplicationContext rootContext =
         new AnnotationConfigWebApplicationContext();
       rootContext.register(AppConfig.class);
 
       // Manage the lifecycle of the root application context
       container.addListener(new ContextLoaderListener(rootContext));
 
       // Create the dispatcher servlet's Spring application context
       AnnotationConfigWebApplicationContext dispatcherContext =
         new AnnotationConfigWebApplicationContext();
       dispatcherContext.register(DispatcherConfig.class);
 
       // Register and map the dispatcher servlet
       ServletRegistration.Dynamic dispatcher =
         container.addServlet("dispatcher", new DispatcherServlet(dispatcherContext));
       dispatcher.setLoadOnStartup(1);
       dispatcher.addMapping("/");
     }
 
  }
```

By implementing this WebApplicationInitializer, you can set the WebApplication in detail based on code. (like above)

There are several implementations of the `WebApplicationInitializer` that are provided by default. <u>**`AbstractAnnotationConfigDispatcherServletInitializer`**</u> is the base class to initialize Spring application in Servlet container environment, so we will check that class and its parent class.

<img src="https://user-images.githubusercontent.com/81006587/207053870-d19af237-26c1-4c35-8318-91beacaad915.png" height=400px>

## AbstractAnnotationConfigDispatcherServletInitializer

It is constructed like <a href="https://github.com/rlaisqls/TIL/blob/main/%EB%94%94%EC%9E%90%EC%9D%B8%ED%8C%A8%ED%84%B4%E2%80%85DesignPattern/2.%E2%80%85%EA%B5%AC%EC%A1%B0%ED%8C%A8%ED%84%B4/%EB%8D%B0%EC%BD%94%EB%A0%88%EC%9D%B4%ED%84%B0%E2%80%85%ED%8C%A8%ED%84%B4.md">"Decorator Pattern"</a>.

If look at the order of operation from the bottom,

- `AbstractAnnotationConfigDispatcherServletInitializer` registers the ContextLoaderListener, including the settings of the class with the specific Annotation(`@Configuration`), and creates the ServletApplicationContext,
- `AbstractContextLoaderInitializer` registers the ContextLoaderListener,
- `AbstractDispatcherServletInitializer` creates DispatcherServlet by register ServletFilters on servletContext,

The order of execution is the order of calls, not the parent-child order. To explain it in detail by looking at the code,

```java
//in AbstractAnnotationConfigDispatcherServletInitializer.java
	@Override
	@Nullable
	protected WebApplicationContext createRootApplicationContext() {
		Class<?>[] configClasses = getRootConfigClasses();
		if (!ObjectUtils.isEmpty(configClasses)) {
			AnnotationConfigWebApplicationContext context = new AnnotationConfigWebApplicationContext();
			context.register(configClasses);
			return context;
		}
		else {
			return null;
		}
	}
```

1. `AbstractAnnotationConfigDispatcherServletInitializer` registers the ContextLoaderListener, including the settings of the class with the specific Annotation(`@Configuration`), and creates the ServletApplicationContext,

---

```java
//in AbstractContextLoaderInitializer.java
    @Override
	public void onStartup(ServletContext servletContext) throws ServletException {
		registerContextLoaderListener(servletContext);
	}

	protected void registerContextLoaderListener(ServletContext servletContext) {
		WebApplicationContext rootAppContext = createRootApplicationContext(); //Result of AbstractAnnotationConfigDispatcherServletInitializer's createRootApplicationContext()
		if (rootAppContext != null) {
			ContextLoaderListener listener = new ContextLoaderListener(rootAppContext);
			listener.setContextInitializers(getRootApplicationContextInitializers());
			servletContext.addListener(listener);
		}
		else {
			logger.debug("No ContextLoaderListener registered, as " +
					"createRootApplicationContext() did not return an application context");
		}
	}

```

2. `AbstractContextLoaderInitializer` registers the ContextLoaderListener,

---

```java
//in AbstractDispatcherServletInitializer
	@Override
	public void onStartup(ServletContext servletContext) throws ServletException {
		super.onStartup(servletContext); //It is equel to AbstractContextLoaderInitializer's onStartup method
		registerDispatcherServlet(servletContext);
	}

	protected void registerDispatcherServlet(ServletContext servletContext) {
		String servletName = getServletName();
		Assert.state(StringUtils.hasLength(servletName), "getServletName() must not return null or empty");

		WebApplicationContext servletAppContext = createServletApplicationContext();
		Assert.state(servletAppContext != null, "createServletApplicationContext() must not return null");
    ...
    }
```
# ⚡️ WebFlux

Spring WebFlux는 **논블로킹(Non-Blocking) 런타임에서 리액티브 프로그래밍**을 할 수 있도록 하는 새로운 Web 프레임워크이다. Spring 5에서 추가되었다.

<img src="https://user-images.githubusercontent.com/81006587/206968529-a61ff8bd-6d61-420d-97b5-e95bc2d2b061.png" height=300px>

지금까지 Spring MVC는 서블릿 컨테이너에 `Servlet API`를 기반으로 한 프레임워크이었지만, Spring WebFlux는 Servlet API를 사용하지 않고 **`Reactive Streams`와 그 구현체인 `Reactor`를 기반**으로 한 새로운 HTTP API로 구현되어 있다. 런타임으로서 Netty, Undertow(서블릿 컨테이너가 아닌 방향)와 같은 WAS로 NonBlocking을 사용할 수 있다. 또한 Servlet 3.1에서 도입된 NonBlocking API를 사용하여 Tomcat, Jetty 구현체를 사용할 수도 있다.

WebFlux를 사용할 때에는, Web MVC와 같이 <a href="./@Controller.md">**@Controller**</a> 어노테이션을 사용하여 기존과 같은 구현방식(하지만 다른 런타임)을 사용할 수도 있고, <a href="./RouterFunctions.md">**Router Functions**</a>라는 람다 기반의 새로운 Controller의 구현 방법을 사용해 비동기처리를 구현할 수도 있다.
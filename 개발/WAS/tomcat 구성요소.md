### tomcat-Catalina

Catalina는 Tomcat의 서블릿 컨테이너 이름이다.

자바 서블릿을 호스팅 하는 환경.

### tomcat-Coyote

톰캣에 TCP를 통한 프로토콜을 지원한다.

Coyote가 HTTP요청을 받으면 Catalina 서블릿 컨테이너에서 요청중에서 java웹 어플리케이션을 해석하는데, jsp에 관한 요청 일땐 Jasper가 처리한다.

### tomcat-Jasper

Jasper는 실제 JSP페이지의 요청을 처리하는 서블릿 엔진이다.

Jasper는 JSP 파일을 구문 분석하여 Java 코드로 컴파일한다. 런타임에 Jasper는 JSP 파일에 대한 변경 사항을 감지하고 재컴파일한다.

**Catalina** is Tomcat's servlet container. Catalina implements Sun Microsystems' specifications for servlet and JavaServer Pages (JSP). In Tomcat, a Realm element represents a "database" of usernames, passwords, and roles (similar to Unix groups) assigned to those users. Different implementations of Realm allow Catalina to be integrated into environments where such authentication information is already being created and maintained, and then use that information to implement Container Managed Security as described in the Servlet Specification

**Coyote** is a Connector component for Tomcat that supports the HTTP 1.1 protocol as a web server. This allows Catalina, nominally a Java Servlet or JSP container, to also act as a plain web server that serves local files as HTTP documents.

Coyote listens for incoming connections to the server on a specific TCP port and forwards the request to the Tomcat Engine to process the request and send back a response to the requesting client. Another Coyote Connector, Coyote JK, listens similarly but instead forwards its requests to another web server, such as Apache, using the JK protocol. This usually offers better performance.
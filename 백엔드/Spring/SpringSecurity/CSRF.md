
CSRF(Cross site Request forgery)는 웹 애플리케이션의 취약점 중 하나로, 이용자가 의도하지 않은 요청을 통한 공격을 의미한다. 즉, 인터넷 사용자가 자신의 의지와 무관하게 공격자가 의도한 특정 행위를 웹사이트의 요청하도록 하여 간접적으로 해킹하도록 하는 것이다.

<img src="https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcRMDFmY7IZJcsHpcFdGe_bb93zHmDjWvoLJ6wqilqYBg99Sc1mw">

따라서, 스프링 시큐리티는 CSRF 공격을 방지하기 위한 기능을 가지고있다.

@EnableWebSecurity 어노테이션을 붙이면 Referrer 검증, CSRF Token 사용 등의 기능이 활성화된다.

각 기능에 대해 간단하게 알아보자

- Referrer 검증

서버단에서 request의 referrer을 확인하여 domain이 일치하는지 검증하는 방법이다.

- Spring Security CSRF Token

임의의 토큰을 발급한 후 자원에 대한 변경 요청일 경우 Token 값을 확인한 후 클라이언트가 정상적인 요청을 보낸것인지 확인하는 방법이다. 만약 CSRF Token이 존재하지 않거나, 기존의 Token과 일치하지 않는 경우 4XX 상태코드를 반환하도록 한다. 
(타임리프 템플릿 및 jsp의 spring:form 태그를 사용한다면 기본적으로 csrf token을 넣어준다)

### 왜 비활성화할까?

CSRF(Cross-Site Request Forgery)는 "사이트 간 요청"이 발생하기 쉬운 웹에 대해 요청할 때 필요하다.

이러한 애플리케이션은 보통 템플릿 엔진(Thymeleaf, JSP)등을 사용하여 서버 측에서 전체 HTML을 생성하는 구조이다.

하지만 최신의 애플리케이션은 주로 REST API의 앤드포인트에 의존하며, HTTP 형식에 따라 무상태로 통신하도록 한다. 이러한 `REST API`는 서버쪽의 세션이나 브라우저 쿠키에 의존하지 않기 때문에 CSRF 공격의 대상이 될 수 없다.

따라서 API만 노출하는 `REST API`를 만드는 경우에는 CSRF를 비활성화해도 된다.
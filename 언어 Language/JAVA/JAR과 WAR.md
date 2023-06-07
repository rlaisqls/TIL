## JAR

- Java Archive의 약자
- 자바에서 사용되는 압축 파일의 한 형태로, 작동 방식은 흔히 자료를 압축하는 `.zip`과 유사.
- `.jar`는 압축을 따로 해제하지 않아도 JDK(Java Development Kit)에서 접근하여 사용이 가능
    
    (JDK에 포함되는 JRE(Java Runtime Environment)만 가지고도 실행이 가능)
    
- `.jar` 파일은 일반적으로 라이브러리, 자바 클래스 및 해당 리소스 파일(텍스트, 음성, 영상자료 ...), 속성 파일을 담는다.

## WAR

- WAR는 Web Application Archive의 약자로 웹 애플리케이션을 압축하고 배포하는데 사용되는 파일 형태. (`.war` 파일도 압축파일의 일종으로 `.jar`와 유사)
- WAR는 JSP, Servlet, Java Class, XML, 라이브러리, 정적 웹페이지(html ...) 및 웹 애플리케이션을 구성할 때 필요한 자원을 압축한 jar 파일이다.
- 배포 서술자라고 불리는 `web.xml`을 통해 경로를 반드시 지정해줘야 한다.
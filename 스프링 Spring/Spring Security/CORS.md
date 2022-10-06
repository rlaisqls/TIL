# 🔓 CORS

CORS란Cross-Origin Resource Sharing, 교차 출처 리소스 공유의 약자이다. 서로 출처가 다른 웹 애플리케이션에서 자원을 공유하는 것을 말한다.

보안상의 이유로 브라우저에서는 이 교차 출처 요청을 제한하는 경우가 많다. (포스트맨은 개발 도구이기 때문에 CORS에 신경쓰지 않는다.)

Spring Security에서도 기본적으로 CORS가 제한되어있다. 이때 특정 도메인, 또는 전체 도메인에서의 요청을 허용하려면 아래와 같이 설정해주면 된다.

```kotlin
@Bean
fun filterChain(httpSecurity: HttpSecurity): SecurityFilterChain {
        
    return httpSecurity
        .cors().and() // cors 설정을 적용하겠다는 뜻
        .csrf().disable()
        .formLogin().disable()
        .sessionManagement()
        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
        .and()
        .build();
}
    
```

```kotlin
@Configuration
public class CorsConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedHeaders("*")
                .allowedOrigins("http://localhost:3000"); //원하는 도메인, 포트를 적어준다
    }

}
```
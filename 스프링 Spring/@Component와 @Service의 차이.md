# @Component와 @Service의 차이

@Component는 스프링 빈 등록을 위한 기본 annotation이다.

@Service, @Controller, @Repository 등은 모두 @Component를 상속 받고 있다.

@Service와 @Component의 기능상의 차이는 없다.

하지만 비즈니스 레이어를 구분하기 위해 구분하여 사용하는 것이다.

나머지 어노테이션도 마찬가지이지만,  @Controller에는 @RequestMapping을 함께 사용할 수 있다는 차이점이 있다.
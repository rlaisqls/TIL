# 🍃 AOT

Spring AOT 엔진은 **빌드 시 스프링 애플리케이션을 분석하고 최적화**하는 도구이다. 또한 AOT 엔진은 GraalVM Native Configuration이 필요로 하는 `reflection configuration`을 생성해준다. 이것은 Spring native 실행 파일로 컴파일 하는데 사용되고 이후에 애플리케이션의 시작 시간과 메모리 사용량을 줄일 수 있게 한다.

그러한 변환은 Maven과 Gradle 스프링 AOT 플러그인에 의해 수행된다.

![image](https://user-images.githubusercontent.com/81006587/211175035-aa7eeab5-a2d2-4674-b912-97eb5470b816.png)

AOT 엔진은 최적화된 애플리케이션 컨텍스트와 애플리케이션을 위해 특별히 제작된 스프링 팩토리(Spring Boot 뒤의 플러그인 시스템)를 생성하기 위해 빌드 시 조건을 평가한다. 이를 통해 아래와 같은 효과를 볼 수 있다.

- 런타임시 필요한 스프링 인프라가 줄어든다.
- 런타임에 계산해야하는 조건이 감소한다.
- reflection의 방식을 줄이고, [프로그래밍 방식](https://github.com/rlaisqls/TIL/blob/main/%EC%8A%A4%ED%94%84%EB%A7%81%E2%80%85Spring/%EA%B8%B0%EB%B3%B8%EC%9B%90%EB%A6%AC/Programmatic%EA%B3%BC%E2%80%85Declarative.md)의 빈 등록을 사용한다.

AOT 엔진은 식별된 빈과 Spring 프로그래밍 모델, Spring Native에 있는 Native 힌트를 기반으로 애플리케이션을 돌리기 위해 필요한 `native configuration`을 추론한다.

![image](https://user-images.githubusercontent.com/81006587/211175291-f06ae320-bc0c-4748-8316-9642afa11ef8.png)


## 장점

### 적은 메모리 사용량 (Reduced Memory Footprint
)

AOT 엔진의 주요 장점은 더 정확한 네이티브 구성을 사용하고 reflection이 덜 필요하며 런타임에 스프링 인프라가 덜 필요하기 때문에 네이티브 실행 파일에 더 작은 메모리를 사용한다는 것이다.

Spring Native 0.11는 Spring Native 0.10에 비해 20%에서 26% 줄어든 매모리의 양만큼만 사용한다고 한다.

![image](https://user-images.githubusercontent.com/81006587/211175366-ba5d7914-6579-44f8-9bc4-81eb5030a9ce.png)


### 빠른 스타트업 (Faster Startup)

일부 처리가 런타임에서 빌드 시간으로 이동했기 때문에 스프링 네이티브 0.11에서 시작 시간이 0.10에 비해 16%에서 35% 더 빠르다. 이 마이너 버전 업데이트에서는 스프링 부트 및 스프링 프레임워크의 내부 아키텍처를 미세 조정할 수 없었기 때문에 여전히 개선의 여지가 있다.

![image](https://user-images.githubusercontent.com/81006587/211175390-795427ae-b029-4584-bd89-6495a628eda7.png)

### 향상된 호환성

AOT 엔진은 스프링 annotation 등의 다양한 유형을 분석하여, 실행 시 스프링이 수행하는 작업을 복제하지 않기 때문에 훨씬 더 정확하다. 대신에, 애플리케이션 컨텍스트를 (시작하지 않고) 빌드 시에 생성하고 내성적으로 만드는 새로운 프로세스를 시작한다. 이를 통해 Spring Framework가 런타임에 수행하고 빈 정의 수준에서 작동하는 부분 집합을 사용할 수 있으며, 이는 훨씬 더 정확하다.


## 단점 

### 런타임 유연성

빌드 시 이러한 최적화를 수행하면 일반 Spring Boot 자동 구성 모델보다 런타임 유연성이 떨어진다. 이미 컴파일된 Spring Boot 응용 프로그램을 실행하는 경우에도 응용 프로그램의 HTTP 포트 또는 로그 수준을 변경할 수 있지만, 프로파일을 사용하여 런타임에 새 빈을 추가할 수는 없다.

그렇기 때문에 JVM에서 AOT 모드는 선택 사항이다. 이는 필요에 따라 사용할 수 있는 최적화다. 하지만 네이티브(설계상 런타임에 훨씬 덜 동적임)에서는 필수이다. 또한 현재로서는 구축 시 조건이 평가되지만, 향후에는 대부분의 사용 사례에 적합하도록 유연성을 높일 것이라고 한다.

Spring native와 AOT, 버전별 정보에 대해서 더 공부해야겠다는 생각이 들었다. 정보 문서의 일부를 찾아 번역한 수준의 글이기 때문에 제대로 설명되지 않았거나 잘못 옮겨적은 부분이 있을 수 있다.

추후 내용을 추가하거나 수정할 예정이다.

https://spring.io/blog/2021/12/09/new-aot-engine-brings-spring-native-to-the-next-level
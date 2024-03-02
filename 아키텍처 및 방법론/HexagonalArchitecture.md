
> The  <a href="https://beyondxscratch.com/2017/08/19/hexagonal-architecture-the-practical-guide-for-a-clean-architecture">Hexagonal Architecture<a/> is a very powerful pattern. It helps you create more sustainable and better testable software by decoupling the business logic from the technical code.

만약 비즈니스 로직(Domain)이 특정 라이브러리에 의존성을 가지고 있다면 기술 스택을 업그레이드하고 바꿔야 할떄, 모든 비즈니스 로직과 infrastructure를 갈아 엎어야 할 것이다!

육각형 아키텍처(Hexagonal Architecture)는 그러한 문제를 해결하기 위해 **기술과 비지니스 로직 사이를 분리**하여 비지니스 로직이 기술에 구애받지 않고 동작할 수 있도록 하는 아키텍처이다.

### Hexagonal Architecture의 특징

<img height=300px src="https://beyondxscratch.com/wp-content/uploads/2020/08/overview-of-a-hexagonal-architecture.png">

위의 그림은 Hexagonal Architecture의 구조를 간단히 표현한 것이다.

특징은 다음과 같다.

1. 안의 비즈니스 로직과 밖의 infrastructure 두 부분으로 나눌 수 있다.

2. 종속성은 항상 infrastructure에서 Domain 내부로 이동한다. 이를 통해 외부 라이브러리, 기술과 비즈니스 도메인의 격리를 보장할 수 있게 된다.

3. 비즈니스 로직은 자기 자신을 제외하고 어디에도 의존하지 않는다.

### Hexagonal Architecture에서의 Interface 사용

<img height=300px src="https://beyondxscratch.com/wp-content/uploads/2020/08/implementation-of-the-hexagonal-architecture-1024x554.png">

육각형의 독립성을 보장하기 위해서는 의존성의 방향이 역전되어야 한다.

따라서 특정 기술에 종속되어있는 코드는 interface를 매개체로 분리하고, Domain에서는 interface만을 사용하여 그 구현 방식이 어떻냐에 관계 없이 로직을 수행할 수 있다.

이러한 interface는 육각형의 일부로 취급되며, 2가지 종류로 나눌 수 있다.

- **API(application programming interface)**:<br>도메인에 질의하기 위해 필요한 인터페이스이다. 우리가 아는 그 API가 맞다.
- **SPI(Service Provider Interface)**:<br>Third party에서 정보를 구해올 때 도메인에 필요한 인터페이스들이다. 상황에 따라 Domain에서 이걸 구현할 수도 있다.

### 정리

Hexagonal Architecture를 사용하면 다음과 같은 이점을 얻을 수 있다.

1. 도메인이 기술과 무관하므로 비즈니스에 영향을 주지 않고 스택을 변경할 수 있다.
2. 그리고 기능에 대한 테스트를 보다 쉽게 만들 수 있다.
3. 도메인에서 시작하여 기능 개발에 집중하고, 기술 구현에 대한 선택을 연기할 수 있다.

하지만 당연히 육각형 아키텍처기 모든 상황에 적합하지는 않다. trade off를 가지며, 다른 문제를 야기할수도 있고, 러닝 커브가 높다고 느낄수도 있다. 하지만 추후의 기술 변경시의 유연함을 지키기 위해서 육각형 아키텍처는 매력적인 선택지이다!

### 느낀점

특정 기술에 대해 구현할때 해당 코드를 Interface, Facade 혹은 Util로 분리하는 구조를 많이 봤고, 사용도 꽤 해봤는데 이게 육각형 아키텍처와 관련이 있다는 것은 처음 알게 되었다.

그리고 Hexagonal Architecture도 그렇고 아키텍처들은 SOLID, Ioc 등의 기본적인 원리를 응용한 경우가 많은 것 같다. 대부분 지향점이 비슷하다 보니 코드를 보고 어떤 아키텍처다 하고 확실히 구분하는게 조금 어려운 것 같다. (디자인 패턴을 공부할떄도 비슷한 기분이 들었다.)

아키텍처는 "다 비슷비슷한 그런거"를 모두가 납득할 수 있도록 설명하고 명료하게 정리하여 정형화하여 프로젝트에 적용할 수 있도록 하는 것이 목표가 아닐까 하는 생각이 든다. 그러한 원리들을 코드에 담을 특정한 방법을 구체적으로 정해야, 모든 팀원들이 그에 맞춰 하나의 프로젝트를 만들어나갈 수 있으니까 말이다.

더 좋은 코드를 만들고, 설명할 수 있는 사람이 되기 위해 더 노력해야겠다..!

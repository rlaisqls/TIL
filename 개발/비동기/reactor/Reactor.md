# Reactor

Reactor란 Pivotal의 오픈소스 프로젝트로, JVM 환경에서 동작하는 non-blocking reactive 라이브러리로서 non-blocking IPC(Inter-Process Commumication)을 지원한다.

## Reactive Programing

> 반응형 프로그래밍(reactive programming)은 데이터 스트림과 변화의 전파와 관련된 선언적 프로그래밍 패러다임이다. 이 패러다임을 사용하면 정적 또는 동적 데이터 스트림을 쉽게 표현할 수 있다. In computing, reactive programming is a declarative programming paradigm concerned with data streams and the propagation of change. With this paradigm, it's possible to express static (e.g., arrays) or dynamic (e.g., event emitters) data streams with ease.

Reactive Programming 패러다임은 객체지향 언어에서는 보통 옵저버 패턴으로 표현되며 Reactive Stream은 Publisher와 Subscriber 구조로 되어있다.

스트림에서 새로 사용 가능한 값이 올 때 Publisher는 Subscriber에게 알려줄 수 있다 (push라고도 한다). 이렇게 Publisher가 Push 해주는 것은 Reactive의 핵심이다. 그리고 Push된 값을 적용시키는 연산자를 명령형 대신 선언형으로 표현하는데, Reactive Programming에서는 값을 조작시키는 것애 대한 제어 흐름을 나타내는 것 보다는 연산의 논리를 표현하는 것에 초점을 두기 때문이다.

그리고 Publisher 값을 푸쉬하는 것 외에도 에러가 발생하거나 정상적으로 완료했을 때에 대한 핸들링 로직도 정의할 수 있다. Publisher는 Subscriber에게 새로운 값을 푸쉬할 수도 있지만 에러를 보내거나 더 이상 보낼 데이터가 없을 때 완료 신호를 보낼 수도 있다. 에러나 완료 신호를 받는다면 시퀀스는 종료된다. 이러한 특성 때문에 Reactive Stream은 다양한 스트림을 표현할 수 있다.

- 값이 없는 스트림 (바로 완료 신호를 줌)
- 오직 하나의 값(하나의 값을 주고 완료 신호)이 있는 스트림
- 유한개의 값(여러 개 보내고 완료 신호)이 있는 스트림
- 무한한(완료 신호를 주지 않는 경우) 스트림

https://tech.kakao.com/2018/05/29/reactor-programming/

## 목표

Reactor는 다음과 같은 목표를 이루기 위해 노력한다.

### Composability and Readability

Composability는 이전 task의 결과를 사용하여 그 결과를 다음 task에 사용할 수 있도록 하는 여러가지 비동기 task들을 조율하는 능력을 의미한다. 그리고 이 몇가지 task들을 fork-join 하는 형식으로 실행시킬 수 있다. 그리고 비동기 task들을 개별적인 컴포넌트로써 재사용할 수 있다.

여러 task들을 조율하는 능력은 코드의 가독성과 유지능력과 밀접한 관계를 이룬다. 비동기 프로세스의 개수와 복잡성이 모두 증가하면 코드를 읽기 어려워지고, 유지하는데 어려움이 발생한다. (콜백 지옥이라거나..) Reactor는 코드로 추상 프로세스를 구성할 수 있고, 모든 task들이 동일한 수준으로 유지될 수 있도록 풍부한 구성 옵션들을 제공한다.

### The Assembly Line Analogy

Reactor를 사용해 짜여진 코드를 실행하는 것은 데이터를 조립라인에 통과시키는 것으로 생각할 수 있다. 최초의 raw data는 source(Publisher)로 들어가서 처리가 완료된 데이터는 consumer(Subscriber)로 전달(push)된다.

최초의 데이터는 여러가지 변형과정을 거치거나 여러 조각으로 분해되거나 여러 조각을 함께 모으는 작업을 거칠 수도 있다. 하나의 지점에 결함이나 문제가 발생하는 경우에 문제가 발생한 워크스테이션에서 데이터의 흐름을 제한하기 위해 upstream에 신호를 보낼 수도 있다.

### Operator

Reactor에서 Operator는 조립라인의 워크스테이션이다. 각 Operator는 Publisher에게 데이터 처리 과정을 더하고 이전 스텝의 Publisher를 새로운 인스턴스로 감싼다. 따라서 전체의 체인들은 연결되어 데이터는 처음 Publisher에서 시작되고, 각 링크에 의해 변형되어 체인 아래로 내려간다. 결국 Subscriber는 모든 체인을 통과하고 나온 결과를 받는다. (여기서 주의해야 할 점은 Subscriber가 Publisher를 구독하지 않으면 아무 일도 발생하지 않는다는 것이다.)

Reactive Stream 사양은 operator를 지정하지 않지만, Reactor와 같은 reactive 라이브러리의 장점 중 하나는 operator가 제공하는 풍부한 표현 방식이다. 이런 표현방식은 단순 변환과 필터링을 포함하여 여러 복잡한 orchestration과 오류 처리 등 여러가지를 표현할 수 있다.

### Nothing Happens Until You subscribe()

Reactor에서 Publisher 체인을 작성하면 그냥 단순히 비동기 프로세스를 만들어 놓을 뿐, Publisher를 선언만 했을 때는 기본적으로 데이터가 Publisher를 통과하여 처리되지 않는다. Subscriber가 구독을 해야 Publisher를 Subscriber에 연결하여 전체 chain에서 데이터 흐름을 유발한다. 이는 upstream으로 전파되는 subscriber의 단일 요청 신호에 의해 내부적으로 처리되고, 다시 Publisher에게 전달된다.

### Backpressure

upstream에 신호를 전파하는 것은 backpressure를 개발하여 사용할 수 있는데, backpressure는 조립라인에서 워크스테이션이 upstream 워크스테이션보다 더 느리게 처리될 때 전송되는 피드백 신호와 비슷하다.

Subscriber가 unbound mode에서 작업하고 source가 도달 가능한 가장 빠른 속도로 푸쉬하도록 하거나 요청 메커니즘을 사용하여 약 n개의 요소를 처리할 준비가 되어있다는 신호를 source에게 보낼 수 있는데, Reactive Stream 스펙에서 정의되는 실제 메커니즘은 이와 유사하다.

중간 operator는 전송 중인 요청을 변경할 수도 있다. 예를 들어, 데이터를 10개 묶음으로 그룹화하는 `buffer operator`를 생각해보자. subscriber가 하나의 버퍼를 요청한다면, source가 10개의 데이터를 생산하는 것이 허용된다. 일부 oprator는 `request(1)` round-trip을 방지하고 요청되기 전에 요소를 생산하는 것이 비용이 많이 들지 않으면 prefetching 전략을 구현한다.

이는 push 모델을 **push-pull 하이브리드 모델**로 변형하는데, 요소가 이미 사용 가능하다면 downstream은 n개의 요소를 upstream으로부터 받아올 수 있다. 하지만, 요소가 당장 사용가능하지 않다면 생산될 때 마다 upstream에서 요소들을 푸쉬 해준다.

### Hot vs Cold

Rx Reactive 라이브러리는 Hot과 Cold라는 두 가지의 리액티브 시퀀스를 구별한다. 이러한 구분은 주로 reactive stream이 subscriber에게 어떻게 반응하는지와 관련된다.

- Cold sequence는 각 subscriber에게 데이터 소스를 포함하여 시퀀스가 새로 시작된다. 예를 들어, source가 HTTP 통신을 사용한다면, 새로운 HTTP 요청이 각 구독마다 새로 만들어진다.
- Hot sequence는 각 subscriber에 대해 시퀀스가 처음부터 시작되지 않는다. 대신에, 나중에 들어온 subscriber는 구독 후 방출되는 신호를 수신한다. 그러나, Hot reactive stream은 전체 또는 일부 방출된 이력을 캐싱하거나 재현할 수 있다. Hot sequence는 아무도 구독하지 않은 경우에도 Hot sequence가 방출될 수 있다.

source가 생산해내는 데이터의 특징에 따라 Hot과 Cold 중 어떤걸 사용해야 할지 생각을 하면 좋을 것 같다.
 
---
참고
- https://projectreactor.io/
- https://github.com/reactor/reactor-core
- https://projectreactor.io/docs/core/3.5.6-SNAPSHOT/reference/index.html

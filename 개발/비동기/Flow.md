
coroutine의 Flow는 데이터 스트림이며, 코루틴 상에서 리액티브 프로그래밍을 지원하기 위한 구성요소이다.

`kotlinx-coroutines-core-jvm` 라이브러리의 `kotlinx.coroutines.flow` 패키지에 인터페이스로 정의되어있다.

```kotlin
public interface Flow<out T> {
    public suspend fun collect(collector: FlowCollector<T>)
}
```

Flow 생성시 연산자(`map`, `filter`, `take`, `zip` 등)들이 추가되면 Flow (SafeFlow) 의 형태로 체인을 형성하게 되고 `collect()` 호출 시 루트 스트림 (최상위 업스트림) 까지 `collect()`가 연쇄적으로 호출되어 데이터가 리프 스트림(최하위 다운스트림)까지 전달되게 된다. 모든 flow operation은 같은 코루틴 안에서 순차적으로 실행된다.(Exception이 발생한 경우에 비동기적으로 `buffer`나 `flatMapMerge`로 전달하는 경우도 있다.)

가장 많이 쓰이는 terminal operator는 collect이다.

```kotlin
try {
    flow.collect { value ->
        println("Received $value")
    }
} catch (e: Exception) {
    println("The flow has thrown an exception: $e")
}
```

이 과정에서 collect() 대신 launchIn(CoroutineScope) 를 사용하여 다음과 같이 특정 코루틴 스코프에서 실행하도록 하고, onEach 를 통해 수집할 수도 있지만, 이는 현재 스코프에서 새로운 코루틴을 실행하여 Flow 를 구독하는 헬퍼일 뿐 기본적인 내용은 변하지 않는다.

가장 많이 쓰이는 terminal operator는 collect이다.

```kotlin
try {
    flow.collect { value ->
        println("Received $value")
    }
} catch (e: Exception) {
    println("The flow has thrown an exception: $e")
}
```

flow에서 중간 연산자는 flow에서 코드를 실행하지 않고 함수 자체를 일시 중단하지 않는다. 이들은 향후 실행과 신속한 복귀를 위해 일련의 작업을 설정할 뿐이다. 이것을 cold flow 프로퍼티라고도 부른다.

flow의 Terminal operator는 `collect`, `single`, `reduce`, `toList` 등과 같은 일시중단 함수이거나, 지정된 scope에서 flow 수집을 시작하는 `leanchIn` operator이다. 이는 upstream flow에 적용되며, 모든 operation의 실행을 trigger한다. flow를 실행한다는 것을 **flow를 collecting한다**고 얘기하기도 하며 그것은 실제로 blocking없이 항상 일시 중단하는 방식으로 수행된다. Terminal operator는 전체 upstream에 속한 연산자들의 성공 여부(Exception이 throw 되었는지)에 따라 정상적으로 또는 예외적으로 완료된다.

`Flow` interface는 해당 flow가 같은 코드 내에서 flow가 반복적으로 collected 되거나 트리거 되는 cold stream인지, 혹은 각각 다른 running source에서 다른 값을 낼 수 있는 hot stream인지에 대한 정보를 전혀 가지고 있지 않는다. 보통 flow는 cold stream를 나타내지만 [SharedFlow](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-shared-flow/index.html)라는 서브타입은 hot stream을 나타낸다. 추가적으로, flow는 `stateIn`이나 `shareIn` 연산자를 통해 hot stream으로 변환되거나, produceIn 연산자를 통해 hot channel로 변환될 수 있다.

## Flow builder

flow를 만드는 방법으로는 아래와 같은 것들이 있다.

- `flowOf(...)` : 고정된 값 목록으로부터 flow를 만든다.
- `asFlow()` : List 등 타입을 가진 객체를 flow로 바꾼다.
- `flow { ... }` : 빌더 함수로 순차적 호출에서 emit 함수로 임의의 flow를 구성한다.
- `channelFlow { .. }` : 빌더 함수를 통해 잠재적으로 동시 호출에서 send 함수로의 임의의 flow를 구성한다.
- `MutableStateFlow` 및 `MutableSharedFlow`는 해당 생성자 함수를 정의하여 직접 업데이트 할 수 있는 hot flow를 생성한다.

## Flow constraints

Flow 인터페이스의 모든 구현은 아래에 자세히 설명된 두 가지 주요 속성을 준수해야 한다.

- context 보존
- Exception transparency 

이런 특성은 flow를 사용하여 코드에 대한 로컬 판단을 수행하고 업스트림 flow emitter가 다운 스트림 flow collector와 별도로 개발 할 수 있는 방식으로 코드를 모듈화하는 기능을 보장한다. flow의 사용자는 flow에서 사용하는 업스트림의 구현 세부 정보를 알 필요가 없다.

## Context preservation

flow는 context 보존 특성을 가지고 있다. 즉, 자체적으로 실행하는 context를 캡슐화하고 다운스트림에서 전파하거나 누출하지 않으므로 특정 변환 또는 터미널 연산자의 실행 context에 대한 판단을 간단하게 만든다.

flow의 context를 변경하는 유일한 방법은 업스트림 context를 변경하는 `flowOn` 연산자이다.


```kotlin
val flowA = flowOf(1, 2, 3)
    .map { it + 1 } // ctxA에서 실행된다.
    .flowOn(ctxA) // 업스트림 context 변경

// 이제 context 보존 특성을 가진 flow가 있다. - 어딘가에서 실행되지만 이 정보는 flow 자체에 캡슐화된다.

val filtered = flowA // ctxA는 flowA에서 캡슐화된다.
   .filter { it == 3 } // 아직 context가 없는 순수 연산자

withContext(Dispatchers.Main) {
    // 캡슐화되지 않은 모든 연산자는 Main에서 실행된다.
    val result = filtered.single()
    myUi.text = result
}
```

구현의 관점에서 모든 flow 구현은 동일한 코루틴에서만 방출되어야 한다는 것을 의미한다. 이 제약 조건은 기본 flow 빌더에 의해 효과적으로 적용되며, flow의 구현이 어떤 코루틴을 시작하지 않는 경우에는 빌더를 사용해야 한다. 이를 구현하면 대부분의 개발 실수를 방지할 수 있다.

```kotlin
val myFlow = flow {     
  // GlobalScope.launch {  // 금지됨     
  // launch (Dispatchers.IO) {  // 금지됨     
  // withContext(CoroutineName( "myFlow")) // 금지됨     
  emit(1) // OK    
  coroutineScope {         
    emit(2) // OK - 여전히 동일한 코루틴     
  }  
}
```

flow의 수집과 방출이 여러 코루틴으로 분리되어야하는 경우 channelFlow를 사용할 수 있다. 모든 context 보존 작업을 캡슐화하여 구현의 세부 사항이 아닌 도메인 별 문제에 집중할 수 있다. channelFlow 내에서 코루틴 빌더를 조합하여 사용할 수 있다.

동시에 emit 되거나 context jump가 발생하는 경우가 없다고 확신하는 경우, flow 빌더 대신 `coroutineScope` 또는 `supervisorScope`와 함께 사용하여 성능을 개선할 수 있다.

## Exception transparency

flow 구현은 다운스트림 flow에서 발생하는 예외를 포착하거나 처리하지 않는다. 구현 관점에서 보면 emit 및 emitAll의 호출이 `try { .. } catch { .. }` 블록으로 래핑되지 않아야 한다는 것을 의미한다. flow의 예외 처리는 catch 연산자로 수행되어야 하며 이 연산자는 모든 다운스트림에게 예외를 전달하는 동안 업스트림 flow에서 발생하는 예외만 catch 하도록 설계되었다. 마찬가지로 collect와 같은 터미널 연산자는 코드 또는 업스트림 flow에서 발생하는 처리되지 않는 예외를 발생시킨다.

```kotlin
flow { emitData() } 
    .map { computeOne(it) } 
    .catch {...} // emitData 및 computeOne에서 예외 포착 
    .map { computeTwo(it) } 
    .collect { process(it) } // 다음에서 예외 발생 처리 및 computeTwo
```

finally 블록에 대한 대체로 `onCompletion` 연산자에도 동일한 추론을 적용할 수 있다.

예외 투명성의 요구 사항을 준수하지 않으면 `collect { .. }`의 예외로 인하여 코드에 대한 추론을 어렵게 만드는 이상한 동작이 발생할 수 있다. 왜냐하면 exception이 업스트림 flow에 의해 어떻게든 “caugth”되어 로컬 추론 능력을 제한할 수 있기 때문이다.

flow는 런타임에 **예외 투명성**을 적용하여 이전 시도에서 예외가 발생된 경우 값을 emit하려는 모든 시도에서 `IllegalStateException`을 던진다.

## Reactive streams

Flow는 Reactive Stream과 호환되므로 `Flow.asPublisher` 및 `Publisher.asFlow`를 사용하여 `kotlin-coroutines-reactive` 모듈의 리액티브 스트림과 안전하게 상호 작용할 수 있다.

---
참고
- https://kotlin.github.io/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-flow/
- https://myungpyo.medium.com/%EC%BD%94%EB%A3%A8%ED%8B%B4-%ED%94%8C%EB%A1%9C%EC%9A%B0-%EB%82%B4%EB%B6%80-%EC%82%B4%ED%8E%B4%EB%B3%B4%EA%B8%B0-eb4d9dfebe43
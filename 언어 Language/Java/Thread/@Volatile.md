# @Volatile

변수 선언시에 자바의 volatile 키워드 또는 코틀린의 `@Volatile` 애노테이션을 지정해줄 수 있다. 사전적으론 ‘휘발성의’라는 뜻을 가지며, 변수 선언시 volatile을 지정하면 값을 메인 메모리에만 적재하게 된다.

> Annotate INSTANCE with @Volatile. The value of a volatile variable will never be cached, and all writes and reads will be done to and from the main memory. This helps make sure the value of INSTANCE is always up-to-date and the same to all execution threads. It means that changes made by one thread to INSTANCE are visible to all other threads immediately, and you don't get a situation where, say, two threads each update the same entity in a cache, which would create a problem.

volatile 변수를 사용하지 않는 일반적인 경우는 내부적으로 성능 향상을 위해 메인 메모리로부터 읽어온 값을 CPU 캐시에 저장한다. 하지만 멀티쓰레드 애플리케이션에서는 각 쓰레드를 통해 CPU에 캐싱한 값이 서로 다를 수 있다 (CPU 캐시1 값 ≠ CPU 캐시2 값). 예제코드를 살펴보자.

다음과 같은 Thread를 확장한 서브 클래스가 있다고 가정하자.

```kotlin
class Worker : Thread() {
    var stop = false
    override fun run() {
        super.run()
        while(!stop){ }
    }
}
````

이 Worker 클래스는 단순히 무한루프에 빠지는 쓰레드이다. 하지만 stop이 true가 되는 순간 루프에서 빠져나와 작업을 마칠 수 있게되고, 쓰레드는 종료된다.

이제 Worker 클래스를 사용한 다음 예제코드를 살펴보자.

```kotlin
@Test
fun `Worker test`(){
    repeat(3){
        val worker = Worker() // worker 쓰레드 생성
        worker.start() // worker 쓰레드 시작
        Thread.sleep(100) // 메인 쓰레드 잠시 수면
        println("stop을 true로 변경")
        worker.stop = true // worker쓰레드의 stop 플래그 변경
        worker.join() // worker 쓰레드가 끝날 때까지 메인쓰레드에서 대기
    }
    println("작업 종료")
}
```

이 코드를 실행했을 때 직관적으로 생각할 수 있는 출력 메시지는 아마 다음과 같을 것이다.

```
stop을 true로 변경
stop을 true로 변경
stop을 true로 변경
작업 종료
```

하지만 실제로는 그렇지 않다. “stop을 true로 변경” 메시지만 남긴 채 프로그램이 멈추게 된다.

그 이유는 Worker 쓰레드가 ‘stop’이란 값을 계속 참조해야 하기 때문에 성능을 위해 CPU 캐시에 담아두게 되는데, 이때 메인쓰레드에서 접근하는 worker.stop의 값은 메인 메모리로부터 참조하는 값이므로 서로 다른 두개의 영역에 값이 존재한다.

메인스레드에서 stop을 true로 바꿔도 Worker 쓰레드가 참조하는 stop은 CPU 캐시 영역에 저장된 값이므로 여전히 stop은 false이다. 그렇기 때문에 Worker 쓰레드는 루프를 빠져나오지 못하고 프로그램은 멈추게 된다.

이제 코드를 약간 수정해보자. 수정은 매우 간단하다. @Volatile 만 붙이면 된다.

```kotlin
class Worker : Thread() {
    @Volatile
    var stop = false
    override fun run() {
        super.run()
        while(!stop){ }
    }
}
```
이제 아까 테스트 코드를 다시 수행하면 기대한 결과를 얻을 수 있다.

### 결론

`@Volatile`을 붙이면 변수의 값이 메인 메모리에만 저장되며, 멀티 쓰레드 환경에서 메인 메모리의 값을 참조하므로 변수 값 불일치 문제를 해결할 수 있게된다. 다만 CPU캐시를 참조하는 것보다 메인메모리를 참조하는 것이 더 느리므로, 성능은 떨어질 수 밖에 없다.
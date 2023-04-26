# cold stream과 hot stream

flow에서 사용되는 개념인 cold stream과 hot stream에 대해 알아보고, 서로 비교해보자.

우선 observable과 producer의 개념에 대해 알아보자.

### observable

Observable은 observer를 producer에 연결해주는 함수이다. obserable을 함수처럼 call하면 observer에 값이 전달된다고 생각하면 된다. 

### producer

producer는 obserable의 실행 값이다. producer는 web socket이 될 수도 있고, DOM event가 될 수 있고, iterator도 될 수 있다. 보통은 `observer.next(value)`를 통해 값을 받는 것이 producer라고 생각할 수 있다.

## cold stream

cold stream은 스트림의 구독자마다 개별 스트림이 생성/시작되어 데이터를 전달하며 그렇기에 스트림 생성 후 구독하지 않으면 어떤 연산도 발생하지 않는다.

producer가 구독하는 동안 만들어지고 동작한다. Cold 스크림에는 구독자가 오로지 1명 뿐이며, 해당 구독자에게만 값을 내보낸다. (따라서 Cold 스트림에는 unicast 매커니즘이 있다고 볼 수 있다.)

누군가가 구독할 때만 값의 방출이 시작되기 때문에 lazy한 특성이 있다고도 얘기할 수 있다.

아래는 webSocket을 listen하는 cold stream의 예시이다.

```kotlin
// COLD
const source = new Observable((observer) => {
  const socket = new WebSocket('ws://someurl');
  socket.addEventListener('message', (e) => observer.next(e));
  return () => socket.close();
});
```

일부 값을 생성하기 위해 실행될 코드 라인은 호출하는 주체에 따라 달라지지 않고, 모든 구독자에 대해 동일하다는 점에 유의해야 한다.

## Hot Stream

스트림이 생성되면 바로 연산이 시작되고 데이터를 전달하며 다수의 구독자가 동일한 스트림에서 데이터를 전달 받을 수 있다.

Hot 스트림은 0개 이상의 구독자를 가질 수 있으며 동시에 모든 구독자에게 값을 내보낸다. 따라서 Hot 스트림에는 multicast 매커니즘이 있다고 볼 수 있다.

아래는 webSocket을 listen하는 hot stream의 예시이다.

```kotlin
const socket = new WebSocket('ws://someurl');
const source = new Observable((observer) => {
  socket.addEventListener('message', (e) => observer.next(e));
});
```

Cold stream을 쓰는 경우 producer 객체를 매번 생성해야하기 때문에 낭비가 생길 수 있다. 그렇기 때문에 상황에 맞게 producer를 묶어서 실행해야하는 경우 hot stream, 그렇지 않은 경우에는 cold stream을 선택하여 사용해야 한다.

필요하다면 각 라이브러리별로 cold stream을 hot으로 만드는 방법이 있으니 고려해보면 좋다.

```js
function makeHot(cold) {
  const subject = new Subject();
  cold.subscribe(subject);
  return new Observable((observer) => subject.subscribe(observer));
}
```

---

참고
- https://luukgruijs.medium.com/understanding-hot-vs-cold-observables-62d04cf92e03
- https://myungpyo.medium.com/%EC%BD%94%EB%A3%A8%ED%8B%B4-%ED%94%8C%EB%A1%9C%EC%9A%B0-%EB%82%B4%EB%B6%80-%EC%82%B4%ED%8E%B4%EB%B3%B4%EA%B8%B0-eb4d9dfebe43
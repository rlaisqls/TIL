# Lexical Scope와 Closure

### Lexical scope

프로그래밍에서 scope란 변수의 유효범위를 나타내는 용어이다. JavaScript는 **함수를 어디서 선언하였는지에 따라 상위스코프를 결정**하는 Lexical Scope를 따르고 있다. 다른 말로, 정적 스코프(Static scope)라 부르기도 한다.

```js
var num = 1;

function a() {
  var num = 10;
  b();
}

function b() {
  console.log(num);
}

a();
```

위 예제를 살펴보자. a 함수 내에서 호출하는 b 함수에서 참조하는 num은, 전역의 num을 참조하는 것이기 때문에 1이 출력된다.

### Closure

클로저는 주변 상태(어휘적 환경)에 대한 참조와 함께 묶인 함수의 조합이다. 즉, 클로저는 내부 함수에서 외부 함수의 범위에 대한 접근을 제공한다. JavaScript에서 클로저는 함수 생성 시 함수가 생성될 때마다 생성된다.


```js
function makeFunc() {
  const name = "Mozilla";
  function displayName() {
    console.log(name);
  }
  return displayName;
}

const myFunc = makeFunc();
myFunc();
```

이 코드는 JS에서 정상적으로 동작한다. 어찌보면 당연하게 생각될 수도 있지만, 몇몇 프로그래밍 언어에서, 함수 안의 지역 변수들은 그 함수가 처리되는 동안에만 존재하기도 한다. 그러나 JS는 클로저를 형성하기 때문에 클로저가 생성된 시점의 유효 범위 내에 있는 모든 지역 변수에 접근할 수 있게 되는 것이다.

클로저를 이용하면 아래와 같은 코드를 작성할 수도 있다.

```js
function makeAdder(x) {
  return function (y) {
    return x + y;
  };
}

const add5 = makeAdder(5);
const add10 = makeAdder(10);

console.log(add5(2)); // 7
console.log(add10(2)); // 12
```

x를 받아서 새 함수를 반환하는 함수 `makeAdder(x)`를 정의하고, 그 함수를 사용해 각각 5, 10을 더하는 함수를 만들어 활용하는 코드이다.

`add5`와 `add10`은 둘 다 클로저이다. 둘은 같은 함수 본문 정의를 공유하지만, 서로 다른 맥락(어휘)적 환경을 저장한다. 함수 실행 시 `add5`의 맥락에서, 클로저 내부의 x는 5 이지만, `add10`의 맥락에서 x는 10이 된다.

---
참고
- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Closures
- https://poiemaweb.com/js-closure

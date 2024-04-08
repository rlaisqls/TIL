
- setInterval은 일정 시간마다 작업을 수행하는 메서드다. 
- 주기적으로 카운트를 증가시키기 위해 이런 코드를 작성할 수 있다.
  
```js
function Counter() {
  let [count, setCount] = useState(0);

  useEffect(() => {
    let id = setInterval(() => {
      setCount(count + 1);
    }, 1000);
    return () => clearInterval(id);
  }, []);

  return <h1>{count}</h1>;
}

const rootElement = document.getElementById("root");
ReactDOM.render(<Counter />, rootElement);
```

- 1초마다 +1이 되어야 할 것 같지만, 이 코드에서 count는 계속 1에서 머문다.
- 이렇게 되는 이유는 `useEffect`가 첫 render에 count를 capture하기 때문이다. 
  - `setInterval` 메소드도 브라우저에서 제공하는 Web API 중 하나이기 때문에 호출되면 바로 실행되지 않고 등록한 delay 시간을 기다렸다가 Callback Queue에 쌓인다. 그리고 Call Stack이 비면 그때 실행된다. 그리고 실행된 `setInterval`은 한 번 호출된 후에 바로 종료된다. 이제부터 `setInterval`이 주기적으로 실행하라고 남겨놓은 `setCount` 함수가 주기적으로 실행된다. 
  - Closure에서 외부 함수가 종료되면 내부 함수가 그 함수의 값을 기억하는 특성이 있어 문제가 발생한다.
  - `setInterval`은 종료되었지만, `setInterval`의 내부 함수인 `setCount`가 실행될 때마다 그 초기값이었던 0을 기억하고 계속 1을 더하는 것이다. 다시 실행될 때에도 마찬가지다. `setCount`가 기억하는 count는 계속 0이기때문에, 값이 계속 1이 된다.

### 해결 방법

- count가 우리가 원하는 대로 동작하려면, count가 0에서 1이 되고, 1이 된 것을 기억했다가 다시 +1을 해서 2가 되어야 한다. 즉, 바뀌기 전의 state를 기억해야한다. 
- 이를 해결하기 위한 다양한 방법들이 있지만, 가장 쉬운 방법은 `setState`에 callback 함수를 넘겨주는 것이다. `setState`에서는 이전의 state를 보장할 수 있는 방법을 제공하고 있다. `setState`에 callback 함수를 넘겨주면 해결된다. 즉, `setCount((previousCount) => previousCount + 1)`을 하게 되면 문제가 해결된다.
  
- 이런 방법을 통해 문제를 당장 해결하더라도 `setInterval`을 React에서 사용하는 것이 불편한 이유가 한가지 존재한다. react의 lifecycle과 다소 벗어난 행동을 한다는 것이다. state가 바뀌면 React는 리렌더링을 하게 되는데, `setInterval`은 렌더와 관계없이 계속 살아남아있는다. 
- React는 리렌더링을 하면서 이전의 render된 내용들을 다 잊고 새로 그리게 되는데, `setInterval`은 그렇지 않다. Timer를 새로 설정하지 않는 이상 계속 이전의 내용(props나 state)들을 기억하고 있다. 
- 이런 문제점을 해결하기 위해 아래와 같은 코드를 사용할 수 있다.
  
```js
import { useState, useEffect, useRef } from 'react';

function useInterval(callback, delay) {
  const savedCallback = useRef(); // 최근에 들어온 callback을 저장할 ref를 하나 만든다.

  useEffect(() => {
    savedCallback.current = callback; // callback이 바뀔 때마다 ref를 업데이트 해준다.
  }, [callback]);

  useEffect(() => {
    function tick() {
      savedCallback.current(); // tick이 실행되면 callback 함수를 실행시킨다.
    }
    if (delay !== null) { // 만약 delay가 null이 아니라면 
      let id = setInterval(tick, delay); // delay에 맞추어 interval을 새로 실행시킨다.
      return () => clearInterval(id); // unmount될 때 clearInterval을 해준다.
    }
  }, [delay]); // delay가 바뀔 때마다 새로 실행된다.
}
```

- 이 Hook은 interval을 set하고 unmount 되기 전에 clearInterval을 해준다. useRef를 사용해 setInterval이 React의 Lifecycle과 함께 동작하도록 만들어주었다. 

### savedCallback을 저장할 때에 state 대신 ref를 사용한 이유

- `useRef`와 `useState`의 가장 큰 차이점은 리렌더링의 여부이다. 
- `setState`로 State의 값을 바꾸어주면 함수가 새로 실행되면서 리렌더링이 일어난다. 반면 `ref.current`에는 새로운 값을 넣어주더라도 리렌더링이 일어나지 않는다.
- 만약 위의 코드에서 아래의 예시 코드처럼 `useState`을 사용했다면, `useEffect` 안에서 `savedCallback`을 새로 set할 때 리렌더링이 일어나면서 아래에 주석으로 남겨놓은 문제점이 일어나게된다.

```js
import { useEffect, useState } from 'react';

const useInterval = (callback, delay) => {
  const [savedCallback, setSavedCallback] = useState(null) // useState사용

  // callback이 바뀔 때마다 실행
  // 첫 실행에 callback이 한 번 들어옴 -> 리렌더링 -> 다시 들어옴 -> 리렌더링 -> .. 무한 반복
  // 원래의 의도는 callback이 새로 들어오면 그 callback을 저장해두고 아래의 setInterval을 다시 실행해주려는 의도
  useEffect(() => {
    setSavedCallback(callback);
  }, [callback]);
  
  // mount가 끝나고 1번 일어남
  // 맨 처음 mount가 끝나고 savedCallback은 null이기 때문에 setInterval의 executeCallback이 제대로 실행되지 않음 (null이기 때문에)
  useEffect(() => {
    console.log(savedCallback());
    const executeCallback = () => {
      savedCallback();
    };

    const timerId = setInterval(executeCallback, delay);

    return () => clearInterval(timerId);
  }, []);
};

export default useInterval;
```

- 따라서 값이 바뀌어도 리렌더링이 일어나지 않는 Ref를 사용해야 제대로 동작한다.

---
참고
- https://ko.javascript.info/settimeout-setinterval
- https://overreacted.io/making-setinterval-declarative-with-react-hooks/
- https://youtu.be/wcxWlyps4Vg
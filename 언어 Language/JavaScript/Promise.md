# Promise

- Kleisli composition은 함수형 프로그래밍에서 두 개의 Kleisli 함수를 조합하는 기술을 가리킨다.
-  Kleisli 함수는 모나드를 사용하는 함수로, 입력을 받아 모나드 값을 반환한다.
-  이러한 함수를 조합하여 모나드 내의 값을 연속적으로 처리하거나 변환하는 작업을 가능하게 하는 것이 바로 Kleisli composition이다.

```js
// 모나드 M의 Kleisli 함수 정의
kleisliFuncA :: A -> M<B>
kleisliFuncB :: B -> M<C>

// Kleisli 함수 조합
composedKleisliFunc :: A -> M<C>
composedKleisliFunc = kleisliFuncA >=> kleisliFuncB
```

- Promises는 **kleisli composition을 지원하는 도구**이다.

- kleisli composition을 지원한다는 것은 함수 합성을 언제나 수학적으로 안전하게 할 수 있다는 의미이다.

- 예를 들어 f,g 함수를 합성할 경우 `f(g(x)) = f(g(x))` 식을 수학적으로 바라볼 경우 항상 성립되어야 한다. 
  - 해당 식이 성립되지 않는 요인이 있다면 순수한 함수형 프로그래밍을 가능하게 (수학적으로 프로그래밍을 바라볼 수 있도록) 보장해주지 못하는 것이다.

- kleisli composition을 지원해주기 위해서는 에러 처리를 해주어서 에러가 발생하더라도 `f(g(x)) = f(g(x))` 라는 식이 성립되도록 해야 한다.

- Promise는 reject와 catch를 통해 언제나 `f(g(x)) = f(g(x))` 라는 식이 성립되도록 에러 처리를 해줄 수 있기 때문에 kleisli composition을 지원한다고 할 수 있다.

```js
const user = [
  {id:1, name: 'aa'},
  {id:2, name: 'bb'},
];

const getUserById = id => find(u=>u.id===id,user) || promise.reject('없어요!');
const ({name}) => name;
const g = getUserById;

const fg = id => f(g(id));
const fg = id => promise.resolve(id).then(g).then(f).catch(a=>a);

fg(3).then(log);
```

---
참고
- https://www.inflearn.com/course/functional-es6/dashboard
- https://github.com/indongyoo/functional-javascript-01/tree/master/09.%20%EB%B9%84%EB%8F%99%EA%B8%B0%20%EB%8F%99%EC%8B%9C%EC%84%B1%20%ED%94%84%EB%A1%9C%EA%B7%B8%EB%9E%98%EB%B0%8D/1

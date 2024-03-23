```js
const curry = f =>
  (a, ..._) => _.length ? f(a, ..._) : (..._) => f(a, ..._);

const go1 = (a, f) => a instanceof Promise ? a.then(f) : f(a);

const go = (...args) => reduce((a, f) => f(a), args);

const pipe = (f, ...fs) => (...as) => go(f(...as), ...fs);
```

## 병렬 평가

```js
const L = {};

L.range = function* (l) {
  let i = -1;
  while (++i < l) yield i;
};

L.map = curry(function* (f, iter) {
  for (const a of iter) {
    yield go1(a, f);
  }
});

const nop = Symbol('nop');

L.filter = curry(function* (f, iter) {
  for (const a of iter) {
    const b = go1(a, f);
    if (b instanceof Promise) yield b.then(b => b ? a : Promise.reject(nop));
    else if (b) yield a;
  }
});

L.entries = function* (obj) {
  for (const k in obj) yield [k, obj[k]];
};

L.flatten = function* (iter) {
  for (const a of iter) {
    if (isIterable(a)) yield* a;
    else yield a;
  }
};

L.deepFlat = function* f(iter) {
  for (const a of iter) {
    if (isIterable(a)) yield* f(a);
    else yield a;
  }
};

L.flatMap = curry(pipe(L.map, L.flatten));

const map = curry(pipe(L.map, takeAll));
const filter = curry(pipe(L.filter, takeAll));
const find = curry((f, iter) => go(
  iter,
  L.filter(f),
  take(1),
  ([a]) => a));
const flatten = pipe(L.flatten, takeAll);
const flatMap = curry(pipe(L.map, flatten));
```

## 엄격한 평가

```js
const C = {};

function noop() {
}

const catchNoop = ([...arr]) =>
  (arr.forEach(a => a instanceof Promise ? a.catch(noop) : a), arr);

C.reduce = curry((f, acc, iter) => iter ?
  reduce(f, acc, catchNoop(iter)) :
  reduce(f, catchNoop(acc)));
C.take = curry((l, iter) => take(l, catchNoop(iter)));
C.takeAll = C.take(Infinity);
C.map = curry(pipe(L.map, C.takeAll));
C.filter = curry(pipe(L.filter, C.takeAll));
```

---
참고
- https://github.com/indongyoo/functional-javascript-01/blob/master/11.%20%EB%B9%84%EB%8F%99%EA%B8%B0%20%EB%8F%99%EC%8B%9C%EC%84%B1%20%ED%94%84%EB%A1%9C%EA%B7%B8%EB%9E%98%EB%B0%8D%203/1/lib/fx.js
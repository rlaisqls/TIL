# module.exports와 exports

모듈이란 관련된 코드들을 하나의 코드 단위로 캡슐화 하는 것을 말한다.

`greeting.js` 라는 파일이 있다. 이 파일은 두개의 함수를 포함하고 있다.

```js
// greetings.js
sayHelloInEnglish = function() {
    return "Hello";
};

sayHelloInSpanish = function() {
 return "Hola";
};
```

## 모듈 추출하기(exporting)

`gretting.js`의 코드를 다른 파일에서 사용해보자. 

우선 외부에서 사용할 함수에 아래와 같이 export 설정을 해주어야 한다.

```js
// greetings.js

exports.sayHelloInEnglish = function() {
    return "HELLO";
};
exports.sayHelloInSpanish = function() {
    return "Hola";
};
```

위의 코드에서 `exports`를 `module.exports`로 묶어주는 것으로 사용할 수도 있으며 의미는 같다.

```js
module.exports = {
    sayHelloInEnglish: function() {
        return "HELLO";
    },

    sayHelloInSpanish: function() {
        return "Hola";
    }
};
```

## 모듈 사용하기

`main.js` 라는 새로운 파일에서 `greeting.js` 의 메소드를 사용 할 수 있도록 import 해보자.

require 키워드를 사용해 `main.js`에서 `greetings.js`를 require 한다.

```js
// main.js
var greetings = require("./greetings.js");
```


이제 `main.js` 에서 `greeting.js` 의 값과 메소드에 접근할 수 있다.

```js
// main.js
var greetings = require("./greetings.js");

// "Hello"
greetings.sayHelloInEnglish();

// "Hola"
greetings.sayHelloInSpanish();
```

require 키워드는 `object`를 반환한다. 그리고 `module.exports` 와 `exports` 는 call by reference 로 동일한 객체를 바라보고 있고, 리턴되는 값은 항상 `module.exports` 이다.

모듈은 기본적으로 객체이고, 이 객체를 `module.exports`, `exports` 모두 바라보고 있는데, 최종적으로 return 되는 것은 무조건 `module.exports` 라는 것이다.

아래는 `express.Router()`가 리턴한 “객체”에 일부 프로퍼티를 수정한 뒤, 이 객체 자체를 모듈로 return 하고있는 코드이다.

```js
var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res) {
    res.render('index', { title: 'Express' });
});

module.exports = router;
```


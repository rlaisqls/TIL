- Node.js는 js 코드를 V8 엔진으로 해석하여 실행하고, 비동기 작업을 libUV에게 위임하여 논 블로킹 I/O를 지원한다. 
- 각 요소의 구체적인 동작 방식에 대해 알아보자.

<img width="810" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/78c6ff59-7e88-40fa-80ce-e45e57a59ba8">

## V8

- [V8](https://github.com/v8/v8)은 구글이 C++로 개발한 자바스크립트 엔진으로 JS 코드 기계어로 해석하여 OS가 실행할 수 있는 상태로 만들어준다. 
   
- JIT(Just-In-Time) 방식으로 코드를 해석한다.

- GC를 위해 메모리 영역을 Heap(New space, Old space), Stack으로 나누어 관리한다.

    <img width="542" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/6228fb82-ab4f-4cc8-bcb1-e1c1bb53de68">

## libUV

<img width="756" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/3920a026-0ff3-441d-b690-e1a11743a8b9">

- [libUV](https://libuv.org/)는 운영체제의 커널을 추상화하여 C++로 작성된 Wrapping 라이브러리이다.

- Node.js는 기본적으로 libUV 위에서 동작하며, node 인스턴스가 뜰 때, libuv에는 워커 쓰레드풀(default 4개)이 생성된다. 

- Node.js는 I/O 작업을 libUV에게 위임하여 논 블로킹 I/O를 지원한다. 
  - 소켓 작업류는 커널들이 이미 비동기로 지원하지만, 파일시스템쪽 작업은 (libuv에서 추상화 문제로) 지원하지 않는데 이럴때 libuv의 쓰레드가 쓰인다.

- libUV에게 파일 읽기와 같은 비동기 작업을 요청하면 libuv는 이 작업을 커널이 지원하는지 확인한다. 
  1. 요청한 작업을 커널이 지원한다면: libuv가 커널에게 비동기적으로 요청한다.
  2. 요청한 작업을 커널이 지원하지 않는다면: **이벤트 루프**에서 작업을 처리한다.

### 이벤트 루프

- libUV는 여러 비동기 작업을 관리하기 위해 이벤트 루프를 구현한다. 

- 이벤트 루프는 여러 phase로 구성되어있고, phase마다 다 다른 종류의 이벤트를 다룬다. 
  
- 각 phase는 자신만의 큐를 하나씩 가지고 있어서 이 큐에는 이벤트 루프가 실행해야 하는 작업들이 순서대로 담겨있다. 

- Node.js가 phase에 진입하면 이 큐에서 자바스크립트 코드를 꺼내서 하나씩 실행한다. 만약 큐에 있는 작업들을 다 실행하거나, 시스템의 실행 한도에 다다르면 Node.js는 다음 phase로 넘어간다.

- Node.js는 싱글 스레드로 이뤄져있기에 한번에 하나의 phase에만 진입해 하나의 작업만 수행한다. 한 phase가 끝나면 다음 phase로 넘어가면서 실행된다.
  
- phase는 `Timer`, `Pending Callbacks`, `Idle`, `Prepare`, `Poll`, `Check`, `Close Callbacks`로 총 7개의 종류가 있다. 각 Phase의 실행 순서는 나열된 순서와 같다.

    ```
       ┌───────────────────────────┐
    ┌─>│           timers          │
    │  └─────────────┬─────────────┘
    │  ┌─────────────┴─────────────┐
    │  │     pending callbacks     │
    │  └─────────────┬─────────────┘
    │  ┌─────────────┴─────────────┐
    │  │       idle, prepare       │
    │  └─────────────┬─────────────┘      ┌───────────────┐
    │  ┌─────────────┴─────────────┐      │   incoming:   │
    │  │           poll            │<─────┤  connections, │
    │  └─────────────┬─────────────┘      │   data, etc.  │
    │  ┌─────────────┴─────────────┐      └───────────────┘
    │  │           check           │
    │  └─────────────┬─────────────┘
    │  ┌─────────────┴─────────────┐
    └──┤      close callbacks      │
       └───────────────────────────┘
    ```

  - **Timers**
    - `setTimeout`이나 `setInterval`과 같은 함수가 만들어 내는 타이머들을 다룬다. 
    - 타이머를 `min-heap`에 저장하여 가장 이른 타이머를 빠르게 탐색, 비교한다.
    - Timer 시간이 다 되면 타이머 phase에서 콜백을 실행한다.
    - 큐에 실행할 수 있는 작업이 없다면 다음 phase로 넘어간다.

  - **Pending Callbacks**
    - 대부분의 phase는 시스템의 실행 한도의 영향을 받는다. 따라서 제한에 의해 큐에 쌓인 모든 작업을 실행하지 못하고 다음 phase로 넘어갈 수도 있는데, 이때 처리하지 못하고 넘어간 작업들을 쌓아놓고 실행하는 phase다.
    - 큐에 실행할 수 있는 작업이 없다면 다음 phase로 넘어간다.

  - **Idle, Prepare**
    - 이 phase들은 Node.js의 내부적인 관리를 위한 phase로 코드의 직접적인 실행에 영향을 미치지 않는다.

  - **Poll**
    - 이 phase에서는 일정시간동안 대기(blocking)하면서 새로운 I/O operation이 들어오는지를 polling(watching)한다.
    - 이벤트 루프는 Poll phase에서
      - Check phase 혹은 Close phase에 실행할 콜백이 있으면 다음 phase로 바로 넘어간다.
      - 만약 Check phase 와 Close phase에 실행할 콜백이 없으면 타이머를 살펴보고, 타이머가 있으면 해당 타이머를 실행할 수 있을 때까지 Poll phase에서 기다렸다가 다음 phase로 넘어간다.
      - 만약 타이머도 없으면 Poll phase에서 대기한다.
    - linux에선 epoll, mac에선 kqueue를 사용해 구현된다.

  - **Check**
    - 이 phase는 오직 `setImmediate`의 콜백만을 위한 phase이다.
    - `setImmediate`는 Node.js가 틱을 거쳐 Check Phase에 진입하면 바로 실행된다.
    - 즉시 실행해야 하는 경우 쓰는 다른 함수로 `process.nextTick`이 있는데, 이 함수는 호출한 phase에서 바로 실행된다. (node.js의 `nextTickQueue`에 의해 별도로 관리된다.)
      - `process.nextTick`은 **즉시** 실행되고 `setImmediate`는 **다음 Check Phase**에 실행되기 때문에 이름이 서로 바뀌어야 하는 게 맞지만, 바뀐 동작에 의존하는 코드가 많아서 수정하지 않을 예정이라고 한다. [(문서)](https://nodejs.org/en/learn/asynchronous-work/event-loop-timers-and-nexttick#processnexttick-vs-setimmediate)

  - **Close Callbacks Phase**
    - `socket.destroy()`와 같은 close 이벤트 타입의 핸들러를 처리하는 phase이다.

---
참고
- https://nodejs.org/en/learn/asynchronous-work/event-loop-timers-and-nexttick
- https://docs.libuv.org/en/v1.x/design.html
- https://docs.libuv.org/en/v1.x/loop.html
- https://evan-moon.github.io/2019/08/01/nodejs-event-loop-workflow/
- https://fe-developers.kakaoent.com/2022/220519-garbage-collection/
- https://sjh836.tistory.com/149
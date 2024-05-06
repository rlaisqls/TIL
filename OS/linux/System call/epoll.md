
Epoll은 리눅스에서 select의 단점을 보완하여 사용할 수 있도록 만든 I/O 통지 모델이다. 파일 디스크립터를 커널이 관리하기 때문에 CPU는 계속해서 파일 디스크립터의 상태 변화를 감시할 필요가 없고, 관찰대상의 정보를 매번 전달하지 않아도 된다.

select는 어느 파일 디스크립터에 이벤트가 발생하였는지 찾기 위해 전체 파일 디스크립터에 대해서 순차검색을 위한 `FD_ISSET` 루프를 돌려야 하지만, Epoll는 이벤트가 발생한 파일 디스크립터들만 구조체 배열을 통해 넘겨주므로 메모리 카피에 대한 비용이 줄어든다. 

### level vs edge trigger

epoll의 이벤트 탐지 방법은 level-trigger와 edge-trigger 두 가지가 있다. 

- **level-trigger**:
  - 특정한 조건이 유지되는 동안 계속 감지한다. level-trigger의 조건을 1로 설정했다면, epoll은 fd가 1을 유지하는 동안 계속 감지한다. 
- **edge-trigger**:
  - 특정 조건이 변할 때에 감지한다. fd가 0 에서 1로 변하거나, 1에서 0으로 변할 때에만 이를 감지한다.

주의사항
- poll 방식을 edge-trigger로 설정할 경우, 항상 non-blocking 방식으로 구현해야 한다. 
- 예를 들어 소켓이 데이터를 전송했을 때, level-trigger 방식이라면 데이터가 있다고 감지하는 동안 계속 버퍼에서 내용을 읽어들일 수 있을 것이다. 하지만 edge-trigger의 경우 데이터가 변경된 시점(즉, 버퍼로 데이터가 전송된 순간)에만 이벤트를 감지하기에 버퍼에서 내용을 읽어들이다가 block된 경우 나머지 데이터를 읽어올 수 없다.

## 시스템 콜

### `epoll_create()`

```c
#include <sys/epoll.h>

int epoll_create(int size);
```

- 성공 시 epoll 파일 디스크립터, 실패시 -1 반환
- epoll 인스턴스라 불리는 파일 디스크립터의 저장소를 생성.
- 소멸시 close 함수 호출을 통한 종료 과정이 필요.

### `epoll_ctl()`
 
```c
#include <sys/epoll.h>

int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);
```

- 성공 시 0, 실패 시 -1 반환
- 파라미터
    - `epfd`: 관찰 대상을 등록할 epoll 인스턴스의 파일디스크립터
    - `op` : 관찰 대상 추가, 삭제 또는 변경여부 지정
        - `EPOLL_CTL_ADD` : 파일 디스크립터를 epoll 인스턴스에 등록
        - `EPOLL_CTL_DEL` : 파일 디스크립터를 epoll 인스턴스에서 삭제
        - `EPOLL_CTL_MOD` : 등록된 파일 디스크립터의 이벤트 발생상황을 변경
    - `fd` : 등록할 관찰대상의 파일 디스크립터
    - `event` : 관찰 대상의 관찰 이벤트 유형


- epoll_event 구조체는 epoll 이벤트를 등록하거나 조회하기 위해 사용된다.
- 예제

    ```c
    struct epoll_event event;
    ...
    event.events = EPOLLIN;
    event.data.fd = sockfd;
    epoll_ctl(epfd, EPOLL_CTL_ADD, sockfd, &event);
    ...
    ```

    - sockfd로 수신할 데이터가 존재하는 상황이면 이벤트가 발생된다.
    - `epoll_ctl` 함수는 event 구조체에 반환을 하게 해준다.
    - 반환된 event 구조체에는 이벤트가 발생된 파일 디스크립터가 들어가 있다.

- event의 유형에는 아래와 같은 것들이 있다.
  - EPOLL_CTL의 입력에만 사용되는 event
    - `EPOLLET` : 이벤트의 감지를 edge-trigger 방식으로 동작한다.
    - `EPOLLONESHOT` : 이벤트가 한 번 감지되면, 해당 파일 디스크립터에서 더 이상 이벤트를 발생시키지 않도록 한다.
  - EPOLL_CTL의 입력, WAIT의 출력 모두에 사용되는 event
    - `EPOLLIN` : 수신할 데이터가 존재하는 상황  
    - `EPOLLOUT` : 출력버퍼가 비워져서 당장 데이터를 전송할 수 있는 상황  
    - `EPOLLPRI` : OOB 데이터가 수신된 상황  
    - `EPOLLRDHUP` : 연결이 종료되거나 Half-close가 진행된 상황 (edge-trigger 방식에서 유용하게 사용될 수 있다) 
  - WAIT의 출력에만 사용되는 event
    - `EPOLLERR` : 에러가 발생한 상황  
    - `EPOLLHUP` : 장애발생 (hangup)  

### `epoll_wait()`

```c
#include <sys/epoll.h>
int epoll_wait(int epfd, struct epoll_event *event, int maxevents, int timeout);
```

- 성공 시 이벤트가 발생한 파일 디스크립터의 수, 실패시 -1 반환
- 파라미터
  - `epfd` : 이벤트 발생의 관찰영역인 epoll 인스턴스의 파일 디스크립터
  - `events` : 이벤트가 발생한 파일디스크립터가 채워질 버퍼의 주소값
  - `maxevents` : 두번째 인자로 전달된 주소값의 버퍼에 등록 가능한 최대 이벤트수
  - `timeout` : 1/1000초 단위의 대기시간, -1 전달시 이벤트가 발생할 때까지 무한대기

 
- 예제
  
    ```c
    int event_cnt;
    struct epoll_event *ep_events
    ...
    ep_events = malloc(sizeof(struct epoll_event) * EPOLL_SIZE);
    ...
    event_cnt = epoll_wait(epfd, ep_events, EPOLL_SIZE, -1);
    ```

---
참고
- https://en.wikipedia.org/wiki/Epoll
- https://jvns.ca/blog/2017/06/03/async-io-on-linux--select--poll--and-epoll/
- https://man7.org/linux/man-pages/man2/epoll_ctl.2.html
- https://kldp.org/node/74537
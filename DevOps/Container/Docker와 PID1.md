## 1. 배경

- Linux 신호는 컨테이너 내부의 프로세스 수명 주기를 제어하는 주요 방법이다. 앱의 수명 주기를 앱이 포함된 컨테이너와 긴밀하게 연결하려면 앱이 Linux 신호를 올바르게 처리하도록 해야한다.

- 프로세스 식별자(PID)는 Linux커널이 각 프로세스에 제공하는 고유한 식별자이다. PID는 namespace다. 즉, 컨테이너에는 호스트 시스템의 PID가 매핑되는 고유한 PID 세트가 있다.

- Linux 커널을 시작할 때 실행된 첫 번째 프로세스에는 PID 1이 있다. 정상적인 운영체제의 경우 이 프로세스는 init 시스템(ex. systemd 또는 SysV)이다. 마찬가지로 컨테이너에서 실행된 첫 번째 프로세스는 PID 1을 얻는다.

- Docker와 Kubernetes는 신호를 사용하여 컨테이너 내부의 프로세스와 통신하며, 특히 컨테이너를 종료하기 위해 사용된다. Docker와 Kubernetes는 모두 컨테이너 내부에 PID 1이 있는 프로세스에만 신호를 보낼 수 있다.

## 2. 문제

### 2.1 Linux 커널이 신호를 처리하는 방법

- Linux 커널이 신호를 처리하는 방법은 PID 1을 가진 프로세스와 그렇지 않은 프로세스에서 차이가 있다.

- 신호 핸들러가 이 프로세스에서 자동으로 등록되지 않으므로 SIGTERM 또는 SIGINT 같은 신호는 기본적으로 아무런 영향을 미치지 않는다. 기본적으로, 단계적 종료를 방지하는 SIGKILL을 사용하여 프로세스를 강제 종료해야한다. 앱에 따라 SIGKILL을 사용하면 모니터링 시스템에 사용자 표시 오류, 쓰기 중단(데이터 저장용), 원치 않는 알림이 발생할 수 있다.

### 2.2 기본 init 시스템이 분리된 프로세스를 처리하는 방법

- systemd와 같은 기본 init 시스템은 분리된 좀비 프로세스를 제거하는 데에도 사용된다. 분리된 프로세스(상위 요소가 사라진 프로세스)는 PID 1이 있는 프로세스에 다시 첨부된다. PID 1은 프로세스가 사라질 때 다시 거둬야 한다.

- 정상적인 init 시스템은 그렇게 작동하지만 컨테이너에서는 PID 1을 갖고 있는 프로세스가 이러한 책임을 갖게 된다. 이 프로세스에서 이런 제거를 제대로 하지 못하면 메모리나 다른 리소스가 부족해질 수 있다.

## 3. 해결

### 3.1 PID 1으로 실행하고 신호 핸들러로 등록

- 첫 번째 문제만 해결된다.
- 앱이 제어된 방식(흔한 경우)으로 하위 프로세스를 생성하면 두 번째 문제를 방지할 수 있다.
- 이 솔루션을 구현하는 가장 쉬운 방법은 Dockerfile에서 `CMD` 또는 `ENTRYPOINT`를 사용하여 프로세스를 실행하는 것이다.

        ```dockerfile
        FROM debian:9

        RUN apt-get update && \
            apt-get install -y nginx

        EXPOSE 80

        CMD [ "nginx", "-g", "daemon off;" ]
        ```

- 이 방법을 사용하는 경우 도커 파일에 포함된 셸 스크립트는 PID 1을 가지므로 기본 exec 명령어를 사용하여 셸 스크립트에서 프로세스를 실행해야한다.

### 3.2 Kubernetes에서 프로세스 네임스페이스 공유 사용 설정

- pod에 프로세스 네임스페이스 공유를 설정하면 Kubernetes는 해당 pod의 모든 컨테이너에 단일 프로세스 네임스페이스를 사용한다. Kubernetes pod 인프라 컨테이너가 PID 1이 되고 분리된 프로세스는 자동으로 다시 수거(reap)된다.

### 3.3 특수한 init 시스템 사용

- 기본적인 Linux 환경에서와 마찬가지로 init 시스템을 사용하여 이러한 문제를 처리할 수도 있다. 하지만 systemd 또는 SysV등의 일반 init 시스템은 단지 이 용도로 사용하기에는 너무 복잡하고 크기 때문에 컨테이너용으로 특별히 제작된 dumb-init, tini와 같은 init 시스템을 사용하는 것이 좋다.

- 특수한 init 시스템을 사용하는 경우 init 프로세스는 PID 1을 가지며 다음을 수행한다.

  - 올바른 신호 핸들러를 등록
  - 앱에서 신호가 작동하는지 확인
  - 최종 모든 좀비 프로세스를 수거

- `docker run` 명령어의 `--init` 옵션을 사용하면 Docker 자체에서 이 솔루션을 사용할 수 있다. Kubernetes에서 이 솔루션을 사용하려면 컨테이너 이미지에 init 시스템을 설치하고 컨테이너의 진입점으로 사용해야 한다.

- 컨테이너용으로 제작된 init 시스템인 `dumb-init`의 동작을 자세히 알아본다.

  - 서버 프로세스를 직접 실행하는 대신 Dockerfile에서 `CMD ["dumb-init", "python", "my_server.py"]`. 이렇게 하면 다음과 같은 프로세스 트리가 생성된다.

    <img width="352" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/b3a08e34-6948-4cfe-95ab-067bae5e37ed">

  - dumb-init는 잡을 수 있는 모든 신호에 대해 신호 처리기를 등록하고, 해당 신호를 프로세스를 기반으로 하는 세션으로 전달한다.

  - Python 프로세스가 더 이상 PID 1로 실행되지 않기 때문에 dumb-init가 와 같은 신호를 전달할 때 TERM 다른 핸들러를 등록하지 않은 경우 커널은 여전히 기본 동작(프로세스 종료)을 적용한다.

  - dumb-init는 프로세스를 유일한 자식으로 생성하고 이에 대한 신호를 프록시한다. dump-init는 프로세스가 죽을 때까지 실제로 죽지 않으므로 적절한 정리를 수행할 수 있다.
  
  - `dumb-init`은 추가 종속성이 없는 정적 연결 바이너리로 배포된다. 간단한 초기화 시스템으로 사용하는 것이 이상적이며 일반적으로 모든 컨테이너에 추가할 수 있다. 기본적으로 모든 Docker 컨테이너에서 사용하는 것이 좋다.

  - dumb-init는 신호 처리를 향상시킬 뿐만 아니라 고아 좀비 프로세스를 수확하는 것과 같은 init 시스템의 다른 기능도 처리한다.

---
참고

- <https://cloud.google.com/architecture/best-practices-for-building-containers?hl=ko#signal-handling>
- <https://engineeringblog.yelp.com/2016/01/dumb-init-an-init-for-docker.html>
- <https://www.baeldung.com/linux/docker-container-process-host-pid>


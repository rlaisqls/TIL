# 🦮 datadog APM기능 사용하기

서버에 datadog agent를 설치하면 CPU 점유율, Memory, Disk사용량 등의 중요한 성능 정보를 모니터링할 수 있다. 하지만 애플리케이션의 전반적인 LifeCycle에 대한 리포트 (ex: GC, JVM, I/O 등)를 바탕으로 에러나 병목현상에 더 빠르게 대응할 수 있도록 하고싶다면 **Datadog APM**을 연결해야한다.

## APM 이란?

Application Performance Monitoring 의 약자로 구동 중인 애플리케이션의 대한 성능측정과 에러탐지 등, 전반적인 애플리케이션 라이프사이클의 정보를 수집해 모니터링할 수 있게 해준다. 보다 편리성을 위해서 다양하게 시각화한 Metrics, 그리고 API 테스트도 지원한다.

여러 대의 애플리케이션에 설치가 가능하며 이를 한꺼번에 같은 UI 상에 보여주기 때문에 마이크로서비스 아키텍처 에도 유용하게 사용될 수 있다고 한다.

## APM 설정해보기

### 1. 환경에 맞게 agent 설치

이 내용에 대해서는 <a href="https://us5.datadoghq.com/account/settings#agent/overview">데이터독 사이트<a/>을 참고할 수 있다.

설명대로 잘 따라하면 된다.

### 2. datadog.yaml 수정

Agent의 모든 설정은 제목의 파일명에서 확인할 수 있다. 각각의 설치환경 별로 해당파일의 경로를 모두 소개해주고 있으니 APM Service setup docs를 확인하여 파일을 찾아보자.

단, 도커의 경우에는 그냥 실행시 `e- DD_APM_ENABLED=true`로 설정해주면 된다.

그 외의 경우에는 설정 파일을 열어 쭈욱 밑으로 내려 Traces Configuration에서 아래와 같이 되어있는 부분을 찾는다.

```bash
***********************************
Traces Configuration
***********************************
#
...중략....
#
# apm_config:
# enable: true
```

이 두개의 부분의 주석을 해제한 후, Agent를 restart 해준다.

```bash
systemctl restart datadog-agent
```

### 3. Tracer 설치, 실행

<a href="https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/java/?tab=containers">데이터독 공식 Docs<a/>에 따라 Teacer를 설치하고 실행한다.

도커의 경우엔 아래의 명령어를 입력해주면 된다.

```
docker run -d --cgroupns host \
              --pid host \
              -v /var/run/docker.sock:/var/run/docker.sock:ro \
              -v /proc/:/host/proc/:ro \
              -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
              -p 127.0.0.1:8126:8126/tcp \
              -e DD_API_KEY=<DATADOG_API_KEY> \
              -e DD_APM_ENABLED=true \
              -e DD_SITE=<DATADOG_SITE> \
              gcr.io/datadoghq/agent:latest
```

### 4. 모니터링

연결한 후 APM 탭에 들어가보면, 정말 많은 정보를 확인할 수 있다. jvm 상태와 모든 프로그램에 대한 트래이싱 데이터 등등을 꼼꼼히 살펴볼 수 있다. 
  
![image](https://user-images.githubusercontent.com/81006587/204086332-2d092adc-36f4-4770-a8ed-7a91e02914e1.png)

![image](https://user-images.githubusercontent.com/81006587/204086343-e169c32b-e0fc-40dc-8374-c6c42f89f2be.png)

![image](https://user-images.githubusercontent.com/81006587/204086356-d8e06ce4-c786-459b-96e8-2dc56bec2c81.png)

화면을 보면, 현재 실행 중인 앱에서 어떤 것이 가장 많은 요청을 받고 있는지, 어떤 동작을 얼마나 수행하는지 Code-Level 단위로 세세하게 나오고 있다. 더 자세한 화면들은 직접 설정하여 둘러보자!

datadog은 한국어로 친절하게 설명되어있는 자료가 별로 없는 반면에, Docs 내용이 정말 유익하다.  APM 기능으로 어떤 것들을 할 수 있고 볼 수 있는지 더 알아보고 싶다면 <a href="https://docs.datadoghq.com/tracing/glossary/">Docs<a/>에 직접 들어가서 보면 좋다 ㅎㅎ

# 🐳 Docker Swarm

Docker Swarm은 도커에서 자체적으로 제작한 <a href="https://github.com/rlaisqls/TIL/blob/main/%EB%8D%B0%EB%B8%8C%EC%98%B5%EC%8A%A4%20DevOps/Container%20Orchestration.md">컨테이너 오케스트레이션</a> 도구이다. 

Docker Swarm을 사용한다면 여러 컨테이너의 배포를 관리하고, 네트워크 및 컨테이너 상태를 제어 및 모니터링 할 수 있다.

## 쿠버네티스와의 차이?

컨테이너 오케스트레이션을 위한 툴로는 여러가지가 있는데 그중 가장 널리 쓰이는 것은 <a href="https://github.com/rlaisqls/TIL/blob/main/%EB%8D%B0%EB%B8%8C%EC%98%B5%EC%8A%A4%20DevOps/Kubernetes/.Kubernetes.md">쿠버네티스</a>로, 사실상 표준 기술로 자리잡았다 볼 수 있을 정도로 널리 쓰이고 있다.

하지만 도커 스웜(Docker Swarm)은 Mirantis가 Docker의 엔터프라이즈 플랫폼 사업을 인수한 이래로 유지보수 단계에 접어들어 더 이상의 발전과 기능 추가를 기대할 수 없게 되었다.

그렇다면 도커 스웜보다는 쿠버네티스를 배우는게 좋지 않을까? 굳이 도커 스웜을 사용해야하는 이유가 뭘까?

도커 스웜은 아래와 같은 장점을 가지고 있다.

- 쿠버네티스 만큼은 아니더라도, 여러 대의 호스트로 구성된 중소 규모의 클러스터에서 컨테이너 기반 애플리케이션 구동을 제어하기에 충분한 기능을 갖추고 있다.
- 도커 엔진(Docker Engine)이 설치된 환경이라면 별도의 구축 비용 없이 스웜 모드(Swarm Mode)를 활성화하는 것만으로 시작할 수 있다.
- 도커 컴포즈(Docker Compose)를 사용해 본 사람이라면 도커 스웜(Docker Swarm)의 스택(Stack)을 이용한 애플리케이션 운영에 곧바로 적응할 수 있다.
- 도커 데스크탑(Docker Desktop)으로도 클러스터 관리와 배포가 모두 가능한 단일 노드 클러스터를 바로 만들 수 있다. 따라서 최소한의 자원으로 컨테이너 오케스트레이션 환경을 만들어 시험해볼 수 있다.

이처럼 진입 장벽이 낮고, 간단한 구조로 빠르게 시험 가능한 특성은 학습자의 입장에서 매우 큰 이점이다. 같은 컨테이너 오케스트레이션 도구로서 도커 스웜에 대해 익힌 내용은 추후 쿠버네티스 등 엔터프라이즈 레벨의 도구를 다루는 과정에도 도움이 될 수 있다.

## 주요 용어

#### 노드(Node)
- 클러스터를 구성하는 개별 도커 서버를 의미한다.

#### 매니저 노드(Manager Node)
- 클러스터 관리와 컨테이너 오케스트레이션을 담당한다. 쿠버네티스의 마스터 노드(Master Node)와 같은 역할이라고 할 수 있다.

#### 워커 노드(Worker Node)
- 컨테이너 기반 서비스(Service)들이 실제 구동되는 노드를 의미한다. 쿠버네티스와 다른 점이 있다면, Docker Swarm에서는 매니저 노드(Manager Node)도 기본적으로 워커 노드(Worker Node)의 역할을 같이 수행할 수 있다는 것이다. 물론 스케줄링을 임의로 막는 것도 가능하다.

#### 스택(Stack)
- 하나 이상의 서비스(Service)로 구성된 다중 컨테이너 애플리케이션 묶음을 의미한다. 도커 컴포즈(Docker Compose)와 유사한 양식의 YAML 파일로 스택 배포를 진행한다.

#### 서비스(Service)
- 노드에서 수행하고자 하는 작업들을 정의해놓은 것으로, 클러스터 안에서 구동시킬 컨테이너 묶음을 정의한 객체라고 할 수 있다. 도커 스웜에서의 기본적인 배포 단위로 취급된다. 하나의 서비스는 하나의 이미지를 기반으로 구동되며, 이들 각각이 전체 애플리케이션의 구동에 필요한 개별적인 마이크로서비스(microservice)로 기능한다.

#### 태스크(Task)
- 클러스터를 통해 서비스를 구동시킬 때, 도커 스웜은 해당 서비스의 요구 사항에 맞춰 실제 마이크로서비스가 동작할 도커 컨테이너를 구성하여 노드에 분배한다. 이것을 태스크(Task)라고 한다. 하나의 서비스는 지정된 복제본(replica) 수에 따라 여러 개의 태스크를 가질 수 있으며, 각각의 태스크에는 하나씩의 컨테이너가 포함된다.

### 스케줄링(Scheduling)
- 도커 스웜에서 스케줄링은 서비스 명세에 따라 태스크(컨테이너)를 노드에 분배하는 작업을 의미한다. 2022년 8월 기준으로 도커 스웜에서는 오직 균등 분배(spread) 방식만 지원하고 있다. 물론 노드별 설정 변경 또는 라벨링(labeling)을 통해 스케줄링 가능한 노드의 범위를 제한할 수도 있다.

## Docker Swarm (Swarmpit) 사용하는법

도커를 설치한 후 아래 명령어를 linux 터미널에 입력한다.

```js
docker swarm init
```

Docker swarm을 관리하기 쉽게 GUI형태로 확인할 수 있는 도구인 <a href="https://swarmpit.io/">Swarmpit</a>을 다운받는다.

```js
sudo docker run -it --rm \
  --name swarmpit-installer \
  --volume /var/run/docker.sock:/var/run/docker.sock \
swarmpit/install:1.9
```

다운 과정에서 name, port 등의 정보를 원하는대로 설정해준다.
대괄호 안에 특정 값이 써있는 경우에는, 엔터를 누르면 해당 값으로 세팅된다. 기본값으로 생각하면 된다.

```js
Application setup
Enter stack name [swarmpit] :
Enter application port [888] :
Enter database volume driver [local] :
Enter admin username [admin] :
Enter admin password (min 8 characters long): qwertyuiop...
```

ec2에서 swarmpit을 사용하는 경우 설정한 포트를 인바운드 규칙에 추가해줘야한다.

`서버 주소:swarmpit 포트`를 통해 접속 후, 로그인하면 Swarmpit으로 docker 컨테이너들을 GUI로 배포 및 관리할 수 있다.

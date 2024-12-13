
Amazon Elastic Container Service (Amazon ECS) is a fully managed container orchestration service that helps you easily deploy, manage, and scale containerized applications. As a fully managed service, Amazon ECS comes with AWS configuration and operational best practices built-in. It's integrated with both AWS and third-party tools, such as Amazon Elastic Container Registry and Docker. This integration makes it easier for teams to focus on building the applications, not the environment. You can run and scale your container workloads across AWS Regions in the cloud, and on-premises, without the complexity of managing a control plane.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/205771e3-3e76-43d9-98b7-b9f3ae710c20)

## ECS 요소

### 컨테이너(container) 및 이미지(image)

ECS에서 애플리케이션을 배포하려면 애플리케이션 구성 요소가 컨테이너에서 실행되도록 구축되어야 한다. 일반적으로 Dockerfile로 빌드 되는 이미지가 이에 해당한다.

### 작업 정의(Task definition)

애플리케이션이 ECS에서 실행되도록 준비하려면 작업 정의를 생성한다.

작업 정의는 애플리케이션을 구성하는 하나 이상의 컨테이너를 설명하는 JSON 파일이다. 작업 정의는 JSON 파일에 사용할 컨테이너, 사용할 시작 유형, 개방할 포트, 컨테이너에 사용할 볼륨 등의 다양한 파라미터가 포함된다.

Fargate 시작 유형 + NginX 웹 서버를 실행하는 단일 컨테이너가 포함된 작업 정의의 예제는 아래와 같다.

```json
{
  "family": "webserver",
  "containerDefinitions": [
    {
      "name": "web",
      "image": "nginx",
      "memory": "100",
      "cpu": "99"
    }
  ],
  "requiresCompatibilities": ["FARGATE"],
  "networkMode": "awsvpc",
  "memory": "512",
  "cpu": "256"
}
```

### 작업(Task) 및 예약(Scheduling)

작업은 클러스터 내 작업 정의를 인스턴스화하는 것이다. ECS에서 애플리케이션에 대한 작업 정의를 생성 하면 클러스터에서 실행 할 작업 수를 지정할 수 있다. 각 작업은 자체 격리 경계를 포함하여 메모리, CPU, 기본 커널, 네트워크 인터페이스를 다른 작업과 공유하지 않는다.

ECS 작업 스케줄러는 클러스터 내에 작업을 배치하는 일을 한다. 다양한 예약 옵션을 지정할 수 있다.

### 서비스(Service)

ECS 클러스터에서 지정된 수의 작업 정의 인스턴스를 동시에 실행하고 관리할 수 있다. 어떤 이유로 작업이 실패 또는 중지되는 경우 서비스 스케줄러가 작업 정의의 다른 인스턴스를 시작하여 이를 대체하고 사용되는 일정 전략에 따라 원하는 작업 수를 유지한다.

### 클러스터(Cluster)

ECS를 사용하여 작업을 실행하면 Resource의 논리적 그룹인 클러스터에 작업을 배치하는 것이다.

Fargate 시작 유형의 경우, ECS에서 클러스터 리소스를 관리한다. (ECS가 관리하는 EC2 인스턴스) EC2 시작 유형을 사용하면 클러스터는 사용자가 관리하는 컨테이너 인스턴스의 그룹이 된다.

### 컨테이너 에이전트(Container Agent)

컨테이너 에이전트는 ECS 클러스터의 각 인프라 Resource에서 실행된다. Resource에서 현재 실행 중인 작업과 Resource 사용률에 대한 정보를 ECS에 전송하고, ECS로부터 요청을 수신할 때마다 작업을 시작 또는 중지한다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/a6682ef5-09c0-4dbf-83fb-44eef1d7c06d)

---
reference

- <https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/Welcome.html>
- <https://aws.amazon.com/ko/ecs/>
- <https://aws.amazon.com/ko/ecs/faqs/>


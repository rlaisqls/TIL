# Datadog이란?

> 💡 APM, log, Infrastructure를 통합적으로 모니터링·관리하는 클라우드 모니터링 솔루션**

- 여러 클라우드 환경에  나뉘어있는 리소스들을 통합적으로 모니터링 가능하다.
- 클라우드의 상태를 지속적으로 감시하여 예기치 못한 상황과 오류를 대비, 대응할 수 있다.

## 장점

- 에러를 빠르게 확인하여 **신속한 대응** 가능
- 애플리케이션 정보(log, query 등) 축적하여 **데이터 기반 개선**
- 개발자, 운영팀, 비즈니스 유저간 **긴밀한 협업**
- 다양한 언어과 환경을 지원하기 때문에, 원하는 애플리케이션에 **확장** 가능
- **커스텀 대시보드** 생성 가능
- 공식 문서가 친절함

## 단점

- 비용이 많이 든다.
- 기능이 많아서 실무에 도입하기 위해 사전 지식이 필요함.

---

# Datadog의 주요기능

### Integrations

- 여러가지 서비스와 연계하여 모니터링을 할 수 있다. (docker, k8s, ec2, rds, nginx 등등…)
- 정말 많은 호환을 제공한다.

![image](https://user-images.githubusercontent.com/81006587/234476253-10642ee8-6ac6-4a51-a9ee-108913c0f997.png)

### Dashboards

- 서버의 중요한 성능수치를 시각적으로 추적, 분석, 표시할 수 있다. (cpu, memory, disk 용량 등)
- Datadog에서 제공하는 디폴트 측량값을 사용하거나, 커스텀하여 대시보드를 만드는 것도 가능하다

> 일부 정보에 태그를 붙여서 그룹화할 수도 있다. (ex. 버전별, 서버별 등)
> 

![image](https://user-images.githubusercontent.com/81006587/234476294-e0cb8deb-e270-4d1e-a9b8-387911f96050.png)

### **APM**

- Application Performance Management
- 애플리케이션 내부에 심어, 애플리케이션의 성능을 분석하는 서비스이다.
- 추가 셋업이 필요하지만, 기존 모니터링보다 더 많은 정보를 수집할 수 있다.

![image](https://user-images.githubusercontent.com/81006587/234476316-83103bda-ccd0-4aaa-99e7-6fa79b58078f.png)

### Logs

- 로그 수집 및 모니터링 환경 구축 가능
    - 인프라 및 어플리케이션에서 발생한 대량의 로그를 효율적으로 수집, 처리, 저장, 검색할 수 있다.
- Logs의 설정(Pipelines)로 수집한 로그에 대한 처리를 어떻게 할 것인지 정의할 수 있다.

![image](https://user-images.githubusercontent.com/81006587/234476387-911fa610-bf86-4b57-ba0f-7a69867e632e.png)

### Monitors

- 수집한 정보로부터 특정 판단 기준에 도달한 경우, 경고 또는 통지할 수 있다
- slack이나 메일로 전달되도록 설정하는 것도 가능하다.

![image](https://user-images.githubusercontent.com/81006587/234476423-2d6f4789-4aa2-4beb-b533-62b224c33703.png)

### ****Service Map****

- 데이터 흐름 및 클러스터 서비스 자동매핑
- 글로벌알림을 통해 추적, 로그 및 인프라 메트릭으로 원클릭 탐색

![image](https://user-images.githubusercontent.com/81006587/234476440-ea8fc30f-9ffc-429b-9c39-1f4fa9bc15d8.png)

### ****Collaboration****

- 외부사용자와 실시간 그래프 및 대시보드를 공유하기 위한 공개 URL 설정 및 공유 기능을 제공한다.
- 그래프에 코멘트 및 주석을 추가하여 이슈 공유 및 트래킹을 할 수 있다.

![image](https://user-images.githubusercontent.com/81006587/234476465-952feb71-1fd4-4e7b-86a8-d284bcfc92d8.png)

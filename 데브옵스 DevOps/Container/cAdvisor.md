# cAdvisor

Kubernetes (k8s)에서 cAdvisor는 "Container Advisor"의 줄임말로, 컨테이너 메트릭을 수집하고 모니터링하기 위한 도구이다. cAdvisor는 Google에서 개발한 오픈 소스 프로젝트로, 컨테이너화된 환경에서 작동하는 애플리케이션 및 서비스의 성능을 실시간으로 추적하고 이해하는 데 도움을 준다.

## 주 기능

- 컨테이너 메트릭 수집: cAdvisor는 호스트 시스템에서 실행 중인 각 컨테이너에 대한 메트릭을 수집한다. 이 메트릭은 CPU 사용량, 메모리 사용량, 디스크 I/O, 네트워크 사용량 및 다른 성능 관련 정보를 포함한다.
- 시각화: cAdvisor는 수집된 메트릭을 시각적으로 표시하여 사용자가 컨테이너의 성능과 리소스 사용 상태를 쉽게 이해할 수 있도록 도와준다.
- 리소스 모니터링: cAdvisor는 각 컨테이너의 리소스 사용량을 모니터링하고 경고를 설정하여 리소스 부족 현상을 감지할 수 있다.
- 컨테이너 및 호스트 정보 제공: cAdvisor는 실행 중인 컨테이너와 호스트 시스템에 대한 정보를 제공하여 컨테이너 환경을 더 잘 이해하고 관리할 수 있게 해준다.

Kubernetes 클러스터에서 cAdvisor는 kubelet과 함께 실행되며, kubelet은 각 노드에서 cAdvisor를 통해 컨테이너 메트릭을 수집하고 이러한 정보를 Kubernetes 마스터 노드에 보고한다. 마스터 노드에서는 이 정보를 사용하여 컨테이너의 상태 및 성능을 모니터링하고 관리한다. 

k8s와 함께 쓰는 것이 아니더라도 Docker container를 모니터링하기 위해 따로 설치하여 사용할 수 있는 툴이다. 

<img src="https://github.com/rlaisqls/TIL/assets/81006587/09f695e5-f92b-4dfa-a551-bb7d38c20fee" height=300px>

---
참고
- https://www.kubecost.com/kubernetes-devops-tools/cadvisor/
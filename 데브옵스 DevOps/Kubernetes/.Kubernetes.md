# ⚓ Kubernetes

쿠버네티스(Kubernetes)는 컨테이너화 된 애플리케이션의 대규모 배포, 스케일링 및 관리를 간편하게 만들어주는 오픈 소스 기반 <a href="https://github.com/rlaisqls/TIL/blob/main/%EB%8D%B0%EB%B8%8C%EC%98%B5%EC%8A%A4%20DevOps/Container%20Orchestration.md">컨테이너 오케스트레이션</a> 도구이다. 

프로덕션 환경에서는 애플리케이션을 실행하는 여러 컨테이너를 관리하고 다운타임이 없는지 확인해야하는데, Kubernetes는 다중 컨테이너 처리를 자동으로 처리하고, 분산 시스템을 탄력적으로 실행할 수 있는 프레임워크를 제공한다. K8s를 사용하면 애플리케이션의 확장 및 장애 조치를 처리하고 배포 패턴 등을 쉽게 처리할 수 있다.

<img height="300px" src="https://images.velog.io/images/sanspareilsmyn/post/557e22d9-856a-48fc-9f29-e85c8b3004e4/k8s-eyecatch.jpeg">

## 쿠버네티스의 특징 5가지

### 1. 선언적 접근 방식

쿠버네티스에서는 동작을 지시하는 개념보다는 상태를 선언하는 개념을 주로 사용한다.

쿠버네티스는 원하는 상태(Desired state)와 현재의 상태(Current state)가 서로 일치하는지를 지속적으로 체크하고 업데이트한다. 만약 컨테이너의 상태에 문제가 생겼을 경우, 쿠버네티스는 해당 요소가 원하는 상태로 복구될 수 있도록 필요한 조치를 자동으로 취한다.  

### 2. 기능 단위의 분산

쿠버네티스에서는 각각의 기능들이 개별적인 구성 요소로서 독립적으로 분산되어 있다. 실제로 노드(Node), 레플리카셋(ReplicaSet), 디플로이먼트(Deployment), 네임스페이스(Namespace) 등 클러스터를 구성하는 주요 요소들이 모두 컨트롤러(Controller)로서 구성되어 있으며, 이들은 <a href="https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/">Kube Controller Manager</a> 안에 패키징 되어 있다

### 3. 클러스터 단위 중앙 제어
쿠버네티스에서는 전체 물리 리소스를 클러스터 단위로 추상화하여 관리한다. 클러스터 내부에는 클러스터의 구성 요소들에 대해 제어 권한을 가진 컨트롤 플레인(Control Plane) 역할의 마스터 노드(Master Node)를 두게 되며, 관리자는 이 마스터 노드를 이용하여 클러스터 전체를 제어한다.

### 4. 동적 그룹화
쿠버네티스의 구성 요소들에는 쿼리 가능한 레이블(Label)과 메타데이터용 어노테이션(Annotation)에 임의로 키-값 쌍을 삽입할 수 있다. 관리자는 selector를 이용해서 레이블 기준으로 구성 요소들을 유연하게 관리할 수 있고, 어노테이션에 기재된 내용을 참고하여 해당 요소의 특징적인 내역을 추적할 수 있다.

### 5. API 기반 상호작용
쿠버네티스의 구성 요소들은 오직 Kubernetes API server(kube-apiserver)를 통해서만 상호 접근이 가능한 구조를 가진다. 마스터 노드에서 kubectl을 거쳐 실행되는 모든 명령은 이 API 서버를 거쳐 수행되며, 컨트롤 플레인(Control Plane)에 포함된 클러스터 제어 요소나 워커 노드(Worker Node)에 포함된 kubelet, 프록시 역시 API 서버를 항상 바라보게 되어 있다.
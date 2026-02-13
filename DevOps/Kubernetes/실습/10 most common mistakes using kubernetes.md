
## 1. resources - requests와 limits

- CPU request는 보통 **설정하지 않거나** **매우 낮게 설정**하여(각 노드에 많은 Pod를 배치하기 위해) 노드가 오버커밋 상태가 된다. 높은 부하 시 노드의 CPU가 완전히 사용되면 워크로드는 "요청한 만큼"만 받게 되어 **CPU 쓰로틀링**이 발생하고, 애플리케이션 레이턴시 증가, 타임아웃 등의 문제가 생긴다.

- 반면 CPU limit은 노드의 CPU가 완전히 사용되지 않더라도 Pod를 불필요하게 쓰로틀링하여 레이턴시를 증가시킬 수 있다. Linux 커널의 CPU CFS 할당량과 설정된 CPU limit 기반 쓰로틀링, CFS 할당량 비활성화에 대한 논의가 진행 중이다. CPU limit은 해결하는 것보다 더 많은 문제를 일으킬 수 있다.

- 메모리 오버커밋은 더 큰 문제를 야기한다. CPU limit에 도달하면 쓰로틀링이 발생하지만, 메모리 limit에 도달하면 Pod가 종료(OOMKill)된다. 이를 최소화하려면 메모리를 오버커밋하지 말고, 아래 예시처럼 메모리 request를 limit과 동일하게 설정하여 Guaranteed QoS를 사용한다. ([참조](https://www.slideshare.net/try_except_/optimizing-kubernetes-resource-requestslimits-for-costefficiency-and-latency-highload))

- Burstable (OOMKill 발생 가능성이 더 높음):

    ```yaml
    resources:
    requests:
      memory: "128Mi"
      cpu: "500m"
    limits:
      memory: "256Mi"
      cpu: 2
    ```

- Guaranteed:

    ```yaml
    resources:
    requests:
      memory: "128Mi"
      cpu: 2
    limits:
      memory: "128Mi"
      cpu: 2
    ```

- metrics-server를 사용하면 Pod(및 내부 컨테이너)의 현재 CPU와 메모리 사용량을 확인할 수 있다. 리소스 설정 시 참고할 수 있다.

    ```bash
    kubectl top pods
    kubectl top pods --containers
    kubectl top nodes
    ```

- 하지만 이것은 현재 사용량만 보여준다. 대략적인 수치를 파악하는 데는 좋지만, 결국 **시간에 따른 사용량 메트릭**(예: 피크 시 CPU 사용량, 어제 오전의 사용량 등)을 보고 싶어지게 된다. 이를 위해 Prometheus, DataDog 등을 사용할 수 있다. metrics-server의 메트릭을 수집하여 저장하고 쿼리 및 그래프로 확인할 수 있다.

- [VerticalPodAutoscaler](https://cloud.google.com/kubernetes-engine/docs/concepts/verticalpodautoscaler)를 사용하면 시간에 따른 CPU/메모리 사용량을 확인하고 이를 기반으로 request와 limit을 설정하는 수동 과정을 **자동화**할 수 있다.

## 2. liveness와 readiness probes

- Liveness probe는 실패 시 Pod를 재시작한다.
- Readiness probe는 실패 시 해당 Pod를 Kubernetes 서비스에서 분리하여(`kubectl get endpoints`로 확인 가능) 다시 성공할 때까지 트래픽을 보내지 않는다.

- 기본적으로 liveness와 readiness probe는 설정되어 있지 않다. 하지만 설정하지 않으면 복구 불가능한 에러 발생 시 서비스가 어떻게 재시작될 수 있겠는가? 로드 밸런서는 특정 Pod가 트래픽 처리를 시작할 수 있는지, 더 많은 트래픽을 처리할 수 있는지 어떻게 알 수 있겠는가? liveness와 readiness probe는 Pod의 전체 라이프사이클 동안 실행되며, Pod 복구에 매우 중요하다.

- Readiness probe는 시작 시 Pod가 Ready 상태가 되어 트래픽 처리를 시작할 수 있는지 알려주는 것뿐만 아니라, Pod의 수명 동안에도 실행된다. Pod가 너무 많은 트래픽(또는 비용이 큰 연산)을 처리하느라 과열된 경우 더 이상 작업을 보내지 않고 쿨다운시킨 뒤, readiness probe가 성공하면 다시 트래픽을 보내기 시작한다.
  - 이 경우 liveness probe까지 실패하는 것은 매우 역효과적이다. 정상적으로 많은 작업을 처리하고 있는 Pod를 왜 재시작하겠는가?
  - 때로는 probe를 아예 정의하지 않는 것이 잘못 정의하는 것보다 낫다. liveness probe가 readiness probe와 동일하게 설정되어 있다면 큰 문제가 생길 수 있다. readiness probe만 먼저 정의하는 것이 좋다. liveness probe는 위험할 수 있기 때문이다.

- 공유 의존성이 다운되었을 때 어느 쪽 probe든 실패하게 만들면 안 된다. 모든 Pod가 연쇄적으로 실패하는 장애를 초래하게 된다.

## 3. Kubernetes를 인식하지 못하는 클러스터 오토스케일링

- Pod를 스케줄링할 때는 Pod 및 노드 어피니티, 테인트와 톨러레이션, 리소스 request, QoS 등 많은 **스케줄링 제약 조건**을 기반으로 결정한다. 이러한 제약 조건을 이해하지 못하는 외부 오토스케일러를 사용하면 문제가 발생할 수 있다.

- 사용 가능한 모든 CPU가 request되어 새 Pod가 **Pending 상태**에 갇힌 상황을 상상해보자. 외부 오토스케일러는 현재 CPU 사용량(request가 아닌)의 평균만 보고 스케일 아웃하지 않을 것이다(노드를 추가하지 않는다). Pod는 스케줄링되지 않는다.

- 스케일 인(클러스터에서 노드 제거)은 항상 더 어렵다. persistent volume이 연결된 스테이트풀 Pod가 있다고 가정하자. **persistent volume**은 보통 **특정 가용 영역에 속하는** 리소스이고 리전 내에서 복제되지 않으므로, 커스텀 오토스케일러가 이 Pod가 있는 노드를 제거하면 스케줄러가 persistent 디스크가 있는 가용 영역 제한 때문에 다른 노드에 스케줄링할 수 없다. Pod는 다시 Pending 상태에 갇힌다.

- 커뮤니티에서는 클러스터 내에서 실행되며 대부분의 주요 퍼블릭 클라우드 벤더 API와 통합된 **[cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)**를 널리 사용한다. 위에서 언급한 모든 제약 조건을 이해하고 해당 경우에 스케일 아웃한다. 또한 설정한 제약 조건에 영향을 주지 않고 안전하게 스케일 인할 수 있는지 판단하여 컴퓨팅 비용을 절약한다.

## 4. IAM/RBAC 활용 부족

- 머신과 애플리케이션에 영구 시크릿이 있는 IAM 사용자를 사용하지 말고, 역할과 서비스 계정을 사용하여 임시 자격 증명을 생성해야 한다.

- 애플리케이션 설정에 access key와 secret key를 하드코딩하고, Cloud IAM이 있는데도 시크릿을 교체하지 않는 경우를 자주 본다. 적절한 경우에는 사용자 대신 IAM 역할과 서비스 계정을 사용해야 한다.

    ```yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/my-app-role
    name: my-serviceaccount
    namespace: default
    ```

- 또한 서비스 계정이나 인스턴스 프로파일에 필요하지 않은 admin이나 cluster-admin 권한을 부여하지 말아야 한다. 특히 K8s RBAC에서는 더 어렵지만, 그래도 노력할 가치가 있다.

## 5. Pod의 self anti-affinity

- 하나의 Deployment에서 여러 레플리카를 사용하는 경우 명시적으로 정의해야 한다.

- 다음과 같이 설정할 수 있다:

    ```yaml
    spec:
            topologySpreadConstraints:
            - maxSkew: 1
                topologyKey: kubernetes.io/hostname
                whenUnsatisfiable: DoNotSchedule
                labelSelector:
                matchLabels:
                    ket: value
    ```

- 또는 다음과 같이:

    ```yaml
    affinity:
                podAntiAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                    - labelSelector:
                        matchExpressions:
                        - key: "key"
                            operator: In
                            values:
                            - value
                    topologyKey: "kubernetes.io/hostname"
    ```

- 이렇게 하면 Pod가 서로 다른 노드에 스케줄링된다(이것은 스케줄링 시점에만 확인되고 실행 시점에는 확인하지 않으므로 `requiredDuringSchedulingIgnoredDuringExecution`으로 설정).

- 여기서 다루는 것은 서로 다른 노드 이름에 대한 podAntiAffinity이며, 서로 다른 가용 영역에 대한 것이 아니다. 진정한 고가용성이 필요하다면 이 주제를 더 깊이 살펴봐야 한다.

## 6. 공유 클러스터에서의 멀티 테넌트 또는 환경

- Kubernetes 네임스페이스는 강력한 격리를 제공하지 않는다.

- 비프로덕션 워크로드를 하나의 네임스페이스에, 프로덕션을 prod 네임스페이스에 분리하면 하나의 **워크로드가 다른 것에 절대 영향을 미치지 않을 것**이라고 기대하는 경향이 있다. 리소스 request와 limit, 할당량, priorityClass로 일정 수준의 공정성을 달성하고, 어피니티, 톨러레이션, 테인트(또는 nodeSelector)로 데이터 플레인에서 워크로드를 "물리적으로" 분리하여 격리를 달성할 수 있지만, 이 분리는 꽤 **복잡**하다.

- 같은 클러스터에 두 유형의 워크로드를 모두 두어야 한다면 그 복잡성을 감수해야 한다. 필요하지 않고 **별도 클러스터**를 만드는 것이 비교적 저렴하다면(퍼블릭 클라우드에서처럼) 다른 클러스터에 배치하여 훨씬 강력한 격리를 달성하는 것이 낫다.

## 7. externalTrafficPolicy: Cluster

- 매우 자주 보이는 실수이다. 모든 트래픽이 클러스터 내부의 NodePort 서비스로 라우팅되는데, 이 서비스의 기본 설정은 `externalTrafficPolicy: Cluster`이다. 이는 클러스터의 모든 노드에 NodePort가 열려서 원하는 서비스(Pod 집합)와 통신하기 위해 아무 노드나 사용할 수 있음을 의미한다.

<img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/4769b803-dbd6-4b9b-8368-4675300f5682" height=300px>

- 대부분의 경우 NodePort 서비스가 대상으로 하는 실제 Pod는 **해당 노드의 일부에서만 실행**된다. 즉, Pod가 실행되지 않는 노드와 통신하면 다른 노드로 트래픽을 포워딩하게 되어 **추가 네트워크 홉**과 레이턴시 증가가 발생한다(노드가 서로 다른 AZ/데이터센터에 있으면 레이턴시가 상당히 높아질 수 있고 추가 이그레스 비용도 발생한다).

- Kubernetes 서비스에 `externalTrafficPolicy: Local`을 설정하면 모든 노드가 아닌 Pod가 실제로 실행 중인 노드에서만 NodePort가 열린다. 엔드포인트 헬스체크를 수행하는 외부 로드 밸런서(AWS ELB 등)를 사용하면 트래픽을 보내야 할 노드에만 **트래픽을 전송**하게 되어 레이턴시, 컴퓨팅 오버헤드, 이그레스 비용이 개선된다.

- traefik이나 nginx-ingress-controller가 인그레스 HTTP 트래픽 라우팅을 처리하기 위해 NodePort(또는 NodePort를 사용하는 LoadBalancer)로 노출되어 있을 가능성이 높으며, 이 설정으로 해당 요청의 레이턴시를 크게 줄일 수 있다.

---
참고

- <https://blog.pipetail.io/posts/2020-05-04-most-common-mistakes-k8s/>
- <https://medium.com/@SkyscannerEng/how-a-couple-of-characters-brought-down-our-site-356ccaf1fbc3>

> Metrics Server is a scalable, efficient source of container resource metrics for Kubernetes built-in autoscaling pipelines.

K8s *메트릭 API(Metrics API)* 는 자동 스케일링 및 비슷한 사용 사례를 지원하기 위한 기본적인 메트릭 집합을 제공한다. 이 API를 사용해 노드와 파드의 CPU 및 메모리 사용량을 쉽게 쿼리할 수 있다. (`[kubectl top](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#top)` 명령어 사용)

[HorizontalPodAutoscaler](https://kubernetes.io/ko/docs/tasks/run-application/horizontal-pod-autoscale/)(HPA) 와 [VerticalPodAutoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler#readme)(VPA)를 사용하는 경우, 워크로드 레플리카와 리소스를 조정하기 위해 메트릭 API의 데이터가 이용된다.

<img width="689" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/0d4c8d11-9fe6-4f5b-a34a-65fbc15c6816">

### 구조

- [cAdvisor](https://github.com/google/cadvisor): kubelet에 포함된 컨테이너 메트릭을 수집, 집계, 노출하는 데몬
- [kubelet](https://kubernetes.io/ko/docs/concepts/overview/components/#kubelet): 컨테이너 리소스 관리를 위한 노드 에이전트.
  - 리소스 메트릭은 kubelet API 엔드포인트 `/metrics/resource` 및 `/stats` 를 사용하여 접근 가능하다.
- [요약 API](https://kubernetes.io/ko/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/#summary-api-source): `/stats` 엔드포인트를 통해 사용할 수 있는 노드 별 요약된 정보를 탐색 및 수집할 수 있도록 kubelet이 제공하는 API
- [metrics-server](https://kubernetes.io/ko/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/#metrics-server): 각 kubelet으로부터 수집한 리소스 메트릭을 수집 및 집계하는 클러스터 애드온 구성 요소.
API 서버는 HPA, VPA 및 `kubectl top` 명령어가 사용할 수 있도록 메트릭 API를 제공한다.
  - metrics-server는 메트릭 API에 대한 기준 구현(reference implementation) 중 하나이다.
- [메트릭 API](https://kubernetes.io/ko/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/#metrics-api): 워크로드 오토스케일링에 사용되는 CPU 및 메모리 정보로의 접근을 지원하는 쿠버네티스 API.
  - 이를 클러스터에서 사용하려면, 메트릭 API를 제공하는 API 확장(extension) 서버가 필요하다.

### 설치

아래 명령어로 메트릭 API를 제공하는 metrics-server(API 확장 서버)를 설치할 수 있다.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 예시

- `[kubectl top](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#top)` 명령어를 사용하여 여러 정보를 조회할 수 있다.

    ```bash
    ~ kubectl top --help
    Display Resource (CPU/Memory) usage.
    
     The top command allows you to see the resource consumption for nodes or pods.
    
     This command requires Metrics Server to be correctly configured and working on the server.
    
    Available Commands:
      node          Display resource (CPU/memory) usage of nodes
      pod           Display resource (CPU/memory) usage of pods
    
    Usage:
      kubectl top [flags] [options]
    
    Use "kubectl <command> --help" for more information about a given command.
    Use "kubectl options" for a list of global command-line options (applies to all commands).
    ```

- node별 CPU, memory 사용량 조회

    ```bash
    ~ kubectl top node
    NAME                                              CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
    ip-10-0-128-227.ap-northeast-2.compute.internal   99m          5%     2810Mi          40%
    ip-10-0-128-242.ap-northeast-2.compute.internal   257m         13%    6427Mi          91%
    ip-10-0-140-151.ap-northeast-2.compute.internal   136m         7%     3203Mi          45%
    ip-10-0-142-0.ap-northeast-2.compute.internal     285m         14%    5090Mi          72%
    ip-10-0-143-249.ap-northeast-2.compute.internal   484m         25%    6083Mi          86%
    ```

- Pod별 CPU, memory 사용량 조회

    ```bash
    ~ kubectl top pods -A
    NAMESPACE        NAME                                                        CPU(cores)   MEMORY(bytes)
    argocd           argocd-application-controller-0                             46m          205Mi
    argocd           argocd-applicationset-controller-7865bfc576-72mtf           1m           25Mi
    argocd           argocd-dex-server-bb6887f96-7s6n4                           1m           17Mi
    argocd           argocd-notifications-controller-8695b6f65f-9nbvw            1m           19Mi
    argocd           argocd-redis-679d4b99df-pqntm                               2m           4Mi
    argocd           argocd-repo-server-5d66db8598-mlr26                         1m           64Mi
    argocd           argocd-server-56589dc7cb-786dh                              1m           18Mi
    cert-manager     cert-manager-6687c95c6d-t84xg                               4m           80Mi
    cert-manager     cert-manager-cainjector-74dc4cdd47-77t2m                    4m           102Mi
    cert-manager     cert-manager-webhook-8bf9564f7-lpmpq                        4m           63Mi
    dex              dex-5cd4985855-4kdxk                                        3m           65Mi
    dex              dex-k8s-authenticator-87d9dfb57-4sn59                       3m           60Mi
    dex              kube-oidc-proxy-69d9c5c488-kfbt4                            4m           67Mi
    istio-operator   istio-operator-97fb74554-gdg5k                              2m           66Mi
    istio-system     istio-ingressgateway-5dbdb957bc-mk22s                       6m           55Mi
    istio-system     istio-ingressgateway-5dbdb957bc-mpd9l                       5m           52Mi
    istio-system     istiod-ff577f8b8-5px7d                                      2m           114Mi
    istio-system     jaeger-58c79c85cd-kw9w9                                     8m           39Mi
    istio-system     kiali-749d76d7bb-7h4jv                                      2m           35Mi
    istio-system     prometheus-5d5d6d6fc-bk5bk                                  114m         1091Mi
    ...
    ```

### 참고

[GitHub - kubernetes-sigs/metrics-server: Scalable and efficient source of container resource metrics for Kubernetes built-in autoscaling pipelines.](https://github.com/kubernetes-sigs/metrics-server)

[Resource metrics pipeline](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)

[노드 메트릭 데이터](https://kubernetes.io/ko/docs/reference/instrumentation/node-metrics/)


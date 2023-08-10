# Istio RBAC

Istio RBAC를 통해 네임스페이스, 서비스, HTTP 메소드 수준의 권한 제어를 실습 해보자.

### 준비작업

1. k8s, helm 설치
2. Istio 초기화 (namespace, CRDs)
   
```bash
$ wget https://github.com/istio/istio/releases/download/1.8.2/istio-1.8.2-osx.tar.gz
$ tar -vxzf istio-1.8.2-osx.tar.gz
$ cd istio-1.8.2
$ kubectl create namespace istio-system
$ helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
```

3. Istio ingresgateway는 노드 포트로 설치

```bash
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
--set gateways.istio-ingressgateway.type=NodePort \
| kubectl apply -f -
```

4. Istio pod 정상상태 확인 및 대기
   
```bash
$ kubectl get pod -n istio-system
```

5. bookinfo 설치
   
```bash
$ kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml)
$ kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
$ kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
```

6. `/productpage` 정상 동작여부 확인

```bash
$ INGRESS_URL=http://$(minikube ip -p istio-security):$(k get svc/istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')/productpage
$ curl -I $INGRESS_URL
```

7. productpage 와 reviews 의 서비스를 위한 ServiceAccount 생성

```bash
$ kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo-add-serviceaccount.yaml)
```

8. 브라우저에서 `/productpage` URL 접속해보기

```bash
echo $INGRESS_URL
```

### Istio authorization 활성화

- ClusterRbacConfig를 구성하여 네임스페이스 “default”에 대한 Istio authorization을 활성화한다.

```yaml
$ kubectl apply -f - <<EOF
apiVersion: "rbac.istio.io/v1alpha1"
kind: ClusterRbacConfig
metadata:
  name: default
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["default"]
EOF
```

authorization 대상을 지정하지 않았으므로 `/productpage`에 요청을 보내면 `RBAC: access denied`가 반환된다.

```bash
$ curl $INGRESS_URL
RBAC: access denied
```

---

# Namespace-level 접근 제어

- 네임스페이스 레벨에서 접근 제어를 정의한다.
- app 라벨이 `[“productpage”, “details”, “reviews”, “ratings”]` 인 서비스의 `“GET”` 호출에 대해 ServiceRole을 정의하고 전체 사용자에게 ServiceRole을 부여한다. **(ServiceRoleBinding)**

```yaml
$ kubectl apply -f - <<EOF
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: my-role
  namespace: default
spec:
  rules:
  - services: ["*"]
    methods: ["GET"]
    constraints:
    - key: "destination.labels[app]"
      values: ["productpage", "details", "reviews", "ratings"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: my-role-binding
  namespace: default
spec:
  subjects:
    - user: "*"
  roleRef:
    kind: ServiceRole
    name: "my-role"
EOF
```

결과: `“RBAC: access denied”` 에서 정상적인 화면으로 전환된다.

```yaml
$ echo $INGRESS_URL
```

### cleanup

```bash
$ kubectl delete ServiceRole --all
$ kubectl delete ServiceRoleBinding --all
```

---

# Service-level 접근 제어

### #1. productpage 서비스 접근 허용

- 네임스페이스가 아닌 특정 서비스에 대해서 접근 제어를 허용하는 예제

- ServiceRole에 특정 서비스(`productpage.default.svc.cluster.local`)의 GET 메소드에 대한 ServiceRole을 부여하도록 정의하고 전체 사용자에게 ServiceRole를 부여(ServiceRoleBinding)한다.

```yml
$ kubectl apply -f - <<EOF
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: my-role
  namespace: default
spec:
  rules:
  - services: ["productpage.default.svc.cluster.local"]
    methods: ["GET"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: my-role-binding
  namespace: default
spec:
  subjects:
  - user: "*"
  roleRef:
    kind: ServiceRole
    name: "my-role"
EOF
```

- 결과: `/productpage`는 정상적으로 조회되지만 Detail 과 Review 부분은 에러가 발생한다.

```bash
$ echo $INGRESS_URL
```

### #2. details & reviews 서비스 접근 허용

- details과 reviews의 서비스에도 ServiceRole을 부여해보자.
- ServiceRole 이름을 새로 생성했으므로 이전 ServiceRole, ServiceRoleBinding과 함께 적용된다.

```yml
$ kubectl apply -f - <<EOF
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: details-reviews-viewer  
  namespace: default
spec:
  rules:
  - services: ["details.default.svc.cluster.local", "reviews.default.svc.cluster.local"]
    methods: ["GET"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: bind-details-reviews
  namespace: default
spec:
  subjects:
  - user: "*"
  roleRef:
    kind: ServiceRole
    name: "details-reviews-viewer"
EOF
```

```yml
$ kubectl apply -f - <<EOF
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: ratings-viewer
  namespace: default
spec:
  rules:
  - services: ["ratings.default.svc.cluster.local"]
    methods: ["GET"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: bind-ratings
  namespace: default
spec:
  subjects:
  - user: "*"
  roleRef:
    kind: ServiceRole
    name: "ratings-viewer"
EOF
```

결과: review, rating이 정상적으로 조회된다.

```bash
$ echo $INGRESS_URL
```

### cleanup

```bash
$ kubectl delete servicerole --all
$ kubectl delete servicerolebinding --all
$ kubectl delete clusterrbacconfig --all
```

---
참고
- https://rafabene.com/istio-tutorial/istio-tutorial/1.2.x/8rbac.html
- https://istio.io/latest/docs/concepts/security/#authorization
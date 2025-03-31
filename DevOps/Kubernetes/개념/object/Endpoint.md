
### Endpoints

- Service가 선택한 **Pod들의 IP와 Port 정보를 저장하는 리소스**.
- Service가 특정 Pod들을 대상으로 트래픽을 라우팅하기 위해 필요.
- `selector`가 있는 Service가 생성되면 자동으로 생성됨.
- `kubectl get endpoints <service-name>` 명령어로 확인 가능.

**Endpoints 예제 (기본 구조)**:

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: my-service
subsets:
  - addresses:
      - ip: 10.0.0.1
      - ip: 10.0.0.2
    ports:
      - port: 80
```

- 위 예제에서 `my-service`는 `10.0.0.1:80`, `10.0.0.2:80` 두 개의 Pod로 트래픽을 보낼 수 있음.

### EndpointSlice

- Endpoints 리소스의 확장 버전으로, Kubernetes 1.17부터 도입됨.
- Endpoints가 **하나의 오브젝트에 모든 엔드포인트를 저장하는 방식**이라면, EndpointSlice는 **여러 개의 작은 단위로 나눠서 저장**하는 방식.
- 확장성과 성능을 고려하여 도입됨.

**EndpointSlice 예제 (기본 구조)**:

```yaml
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: my-service-xyz
  labels:
    kubernetes.io/service-name: my-service
endpoints:
  - addresses:
      - 10.0.0.1
  - addresses:
      - 10.0.0.2
ports:
  - port: 80
```

- 하나의 Service에 대한 여러 개의 EndpointSlice가 존재할 수 있음.
- Endpoints와 다르게, 여러 개의 `EndpointSlice`에 분산 저장되어 확장성과 성능이 향상됨.

---

## 2. Service와 Endpoints, EndpointSlice의 동작 방식

1. **Service 생성**
   - `selector`를 통해 특정 Pod들을 찾음.
   - `selector`가 없을 경우 수동으로 Endpoints 또는 EndpointSlice를 생성해야 함.

2. **Endpoints 또는 EndpointSlice 자동 생성**
   - Kubernetes 컨트롤러가 `selector`에 맞는 Pod을 찾아 Endpoints 또는 EndpointSlice를 자동 생성.
   - EndpointSlice는 클러스터의 크기에 따라 여러 개로 분할됨.

3. **트래픽 라우팅**
   - Service에 접근하면 kube-proxy가 Endpoints 또는 EndpointSlice 정보를 이용하여 적절한 Pod로 트래픽을 전달.

---

## 3. EndpointSlice가 도입된 이유

### **Endpoints의 문제점**

- **대규모 클러스터에서 성능 저하**  
  - 모든 Pod의 정보를 하나의 Endpoints 객체에 저장하면, Pod 개수가 많아질수록 etcd에 부담이 증가함.
  - 변경 사항이 발생할 때마다 전체 Endpoints 객체를 갱신해야 하므로, etcd 및 kube-proxy의 부하가 증가.

- **리소스 관리의 비효율성**  
  - 1000개 이상의 Pod이 하나의 서비스에 속할 경우, Endpoints 오브젝트가 매우 커지면서 업데이트 비용이 증가.

### **EndpointSlice의 장점**

**확장성**  

- 여러 개의 EndpointSlice로 나눠 저장하여 etcd 부하 감소.  
- Pod 수가 증가해도 개별 Slice만 업데이트하므로 성능 향상.  

**성능 최적화**  

- Endpoints보다 가볍고 네트워크 업데이트 속도가 빠름.  
- kube-proxy가 더 작은 단위로 정보를 가져와서 처리 가능.  

**다양한 프로토콜 지원**  

- TCP, UDP, SCTP 등의 다양한 프로토콜을 지원.

## 4. 정리

| 항목 | Endpoints | EndpointSlice |
|------|----------|--------------|
| 데이터 저장 방식 | 단일 오브젝트 | 여러 개의 작은 Slice로 분할 |
| 확장성 | 낮음 (Pod 증가 시 성능 저하) | 높음 (클러스터가 커질수록 유리) |
| 업데이트 비용 | 높음 (전체 오브젝트 수정) | 낮음 (부분 업데이트 가능) |
| Kubernetes 버전 | 기본 (오래된 방식) | 1.17+부터 기본 |
| etcd 부하 | 증가 가능 | 분산 저장으로 감소 |

---
참고

- <https://kubernetes.io/docs/concepts/services-networking/service/#endpoints>
- <https://kubernetes.io/docs/concepts/services-networking/endpoint-slices>

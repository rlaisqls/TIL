
Endpoints는 Service가 트래픽을 보낼 대상 Pod들의 IP와 포트 정보를 저장하는 리소스다.

Service를 생성하면 어떻게 될까? `selector`에 매칭되는 Pod들을 찾아서, 그 Pod들의 IP 주소를 Endpoints 오브젝트에 자동으로 등록한다. kube-proxy는 이 Endpoints를 보고 iptables/IPVS 규칙을 만들어 실제 트래픽을 라우팅한다.

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

위 Endpoints는 `my-service`로 들어오는 트래픽을 `10.0.0.1:80`, `10.0.0.2:80` 두 Pod로 분산한다는 의미다.

selector가 없는 Service를 만들면 Endpoints가 자동 생성되지 않는다. 이 경우 직접 Endpoints를 만들어서 외부 시스템을 Service처럼 사용할 수 있다.

```yaml
# selector 없는 Service
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  ports:
    - port: 5432
---
# 수동으로 생성하는 Endpoints
apiVersion: v1
kind: Endpoints
metadata:
  name: external-db  # Service 이름과 동일해야 함
subsets:
  - addresses:
      - ip: 192.168.10.50
    ports:
      - port: 5432
```

이렇게 하면 클러스터 내에서 `external-db:5432`로 접근하면 외부 데이터베이스 `192.168.10.50:5432`로 연결된다.

## Endpoints의 한계

Endpoints는 모든 엔드포인트를 하나의 오브젝트에 저장한다. Pod가 몇 개일 때는 문제없지만, 수백~수천 개가 되면 Pod 하나가 추가되거나 삭제될 때마다 전체 Endpoints 오브젝트를 업데이트해야 한다. 1000개 Pod 중 1개만 바뀌어도 1000개 전체를 다시 전송한다. 이 때 etcd와 이를 watch하는 kube-proxy에 부담이 될 수 있다.

이 문제를 해결하기 위해 Kubernetes 1.17에서 [EndpointSlice](EndpointSlice.md)가 도입되었다. EndpointSlice는 엔드포인트를 여러 개의 작은 슬라이스로 나눠서 저장하므로, 변경이 있을 때 해당 슬라이스만 업데이트하면 된다.

현재 Kubernetes에서는 EndpointSlice가 기본이고, 기존 Endpoints는 호환성을 위해 유지되고 있다.

---

참고

- <https://kubernetes.io/docs/concepts/services-networking/service/#endpoints>
- <https://kubernetes.io/docs/concepts/services-networking/endpoint-slices>

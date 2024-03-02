
Istio는 `ClusterRbacConfig`를 통해 ServiceRole에 권한 Rule을 정의한 후 ServiceRoleBinding을 통해 특정 대상에 해당 ServiceRole에 지정하여 접근 제어를 수행한다. mesh, namespace, workload 범위에서의 access control을 적용할 수 있다.

Istio authorization을 사용했을 때 얻을 수 있는 이점은 아래와 같다.

- 간단한 API: AuthorizationPolicy CRD를 통해 쉬운 접근 제어가 가능하다.
- 유연한 설정: CUSTOM, DENY 및 ALLOW 등 Istio 특성에 대한 사용자 지정 조건을 자유롭게 정의할 수 있다.
- 고성능: Envoy native를 사용하기에 성능이 우수하다.
- 높은 호환성: gRPC, HTTP, HTTPS, HTTP/2, plain TCP 등 여러 프로토콜을 지원하여 상황에 맞게 사용할 수 있다.

![image](https://github.com/rlaisqls/TIL/assets/81006587/dbb9146a-ffbf-48d5-8208-560772f0a939)

## Authorization policy

아무 설정도 하지 않은 상태의 Workload는 기본적으로 모든 요청을 허용하는데, 특정 규칙에 따른 access control을 사용하기 위해선 Authorization policy를 적용하면 된다. 

Authorization policy는 `ALLOW`, `DENY`, `CUSTOM` action을 지원한다. 한 workload에 여러 정책을 적용할 수도 있다. 각 action들은 아래와 같은 순서로 검증된다.

<img width="386" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/a5a4c4ee-6159-4639-b378-7e0233b9247d">

### 코드 예시

Authorization policy는 selector, action, rule 목록 이렇게 총 3개 부분으로 구성되어있다.

- `selector`: policy의 타겟 지정
- `action`: `ALLOW`, `DENY`, `CUSTOM` 중 하나의 action
- `rules`: 적용 규칙
  - `from`: 요청하는 주체에 대한 규칙
  - `to`: 요청을 처리하는 주체에 대한 규칙
  - `when`: 적용할 경우에 대한 condition 정의

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep"]
   - source:
       namespaces: ["dev"]
   to:
   - operation:
       methods: ["GET"]
   when:
   - key: request.auth.claims[iss]
     values: ["https://accounts.google.com"]
```


---
참고
- https://rafabene.com/istio-tutorial/istio-tutorial/1.2.x/8rbac.html
- https://istio.io/latest/docs/concepts/security/#authorization
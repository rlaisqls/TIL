
Thanos is a set of components that can be composed into a highly available metric system with unlimited storage capacity, which can be added seamlessly on top of existing Prometheus deployments that included in CNCF Incubating project.

Thanos leverages the Prometheus 2.0 storage format to cost-efficiently store historical metric data in any object storage while retaining fast query latencies. Additionally, it provides a global query view across all Prometheus installations and can merge data from Prometheus HA pairs on the fly.

Concretely the aims of the project are:

1. Global query view of metrics.
2. Unlimited retention of metrics.
3. High availability of components, including Prometheus.

## Features

- Global querying view across all connected Prometheus servers
- Deduplication and merging of metrics collected from Prometheus HA pairs
- Seamless integration with existing Prometheus setups
- Any object storage as its only, optional dependency
- Downsampling historical data for massive query speedup
- Cross-cluster federation
- Fault-tolerant query routing
- Simple gRPC "Store API" for unified data access across all metric data
- Easy integration points for custom metric providers

## Architecture

Deployment with Sidecar for Kubernetes:

![image](https://github.com/rlaisqls/TIL/assets/81006587/cad6a570-e180-40cd-b161-11af7b0e6543)

Deployment with Receive in order to scale out or implement with other remote write compatible sources:

![image](https://github.com/rlaisqls/TIL/assets/81006587/aef440a3-a1e7-43f3-9faa-1acf22603a41)

## Component

- **Thanos Sidecar**
  - Prometheus에 Sidecar로 설치됨
  - Prometheus metric을 설정한 스토리지에 저장함
  - 쿼리시 참조됨
- **Thanos Query**
  - 데이터 쿼리하기 위한 모듈
  - 아직 Storage로 안옮긴 최근 데이터는 SideCar에서, 오래된 데이터는 Storage Gateway에서 참조해서 가져옴
  - promQL 동일하게 쓸 수 있음
  - kiali, grafana 등 대시보드에도 prometheus url을 넣었던 곳에 Thanos Query url을 연결해줘야함
- **Thano Storage Gateway**
  - Prometheus 쿼리 할 때 스토리지에 저장된 데이터를 같이 가져올 수 있게 함
  - 중간에 캐시 제공 역할도 해준다
- **Thanos Compactor**
  - 데이터 파일 압축 및 다운 샘플링(오래된 건 시간 단위로 묶어줌)

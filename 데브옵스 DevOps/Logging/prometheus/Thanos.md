# Thanos

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



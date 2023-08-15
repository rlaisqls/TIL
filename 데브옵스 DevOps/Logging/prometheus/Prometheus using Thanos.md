# Prometheus using Thanos

![image](https://github.com/rlaisqls/TIL/assets/81006587/dc8953cd-7b3d-4733-9b4c-bac0edbc9d4f)

### Prometheus

[Prometheus](prometheus.md) is an **open source systems monitoring and alerting toolkit** that is widely adopted as a standard monitoring tool with self-managed and provider-managed Kubernetes. Prometheus provides many useful features, such as dynamic service discovery, powerful queries, and seamless alert notification integration. Beyond certain scale, however, problems arise when basic Prometheus capabilities do not meet requirements such as:

- Storing petabyte-scale historical data in a reliable and cost-efficient way
- Accessing all metrics using a single-query API
- Merging replicated data collected via Prometheus high-availability (HA) setups

### Thanos

[Thanos](https://github.com/thanos-io/thanos) was built in response to these challenges. Thanos, which is released under the Apache 2.0 license, offers a set of components that can be composed into a highly available Prometheus setup with long-term storage capabilities. Thanos uses the Prometheus 2.0 storage format to cost-efficiently store historical metric data in object storage, such as Amazon Simple Storage Service (Amazon S3), while retaining fast query latencies. In summary, Thanos is intended to provide:

- Global query view of metrics
- Virtually unlimited retention of metrics, including downsampling
- High availability of components, including support for Prometheus HA

Thanos are consists by few componets like below.

![image](https://github.com/rlaisqls/TIL/assets/81006587/ad2e74d6-3763-403b-a690-f5ee7a0b2780)

- **Thanos SideCar**: SideCar runs with every Prometheus instance. The sidecar uploads Prometheus data every two hours to storage (an S3 bucket in our case). It also serves real-time metrics that are not uploaded in bucket.
- **Thanos Store**: Store serves metrics from Amazon S3 storage.
- **Thanos Querier**: Querier has a user interface similar to that of Prometheus and it handles Prometheus query API. Querier queries Store and Sidecar to return the relevant metrics. If there are multiple Prometheus instances set up for HA, it can also de-duplicate the metrics.

We can also install Thanos Compactor, which applies compaction procedure to Prometheus block data stored in an S3 bucket. It is also responsible for downsampling data.

## Practice 

Let's learn how to implement with Thanos for that. To deploy the Thanos components, we complete the following:

![image](https://github.com/rlaisqls/TIL/assets/81006587/ca6882bc-b984-4131-be05-a5afaf05ac2b)

1. Enable Thanos Sidecar for Prometheus.
2. Deploy Thanos Querier with the ability to talk to Sidecar.
3. Confirm that Thanos Sidecar is able to upload Prometheus metrics to our S3 bucket.
4. Deploy Thanos Store to retrieve metrics data stored in long-term storage (in this case, our S3 bucket).
5. Set up Thanos Compactor for data compaction and downsampling.

You can integrate Thanos with Prometheus & Alertmanager using this chart and the [Bitnami kube-prometheus chart](https://github.com/bitnami/charts/tree/main/bitnami/kube-prometheus) following the steps below:

> Note: in this example we will use MinIO&reg; (subchart) as the Objstore. Every component will be deployed in the "monitoring" namespace.

- Create a **values.yaml** like the one below:

```yaml
objstoreConfig: |-
  type: s3
  config:
    bucket: thanos
    endpoint: {{ include "thanos.minio.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local:9000
    access_key: minio
    secret_key: minio123
    insecure: true
query:
  dnsDiscovery:
    sidecarsService: kube-prometheus-prometheus-thanos
    sidecarsNamespace: monitoring
bucketweb:
  enabled: true
compactor:
  enabled: true
storegateway:
  enabled: true
ruler:
  enabled: true
  alertmanagers:
    - http://kube-prometheus-alertmanager.monitoring.svc.cluster.local:9093
  config: |-
    groups:
      - name: "metamonitoring"
        rules:
          - alert: "PrometheusDown"
            expr: absent(up{prometheus="monitoring/kube-prometheus"})
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
minio:
  enabled: true
  auth:
    rootPassword: minio123
    rootUser: minio
  monitoringBuckets: thanos
  accessKey:
    password: minio
  secretKey:
    password: minio123
```

- Install Prometheus Operator and Thanos charts:

For Helm 3:

```bash
$ kubectl create namespace monitoring
helm install kube-prometheus \
    --set prometheus.thanos.create=true \
    --namespace monitoring \
    bitnami/kube-prometheus
helm install thanos \
    --values values.yaml \
    --namespace monitoring \
    oci://registry-1.docker.io/bitnamicharts/thanos
```

That's all! Now you have Thanos fully integrated with Prometheus and Alertmanager.

---
reference
- https://aws.amazon.com/ko/blogs/opensource/improving-ha-and-long-term-storage-for-prometheus-using-thanos-on-eks-with-s3/
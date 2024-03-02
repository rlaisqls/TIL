
Kiali requires Prometheus to generate the topology graph, show metrics, calculate health and for several other features. If Prometheus is missing or Kiali can’t reach it, Kiali won’t work properly.

By default, Kiali assumes that Prometheus is available at the URL of the form http://prometheus.<istio_namespace_name>:9090, which is the usual case if you are using the Prometheus Istio add-on. If your Prometheus instance has a different service name or is installed in a different namespace, you must manually provide the endpoint where it is available, like in the following example:

```yaml
spec:
  external_services:
    prometheus:
      # Prometheus service name is "metrics" and is in the "telemetry" namespace
      url: "http://metrics.telemetry:9090/"
```

Kiali maintains an internal cache of some Prometheus queries to improve performance (mainly, the queries to calculate Health indicators). It would be very rare to see data delays, but should you notice any delays you may tune caching parameters to values that work better for your environment. ([Kiali CR reference page](https://kiali.io/docs/configuration/kialis.kiali.io/#example-cr))

## Compatibility with Prometheus-like servers

Although Kiali assumes a Prometheus server and is tested against it, there are TSDBs that can be used as a Prometheus replacement despite not implementing the full Prometheus API.

Community users have faced two issues when using Prometheus-like TSDBs:

- Kiali may report that the TSDB is unreachable, and/or
- Kiali may show empty metrics if the TSBD does not implement the `/api/v1/status/config`.

To fix these issues, you may need to provide a custom health check endpoint for the TSDB and/or manually provide the configurations that Kiali reads from the `/api/v1/status/config` API endpoint:

```bash
spec:
  external_services:
    prometheus:
      # Fix the "Unreachable" metrics server warning.
      health_check_url: "http://custom-tsdb-health-check-url"
      # Fix for the empty metrics dashboards
      thanos_proxy:
        enabled: true
        retention_period: "7d"
        scrape_interval: "30s"
```

## Prometheus Tuning





---
reference
- https://kiali.io/docs/configuration/p8s-jaeger-grafana/prometheus/
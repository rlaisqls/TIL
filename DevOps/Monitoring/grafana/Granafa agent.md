
Grafana Agent is an OpenTelemetry Collector distribution with configuration. It is designed to be flexible, performant, and compatible with multiple ecosystems such as Prometheus and OpenTelemetry.

Grafana Agent is based around **components**. Components are wired together to form programmable observability **pipelines** for telemetry collection, processing, and delivery.

Grafana Agent is available in three different variants:

- [Static mode](https://grafana.com/docs/agent/latest/static/): The original Grafana Agent.
- [Static mode Kubernetes operator](https://grafana.com/docs/agent/latest/operator/): The Kubernetes operator for Static mode.
- [Flow mode](https://grafana.com/docs/agent/latest/flow/): The new, component-based Grafana Agent.

### Static mode

- [Static mode](https://grafana.com/docs/agent/latest/static/) is the original variant of Grafana Agent, introduced on March 3, 2020. Static mode is the most mature variant of Grafana Agent.

- Static mode is composed of different subsystems:
  
  - The metrics subsystem wraps around Prometheus for **collecting** Prometheus metrics **and forwarding them over the Prometheus** `remote_write` protocol.
  - The logs subsystem wraps around Grafana Promtail for **collecting logs and forwarding them to Grafana Loki.**
  - The traces subsystem wraps around OpenTelemetry Collector for **collecting traces and forwarding them to Grafana Tempo or any OpenTelemetry-compatible endpoint**.

- You should run Static mode when:
  
  - **Maturity**: You need to use the most mature version of Grafana Agent.
  - **Grafana Cloud integrations**: You need to use Grafana Agent with Grafana Cloud integrations.

### Static mode Kubernetes operator

- [The Static mode Kubernetes operator](https://grafana.com/docs/agent/latest/operator/) is a variant of Grafana Agent introduced on June 17, 2021. 

- The Static mode Kubernetes operator provides compatibility with Prometheus Operator, allowing static mode to support resources from Prometheus Operator, such as ServiceMonitors, PodMonitors, and Probes.

- You should run the Static mode Kubernetes operator when:

  - **Prometheus Operator compatibility**: You need to be able to consume ServiceMonitors, PodMonitors, and Probes from the Prometheus Operator project for collecting Prometheus metrics.

- The root of the custom resource hierarchy is the `GrafanaAgent` resource—the primary resource Agent Operator looks for. 
  
  - `GrafanaAgent` is called the root because it discovers other sub-resources, `MetricsInstance` and `LogsInstance`. 
  - The `GrafanaAgent` resource endows them with Pod attributes defined in the `GrafanaAgent` specification, for example, Pod requests, limits, affinities, and tolerations, and defines the Grafana Agent image.
  - You can only define Pod attributes at the `GrafanaAgent` level. They are propagated to MetricsInstance and LogsInstance Pods.

    <img width="467" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/71aa31f8-c3b1-46b4-80cc-e5f8842268f6">

### Flow mode

- Flow mode is a stable variant of Grafana Agent, introduced on September 29, 2022.

- Grafana Agent Flow mode focuses on vendor neutrality, ease-of-use, improved debugging, and ability to adapt to the needs of power users by adopting a configuration-as-code model.

- **Features**
  - Write declarative configurations with a Terraform-inspired configuration language.
  - Declare components to configure parts of a pipeline.
  - Use expressions to bind components together to build a programmable pipeline.
  - Includes a UI for debugging the state of a pipeline.

- Grafana Agent Flow is a [distribution](https://opentelemetry.io/ecosystem/distributions/) of the OpenTelemetry Collector.
  - As a distribution, Grafana Agent Flow includes dozens of OpenTelemetry-native components from the OpenTelemetry project and introduces new features such as programmable pipelines, clustering support, and the ability to share pipelines around the world.
  - In addition to being an OpenTelemetry Collector distribution, Grafana Agent Flow also includes first-class support for the Prometheus and Loki ecosystems, allowing you to mix-and-match your pipelines.

- You can configure the action of the flow mode agent by a declarative language called **river**:
  
  ```c
  // Discover Kubernetes pods to collect metrics from
  discovery.kubernetes "pods" {
    role = "pod"
  }

  // Scrape metrics from Kubernetes pods and send to a prometheus.remote_write
  // component.
  prometheus.scrape "default" {
    targets    = discovery.kubernetes.pods.targets
    forward_to = [prometheus.remote_write.default.receiver]
  }

  // Get an API key from disk.
  local.file "apikey" {
    filename  = "/var/data/my-api-key.txt"
    is_secret = true
  }

  // Collect and send metrics to a Prometheus remote_write endpoint.
  prometheus.remote_write "default" {
    endpoint {
      url = "http://localhost:9009/api/prom/push"

      basic_auth {
        username = "MY_USERNAME"
        password = local.file.apikey.content
      }
    }
  }
  ```


- You should run Flow mode when You need functionality unique to Flow mode:

  - **Improved debugging**: You need to more easily debug configuration issues using a UI.

  - **Full OpenTelemetry support**: Support for collecting OpenTelemetry metrics, logs, and traces.

  - **PrometheusRule support**: Support for the PrometheusRule resource from the Prometheus Operator project for configuring Grafana Mimir.

  - **Ecosystem transformation**: You need to be able to convert Prometheus and Loki pipelines to and from OpenTelmetry Collector pipelines.

  - **Grafana Pyroscope support**: Support for collecting profiles for Grafana Pyroscope.
  
---
참고
- https://grafana.com/docs/agent/latest/
- https://github.com/grafana/agent/tree/main
# prometheus agent mode

![image](https://github.com/rlaisqls/TIL/assets/81006587/3892a18f-6864-422e-9aff-b045f9b56929)

- The core design of Prometheus is inpired by Google's [Borgmon monitoring system](https://sre.google/sre-book/practical-alerting/#the-rise-of-borgmon), you can deploy a Prometheus server alongside the applications you want to monitor, tell Prometheus how to reach them, and allow to scrape the current values of their metrics at regular intervals.

- Such a collection method, which is often referred to as the "pull model", is the core principle that allow Prometheus to be lightweight and reliable.
  
- Futhermore, it enables application instrumentation and exporters to be dead simple, as they only need to provide a simple human-readable HTTP endpoint with the current value of all tracked metrics (in OpenMetrics format). All without complex push infrastructure and non-trivial client libraries. Overall, a simplified typical Prometheus monitoring deployment look as below:
    ![image](https://github.com/rlaisqls/TIL/assets/81006587/c8c0743b-0379-4046-9856-e28c86679936)

- This works great, and we have seen millions of successful deployments like this over the years that process dozens of milions of active series.

## How to get the Global View?

- However, with the advent of the concept of edge clusters or networks, we can see much smaller clusters with limited amounts of resources. So, we need to monitoring data has to be somehow aggregated, presented to users and sometimes even stored on the `Global-View` feature.

- Naively, we could think about implementing this by either putting Prometheus on that global level and scraping metrics across remote networks or pushing metrics directly from the application to the central location for monitoring purposes.  
  - Scraping across network boundaries can be a challenge if it adds new unknowns in a monitoring pipeline. The local pull model allows Prometheus to know why exactly the metric target has problems and when. Maybe it's down, misconfigured, restarted, too slow to give us metrics (e.g. CPU saturated), not discoverable by service discovery, we don't have credentials to access or just DNS, network, or the whole cluster is down.
  - Pushing metrics directly from the application to some central location is equally bad. Especially when you monitor a larger fleet, you know literally nothing when you don't see metrics from remote applications.

- Prometheus introduced three ways to support the global view case, each with its own pros and cons. Let's brify go through those. They arr shown in orange color in the diagram below:

![image](https://github.com/rlaisqls/TIL/assets/81006587/31f91957-ca61-4525-a40f-80a7f6bd2c3d)

1. **Federation**
   - Federation was introduced as the fist feature for aggregation purposes. It allows a global-level Prometheus server to scrape a subset of metrics from a leaf Prometheus.
   - Such a "federation" scrape reduces some unknowns across networks because metrics exposed by federation endpoints include the original samples' timestamps. Yet, it usually suffers from the inability to federate all metrics and not lose data during longer network partitions (minutes). 
2. **Prometheus Remote Read**
   -  Prometheus Remote Read allows selecting raw metrics from a remote Prometheus server's database without direct PromQL query.  You can deploy Prometheus or other solutions (e.g. Thanos) on the global level to perform PromQL queries on this data while fetching the required metrics from multiple remote locations.
   -  Last but not least, certain security guidelines are not allowing ingress traffic, only egress one.
3. **Prometheus Remote Write**
   - Finally, we have Prometheus Remote Write, which seems to be the most popular choice nowadays. Since the **agent mode** focuses on remote write use case.
   - Remote Write protocol allows us to forward (stream) all or a subset of metrics collected by Prometheus to th remote location. You can configure Prometheus to forwatd some metrics to one or more locations that support the Remote Wriate API. 
   - Streaming data from such a scraper enables Global View use cases by allowing you to store metrics data in a centralized location. This also enables separation of concerns, which is useful when applications are managed by different teams than the observability or monitoring pipelines.
   - The amazing part is that, even with Remote Write, Prometheus still uses a pull model to gather metrics from applications, which gives us an understanding of those different failure modes. After that, we batch samples and series and export, replicate (push) data to the Remote Write endpoints.

## Prometheus Agent Mode

- The Agent mode optimizes Prometheus for the remote write usecase. Is disables querying, alerting, and local storage, and replaces it with a customized TSDB WAL. Everything else stays the same: scraping logic, service discovery ans related configuration.
- It can be used as a drop-in replacement for Prometheus if you want to just forward your data to a remote Prometheus server or any other Remote-Write-compliant project. In essence it looks like this:
    ![image](https://github.com/rlaisqls/TIL/assets/81006587/935a2dac-35d3-4811-977d-13c3e192826c)

- What are the benefits of using the Agent mode if you plan not to query or alert on data locally and stream metrics outside? There are a few:
  1. **Efficiency**:
     - Prometheus customized Agent TSDB WAL removes the data immediately after successful writes. If it cannot reach the remote endpoint, it persists the data temporarily on the disk until the remote endpoint is back online.
  2. It is enables easier horizontal scalability for ingestion. A true auto-scalable solution for scraping would need to be based on the amount of metric targets and the number of metrics they expose. The more data we have to scrape, the more instances of Prometheus we deploy automatically. If the number of targets or their number of metrics goes down, we could scale down and remove coupe of instances.

## How to Use Agent Mode in Detail

- From now on, if you show the help output of Prometheus (--help flag), you should see more or less the following:

```bash
usage: prometheus [<flags>]

The Prometheus monitoring server

Flags:
  -h, --help                     Show context-sensitive help (also try --help-long and --help-man).
      (... other flags)
      --storage.tsdb.path="data/"
                                 Base path for metrics storage. Use with server mode only.
      --storage.agent.path="data-agent/"
                                 Base path for metrics storage. Use with agent mode only.
      (... other flags)
      --enable-feature= ...      Comma separated feature names to enable. Valid options: agent, exemplar-storage, expand-external-labels, memory-snapshot-on-shutdown, promql-at-modifier, promql-negative-offset, remote-write-receiver,
                                 extra-scrape-metrics, new-service-discovery-manager. See https://prometheus.io/docs/prometheus/latest/feature_flags/ for more details.
```

- Since the Agent mode is behind a feature flag, as mentioned previously, use the `--enable-feature=agent` flag to run Prometheus in the Agent mode. Now, the rest of the flags are either for both server and Agent or only for a specific mode. You can see which flag is for which mode by checking the last sentence of a flag's help string. "Use with server mode only" means it's only for server mode. If you don't see any mention like this, it means the flag is shared.

- The Agent mode accepts the same scrape configuration with the same discovery options and remote write options.

- It also exposes a web UI with disabled query capabitilies, but showing build info, configuration, targets and service discovery information as in a normal Prometheus server.

---
reference
- https://prometheus.io/blog/2021/11/16/agent/
- https://katacoda.com/thanos/courses/thanos/3-receiver
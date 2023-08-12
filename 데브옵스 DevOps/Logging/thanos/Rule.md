# Rule

By definition, **Thanos Rule** (Ruler) allows for **the evaluation** of Recording and Alerting rules against a Query API, then **sends the results directly to remote storage**. In a way, it works as a combination of Prometheus + Thanos Sidecar, but without the metric scraping and querying capabilities provided by Prometheus.


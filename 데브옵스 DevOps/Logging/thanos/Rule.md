# Rule

By definition, **Thanos Rule** (Ruler) allows for **the evaluation** of Recording and Alerting rules against a Query API, then **sends the results directly to remote storage**. In a way, it works as a combination of Prometheus + Thanos Sidecar, but without the metric scraping and querying capabilities provided by Prometheus.

A thing to take into consideration with Ruler, since relies on a Query API to get metrics for evaluatoin, Query reliability is crucial to ensure proper functioning of Ruler. The Thanos documentation recommends setting up certain alerts to manage this risk, which I highly recommend.







# Grok exporter

[Grok](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html) is a tool to parce crappy unstructured log data into something structured and queryable. Grok is heavily used in Logstash to provide log data as input for ElesticSearch.

Grok ships with about 120 predefined patterns for syslog logs, apache and other webserver logs, mysql logs, etc. It is easy to extend Grok with custom patterns.

The grok_exporter aims at porting Grok from the [ELK stack](https://www.elastic.co/webinars/introduction-elk-stack) to [Prometheus](https://prometheus.io/) monitoring. The goal is to use Grok patterns for extracting Prometheus metrics from arbitrary log files.

---
reference
- https://github.com/fstab/grok_exporter
- https://tech-en.netlify.app/articles/en508870/index.html
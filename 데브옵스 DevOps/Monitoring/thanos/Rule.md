
> **NOTE:** It is recommended to keep deploying rules inside the relevant Prometheus servers locally. Use ruler only on specific cases. Read details below why.

The rule component should in particular not be used to circumvent solving rule deployment properly at the configuration management level.

The thanos rule command evaluates Prometheus recording and alerting rules against chosen query API via repeated `--query` (or FileSD via `--query.sd`). If more than one query is passed, round robin balancing is performed.

By default, rule evaluation results are written back to disk in the Prometheus 2.0 storage format. Rule nodes at the same time participate in the system as source store nodes, which means that they expose StoreAPI and upload their generated TSDB blocks to an object store.

Rule also has a stateless mode which sends rule evaluation results to some remote storages via remote write for better scalability. This way, rule nodes only work as a data producer and the remote receive nodes work as source store nodes. It means that Thanos Rule in this mode does not expose the StoreAPI.

You can think of Rule as a simplified Prometheus that does not require a sidecar and does not scrape and do PromQL evaluation (no QueryAPI).

The data of each Rule node can be labeled to satisfy the clusters labeling scheme. High-availability pairs can be run in parallel and should be distinguished by the designated replica label, just like regular Prometheus servers. Read more about Ruler in HA [here](https://thanos.io/tip/components/rule.md/#ruler-ha)

```bash
thanos rule \
    --data-dir             "/path/to/data" \
    --eval-interval        "30s" \
    --rule-file            "/path/to/rules/*.rules.yaml" \
    --alert.query-url      "http://0.0.0.0:9090" \ # This tells what query URL to link to in UI.
    --alertmanagers.url    "http://alert.thanos.io" \
    --query                "query.example.org" \
    --query                "query2.example.org" \
    --objstore.config-file "bucket.yml" \
    --label                'monitor_cluster="cluster1"' \
    --label                'replica="A"'
```

## Risk

Ruler has conceptual tradeoffs that might not be favorable for most use cases. The main tradeoff is its dependence on query reliability. For Prometheus it is unlikely to have alert/recording rule evaluation failure as evaluation is local.

For Ruler the **read path is distributed**, since most likely Ruler is querying Thanos Querier which gets data from remote Store APIs.

This means that **query failure** are more likely to happen, that’s why clear strategy on what will happen to alert and during query unavailability is the key.

## Configuring Rules

Rule files use YAML, the syntax of a rule file is:

```yaml
groups:
  [ - <rule_group> ]
```

A simple example rules file would be:

```yaml
groups:
  - name: example
    rules:
    - record: job:http_inprogress_requests:sum
      expr: sum(http_inprogress_requests) by (job)
<rule_group>

# The name of the group. Must be unique within a file.
name: <string>

# How often rules in the group are evaluated.
[ interval: <duration> | default = global.evaluation_interval ]

rules:
  [ - <rule> ... ]
Thanos supports two types of rules which may be configured and then evaluated at regular intervals: recording rules and alerting rules.
```

## Recording Rules

Recording rules allow you to **precompute frequently needed** or **computationally expensive expressions and save** their result as a new set of time series. Querying the precomputed result will then often be much faster than executing the original expression every time it is needed. This is especially useful for dashboards, which need to query the same expression repeatedly every time they refresh.

Recording and alerting rules exist in a rule group. Rules within a group are run sequentially at a regular interval.

The syntax for recording rules is:

```yaml
# The name of the time series to output to. Must be a valid metric name.
record: <string>

# The PromQL expression to evaluate. Every evaluation cycle this is
# evaluated at the current time, and the result recorded as a new set of
# time series with the metric name as given by 'record'.
expr: <string>

# Labels to add or overwrite before storing the result.
labels:
  [ <labelname>: <labelvalue> ]
```

Note: If you make use of recording rules, make sure that you expose your Ruler instance as a store in the Thanos Querier so that the new time series can be queried as part of Thanos Query. One of the ways you can do this is by adding a new `--store <thanos-ruler-ip>` command-line argument to the Thanos Query command.

## Alerting Rules 

The syntax for alerting rules is:

```yaml
# The name of the alert. Must be a valid metric name.
alert: <string>

# The PromQL expression to evaluate. Every evaluation cycle this is
# evaluated at the current time, and all resultant time series become
# pending/firing alerts.
expr: <string>

# Alerts are considered firing once they have been returned for this long.
# Alerts which have not yet fired for long enough are considered pending.
[ for: <duration> | default = 0s ]

# Labels to add or overwrite for each alert.
labels:
  [ <labelname>: <tmpl_string> ]

# Annotations to add to each alert.
annotations:
  [ <labelname>: <tmpl_string> ]
```

## Partial Response

See this


---
reference
- https://thanos.io/tip/components/rule.md/


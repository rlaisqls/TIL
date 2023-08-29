# Prometheus

Prometheus is an open-source systems monitoring and alerting toolkit. Prometheus collects and stores its metrics as time series data, i.e. metrics information is stored with the timestamp at which it was recorded, alongside optional key-value pairs called labels.

Prometheus work well for recording any purely numeric time series. It fits both machine-centric monitoring of highly dynamic service-oriented architectures. In a world of microservices, its supports for multi-dimensionl data collection and quering is a particular strength.

Prometheus is designed for reliability, to be the system you go to during an outage to allow you to quickly diagnose problems. Each prometheus server is standalone, not depending on network storage or other remote services. You can rely on it when other parts of your infrastructure are broken, and you do not need to setup extensive infrastructure to use it.s

## Features

Prometheus's main features are:

- a multi-dimensional data model with time series data identifies by metric name and key/value pairs.
- PromQL, a flexible query language to leverage this dimensionality.
- no reliance on distributed storage' single server nodes are autonomous
- time series collection happens via a pull model over HTTP
- pushing time series is supported via an intermediary gateway
- targets are discovered via service discovery or static configuration
- multiple modes of graphing and dashboarding support/

## Architecture

This diagram illustrates the architecture of Prometeus and some of its ecosstem components.

![image](https://github.com/rlaisqls/TIL/assets/81006587/42f0f8a0-f205-4814-b475-728dc28e1132)

Prometheus scrapes metrics from instrumented jobs, either directly or via an intermediary push gateway for short-lived jobs. It stores all scraped samples locally and runs rules over this data to wither aggregate and record new time series from existing data or generate alerts. Grafaba ir itger API consumers can be used to visualize the collected data.

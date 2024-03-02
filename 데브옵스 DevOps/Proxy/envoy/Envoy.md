
Envoy is a high performance C++ distributed proxy designed for single services and applications, as well as a communication bus and **“universal data plane”** designed for large microservice **“service mesh”** architectures.

Built on the learnings of solutions such as NGINX, HAProxy, hardware load balancers, and cloud load balancers, Envoy runs alongside every application and abstracts the network by providing common features in a platform-agnostic manner.

When all service traffic in an infrastructure flows via an Envoy mesh, it becomes easy to visualize problem areas via consistent observability, tune overall performance, and add substrate features in a single place.

## Features

- OUT OF PROCESS ARCHITECTURE
    - Envoy is a self contained, high performance server with a small memory footprint. It runs alongside any application language or framework.
- HTTP/2 AND GRPC SUPPORT
    - Envoy has first class support for HTTP/2 and gRPC for both incoming and outgoing connections. It is a transparent HTTP/1.1 to HTTP/2 proxy.
- ADVANCED LOAD BALANCING
    - Envoy supports advanced load balancing features including automatic retries, circuit breaking, global rate limiting, request shadowing, zone local load balancing, etc.
- APIS FOR CONFIGURATION MANAGEMENT
    - Envoy provides robust APIs for dynamically managing its configuration.
- OBSERVABILITY
    - Deep observability of L7 traffic, native support for distributed tracing, and wire-level observability of MongoDB, DynamoDB, and more.

## Terminology

Envoy uses the following terms through its codebase and documentation:

- **Cluster**: a logical service with a set of endpoints that Envoy forwards requests to.
- **Downstream**: an entity connecting to Envoy. This may be a local application (in a sidecar model) or a network node. In non-sidecar models, this is a remote client.
- **Endpoints**: network nodes that implement a logical service. They are grouped into clusters. Endpoints in a cluster are upstream of an Envoy proxy.
- **Filter**: a module in the connection or request processing pipeline providing some aspect of request handling. An analogy from Unix is the composition of small utilities (filters) with Unix pipes (filter chains).
- **Filter chain**: a series of filters.
- **Listeners**: Envoy module responsible for binding to an IP/port, accepting new TCP connections (or UDP datagrams) and orchestrating the downstream facing aspects of request processing.
- **Upstream**: an endpoint (network node) that Envoy connects to when forwarding requests for a service. This may be a local application (in a sidecar model) or a network node. In non-sidecar models, this corresponds with a remote backend.

## Network topology

How a request flows through the components in a network (including Envoy) depends on the network’s topology. Envoy can be used in a wide variety of networking topologies. We focus on the inner operation of Envoy below, but briefly we address how Envoy relates to the rest of the network in this section.

Envoy originated as a service mesh sidecar proxy, factoring out load balancing, routing, observability, security and discovery services from applications. In the service mesh model, requests flow through Envoys as a gateway to the network. Requests arrive at an Envoy via either ingress or egress listeners:

- Ingress listeners take requests from other nodes in the service mesh and forward them to the local application. Responses from the local application flow back through Envoy to the downstream.

- Egress listeners take requests from the local application and forward them to other nodes in the network. These receiving nodes will also be typically running Envoy and accepting the request via their ingress listeners.

<img width="557" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/e27029b9-7f66-49cd-92e5-35b7c6d748c9">

Envoy is used in a variety of configurations beyond the service mesh. For example, it can also act as an internal load balancer:

<img width="442" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/8ee4c981-f3ab-435f-82cc-c3c33c855abb">

Or as an ingress/egress proxy on the network edge:

<img width="804" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/153be51b-7883-4c07-93f4-0c1ff273a37b">

Envoy may be configured in multi-tier topologies for scalability and reliability, with a request first passing through an edge Envoy prior to passing through a second Envoy tier:

<img width="734" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/1181d3c8-af23-4eef-a80e-9cd5eb1e8b3e">

In all the above cases, a request will arrive at a specific Envoy via TCP, UDP or Unix domain sockets from downstream. Envoy will forward requests upstream via TCP, UDP or Unix domain sockets. We focus on a single Envoy proxy below.

## Configuration

Envoy is a very extensible platform. This results in a combinatorial explosion of possible request paths, depending on:

- L3/4 protocol, e.g. TCP, UDP, Unix domain sockets.
- L7 protocol, e.g. HTTP/1, HTTP/2, HTTP/3, gRPC, Thrift, Dubbo, Kafka, Redis and various databases.
- Transport socket, e.g. plain text, TLS, ALTS.
- Connection routing, e.g. PROXY protocol, original destination, dynamic forwarding.
- Authentication and authorization.
- Circuit breakers and outlier detection configuration and activation state.
- Many other configurations for networking, HTTP, listener, access logging, health checking, tracing and stats extensions.

It’s helpful to focus on one at a time, so this example covers the following:
- An HTTP/2 request with TLS over a TCP connection for both downstream and upstream.
- The HTTP connection manager as the only network filter.
- A hypothetical CustomFilter and the router filter as the HTTP filter chain.
- Filesystem access logging.
- Statsd sink.
- A single cluster with static endpoints.

We assume a static bootstrap configuration file for simplicity:

```yml
static_resources:
  listeners:
  # There is a single listener bound to port 443.
  - name: listener_https
    address:
      socket_address:
        protocol: TCP
        address: 0.0.0.0
        port_value: 443
    # A single listener filter exists for TLS inspector.
    listener_filters:
    - name: "envoy.filters.listener.tls_inspector"
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector
    # On the listener, there is a single filter chain that matches SNI for acme.com.
    filter_chains:
    - filter_chain_match:
        # This will match the SNI extracted by the TLS Inspector filter.
        server_names: ["acme.com"]
      # Downstream TLS configuration.
      transport_socket:
        name: envoy.transport_sockets.tls
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
          common_tls_context:
            tls_certificates:
            - certificate_chain: {filename: "certs/servercert.pem"}
              private_key: {filename: "certs/serverkey.pem"}
      filters:
      # The HTTP connection manager is the only network filter.
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          use_remote_address: true
          http2_protocol_options:
            max_concurrent_streams: 100
          # File system based access logging.
          access_log:
          - name: envoy.access_loggers.file
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
              path: "/var/log/envoy/access.log"
          # The route table, mapping /foo to some_service.
          route_config:
            name: local_route
            virtual_hosts:
            - name: local_service
              domains: ["acme.com"]
              routes:
              - match:
                  path: "/foo"
                route:
                  cluster: some_service
          # CustomFilter and the HTTP router filter are the HTTP filter chain.
          http_filters:
          # - name: some.customer.filter
          - name: envoy.filters.http.router
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
  clusters:
  - name: some_service
    # Upstream TLS configuration.
    transport_socket:
      name: envoy.transport_sockets.tls
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
    load_assignment:
      cluster_name: some_service
      # Static endpoint assignment.
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 10.1.2.10
                port_value: 10002
        - endpoint:
            address:
              socket_address:
                address: 10.1.2.11
                port_value: 10002
    typed_extension_protocol_options:
      envoy.extensions.upstreams.http.v3.HttpProtocolOptions:
        "@type": type.googleapis.com/envoy.extensions.upstreams.http.v3.HttpProtocolOptions
        explicit_http_config:
          http2_protocol_options:
            max_concurrent_streams: 100
  - name: some_statsd_sink
  # The rest of the configuration for statsd sink cluster.
# statsd sink.
stats_sinks:
- name: envoy.stat_sinks.statsd
  typed_config:
    "@type": type.googleapis.com/envoy.config.metrics.v3.StatsdSink
    tcp_cluster_name: some_statsd_sink
```

## High level architecture

The request processing path in Envoy has two main parts:

- **Listener subsystem** which handles downstream request processing. It is also responsible for managing the downstream request lifecycle and for the response path to the client. The downstream HTTP/2 codec lives here.

- **Cluster subsystem** which is responsible for selecting and configuring the upstream connection to an endpoint. This is where knowledge of cluster and endpoint health, load balancing and connection pooling exists. The upstream HTTP/2 codec lives here.

The two subsystems are bridged with the HTTP router filter, which forwards the HTTP request from downstream to upstream.

![image](https://github.com/rlaisqls/TIL/assets/81006587/6505b212-8fe5-4836-ae65-22e2058eb1cd)

---
reference
- https://www.envoyproxy.io/
- https://www.envoyproxy.io/docs/envoy/latest/intro/life_of_a_request
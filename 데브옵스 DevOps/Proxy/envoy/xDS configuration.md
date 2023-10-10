# xDS configuration API

- Envoy is architected such that different types of configuration management approaches are possible. The approach taken in a deployment will be dependent on the needs of the implementor.
- Simple deployments are possible with a fully static configuration. More complicated deployments can incrementally add more complex dynamic configuration, the downside being that the implementor must provide one or more external gRPC/REST based configuration provider APIs.
- These APIs are collectively known as "xDS(* [Discovery service](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#arch-overview-service-discovery))". Let's explore overview of the options currently available.

### Fully static

- In a fully static configuration, the implementor provides a set of listeners (and filter chains), clusters, etc. Dynamic host discovery is only possible via DNS based service discovery. Configuration reloads must take place via the built in hor restart mechanism.

- Though simplistic, fairly complicated deployments can be created using static configurations and graceful hot restarts.

### EDS

- The [Endpoint Descovery Service(EDS) API](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#arch-overview-service-discovery-types-eds) provides a more advanced mechanism by which Envoy can **discover members of an upstream cluster.**
- Layered on top of a static configuration, EDS allows an Envoy deployment to circumvent the limitations of DNS (maximum records in a response, etc.) as well as consume more information used in load balancing and routing (e.g., canary status, zone, etc.)

### CDS

- The [Cluster Discovery Service(CDS)](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cds#config-cluster-manager-cds) API layers on a mechanism by which Envoy can discover **upstream clusters used during routing**.
- Envoy will gracefully add, update, and remove clusters as specified by the API. This API allows implementors to build a topology in which Envoy does not need to be aware of all upstream clusters at initial configuration time. Typically, when doing HTTP routing along with CDS (but without route discovery service), implementors will make use of the router's ability to forward requests to a cluster specified in an [HTTP request header](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#envoy-v3-api-field-config-route-v3-routeaction-cluster-header).
- Although it is possible to use CDS without EDS by specifying fully static clusters, It is recommended still using the EDS API for clusters specified via CDS. Internally, when a cluster drained and reconnedted. EDS does not suffer from this limitation. When hosts are added and removed via EDS, the existing hosts in the cluster are unaffected.

### RDS

- The [Route Discovery Service(RDS) API](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/rds#config-http-conn-man-rds) layers on a mechanism by which Envoy can **discover the entire route configuration** for an HTTP connection manager filter at runtime.
- The route configuration will be gracefully swapped in without affecting existing requests. This API, when used alongside EDS and CDS, allows implementors to build a complex routing topology (traffic shifting, blue/green deployment, etc).

### VHDS

- The [Virtual Host Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/vhds#config-http-conn-man-vhds) allows **the virtual hosts belonging to a route configuration** to be requested as needed separately from the route configuration itself.
- This API is typically used in deployments in which there are a large number of virtual hosts in a route configuration.

### SRDS

- The [Scoped Rout Discovery Service (SRDS) API](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_routing#arch-overview-http-routing-route-scope) allows a **route table to be broken up into multiple pieces**. This API is typically used in deployments of HTTP routing with massive route tables in which simple linear searches are not feasible.

### LDS

- The [Listener Discovery Service (LDS) API](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/lds#config-listeners-lds) layers on a mechanisom by which Envoy can discover **entire listeners at runtime**. This includes all filter stacks, up to and including HTTP filters with embedded references to RDS.
- Adding LDS into the mix allows almost every adpect of Envoy to be dynamically configured. Hot restart should only be required for very rare configuration changes (admin, tracing draver, etc.), certificate rotation, or binary updates.

### SDS

- The [Secret Discovery Service(SDS) API](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#config-secret-discovery-service) layers on a mechanism by which Envoy can **discover cryptographic secrets** (certificate + private key, TLS session ticket keys) for its listeners, as well as configuration of peer certificate validation logic (trusted root certs, revocations, etc.)

### RTDS

- The [RunTime Discovery Service (RTDS) API](https://www.envoyproxy.io/docs/envoy/latest/configuration/operations/runtime#config-runtime-rtds) allows runtime layers to be fetched via an xDS API. This may be favorable to, or augmented by, file system layers.

### ECDS

- The [Extension Config Discovery Service (ECDS) API](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/extension#config-overview-extension-discovery) allows **extension configurations** (e.g. HTTP filter configuration) to be served independently from the listener. This is useful when building systems that are more appropriately split from the primary control plane such as WAF, fault testing, etc.

### Aggregated xDS (ADS)

EDS, CDS, etc are each separate services, with different REST/gRPC service names, e.g. StreamListeners, StreamSecrets. For users looking to enforce the order in which resources of different types reach Envoy, there is aggregated xDS, a single gRPC service that carries all resource types in a single gRPC stream. (ADS is only supported by gRPC). [More details about ADS.](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/xds_api#config-overview-ads)

### Delta gRPC xDS

Standard xDS is "state-of-the-world": every update must contain every resource, with the absence of a resource from an update implying that the resoruce is gone. Envoy supports a "delta" variant of xDS (including ADS), where updated only contain resources added//changed/removed. Delta xDS is a new protocol, with request/response APIs different from SotW. [More details about delta.](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/xds_api#config-overview-delta)

### xDS TTL
Certain xDS updates might want to set a TTL to guard against control plane unavailability, read more [here](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/xds_api#config-overview-ttl).

---
reference
- https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/dynamic_configuration
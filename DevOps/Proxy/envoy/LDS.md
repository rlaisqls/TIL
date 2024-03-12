
The listener discovery service (LDS) is an optional API that Envoy will call to dynamically fetch listeners. Envoy will reconcile the API response and add, modify, or remove known listeners depending on that is required.

The semantics of listener updates are as follows:

- Every listener must have a unique name. If a name is not provided, Envoy will create a UUID. Listeners that are to be synamically updated should have a unique name supplied by the management server.
  
- When a listener is added, it will be "warmed" before taking traffic For example, if the listener references an [RDS](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/rds#config-http-conn-man-rds) configuration, that configuration will resolved and fetched before the listener is moved to "active".
  
- Listeners are effetively constant once created. Thus, when a listener is updated, an entirely new listener is created (if the listener's address is unchanged, the new one uses the same listen socker). This listener is removed, the old listener will be placed into a "draining" state much like when the entire server is drained for restart. Connections woened by the listener will be grace fully closed (if possible) for some period of time before the listener is removed and any remaining connections are closed. The drain time is set via the `--drain-time-s` option.
  
- When a tcp listener is updated, if the enw listener contains a subset of filter chains in the old listener, the connections owned by these overlapping filter chains remain open. Only the connections owned by the removed filter chains will be drained following the above pattern. Note that is any global listener attributes are changed, the entire listener (and all filter chains) are drained similar to removal above. See [filter chain only update](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/listeners/listener_filters#filter-chain-only-update) for detailed rules to reason about the impacted filter chains.

> Any listeners that are statically defined within the Envoy configuration cannot be modified or removed via the LDS API.

---
reference
- https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/lds#config-listeners-lds
# Resource Annotations

The various resource annotations that Istio supports to control its behavior.

> https://istio.io/latest/docs/reference/config/annotations/

|Annotation|Name|Resource Types|Description|
|-|-|-|-|
|`galley.istio.io/analyze-suppres`s|[Any]|A comma separated list of configuration analysis message codes to suppress when Istio analyzers are run. For example, to suppress reporting of IST0103 |(PodMissingProxy) and IST0108 (UnknownAnnotation) on a resource, apply the annotation 'galley.istio.io/analyze-suppress=IST0108,IST0103'. If the value is '*', then all configuration analysis messages are suppressed.|
|`inject.istio.io/templates`|[Pod]|The name of the inject template(s) to use, as a comma separate list. See https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/#custom-templates-experimental for more information|
|`install.operator.istio.io/chart-owner`|[Any]|Represents the name of the chart used to create this resource.|
|`install.operator.istio.io/owner-generation`|[Any]|Represents the generation to which the resource was last reconciled.|
|`install.operator.istio.io/version`|[Any]|Represents the Istio version associated with the resource|
|`istio.io/dry-run`|[AuthorizationPolicy]|Specifies whether or not the given resource is in dry-run mode. See https://istio.io/latest/docs/tasks/security/authorization/authz-dry-run/ for more information.|
|`istio.io/rev`|[Pod]|Specifies a control plane revision to which a given proxy is connected. This annotation is added automatically, not set by a user. In contrary to the label istio.io/rev, it represents the actual revision, not the requested revision.|
|`kubernetes.io/ingress.class`|[Ingress]|Annotation on an Ingress resources denoting the class of controllers responsible for it.|
|`networking.istio.io/exportTo`|[Service]|Specifies the namespaces to which this service should be exported to. A value of '*' indicates it is reachable within the mesh '.' indicates it is reachable within its namespace.|
|`prometheus.istio.io/merge-metrics`|[Pod]|Specifies if application Prometheus metric will be merged with Envoy metrics for this workload.|
|`proxy.istio.io/config`|[Pod]|Overrides for the proxy configuration for this specific proxy. Available options can be found at https://istio.io/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig.|
|`readiness.status.sidecar.istio.io/applicationPorts`|[Pod]|Specifies the list of ports exposed by the application container. Used by the Envoy sidecar readiness probe to determine that Envoy is configured and ready to receive traffic.|
|`readiness.status.sidecar.istio.io/failureThreshold`|[Pod]|Specifies the failure threshold for the Envoy sidecar readiness probe.|
|`readiness.status.sidecar.istio.io/initialDelaySeconds`|[Pod]|Specifies the initial delay (in seconds) for the Envoy sidecar readiness probe.|
|`readiness.status.sidecar.istio.io/periodSeconds`|[Pod]|Specifies the period (in seconds) for the Envoy sidecar readiness probe.|
|`sidecar.istio.io/agentLogLevel`|[Pod]|Specifies the log output level for pilot-agent.|
|`sidecar.istio.io/bootstrapOverride`|[Pod]|Specifies an alternative Envoy bootstrap configuration file.|
|`sidecar.istio.io/componentLogLevel`|[Pod]|Specifies the component log level for Envoy.|
|`sidecar.istio.io/controlPlaneAuthPolicy`(Deprecated)|[Pod]|Specifies the auth policy used by the Istio control plane. If NONE, traffic will not be encrypted. If MUTUAL_TLS, traffic between Envoy sidecar will be wrapped into mutual TLS connections.|
|`sidecar.istio.io/discoveryAddress`(Deprecated)|[Pod]|Specifies the XDS discovery address to be used by the Envoy sidecar.|
|`sidecar.istio.io/enableCoreDump`|[Pod]|Specifies whether or not an Envoy sidecar should enable core dump.|
|`sidecar.istio.io/extraStatTags`|[Pod]|An additional list of tags to extract from the in-proxy Istio telemetry. each additional tag needs to be present in this list.|
|`sidecar.istio.io/inject`(Deprecated)|[Pod]|Specifies whether or not an Envoy sidecar should be automatically injected into the workload. Deprecated in favor of `sidecar.istio.io/inject` label.|
|`sidecar.istio.io/interceptionMode`|[Pod]|Specifies the mode used to redirect inbound connections to Envoy (REDIRECT or TPROXY).|
|`sidecar.istio.io/logLevel`|[Pod]|Specifies the log level for Envoy.|
|`sidecar.istio.io/proxyCPU`|[Pod]|Specifies the requested CPU setting for the Envoy sidecar.|
|`sidecar.istio.io/proxyCPULimit`|[Pod]|Specifies the CPU limit for the Envoy sidecar.|
|`sidecar.istio.io/proxyImage`|[Pod]|Specifies the Docker image to be used by the Envoy sidecar.|
|`sidecar.istio.io/proxyImageType`|[Pod]|Specifies the Docker image type to be used by the Envoy sidecar. Istio publishes debug and distroless image types for every release tag.|
|`sidecar.istio.io/proxyMemory`|[Pod]|Specifies the requested memory setting for the Envoy sidecar.|
|`sidecar.istio.io/proxyMemoryLimit`|[Pod]|Specifies the memory limit for the Envoy sidecar.|
|`sidecar.istio.io/rewriteAppHTTPProbers`|[Pod]|Rewrite HTTP readiness and liveness probes to be redirected to the Envoy sidecar.|
|`sidecar.istio.io/statsInclusionPrefixes`(Deprecated)|[Pod]|Specifies the comma separated list of prefixes of the stats to be emitted by Envoy.|
|`sidecar.istio.io/statsInclusionRegexps`(Deprecated)|[Pod]|Specifies the comma separated list of regexes the stats should match to be emitted by Envoy.|
|`sidecar.istio.io/statsInclusionSuffixes`(Deprecated)|[Pod]|Specifies the comma separated list of suffixes of the stats to be emitted by Envoy.|
|`sidecar.istio.io/status`|[Pod]|Generated by Envoy sidecar injection that indicates the status of the operation. Includes a version hash of the executed template, as well as names of injected resources.|
|`sidecar.istio.io/userVolume`|[Pod]|Specifies one or more user volumes (as a JSON array) to be added to the Envoy sidecar.|
|`sidecar.istio.io/userVolumeMount`|[Pod]|Specifies one or more user volume mounts (as a JSON array) to be added to the Envoy sidecar.|
|status.sidecar.istio.io/port|[Pod]|Specifies the HTTP status Port for the Envoy sidecar. If zero, the sidecar will not provide status.|
|`topology.istio.io/controlPlaneClusters`|[Namespace]|A comma-separated list of clusters (or * for any) running istiod that should attempt leader election for a remote cluster thats system namespace includes this annotation. Istiod will not attempt to lead unannotated remote clusters.|
|`traffic.istio.io/nodeSelector`|[Service]|This annotation is a set of node-labels (key1=value,key2=value). If the annotated Service is of type NodePort and is a multi-network gateway (see topology.istio.io/network), the addresses for selected nodes will be used for cross-network communication.|
|`traffic.sidecar.istio.io/excludeInboundPorts`|[Pod]|A comma separated list of inbound ports to be excluded from redirection to Envoy. Only applies when all inbound traffic (i.e. '*') is being redirected.|
|`traffic.sidecar.istio.io/excludeInterfaces`|[Pod]|A comma separated list of interfaces to be excluded from Istio traffic capture|
|`traffic.sidecar.istio.io/excludeOutboundIPRanges`|[Pod]|A comma separated list of IP ranges in CIDR form to be excluded from redirection. Only applies when all outbound traffic (i.e. '*') is being redirected.|
|`traffic.sidecar.istio.io/excludeOutboundPorts`|[Pod]|A comma separated list of outbound ports to be excluded from redirection to Envoy.|
|`traffic.sidecar.istio.io/includeInboundPorts`|[Pod]|A comma separated list of inbound ports for which traffic is to be redirected to Envoy. The wildcard character '*' can be used to configure redirection for all ports. An empty list will disable all inbound redirection.|
|`traffic.sidecar.istio.io/includeOutboundIPRanges`|[Pod]|A comma separated list of IP ranges in CIDR form to redirect to Envoy (optional). The wildcard character '*' can be used to redirect all outbound traffic. An empty list will disable all outbound redirection.|
|`traffic.sidecar.istio.io/includeOutboundPorts`|[Pod]|A comma separated list of outbound ports for which traffic is to be redirected to Envoy, regardless of the destination IP.|
|`traffic.sidecar.istio.io/kubevirtInterfaces`|[Pod]|A comma separated list of virtual interfaces whose inbound traffic (from VM) will be treated as outbound.|

# Resource Labels

The various resource labels that Istio supports to control its behavior.

|Label Name|Resource Types|Description|
|-|-|-|
|`istio.io/rev`|[Namespace]|Istio control plane revision associated with the resource; e.g. `canary`|
|`networking.istio.io/gatewayPort`|[Service]|IstioGatewayPortLabel overrides the default 15443 value to use for a multi-network gateway's port|
|service.istio.io/canonical-name|[Pod]|The name of the canonical service a workload belongs to|
|`service.istio.io/canonical-revision`|[Pod]|The name of a revision within a canonical service that the workload belongs to|
|`sidecar.istio.io/inject`|[Pod]|Specifies whether or not an Envoy sidecar should be automatically injected into the workload.
|`topology.istio.io/cluster`|[Pod]|This label is applied to a workload internally that identifies the Kubernetes cluster containing the workload. The cluster ID is specified during Istio installation for each cluster via `values.global.multiCluster.clusterName`. It should be noted that this is only used internally within Istio and is not an actual label on workload pods. If a pod contains this label, it will be overridden by Istio internally with the cluster ID specified during Istio installation. This label provides a way to select workloads by cluster when using DestinationRules. For example, a service owner could create a DestinationRule containing a subset per cluster and then use these subsets to control traffic flow to each cluster independently|
|`topology.istio.io/network`|[Namespace Pod Service]|A label used to identify the network for one or more pods. This is used internally by Istio to group pods resident in the same L3 domain/network.<br>Istio assumes that pods in the same network are directly reachable from one another. When pods are in different networks, an Istio Gateway (e.g. east-west gateway) is typically used to establish connectivity (with AUTO_PASSTHROUGH mode). This label can be applied to the following resources to help automate Istio's multi-network configuration.<br>* **Istio System Namespace**: Applying this label to the system namespace establishes a default network for pods managed by the control plane. This is typically configured during control plane installation using an admin-specified value.<br>* **Pod**: Applying this label to a pod allows overriding the default network on a per-pod basis. This is typically applied to the pod via webhook injection, but can also be manually specified on the pod by the service owner. The Istio installation in each cluster configures webhook injection using an admin-specified value.<br>* **Gateway Service**: Applying this label to the Service for an Istio Gateway, indicates that Istio should use this service as the gateway for the network, when configuring cross-network traffic. Istio will configure pods residing outside of the network to access the Gateway service via `spec.externalIPs`, `status.loadBalancer.ingress[].ip`, or in the case of a NodePort service, the Node's address. The label is configured when installing the gateway (e.g. east-west gateway) and should match either the default network for the control plane (as specified by the Istio System Namespace label) or the network of the targeted pods.|
|`topology.istio.io/subzone`|[Node]|User-provided node label for identifying the locality subzone of a workload. This allows admins to specify a more granular level of locality than what is offered by default with Kubernetes regions and zones.|
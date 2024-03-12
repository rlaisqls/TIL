
Calico is a networking and security solution that enables Kubernetes workloads and non-kubernetes/legacy worloads to communicate seamlessly and securely.

In k8s, the default for networking traffic to/from pods is default-allow. If you do not lock down network connectivity using network policy, then all pods can communicate freely with other pods.

Calico consists of networking to secure network communication, and advanced network policy to secure cloud-native microservices/applications at scale.

### Component

#### **Calico CNI for networking**

Calico CNI is a control plane that programs several dataplanes. It is an L3/L4 networking solution that secure containers. kubernetes clusters, virtual machines, and native host-based workloads.

Main features are:
- Built-in data encryption
- Advanced IPAM management
- Overlay and non-overlay networking options
- Choice of dataplanes: iptables, eBPF, Windows HNS, or VPP

#### **Calico network policy suite** for network policy

Calico network policy suite is an interface tothe Calico CNI that contains rules for the dataplane to execute.

Clico network policy:
- Is designed with a zero-trust security model (deny-all, allow only where needed)
- Integrates with the kubernetes API server (so you can still use kubernates network policy)
- Supports legacy systems (bare metal, non-cluster hosts) using that same network policy model.

Main features are:
- **Namespace** and **global** policy to allow/deny traffic within a cluster, between pods and the outside world, and for non-cluster hosts.
- **Network sets** (an arbitrary set of IP subnetworks, CIDRs, or domains) to limit IP ranges for egress and ingress traffic to workloads.
- **Application layer (L7) policy** to enforce traffic using attributes like HTTP methods, paths, and cryptographically-secure identities.

### Feature summary
The following table summarizes the main Calico features.

|Feature|Description|
|-|-|
|Dataplanes|eBPF, standard Linux iptables, Windows HNS, VPP.|
|Networking|• Scalable pod networking using BGP or overlay networking<br/>• Advanced IP address management that is customizable|
|Security|• Network policy enforcement for workload and host endpoints<br/>• Data-in-transit encryption using WireGuard|
|Monitor Calico components|Uses Prometheus to monitor Calico component metrics.|
|User interfaces|CLIs: kubectl and calicoctl|
|APIs|• Calico API for Calico resources <br/>• Installation API for operator installation and configuration|
|Support and maintenance|Community-driven. Calico powers 2M+ nodes daily across 166 countries.|

---
reference
- https://www.calicolabs.com/
- https://www.tigera.io/project-calico/
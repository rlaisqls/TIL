
- Cilium is open source software for **transparently securing** the network connectivity between application services deployed using Linux container management platforms like Docker and Kubernetes.

- At the foundation of Cilium is a new Linux kernel technology called [eBPF](https://github.com/rlaisqls/TIL/blob/main/%EC%9A%B4%EC%98%81%EC%B2%B4%EC%A0%9C%E2%80%85Operating%E2%80%85System/linux/BPF/BPF.md), which enables the dynamic insertion of powerful security visibility and control logic within Linux itself.
  
- Because eBPF runs inside the Linux kernel, Cilium security policies can be applied and updated without any changes to the application code or container configuration.

### What is Hubble?

- Hubble is a fully distributed networking and security observability platform. 

- It is built on top of Cilium and eBPF to enable deep visibility into the communication and behavior of services as well as the networking infrastructure in a completely transparent manner.

- By building on top of Cilium, Hubble can leverage eBPF for visibility. By relying on eBPF, all visibility is programmable and allows for a dynamic approach that minimizes overhead while providing deep and detailed visibility as required by users.

- Hubble has been created and specifically designed to make best use of these new eBPF powers.

### Why Cilium & Hubble?

- This shift toward highly dynamic microservices presents both a challenge and an opportunity in terms of securing connectivity between microservices. Traditional Linux network security approaches (e.g., iptables) filter on IP address and TCP/UDP ports, but IP addresses frequently churn in dynamic microservices environments. 

- The highly volatile life cycle of containers causes these approaches to struggle to scale side by side with the application as load balancing tables and access control lists carrying hundreds of thousands of rules that need to be updated with a continuously growing frequency.

- By leveraging Linux eBPF, Cilium retains the ability to transparently insert security visibility + enforcement, but does so in a way that is based on service / pod / container identity (in contrast to IP address identification in traditional systems) and can filter on application-layer (e.g. HTTP). 

- As a result, Cilium not only makes it simple to apply security policies in a highly dynamic environment by decoupling security from addressing, but can also provide stronger security isolation by operating at the HTTP-layer in addition to providing traditional Layer 3 and Layer 4 segmentation.

- The use of eBPF enables Cilium to achieve all of this in a way that is highly scalable even for large-scale environments.

## Functionality Overview

### Protect and secure APIs transparently

- Ability to secure modern application protocols such as REST/HTTP, gRPC and Kafka.
- Traditional firewalls operates at Layer 3 and 4. A protocol running on a particular port is either completely trusted or blocked entirely. Cilium provides the ability to filter on individual application protocol requests such as:

  - Allow all HTTP requests with method `GET` and path `/public/.*`. Deny all other requests.

  - Allow `service1` to produce on Kafka topic `topic1` and `service2` to consume on `topic1`. Reject all other Kafka messages.

  - Require the HTTP header `X-Token: [0-9]+` to be present in all REST calls.

- https://docs.cilium.io/en/stable/security/policy/language/#layer-7-examples

### Secure service to service communication based on identities

- Modern distributed applications rely on technologies such as application containers to facilitate agility in deployment and scale out on demand. This results in a large number of application containers to be started in a short period of time.
  
- Typical container firewalls secure workloads by filtering on source IP addresses and destination ports. This concept requires the firewalls on all servers to be manipulated whenever a container is started anywhere in the cluster.

- In order to avoid this situation which limits scale, Cilium assigns a security identity to groups of application containers which share identical security policies. 

- The identity is then associated with all network packets emitted by the application containers, allowing to validate the identity at the receiving node. Security identity management is performed using a key-value store.

### Secure access to and from external services

- Label based security is the tool of choice for cluster internal access control. In order to secure access to and from external services, traditional CIDR based security policies for both ingress and egress are supported. This allows to limit access to and from application containers to particular IP ranges.

### Simple Networking

- A simple flat Layer 3 network with the ability to span multiple clusters connects all application containers. IP allocation is kept simple by using host scope allocators. This means that each host can allocate IPs without any coordination between hosts.

- The following multi node networking models are supported:

- **Overlay**: Encapsulation-based virtual network spanning all hosts. Currently VXLAN and Geneve are baked in but all encapsulation formats supported by Linux can be enabled.
    When to use this mode: This mode has minimal infrastructure and integration requirements. It works on almost any network infrastructure as the only requirement is IP connectivity between hosts which is typically already given.

- **Native Routing**: Use of the regular routing table of the Linux host. The network is required to be capable to route the IP addresses of the application containers.
    When to use this mode: This mode is for advanced users and requires some awareness of the underlying networking infrastructure. This mode works well with:
    - Native IPv6 networks
    - In conjunction with cloud network routers
    - If you are already running routing daemons

### Load Balancing

- Cilium implements distributed load balancing for traffic between application containers and to external services and is able to fully replace components such as kube-proxy. 

- he load balancing is implemented in eBPF using efficient hashtables allowing for almost unlimited scale.

- For north-south type load balancing, Cilium’s eBPF implementation is optimized for maximum performance, can be attached to XDP (eXpress Data Path), and supports direct server return (DSR) as well as Maglev consistent hashing if the load balancing operation is not performed on the source host.

- For east-west type load balancing, Cilium performs efficient service-to-backend translation right in the Linux kernel’s socket layer (e.g. at TCP connect time) such that per-packet NAT operations overhead can be avoided in lower layers.

### Bandwidth Management

- Cilium implements bandwidth management through efficient EDT-based (Earliest Departure Time) rate-limiting with eBPF for container traffic that is egressing a node. 

- This allows to significantly reduce transmission tail latencies for applications and to avoid locking under multi-queue NICs compared to traditional approaches such as HTB (Hierarchy Token Bucket) or TBF (Token Bucket Filter) as used in the bandwidth CNI plugin, for example.

### Monitoring and Troubleshooting

- The ability to gain visibility and to troubleshoot issues is fundamental to the operation of any distributed system. This includes tooling to provide:

  - **Event monitoring with metadata**: When a packet is dropped, the tool doesn’t just report the source and destination IP of the packet, the tool provides the full label information of both the sender and receiver among a lot of other information.

  - **Metrics export via Prometheus**: Key metrics are exported via Prometheus for integration with your existing dashboards.

  - **[Hubble](https://github.com/cilium/hubble/)**: An observability platform specifically written for Cilium. It provides service dependency maps, operational monitoring and alerting, and application and security visibility based on flow logs.

## Clium Componenet

<img width="518" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/b2ba15f5-a554-4134-bd68-7afa77aed455">

### Agent

- The Cilium agent (cilium-agent) runs on each node in the cluster. At a high-level, the agent accepts configuration via Kubernetes or APIs that describes networking, service load-balancing, network policies, and visibility & monitoring requirements.

- The Cilium agent listens for events from orchestration systems such as Kubernetes to learn when containers or workloads are started and stopped. It manages the eBPF programs which the Linux kernel uses to control all network access in / out of those containers.

### Client (CLI)

- The Cilium CLI client (cilium) is a command-line tool that is installed along with the Cilium agent.
- It interacts with the REST API of the Cilium agent running on the same node. The CLI allows inspecting the state and status of the local agent. It also provides tooling to directly access the eBPF maps to validate their state.

> The in-agent Cilium CLI client described here should not be confused with the command line tool for quick-installing, managing and troubleshooting Cilium on Kubernetes clusters, which also has the name cilium. That tool is typically installed remote from the cluster, and uses kubeconfig information to access Cilium running on the cluster via the Kubernetes API.

### Operator

- The Cilium Operator is responsible for **managing duties in the cluster** which should logically be handled once for the entire cluster, rather than once for each node in the cluster. The Cilium operator is not in the critical path for any forwarding or network policy decision. A cluster will generally continue to function if the operator is temporarily unavailable. However, depending on the configuration, failure in availability of the operator can lead to:

- Delays in IP Address Management (IPAM) and thus delay in scheduling of new workloads if the operator is required to allocate new IP addresses.

- Failure to update the kvstore heartbeat key which will lead agents to declare kvstore unhealthiness and restart.

### CNI Plugin

- The CNI plugin (cilium-cni) is invoked by Kubernetes when a pod is scheduled or terminated on a node. It interacts with the Cilium API of the node to trigger the necessary datapath configuration to provide networking, load-balancing and network policies for the pod.

## Hubble Componenet

### Server
- The Hubble server runs on each node and retrieves the eBPF-based visibility from Cilium. It is embedded into the Cilium agent in order to achieve high performance and low-overhead. It offers a gRPC service to retrieve flows and Prometheus metrics.

### Relay
- Relay (hubble-relay) is a standalone component which is aware of all running Hubble servers and offers cluster-wide visibility by connecting to their respective gRPC APIs and providing an API that represents all servers in the cluster.

### Client (CLI)
- The Hubble CLI (hubble) is a command-line tool able to connect to either the gRPC API of hubble-relay or the local server to retrieve flow events.

### Graphical UI (GUI)
- The graphical user interface (hubble-ui) utilizes relay-based visibility to provide a graphical service dependency and connectivity map.



---
reference
- https://docs.cilium.io/en/stable/overview/intro/#what-is-cilium

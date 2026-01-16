
- The cluster must have a group of IP addresses that is controls to assign an IP address to a pod, for example, `10.1.0.0./16`. Nodes and pods must have L3 conectivity in this IP address space. In L3, ths Internet layer, connectivity means packets with an IP address can route to a host with that IP address.

- It is important to note that the ability to deliver packets is more fundamental than creating connections (an L4 concept). In L4, firewalls may choose to allow connections from host A to B but reject connections initiating from host B to A.
    L4 connections from A to B, connections at L3, A to B and B to A, must be allowed. Without L3 connectivity, TCP handshackes would not be possible, as the SYN-ACK could not be delivered.
    Generally, pods do not have MAC addresses. Therefore, L2 connectivity to pods is not possible. The CNI will determine this for pods.

- There are no requirements in Kubernetes about L3 connectivity to the outside world. Although the majority of clusters have internet connectivity, some are more isolated for security reasons.
    We will broadly discuss both ingress (traffic leaving a host or cluster) and egress (traffic entering a host or cluster). Our use of “ingress” here shouldn’t be confused with the Kubernetes ingress resource, which is a specific HTTP mechanism to route traffic to Kubernetes services.
    There are broadly three approaches, with many variations, to structuring a cluster’s network: **isolated, flat, and island networks**.

## Isolated Networks

<img height=400px src="https://github.com/rlaisqls/TIL/assets/81006587/5ae5d5e2-7981-48ac-8019-d993acec0410">

- In an isolated cluster network, nodes are routable on the broader network (i.e., hosts that are not part of the cluster can reach nodes in the cluster), but pods are not.

- Because the cluster is not routable from the broader network, multiple clusters can even use the same IP address space. Note that the Kubernetes API server will need to be routable from the broader network, if external systems or users should be able to access the Kubernetes API. Many managed Kubernetes providers have a "secure cluster" option like this, where no direct traffic is possible between the cluster and the internet.

- That isolation to the local cluster can be splendid for security if the cluster's worklaods permit/require such a setup, such as clusters for batch processing. However, it is not reasonable for all clusters.
    The majority of clusters will need to reach and/or be reached by external systems, such as clusters that must support services that have dependencies on the broader internet. Load balancers and procies can be used to breach this barrier and allow internet traffic into or out of an isolated cluster.

## Flat Networks

<img height=400px src="https://github.com/rlaisqls/TIL/assets/81006587/1e49035d-a634-4e18-a124-e1f82cbff34a">

- In a flat network, all pods have an IP address that is routable from the broader network. Barring firewall rules, any host on the network can route to any pod inside or outside the cluster. This configuration has numerous upsides around network simpliciry and performance. Pods can connect directly to arbitrary hosts in the network.

- Note that no two node's pod CIDRs overlap between the two clusters in above Figure, and therefore no two pods will be assigned the same IP address. Because the broader network can route every pod IP address to that pod's node, any host on the network is reachable to and from any pod.

- This openness allows any host with sufficient service discobery data to devide which pod will receibe those packets. A load balancer outside the cluster can load blance pods, such as a gRPC client in another cluster.

- External pod traffic (and incoming pod traffic, when the connection's destination is a specific pod IP address) has low latency and low overhead. Any from of proxying or packet rewriting incurs a latency and processing cost, which is small but nontrivial (especially in an application architecture that involves many backend services, where each delay adds up).

- Unfortunately, this model requires a large, contiguous IP address space for each cluster. Kubernetes requires a single CIDR for pod IP addresses (for each IP family). This model is achievable with a private subnet (such as 10.0.0.0/8 or 172.16.0.0/12); however, it is much harder ans more expensive to do with public IP addresses, especially IPv4 addresses. Administrators will need to use NAT to connect a cluster running in a private IP address space to the internet.

- Aside from needing a large IP address space, administrators also need an easily programmable network. The CNI plugin must allocate pod IP addresses and ensure a route exists to a given pod’s node.

- Flat networks, on a private subnet, are easy to achieve in a cloud provider environment. The vast majority of cloud provider networks will provide large private subnets and have an API (or even preexisting CNI plugins) for IP address allocation and route management.

## Island Networks

<img height=400px src="https://github.com/rlaisqls/TIL/assets/81006587/e4a8f467-b607-4379-a710-7f3ab884e163">

- Island cluster networks are, at a high level, a combination of isolated and flat networks. In an islan cluster setup, nodes have L3 connectivity with the broader network, but pods do not. Traffix to and from pods must pass through some from of proxy, through nodes. Most often, this is achieved by `iptables` source NAY on a pod's packets leaving the node. This setup, called _masquerading_, uses SNAT to rewrite packet sources from the pod's IP address to the node's IP address. In other words, packets appear to be "from" the node, rather than the pod.

- Sharing an IP address while also using NAT hides the indivisual pod IP addresses. IP address-based fiewalling and recognition becones difficult across the cluster boundary.

- Within a cluster, it is still apparent which IP address is which pod (and, therefore, which application). Pords in other clusters, or other hosts on the broader network, will no longer have that mapping. IP address-based firewalling and allow lists are not sufficient security on their own but are a valuable and somtimes required layer.

# kube-controller-manager Configuration

- Now let’s see how we configure any of these network layouts with the kube-controller-manager. Control plane refers to all the functions and processes that determine which path to use to send the packet or frame. Data plane refers to all the functions and processes that forward packets/frames from one interface to another based on control plane logic.

- The `kube-controller-manager` runs most individual Kubernetes controllers in one binary and on process, where most Kubernetes login lives. At a high level, a controller in Kubernetes terms is software that watches resources and takes action to synchronize or enforce a specific state (either the desired state or reflecting the current state as a status.) Kubernetes has many controllers which generally "own" a specific objecy type or specific operation.

- `kube-controller-manager` includes multiple controllers that manage the Kubernetes network stack. Notably, administrators set the cluster CIDR here.

- `kube-controller-manager`, due to running a significant number of controllers, also has a substantial number of flags. below table highlights some notable network configuration flags.
  
|Flag|Default|Description|
|-|-|-|
|`--allocate-node-cidrs`|true|Sets whether CIDRs for pods should be allocated and set on the cloud provider.|
`--CIDR-allocator-type string`|RangeAllocator|Type of CIDR allocator to use.|
|`--cluster-CIDR`||CIDR range from which to assign pod IP addresses. Requires `--allocate-node-cidrs` to be true. If kube-controller-manager has IPv6DualStack enabled, `--cluster-CIDR` accepts a comma-separated pair of IPv4 and IPv6 CIDRs.|
|`--configure-cloud-routes`|true|Sets whether CIDRs should be allocated by `allocate-node-cidrs` and configured on the cloud provider.|
|`--node-CIDR-mask-size`|24 for IPv4 clusters, 64 for IPv6 clusters|Mask size for the node CIDR in a cluster. Kubernetes will assign each node 2^(node-CIDR-mask-size) IP addresses.|
|`--node-CIDR-mask-size-ipv4`|24|Mask size for the node CIDR in a cluster. Use this flag in dual-stack clusters to allow both IPv4 and IPv6 settings.|
|`--node-CIDR-mask-size-ipv6`|64|Mask size for the node CIDR in a cluster. Use this flag in dual-stack clusters to allow both IPv4 and IPv6 settings.|
|`--service-cluster-ip-range`||CIDR range for services in the cluster to allocate service ClusterIPs. Requires `--allocate-node-cidrs` to be true. If kube-controller-manager has IPv6DualStack enabled, `--service-cluster-ip-range` accepts a comma-separated pair of IPv4 and IPv6 CIDRs.|

---
reference
- https://kubernetes.io/docs/concepts/cluster-administration/networking/
- https://sookocheff.com/post/kubernetes/understanding-kubernetes-networking-model/
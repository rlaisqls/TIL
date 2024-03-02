
The CNI specification itself is quite simple. According to the specification, there are four operations that a CNI plugin must support:

- `ADD`: Add a container to the network.
- `DEL`: Delete a container from the network.
- `CHECK`: Return an error if there is a problem with the container’s network.
- `VERSION`: Report version information about the plugin.

> The full CNI spec is available on [GitHub](https://github.com/containernetworking/cni/blob/main/SPEC.md)

---

![image](https://github.com/rlaisqls/TIL/assets/81006587/b65cf102-9c21-4546-9ff4-4c8db1c431f4)

In above figure, we can see how Kubernetes (or the runtime, as the CNI project refers to container orchestrators) invokes CNI plugin operations by executing binaries. Kubernetes supplies any configuration for the command in JSON to `stdin` and receives the command’s output in JSON through `stdout`.

CNI plugins frequently have very simple binaries, which act as a wrapper for Kubernetes to call, while the binary makes an HTTP or RPC API call to a persistent backend. CNI maintainers have discussed changing this to an HTTP or RPC model, based on performance issues when frequently launching Windows processes.

Kubernetes uses only one CNI plugin at a time, though the CNI specification allows for mutiplugin setups (i.e., assigning multiple IP addresses to a container). Multus is a CNI plugin that works around this limitation in Kubernetes by acting as a fan-out to multiple CNI plugins.

## CNI Plugins

The CNI plugin has two primary responsibilities:

- allocate and assign unique IP addresses for pods
- ensure that routes exist within Kubernetes to each pod IP address.

These responsibilities mean that the overarching network that the cluster resides in dictates CNI plugin behavior.

For example, if there are too few IP addresses or it is not possible to attach sufficient IP addresses to a node, cluster admins will need to use a CNI plugin that supports an overlay network. The hardware stack, or cloud provider used, typically dictates which CNI options are suitable. 

To use the CNI, add `--network-plugin=cni` to the Kubelet’s startup arguments. By default, the Kubelet reads CNI configuration from the directory `/etc/cni/net.d/` and expects to find the CNI binary in `/opt/cni/bin/`. Admins can override the configuration location with `--cni-config-dir=<directory>`, and the CNI binary directory with `--cni-bin-dir=<directory>`.

## CNI network medel

There are two broad categories of CNI network models:

- **flat networks**
  - In a flat network, the CNI driver uses IP addresses from the cluster’s network, which typically requires many IP addresses to be available to the cluster.
- **overlay network**
  - In an overlay network, the CNI driver creates a secondary network within Kubernetes, which uses the cluster’s network (called the underlay network) to send packets.
  - Overlay networks create a virtual network within the cluster. In an overlay network, the CNI plugin encapsulates packets. 
  - Overlay networks add substantial complexity and do not allow hosts on the cluster network to connect directly to pods.
  - However, overlay networks allow the cluster network to be much smaller, as only the nodes must be assigned IP addresses on that network.

CNI plugins also typically need a way to communicate state between nodes. Plugins take very different approaches, such as storing data in the Kubernetes API, in a dedicated database.

The CNI plugin is also responsible for calling IPAM plugins for IP addressing.

### The IPAM Interface

The CNI spec has a second interface, the IP Address Management (IPAM) interface, to reduce duplication of IP allocation code in CNI plugins. The IPAM plugin must determine and output the interface IP address, gateway, and routes, as shown in below Example. **The IPAM interface is similar to the CNI: a binary with JSON input to `stdin` and JSON output from `stdout`.**

```json
{
  "cniVersion": "0.4.0",
  "ips": [
      {
          "version": "<4-or-6>",
          "address": "<ip-and-prefix-in-CIDR>",
          "gateway": "<ip-address-of-the-gateway>"  (optional)
      },
      ...
  ],
  "routes": [                                       (optional)
      {
          "dst": "<ip-and-prefix-in-cidr>",
          "gw": "<ip-of-next-hop>"                  (optional)
      },
      ...
  ]
  "dns": {                                          (optional)
    "nameservers": <list-of-nameservers>            (optional)
    "domain": <name-of-local-domain>                (optional)
    "search": <list-of-search-domains>              (optional)
    "options": <list-of-options>                    (optional)
  }
}
```

Now we will review several of the options available for cluster administrators to choose from when deploying a CNI.

## Popular CNI Plugins

- **Cilium** is open source software for transparently securing network connectivity between application containers.
  - Cilium is an L7/HTTP-aware CNI and can enforce network policies on L3–L7 using an identity-based security model decoupled from the network addressing.
  - The Linux technology [eBPF](../eBPF.md) is what powers Cilium. We will do a deep dive into NetworkPolicy objects; for now know that they are effectively pod-level firewalls.

- **Flannel** focuses on the network and is a simple and easy way to configure a layer 3 network fabric designed for Kubernetes.
  - If a cluster requires functionalities like network policies, an admin must deploy other CNIs, such as Calico. <u>Flannel uses the Kubernetes cluster’s existing etcd to store its state information to avoid providing a dedicated data store.</u>

- According to **Calico**, it “combines flexible networking capabilities with run-anywhere security enforcement to provide a solution with native Linux kernel performance and true cloud-native scalability.”
  - Calico does not use an overlay network. Instead, **Calico configures a layer 3 network that uses the BGP routing protocol** to route packets between hosts.
  - Calico can also integrate with Istio, a service mesh, to interpret and enforce policy for workloads within the cluster at the service mesh and network infrastructure layers.

Below gives a brief overview of the major CNI plugins to choose from.

|Name|NetworkPolicy support|Data storage|Network setup|
|-|-|-|-|
|Cilium|Yes|etcd or consul|Ipvlan(beta), veth, L7 aware|
|Flannel|No|etcd|Layer 3 IPv4 overlay network|
|Calico|Yes|etcd or Kubernetes API|Layer 3 network using BGP|
|Weave Net|Yes|No external cluster store|Mesh overlay network|

---
reference
- https://www.cni.dev/docs/spec/
- https://github.com/containernetworking/cni/blob/main/SPEC.md
- https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/





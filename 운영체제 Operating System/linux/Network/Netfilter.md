
Netfilter, included in Linux since 2.3, is a critival component of packet handlin. Netfilter is a framework of kernel hooks, which allow userspace programs to handle packets on behalf of the kernel. In short, a program registers to a specific Nwtfilter hook, and the kernel calls that program on applicable packes. That program could tell the kernel to do something with the packet (like drop it), or it could send back a modified packet to the kernel. With this, developers can build normal programs that run in userspach and handle packets. Netfilter was created jointly with `iptables`, to separate kernel and userspace code.

---

Netfilter has five hooks, shown in below table.

Netfilter triggers each hook under specific stages in a packet's journey through the kernel. 

|Netfilter hook|Iptables chain name|Description|
|-|-|-|
|`NF_IP_PRE_ROUTING`|PREROUTING|Triggers when a packet arrives from an external system.|
|`NF_IP_LOCAL_IN`|INPUT|Triggers when a packet’s destination IP address matches this machine.|
|`NF_IP_FORWARD`|NAT|Triggers for packets where neither source nor destination matches the machine’s IP addresses (in other words, packets that this machine is routing on behalf of other machines).|
|`NF_IP_LOCAL_OUT`|OUTPUT|Triggers when a packet, originating from the machine, is leaving the machine.|
|`NF_IP_POST_ROUTING`|POSTROUTING|Triggers when any packet (regardless of origin) is leaving the machine.|

Netfilter triggers each hook during a specific phase of packet handling, and under specific conditions, we can visualize Netfilter hooks with a flow diagram, as shown in below picture.

<img width="648" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/e37d09b4-baf6-44e8-a48e-f0c28ec7916c">

We can infer from our flow diagram that only certain permutations of Netfilter hook calls are possible for any given packet. For example, a packet originating from a local process will always trigger `NF_IP_LOCAL_OUT` hooks and then `NF_IP_POST_ROUTING` hooks. In particular, the flow of Netfilter hooks for a packet depends on two things: if the packet source is the host and is the packet destination is the host. Note that if a process sends a packet destined for the same host, it triggers the `NF_IP_LOCAL_OUT` and then the `NF_IP_POST_ROUTING` hook before "reentering" the system and triggering the `NF_IP_PRE_ROUTING` and `NF_IP_LOCAL_IN` hooks.

In some systems, it is possible to spoof such a packet by writing a fake source address (i.e., spoofing that a packet has a source and destination address of `127.0.0.1`).

Linux will normally filters packets when a packet arrives at an external interface. More broadly, Linux filters packets when a packet arrives at an interface and the packet's source address does not exist on that network.

A packet with an "impossible" source IP address is called a _Martian packet_. It is possible to disable filtering of Martian packets in Linux. However, doing so poses substantial risk if any services on the host assume that traffic from localhost is "more trustworthy" that external traffic. This can be a common assumption, such as when exposing an API or database to the host without strong authentication.

---

Below table shows the Netfilter hook order for various packet sources and destinations.

|Packet source|Packet destination|Hooks (in order)|
|-|-|-|
|Local machine|Local machine|`NF_IP_LOCAL_OUT`, `NF_IP_LOCAL_IN`|
|Local machine|External machine|`NF_IP_LOCAL_OUT`, `NF_IP_POST_ROUTING`|
|External machine|Local machine|`NF_IP_PRE_ROUTING`, `NF_IP_LOCAL_IN`|
|External machine|External machine|`NF_IP_PRE_ROUTING`, `NF_IP_FORWARD`, `NF_IP_POST_ROUTING`|

Note that packets from the machine to itself will trigger `NF_IP_LOCAL_OUT` and `NF_IP_POST_ROUTING` and then "leave" the network interface. They will "reenter" and be treated like packets from any other source.

Network address translation (NAT) only impacts local routing decisions in the `NF_IP_PRE_ROUTING` and `NF_IP_LOCAL_OUT` hooks (e.g. the kernel makes no routing decisions after a packet reaches the `NF_IP_LOCAL_IN` hook). We see this reflected in the design of `iptables`, where source and destination NAT can be performed only in specific hooks/chains.

Programs can register a hook by calling `NF_REGISTER_NET_HOOK` (`NF_REGISTER_HOOK` prior to Linux 4.13) with a handling function. The hook will be called every time a packet matches. This is how programs like iptables integrate with Netfilter, though you will likely never need to do this yourself.

There are several actions that a Netfilter hook can trigger, based on the return value:

- Accept: Continue packet handling.
- Drop: Drop the packet, without further processing.
- Queue: Pass the packet to a userspace program.
- Stolen: Doesn’t execute further hooks, and allows the userspace program to take ownership of the packet.
- Repeat: Make the packet “reenter” the hook and be reprocessed.

Hooks can also return mutated packets. This allows programs to do things such as reroute or masquerade packets, adjust packet TTLs, etc.

## Conntrack

Conntrack is a component of Netfilter used to **track the state of connections to (and from) the machine.** Connection tracking directly associates packets with a particular connection. Without connection tracking, the flow of packets is much more opaque. Conntrack can be a liability or a valuable tool, or both, depending on how it is used. In general, <u>Conntrack is important on systems that handle firewalling or NAT.</u>

Connection tracking allows firewalls to distinguish between responses and arbitrary packets. A firewall can be configured to allow inbound packets that are part of an existing connection but disallow inbound packets that are not part of a connection. To give an example, a program could be allowed to make an outbound connection and perform an HTTP request, without the remote server being otherwise able to send data or initiate connections inbound.

NAT relies on Conntrack to function. `iptables` exposes NAT as two types: SNAT (source NAT, where `iptables` rewrites the source address) and DNAT (destination NAT, where `iptables` rewrites the destination address). NAT is extremely common; the odds are overwhelming that your home router uses SNAT and DNAT to fan traffic between your public IPv4 address and the local address of each device on the network.

With connection tracking, packets are automatically associated with their connection and easily modified with the same SNAT/DNAT change. This enables** consistent routing decisions**, such as “pinning” a connection in a load balancer to a specific backend or machine. The latter example is highly relevant in Kubernetes, due to `kube-proxy`’s implementation of service load balancing via `iptables`. Without connection tracking, every packet would need to be deterministically remapped to the same destination, which isn’t doable (suppose the list of possible destinations could change…).

Conntrack identifies connections by:
- tuple
- composed of source address
- source port
- destination address
- destination port and L4 protocol
  
These five pieces of information are the minimal identifiers needed to identify any given L4 connection. All L4 connections have an address and port on each side of the connection; after all, the internet uses addresses for routing, and computers use port numbers for application mapping. The final piece, the L4 protocol, is present because a program will bind to a port in TCP or UDP mode (and binding to one does not preclude binding to the other). Conntrack refers to these connections as flows. A flow contains metadata about the connection and its state.

---

![image](https://github.com/rlaisqls/TIL/assets/81006587/4083810b-eb7d-4778-84d3-d73754e0da59)
The structure of Conntrack flows

Conntrack stores flows in a hash table, using the connection tuple as a key. The size of the keyspace is configurable. A larger keyspace requires more memory to hold the underlying array but will result in fewer flows hashing to the same key and being chained in a linked list, leading to faster flow lookup times. The maximum number of flows is also configurable. A severe issue that can happen is when Conntrack runs out of space for connection tracking, and new connections cannot be made.

There are other configuration options too, such as the timeout for a connection. On a typical system, default settings will suffice. However, a system that experiences a huge number of connections will run out of space. If your host runs directly exposed to the internet, overwhelming Conntrack with short-lived or incomplete connections is an easy way to cause a denial of service (DOS).

Conntrack’s max size is normally set in `/proc/sys/net/nf_conntrack_max`, and the hash table size is normally set in `/sys/module/nf_conntrack/parameters/hashsize`.

---

Conntrack entries contain a connection state, which is one of four states. It is important to note that, as a layer 3 (Network layer) tool, Conntrack states are distinct from layer 4 (Protocol layer) states. 

|State|Description|Example|
|-|-|-|
|`NEW`|A valid packet is sent or received, with no response seen.|TCP SYN received.|
|`ESTABLISHED`|Packets observed in both directions.|TCP SYN received, and TCP SYN/ACK sent.|
|`RELATED`|An additional connection is opened, where metadata indicates that it is “related” to an original connection. Related connection handling is complex.|An FTP program, with an ESTABLISHED connection, opens additional data connections.|
|`INVALID`|The packet itself is invalid, or does not properly match another Conntrack connection state.|TCP RST received, with no prior connection.|

Although Conntrack is built into the kernel, it may not be active on your system. Certain kernel modules must be loaded, and you must have relevant `iptables` rules (essentially, Conntrack is normally not active if nothing needs it to be). Conntrack requires the kernel module `nf_conntrack_ipv4` to be active. `lsmod | grep nf_conntrack` will show if the module is loaded, and `sudo modprobe nf_conntrack` will load it. You may also need to install the conntrack command-line interface (CLI) in order to view Conntrack’s state.

When Conntrack is active, `conntrack -L` shows all current flows. Additional Conntrack flags will filter which flows are shown.

Let’s look at the anatomy of a Conntrack flow, as displayed here:

```bash
tcp      6 431999 ESTABLISHED src=10.0.0.2 dst=10.0.0.1
sport=22 dport=49431 src=10.0.0.1 dst=10.0.0.2 sport=49431 dport=22 [ASSURED]
mark=0 use=1


<protocol> <protocol number> <flow TTL> [flow state>]
<source ip> <dest ip> <source port> <dest port> [] <expected return packet>
```

The expected return packet is of the form `<source ip> <dest ip> <source port> <dest port>`. This is the identifier that we expect to see when the remote system sends a packet. Note that in our example, the <u>source and destination values are in reverse for address and ports</u>. This is often, but not always, the case.

For example, if a machine is behind a router, packets destined to that machine will be addressed to the router, whereas packets from the machine will have the machine address, not the router address, as the source.

In the previous example from machine `10.0.0.2`, `10.0.0.1` has established a TCP connection from port 49431 to port 22 on `10.0.0.2`. You may recognize this as being an SSH connection, although Conntrack is unable to show application-level behavior.

Tools like `grep` can be useful for examining Conntrack state and ad hoc statistics:

```bash
grep ESTABLISHED /proc/net/ip_conntrack | wc -l
```

## Routing

When handling any packet, the kernel must decide where to send that packet. In most cases, the destination machine will not be within the same network. For example, suppose you are attempting to connect to `1.2.3.4` from your personal computer.

`1.2.3.4` is not on your network; the best your computer can do is pass it to another host that is closer to being able to reach `1.2.3.4`. The route table serves this purpose by mapping known subnets to a gateway IP address and interface. You can list known routes with route (or route -n to show raw IP addresses instead of hostnames). A typical machine will have a route for the local network and a route for `0.0.0.0/0`. Recall that subnets can be expressed as a CIDR (e.g., `10.0.0.0/24`) or an IP address and a mask (e.g., `10.0.0.0` and `255.255.255.0`).

This is a typical routing table for a machine on a local network with access to the internet:

```bash
# route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.0.1        0.0.0.0         UG    303    0        0 eth0
10.0.0.0        0.0.0.0         255.255.255.0   U     303    0        0 eth0
```

In the previous example, a request to `1.2.3.4` would be sent to `10.0.0.1`, on the eth0 interface, because `1.2.3.4` is in the subnet described by the first rule (`0.0.0.0/0`) and not in the subnet described by the second rule (`10.0.0.0/24`). Subnets are specified by the destination and genmask values.

Linux prefers to route packets by specificity (how “small” a matching subnet is) and then by weight (“metric” in route output). Given our example, a packet addressed to `10.0.0.1` will always be sent to gateway `0.0.0.0` because that route matches a smaller set of addresses. If we had two routes with the same specificity, then the route with a lower metric wiould be preferred.

Some CNI plugins make heavy use of the route table.

---
reference
- https://netfilter.org/
  
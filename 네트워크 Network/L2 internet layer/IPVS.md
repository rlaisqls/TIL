# IPVS

IP Virtual Server (IPVS) is a Linux connection (L4) load balancer. 

<img src="https://github.com/rlaisqls/TIL/assets/81006587/baab90be-20db-4b95-91cb-e2859c2b1b45" height=400px>

iptables can do simple L4 load balancing by randomly routing connections, with the randomness shaped by the weights on individual DNAT rules. **IPVS supports multiple load balancing modes (in contrast with the iptables one), which are outlined in below Table.** This allows IPVS to spread load more effectively than iptables, depending on IPVS configuration and traffic patterns.

|Name|Shortcode|Description|
|-|-|-|
|Round-robin|rr|Sends subsequent connections to the “next” host in a cycle. This increases the time between subsequent connections sent to a given host, compared to random routing like iptables enables.|
|Least connection|lc|Sends connections to the host that currently has the least open connections.|
|Destination hashing|dh|Sends connections deterministically to a specific host, based on the connections’ destination addresses.|
|Source hashing|sh|Sends connections deterministically to a specific host, based on the connections’ source addresses.|
|Shortest expected delay|sed|Sends connections to the host with the lowest connections to weight ratio.|
|Never queue|nq|Sends connections to any host with no existing connections, otherwise uses “shortest expected delay” strategy.|

IPVS supports packet forwarding modes:
- NAT rewrites source and destination addresses.
- DR encapsulates IP datagrams within IP datagrams.
- IP tunneling directly routes packets to the backend server by rewriting the MAC address of the data frame with the MAC address of the selected backend server.

There are three aspects to look at when it comes to issues with iptables as a load balancer:
- **Number of nodes in the cluster**
  - Even though Kubernetes already supports 5,000 nodes in release v1.6, kube-proxy with iptables is a bottleneck to scale the cluster to 5,000 nodes. One example is that with a NodePort service in a 5,000-node cluster, if we have 2,000 services and each service has 10 pods, this will cause at least 20,000 iptables records on each worker node, which can make the kernel pretty busy.
- **Time**
  - The time spent to add one rule when there are 5,000 services (40,000 rules) is 11 minutes. For 20,000 services (160,000 rules), it’s 5 hours.
- **Latency**
  - There is latency to access a service (routing latency); each packet must traverse the iptables list until a match is made. There is latency to add/remove rules, inserting and removing from an extensive list is an intensive operation at scale.

IPVS also supports session affinity, which is exposed as an option in services (`Service.spec.sessionAffinity` and `Service.spec.sessionAffinityConfig`). Repeated connections, within the session affinity time window, will route to the same host. This can be useful for scenarios such as minimizing cache misses. It can also make routing in any mode effectively stateful (by indefinitely routing connections from the same address to the same host), but the routing stickiness is less absolute in Kubernetes, where individual pods come and go.

To create a basic load balancer with two equally weighted destinations, run `ipvsadm -A -t <address> -s <mode>`. `-A`, `-E`, and `-D` are used to add, edit, and delete virtual services, respectively. The lowercase counterparts, `-a`, `-e`, and `-d`, are used to add, edit, and delete host backends, respectively:

```bash
$ ipvsadm -A -t 1.1.1.1:80 -s lc
$ ipvsadm -a -t 1.1.1.1:80 -r 2.2.2.2 -m -w 100
$ ipvsadm -a -t 1.1.1.1:80 -r 3.3.3.3 -m -w 100
```

You can list the IPVS hosts with `-L`. Each virtual server (a unique IP address and port combination) is shown, with its backends:

```bash
$ ipvsadm -L
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  1.1.1.1.80:http lc
  -> 2.2.2.2:http             Masq    100    0          0
  -> 3.3.3.3:http             Masq    100    0          0
```

`-L` supports multiple options, such as `--stats`, to show additional connection statistics.



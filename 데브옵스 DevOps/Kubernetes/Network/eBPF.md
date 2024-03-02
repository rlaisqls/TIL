
eBPF is a programming system that allows special sandboxed programs to run in the kernel **without passing back and forth between kernel and user space**, like we saw with Netfilter and iptables.

Before eBPF, there was the Berkeley Packet Filter (BPF). BPF is a technology used in the kernel, among other things, to analyze network traffic. BPF supports filtering packets, which allows a userspace process to supply a filter that specifies which packets it wants to inspect. One of BPF’s use cases is `tcpdump`, it compiles it as a BPF program and passes it to BPF. The techniques in BPF have been extended to other processes and kernel operations.

**tcpdump example**
```bash
$ sudo tcpdump -n -i any
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
21:45:33.093065 ens5  Out IP 172.31.43.75.2222 > 14.50.190.128.63209: Flags [P.], seq 2457618334:2457618410, ack 3398066884, win 463, options [nop,nop,TS val 1101586736 ecr 1365458938], length 76
21:45:33.094530 ens5  Out IP 172.31.43.75.2222 > 14.50.190.128.63209: Flags [P.], seq 76:280, ack 1, win 463, options [nop,nop,TS val 1101586738 ecr 1365458938], length 204
21:45:33.103287 ens5  In  IP 14.50.190.128.63209 > 172.31.43.75.2222: Flags [.], ack 76, win 2046, options [nop,nop,TS val 1365458993 ecr 1101586736], length 0
21:45:33.104358 ens5  In  IP 14.50.190.128.63209 > 172.31.43.75.2222: Flags [.], ack 280, win 2044, options [nop,nop,TS val 1365458994 ecr 1101586738], length 0
...
```

An eBPF program has **direct access to syscalls**. eBPF programs can directly watch and block syscalls, without the usual approach of adding kernel hooks to a userspace program. Because of its <u>performance characteristics, it is well suited for writing networking software.</u>

---

In addition to socket filtering, other supported attach points in the kernel are as follows:

- **Kprobes**
  - Dynamic kernel tracing of internal kernel components.
- **Uprobes**
  - User-space tracing.
- **Tracepoints**
  - Kernel static tracing. These are programed into the kernel by developers and are more stable as compared to kprobes, which may change between kernel versions.
- **perf_events**
  - Timed sampling of data and events.
- **XDP**
  - Specialized eBPF programs that can go lower than kernel space to access driver space to act directly on packets.

Let’s return to tcpdump as an example. Below figure shows a simplified rendition of tcpdump’s interactions with eBPF.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/92391699-09cc-49da-83e5-55a85465b6ff" height="300px" />

Suppose we run `tcpdump -i any`.

The string is compiled by `pcap_compile` into a BPF program. The kernel will then use this BPF program to filter all packets that go through all the network devices we specified, any with the `-I` in our case.

It will make this data abailable to `tcpdump` via a map. Maps wre a data structure consisting of key-value pairs used by the BPD programs to exchange data.

There are many reasons to use eBPF with Kubernetes:

- **Performance (hashing table versus `iptables` list)**
  - For every service added to Kubernetes, the list of `iptables` rules that have to be traversed grows exponentially. Because of the lack of incremental updates, the entire list of rules has to be replaced each time a new rule is added. This lead to a total duration of 5 hours to install the 160,000 uptables rules representin 20,000 Kubernetes services.

- **Tracing**
  - Using BPF, we can gather pod and container-level network statistics. The BPF socket filter is nothing new, but the BPF socket filter per cgroup is. Introduced in Linux 4.10, `cgroup-bpf` allows attaching eBPF programs to cgroups. Once sttached, the program is executed for all packets entering or exiting any process in the cgroup.

- **Auditing `kubectl exec` with eBPF**
  - With eBPF, you can attach a program that will record any commands executed in the `kubectl exec` session and pass those commands to a user-space program that logs those events.

- **Security**
  - Seccomp
    - Secured computing that restricts what syscalls are alloed. Seccomp filters can be written in eBPF.
  - Falco
    - Open source container-native runtime security that uses eBPF

The most common use of eBPF in Kubernetes is **Cilium, CNI and service implementation**. Cilium replaces `kube-proxy`, which writes `iptables` rules to map a service’s IP address to its corresponding pods.

Through eBPF, Cilium can intercept and route all packets directly in the kernel, which is faster and allows for application-level (layer 7) load balancing. We will cover kube-proxy in Chapter 4.

---
reference
- http://ebpf.io/
- https://cilium.io/blog/2020/11/10/ebpf-future-of-networking/
# iptables

_ìptables_ is staple of Linux sysadmins and has been for many years. _ìptables_ can be used to create firewalls and audit logs, mutate and reroute packets, and even implement crude connection fan-out. _ìptables_ uses **Netfilter**, which allows iptabls to intercept and mutate packets.

_ìptables_ rules can become extremely complex, There are many tools that provide a simpler interface for managing _ìptables_ rules; for example, firewalls like **ufw** and **firewalld**. In Kubernetes componets (specifically, kubelet and kube-proxy) generate _ìptables_ rules in this fashion, too. Understanding _ìptables_ is important to understand access and routing for pods and nodes in most clusters.

## concepts

There are three key concepts in _iptables_ :
- tables
- chains
- rules

They are condidered hierarchical in nature: a table contains chains, and a chain contains rules. The specifics of table → chain → target execution are complex, and there is no end of fiendish diagrams available to describe the full state machine. 

### Tables

Tables organize rules arccording to the type of effect they have. _iptables_ has a broad range of sunctionality, which tables group together. The three most commonly applicable tables are:

- Filter (for firewall-related rules)
- NAT (for NAT-related rules)
- Mangle (for non-NAT packet-mutating rules)
 
A table in _iptables_ maps to a particular capability set, where each table is "responsible" for a specific type of action. In more concrete terms, a table can contain only specific target types, and many target types can be used only in specific tables. _iptables_ has five tables, which are listed in below.

|Table|Purpose|
|-|-|
|Filter|The Filter table handles acceptance and rejection of packets.|
|NAT|The NAT table is used to modify the source or destination IP addresses.|
|Mangle|The Mangle table can perform general-purpose editing of packet headers, but it is not intended for NAT. It can also “mark” the packet with iptables - only metadata.|
|Raw|The Raw table allows for packet mutation before connection tracking and other tables are handled. Its most common use is to disable connection tracking for some packets.|
|Security|SELinux uses the Security table for packet handling. It is not applicable on a machine that is not using SELinux.|

_ipdables_ executes tables in a particular order: Raw, Mangle, NAT, Filter. However, this order of execution is broken up by chains. Linux users generally accept the mantra of "tables contains chains", but thus may feel midleading. The order of execution is **chains, then tables**. 

### Chains

Chains contain a list of rules. When a packet executes a chain, the rules in the chain are evaluated in order. Chains exist within a table and organize rules according to Netfilter hooks. There are five built-in, top-level chains, each of which corresponds to a Netfilter hook (recall that Netfilter was designed joinyly with _iptables_). Therefore, the choice of which chain to insert a rule dictates if/when the rule will be evaluated for a given packet.

When a packet triggers or passes through a chain, each rule is sequentially evaluated, until the packet matches a "termination target" (such as DROP), or the packet reaches the end of the chain.

The built-in, "top-level" chains are PREROUTING, INPUT, NAT, OUTPUT, and POSTROUTING. 

### Rules

Rules are a combination condition and action (referred to as a target) For example, "if a packet is addressed to port 22, drop it". _iptables_ evaluates individual packets, although chains and tables dictate which packets a rule will be evaluated against. 

---




---
reference
- [Kubernetes and networking](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/)
- https://kevinalmansa.github.io/network%20security/IPTables/
- https://kubernetes.io/docs/concepts/cluster-administration/networking/
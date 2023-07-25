# IP masquerading

`IP masquerading` **is a process where one computer acts as an IP gateway for a network.** All computers on the network send their IP packets through the gateway, which replaces the source IP address with its own address and then forwards it to the internet. Perhaps the **source IP port number is also replaced** with another port number, although that is less interesting.  All hosts on the internet see the packet as originating from the gateway.

Any host on the Internet which wishes to send a packet back, ie in reply, must necessarily address that packet to the gateway. Remember that the gateway is the only host seen on the internet. **The gateway rewrites the destination address, replacing its own address with the IP address of the machine which is being masqueraded, and forwards that packet on to the local network for delivery.**

---

This procedure sounds simple, and it is. It provides an effective means by which you can provide second class internet connections for a complete LAN using only one (internet) IP address. Note the essential phrase, “second class internet connections”.

IP masquerading cannot provide full internet connections to the hosts which hide behind it.  The reason for this is that any connection can be established outwards, that is a hidden host can connect to any service which is “advertised” on the internet, but no connection can be established inwards.  No host which is hidden behind the gateway will ever receive a connection for a port which it listens to. This precludes hidden hosts from offering services such as Telnet, file transfer, www, mail, news and so on.

The reason why no inward connection will ever be established is **that the process of listening on a port produces no packet.**  When a program listens it does not annouce that it is listening, it just listens.  When a host wishes to connect to a service it has no way of knowing if that connection can possibly succeed; it simply sends a connection packet to the destination IP address. If there no host at that destination address, the host trying to connect eventually times out and reports the connection failed.  If there is a host at that destination address, but it is not listening at that port, the destination host returns a connection refused message and the host trying to connect immediately reports the connection failed.

Remember that the only IP address visible on the internet, with respect to a masqueraded LAN, is the gateway’s address.  Any inbound connection must be addressed to the gateway’s address.  With no prior communication between the hidden host and the gateway, there is nothing to indicate (to the gateway) how to rewrite the destination address for local delivery.

The conclusion of all of this is that if your program works by listening at an address (I suspect ICQ does this) so that other hosts on the internet can connect to you, that program will be of no use to you if your connection is through a masquerading gateway.

## with NAT

IP masquerading and Network Address Translation (NAT) are closely related concepts, and sometimes the terms are used interchangeably. However, there is a subtle difference between the two:

- Network Address Translation (NAT):
  - NAT is a technique used to modify the IP addresses and/or port numbers in IP packet headers while they traverse a network device, typically a router or a firewall. The primary purpose of NAT is to allow multiple devices on a private network to share a single public IP address, which conserves the limited pool of available public IP addresses. It works by translating private IP addresses of devices on the local network to the public IP address of the router before sending packets out to the internet and vice versa.

  - NAT can be of different types:
    - Static NAT: One-to-one mapping of private IP addresses to public IP addresses.
    - Dynamic NAT: Maps private IP addresses to an available pool of public IP addresses on-demand.
    - PAT (Port Address Translation or NAT Overload): Maps multiple private IP addresses to a single public IP address using different port numbers to distinguish between connections.

- IP Masquerading:
  - IP masquerading is a **specific implementation of NAT**, often used in the context of Linux-based routers or firewalls. It provides a form of dynamic NAT (similar to PAT) that allows multiple devices on a local network to share a single public IP address. IP masquerading involves translating the private IP addresses of local devices to the public IP address of the router and keeping track of the state of outgoing connections, so that when responses come back, the router can forward the traffic to the correct internal device based on the state information.
  
In summary, the main difference between IP masquerading and NAT is **that IP masquerading is a specific type of NAT used in Linux-based systems for dynamic NAT** (usually implemented with PAT). NAT, on the other hand, is a more **general term** that encompasses various techniques used to modify IP addresses and/or port numbers in packet headers to allow communication between private and public networks.
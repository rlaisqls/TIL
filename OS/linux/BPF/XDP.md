- XDP(eXpress Data Path) is an eBPF-based high-performance data path used to send and receive network packets at high rates by bypassing most of the operating system networking stack.
  
### Data path

<img width="883" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/c322a547-9858-44ff-880a-acd5859cddaf">

- Packet flow paths in the Linux kernel. XDP bypasses the networking stack and memory allocation for packet metadata.
- The idea behind XDP is to **add an early hook in the RX path of the kernel**, and **let a user supplied eBPF program decide the fate of the packet**.
- The hook is placed in the network interface controller (NIC) driver just after the interrupt processing, and before any memory allocation needed by the network stack itself, because memory allocation can be an expensive operation.
- Due to this design, **XDP can drop 26 million packets per second per core** with commodity hardware.

- The eBPF program must pass a preverifier test before being loaded, to avoid executing malicious code in kernel space. The preverifier checks that the program contains no out-of-bounds accesses, loops or global variables.

- The program is allowed to edit the packet data and, after the eBPF program returns, an action code determines what to do with the packet:
  - `XDP_PASS`: let the packet continue through the network stack
  - `XDP_DROP`: silently drop the packet
  - `XDP_ABORTED`: drop the packet with trace point exception
  - `XDP_TX`: bounce the packet back to the same NIC it arrived on
  - `XDP_REDIRECT`: redirect the packet to another NIC or user space socket via the AF_XDP address family
- XDP requires support in the NIC driver but, as not all drivers support it, it can fallback to a generic implementation, which performs the eBPF processing in the network stack, though with slower performance.

- XDP has infrastructure to offload the eBPF program to a network interface controller which supports it, reducing the CPU load. In 2023, only Netronome cards support it.

- Microsoft is partnering with other companies and adding support for XDP in its MsQuic implementation of the QUIC protocol.

### AF_XDP

- Along with XDP, a new address family entered in the Linux kernel starting 4.18.
- AF_XDP, formerly known as AF_PACKETv4 (which was never included in the mainline kernel), is a raw socket optimized for high performance packet processing and allows zero-copy between kernel and applications.
- As the socket can be used for both receiving and transmitting, it supports high performance network applications purely in user space.

---
reference

- <https://prototype-kernel.readthedocs.io/en/latest/networking/XDP/>
- <https://www.netronome.com/blog/bpf-ebpf-xdp-and-bpfilter-what-are-these-things-and-what-do-they-mean-enterprise/>
- <https://ebpf.io/>


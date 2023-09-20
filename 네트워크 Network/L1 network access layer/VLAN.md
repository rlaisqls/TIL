# VLAN

- A virtual local area network (VLAN) is any broadcast domain that is partitioned and isolated in a computer network at the data link layer (OSI layer 2).

<img width="492" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/260a4ef9-3b02-45d6-b793-755dc56c5037">

- VLANs allow network administrators to group hosts together even if the hosts are not directly connected to the same network switch. 

- Without VLANs, grouping hosts according to their resource needs the labor of relocating nodes or rewiring data links. VLANs allow devices that must be kept separate to share the cabling of a physical network and yet be prevented from directly interacting with one another.

- VLANs address issues such as scalability, security, and network management. Network architects set up VLANs to provide network segmentation. Routers between VLANs filter broadcast traffic, enhance network security, perform address summarization, and mitigate network congestion.

- In a network utilizing broadcasts for service discovery, address assignment and resolution and other services, as the number of peers on a network grows, the frequency of broadcasts also increases. VLANs can help manage broadcast traffic by forming multiple broadcast domains. Breaking up a large network into smaller independent segments reduces the amount of broadcast traffic each network device and network segment has to bear. Switches may not bridge network traffic between VLANs, as doing so would violate the integrity of the VLAN broadcast domain.

- VLANs can also help create multiple layer 3 networks on a single physical infrastructure. VLANs are data link layer (OSI layer 2) constructs, analogous to Internet Protocol (IP) subnets, which are network layer (OSI layer 3) constructs. In an environment employing VLANs, a one-to-one relationship often exists between VLANs and IP subnets, although it is possible to have multiple subnets on one VLAN.

## Trunk(Tagging)

A trunk (tagging) is to share one physical connection (port) in frame delivery between switches so that frames from multiple VLANs can be delivered between VLAN-trunked switches. In the context of VLANs, the term trunk denotes a network link carrying multiple VLANs, which are identified by labels (or tags) inserted into their packets. Such trunks must run between tagged ports of VLAN-aware devices, so they are often switch-to-switch or switch-to-router links rather than links to hosts.

<img width="347" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/4d65668b-5eb8-432f-9eb5-e9fce83a2b61">
<img width="342" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/434ca200-6ac8-4984-8b01-b306167a36ff">

### Trunking protocols

Two trunking protocols have been used on Cisco switches over the years - Inter-Switch Link (ISL) and IEEE 802.1Q. ISL was a Cisco proprietary tagging protocol predecessor of 802.1Q, it has been deprecated and is not used anymore. IEEE 802.1Q is the industry-standard trunking encapsulation at present and is typically the only one supported on modern switches. 

<img width="758" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/3ee0e91d-6280-409f-9c1e-eebcfa452ce6">

It is important to note that the tag adds 4 additional bytes to the Ethernet header of the frames. The most important field in the tag is the VLAN ID which is 12 bits long. **It specifies the VLAN to which the frame belongs**. Because values of `0x000` and `0xFFF` are reserved, there are 4,094 possible VLAN numbers.

### VLAN Tagging 

VLAN trunking allows switches to forwards frames from different VLANs over a single link called trunk.

This is done by adding an additional header information called tag to the Ethernet frame. The process of adding this small header is called VLAN tagging. If you look at below Figure, end-station 1 is sending a broadcast frame. When switch 1 receives the frame, it knows that this is a broadcast frame and it has to send it out all its ports. However, switch 1 must tell switch 2 that this frame belongs to VLAN10. So before sending the frame to switch 2, SW1 adds a VLAN header to the original ethernet frame, with VLAN number 10 as shown in figure 4. 

<img width="743" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/525fddd9-e61d-46e7-8a55-42e71dc9dc9e">

---
reference
- https://aws-hyoh.tistory.com/75
- https://en.wikipedia.org/wiki/VLAN_Trunking_Protocol
- https://en.wikipedia.org/wiki/VLAN
- https://www.n-able.com/blog/vlan-trunking
- https://www.networkacademy.io/ccna/ethernet/vlan-trunking
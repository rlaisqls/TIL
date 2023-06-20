# DHCP

The **Dynamic Host Configuration Protocol (DHCP)** is a network management protocol used on Internet Protocol (IP) networks for automatically assigning IP addresses and other communication parameters to devices connected to the network using a client–server architecture.

The technology eliminates the need for individually configuring network devices manually, and consists of two network components, a centrally installed network DHCP server and client instances of the protocol stack on each computer or device. When connected to the network, and periodically thereafter, a client requests a set of parameters from the server using DHCP.

DHCP services exist for networks running Internet Protocol version 4 (IPv4), as well as version 6 (IPv6). The IPv6 version of the DHCP protocol is commonly called DHCPv6.

## History

The **Reverse Address Resolution Protocol (RARP)** was defined in 1984 for the configuration of simple devices, such as diskless workstations, with a suitable IP address. Acting in the data link layer, **it made implementation difficult on many server platforms**. It required that a server be present on each individual network link. 

**DHCP** was first defined in October 1993. It is based on [BOOTP](https://en.wikipedia.org/wiki/Bootstrap_Protocol), but can dynamically allocate IP addresses from a pool and **reclaim them when they are no longer in use**. It can also be used to deliver a wide range of extra configuration parameters to IP clients, including platform-specific parameters.

## Terms

- DHCP client
  - A DHCP client is an Internet host using DHCP to obtain configuration parameters such as a network address.
- DHCP server
  - A DHCP server is an Internet host that returns configuration parameters to DHCP clients.
-  BOOTP relay agent
    - A BOOTP relay agent or relay agent is an Internet host or router that passes DHCP messages between DHCP clients and DHCP servers. DHCP is designed to use the same relay agent behavior as specified in the BOOTP protocol specification.
    - When a DHCP request enters the router by setting up a DHCP Relay Agent at the router stage, the router can convert it to unicast and send packets to the DHCP server.
- binding
    - A binding is a collection of configuration parameters, including at least an IP address, associated with or "bound to" a DHCP client.  Bindings are managed by DHCP servers.

## Methods

Depending on implementation, the DHCP server may have three methods of allocating IP addresses:

- **Dynamic allocation**
    A network administrator reserves a range of IP addresses for DHCP, and each DHCP client on the LAN is configured to request an IP address from the DHCP server during network initialization. The request-and-grant process uses a lease concept with a controllable time period, allowing the DHCP server to reclaim and then reallocate IP addresses that are not renewed.
- **Automatic allocation**
    The DHCP server permanently assigns an IP address to a requesting client from a range defined by an administrator. This is like dynamic allocation, but the DHCP server keeps a table of past IP address assignments, so that it can preferentially assign to a client the same IP address that the client previously had.
- **Manual allocation**
    - This method is also variously called static DHCP allocation, fixed address allocation, reservation, and MAC/IP address binding. An administrator maps a unique identifier (a client id or MAC address) for each client to an IP address, which is offered to the requesting client. DHCP servers may be configured to fall back to other methods if this fails.

## Lease

DHCP's IP allocation is called lease. This lease has a term, which literally refers to the period during which that IP address can be used. That is, at the end of the lease period, the IP address is returned to the DHCP address pool. The lease period is basically 8 days, and you can find and set an appropriate value depending on the location.

DHCP lease IP by four steps as below description.

### Discover (c->s)

- The DHCP client broadcasts a `DHCPDISCOVER` message on the network subnet using the destination address `255.255.255.255` (limited broadcast) or the specific subnet broadcast address (directed broadcast).

- A DHCP client may also request its last known IP address. If the client remains connected to the same network, the server may grant the request. Otherwise, it depends whether the server is set up as authoritative or not. An authoritative server denies the request, causing the client to issue a new request. A non-authoritative server simply ignores the request, leading to an implementation-dependent timeout for the client to expire the request and ask for a new IP address.

### Offer (c<-s)

- When a DHCP server receives a `DHCPDISCOVER` message from a client, which is an IP address lease request, the DHCP server reserves an IP address for the client and makes a lease offer by sending a DHCPOFFER message to the client.

- This message contains the client's client id (traditionally a MAC address), the IP address that the server is offering, the subnet mask, the lease duration, and the IP address of the DHCP server making the offer.
  
- The DHCP server may also take notice of the hardware-level MAC address in the underlying transport layer: according to current RFCs the transport layer MAC address may be used if no client ID is provided in the DHCP packet.

### Request (c->s)

- In response to the DHCP offer, the client replies with a `DHCPREQUEST` message, broadcast to the server, a requesting the offered address. A client can receive DHCP offers from multiple servers, but it will accept only one DHCP offer. Before claiming an IP address, the client will broadcast an ARP request, in order to find if there is another host present in the network with the proposed IP address. If there is no reply, this address does not conflict with that of another host, so it is free to be used.

- The client must send the server identification option in the `DHCPREQUEST` message, indicating the server whose offer the client has selected.[8]: Section 3.1, Item 3  When other DHCP servers receive this message, they withdraw any offers that they have made to the client and return their offered IP address to the pool of available addresses.

### Acknowledgement (c<-s)

- When the DHCP server receives the `DHCPREQUEST` message from the client, the configuration process enters its final phase. The acknowledgement phase involves sending a `DHCPACK` packet to the client.

- This packet includes the lease duration and any other configuration information that the client might have requested. At this point, the IP configuration process is completed.

- The protocol expects the DHCP client to configure its network interface with the negotiated parameters.

- After the client obtains an IP address, it should probe the newly received address[8]: sec. 2.2  (e.g. with ARP Address Resolution Protocol) to prevent address conflicts caused by overlapping address pools of DHCP servers. If this probe finds another computer using that address, the computer should send DHCPDECLINE, broadcast, to the server.

## Renewal

When a device leases an IP address from a DHCP (Dynamic Host Configuration Protocol) server, it is assigned a lease term, which is the duration for which it can use that IP address. At the end of the lease term, the device is typically required to return the IP address to the DHCP server.

Returning and releasing the IP address can generate broadcast traffic on the network. This is because the device needs to inform other devices on the network that it is no longer using that IP address, allowing them to update their network configurations accordingly. And renewal process is to allow devices to continue using the same IP address if possible, minimizing disruptions caused by IP address changes.

Normally, DHCP leases can be renewed before they expire. Typically, a device will attempt to renew its lease when it reaches the halfway point of the lease term. If the renewal is successful, the lease term is reset to its full duration.

However, if the renewal process fails due to a power-off or another reason, the device will continue using the IP address until approximately 87.5% of the lease term has passed. At this point, the device will make another attempt to renew the lease. The purpose of retrying the renewal at this stage is to ensure that the device has enough time to communicate with the DHCP server and update its lease before the lease actually expires.

## Realease

When the lease term ends or if the IP address is no longer needed, it should be returned to the DHCP server, which is known as releasing the IP address. Both the DHCP server and the client keep track of the lease duration, so even if the lease expires and the client is not connected, the server will send the IP address back to the address pool, making it available for reassignment.

In situations where internet connectivity is not working despite a properly connected Ethernet cable or when the IP address displayed by the `ipconfig` command is in the `169.254.x.x` range with a subnet mask of `255.255.0.0`, the recommended troubleshooting step is to first enter the `ipconfig /release` command in the command prompt and then enter `ipconfig /renew`. The `ipconfig /release` command releases the IP address back to the DHCP server, while `ipconfig /renew` either creates a new lease if no IP address is currently assigned or renews the existing lease if an IP address is already assigned. This process encourages the client to obtain a new IP address if everything is functioning properly.

If the release process is not followed, DHCP becomes less advantageous compared to using a static IP address, as it introduces more disadvantages. Therefore, the release process is considered more important than the lease creation/renewal process in DHCP environments.

---
reference
- https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol
- https://nordvpn.com/blog/dhcp/
- https://datatracker.ietf.org/doc/html/rfc2131
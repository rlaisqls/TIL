# Elastic Network Interfaces (ENI)

An elastic network interface is a networking component that represents a **virtual network card**.

It can include the following attributes:

- A primary private IPv4 address from the IPv4 address range of your VPC

- One or more secondary private IPv4 addresses from the IPv4 address range of your VPC

- One Elastic IP address (IPv4) per private IPv4 address

- One public IPv4 address

- One or more IPv6 addresses

- One or more security groups

- A MAC address

- A source/destination check flag

- A description

## Network interface basis

You can create a network interface, attach is to an instance, detach it from an instance and attach it to another instance. The attributes of a network interface follow it as it's attached or detacehd from an instance and reattached to another instance. When you move a network interface from one instance to another, network traffic is redirect to the new instance

### primary network interface

Each instance has a default network interface, called the primary network interface. You cannot detach a primary network interface from an instance. You can create an dattach additional network interfaces. 

If you attach two or more network interfaces from the same subnet to an instance, you might encounter networking issues such as asymmetric routing. If possible, use a secondary private IPv4 address on the primary network interface instead.

### public IPv4 addresses for network interfaces

In a VPC, all subnets have a mofifiable attribute that determines whether network interfaces created in that subnet (and therefore instances launched into that subnet) are assigned a public IPv4 address. The public IPv4 address is assigned from Amazon's pool of public IPv4 addresses. When you launch an instance, the IP address is assigned to the primary network interface that's ceated.

When you create a network interface, it inherits the public IPv4 addressing attribute from the subnet. If you later modify the public IPv4 addressing attribute of the subnet, the network interface keeps the setting that was in effect when it was created. If you launch an instance and specify an existing network interface as the primary network interface, the public IPv4 address attribute is determined by this network interface.

### Elastic IP addresses for network interface

If you have an Elastic IP address, you can associate it with one of the private IPv4 addresses for the network interface. You can associate one Elastic IP address with each private IPv4 address.

If you disassociate an Elastic IP address from a network interface, you can release it back to the address pool. This is the only way to associate an Elastic IP address with an instance in a different subnet or VPC, as network interfaces are specific to subnets.

### Prefix Delegation

A Prefix Delegation prefix is a reserved private IPv4 or IPv6 CIDR range that you allocate for automatic or manual assignment to network interfaces that are associated with an instance. By using Delegated Presixes, you can launch services faster by assigning a range of IP addresses as a single prefix.

### Termination behavior

You can set the termination behavior for a network interface that's attached to an instance. You can specify whether the network interface should be automatically deleted when you terminate the instance to which it's attached.

### Source/destination checking

You can enable or disable source/destination checks, which ensure that the instance is either the source or the destination of any traffic that it receives. Source/destinatino checks are enabled by default. You must disable source/destination checks if the instance runs services such as network address translation, routing, or firewalls.

### Monitoring IP traffic

You can enable a VPC flow log on your network interface to capture information about the IP traffic going to and from a network interfac. After you've created a flow log, you can view and retrieve its data in Amazon CloudWatch Logs. For more information.

## Network cards

Instances with multiple network cards provide higher network performance, including bandwidth capabilities above 100 Gbps and improved packet rate performance. Each network interfave is attaches to a network card. The primary network interface must be assigned to network card index 0.

If you enable Elastic Fabric Adapter (EFA) when you launch an instance that supports multiple network cars, all network cards are available. You can assign up to one EFA per network card. An EFA counts as a network interface.

## Key Details

- ENI is used mainly for low-budget, high-availabliity network solutions.

- However, if used mainly for low-budget, high-availability network solutions

- Enahced Networking ENI uses single root I/O virtualization to provide high-performance networking capabilities on supported instance types. SR-IOV provides higher I/O and lower throughput and it ensures higher bandwidth, higher packet per second (PPS) performance, and consistently lower inter-instance latensies. SR-IOV does this by dedication the interface to a single instance and effectively bypassing parts of the Hypervisor which allows for better performance.

- Adding more ENIs won't necessarily speed up your network throughput, but Enhanced Networking ENI will.

- There is no extra charge for using Enhanced Networking ENI and the better network performance it provides. The only downside is that Enhanced Networking ENI is not available on all EC2 instance families types.

- You can attach a network interface to an EC2 instance in the following ways:
    - When it's running (hot attach)
    - When it's stopped (warm attach)
    - When the instance is being launched (cold attach)

- If an EC2 instance fails with ENI properly configured, you (or more likely, the code running on your behalf) can attach the network interface to a hot standby instance. Because ENI interfaces maintain their own private IP addresses, Elastic IP addresses, and MAC address, network traffic wil begin to flow to the standby instance as soon as you attach the network interface on the replcement instance. Users will experience a brief loss of connectivity between the tine the instance fails and the time that the network interface is attached to the standby instance, but no changes to the VPC route table or you DNS server are required.

- For instances that work with Machine Learning an dHigh Performance Computing, use EFA(Elastic Fabrip Adaptor). EFAs accelerate the work required from the above use cases. EFA provides lower and more consistent latency and higher throughput than the TCP transport traditionally used in cloud-based High Performance Computing systems.

- EFA can also use OS-bypass (on linux only) that will enable ML and HPC applications to interface with the EFA directly, rather than be normally routed to it through the OS. This gives it a huge performance increase.

- You can enable a VPC flow log on you network interface to capture information about the IP traffic going to and from a network interface.

## AWS Hyperplane

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/5d7cc6be-a467-4544-b1d0-712d86aa16af)

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/09c0681f-0600-4eb6-b84b-66abd3aa0bc9)

> What’s changing<br>Starting today, we’re changing the way that your functions connect to your VPCs. AWS Hyperplane, the Network Function Virtualization platform used for Network Load Balancer and NAT Gateway, has supported inter-VPC connectivity for offerings like AWS PrivateLink, and we are now leveraging Hyperplane to provide NAT capabilities from the Lambda VPC to customer VPCs.<br>The Hyperplane ENI is a managed network resource that the Lambda service controls, allowing multiple execution environments to securely access resources inside of VPCs in your account. Instead of the previous solution of mapping network interfaces in your VPC directly to Lambda execution environments, network interfaces in your VPC are mapped to the Hyperplane ENI and the functions connect using it.

Hyperplane is Load Balancing Service which used in AWS internal service. It based on S3 API's Load Balancer. It is used in API Gateway's VPC Link, NLB (Network Load Balancer), NAT Gateway, VPC Lambda etc.

---
reference
- https://speakerdeck.com/twkiiim/amazon-vpc-deep-dive-eni-reul-almyeon-vpc-ga-boinda
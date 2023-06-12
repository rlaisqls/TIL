# Natwork ACLs

A network access control list (ACL) allows or denies specific inbound or outbound traffic at the **subnet level**. You can use the default network ACL for your VPC, or you can create a custom network ACL for your VPC with rules that are similar to the rules for your security groups in order to add an additional layer of security to your VPC.

The following diagram shows a VPC with two subnets. Each subnet has a network ACL. When traffic enters the VPC (for example, from a peered VPC, VPN connection, or the internet), the router sends the traffic to its destination.

Network ACL A determines which traffic destined for subnet 1 is allowed to enter subnet 1, and which traffic destined for a location outside subnet 1 is allowed to leave subnet 1. Similarly, network ACL B determines which traffic is allowed to enter and leave subnet 2.

<img width="470" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/f2d1c197-14e8-4d8c-a1eb-fb8e64f139a1">

## Security Group vs. NACLs

The following table summarizes the basic differences between security groups and network ACLs.

|Security group|Network ACL|
|-|-|
|Operates at the instance level|Operates at the subnet level|
|Applies to an instance only if it is associated with the instance|Applies to all instances deployed in the associated subnet (providing an additional layer of defense if security group rules are too permissive)|
|Supports allow rules only|Supports allow rules and deny rules|
|Evaluates all rules before deciding whether to allow traffic|Evaluates rules in order, starting with the lowest numbered rule, when deciding whether to allow traffic|
|Stateful: Return traffic is allowed, regardless of the rules|Stateless: Return traffic must be explicitly allowed by the rules|

The following diagram illustrates the layers of security provided by security groups and network ACLs. For example, traffic from an internet gateway is routed to the appropriate subnet using the routes in the routing table.

The rules of the network ACL that is associated with the subnet control which traffic is allowed to the subnet. The rules of the security group that is associated with an instance control which traffic is allowed to the instance.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/aa73d7b6-0970-4f49-b5f4-00efe30e8463)

---
reference
- https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html
- https://www.fugue.co/blog/cloud-network-security-101-aws-security-groups-vs-nacls
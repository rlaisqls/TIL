
Security Groups are used to control access (SSH, HTTP, RDP, ect.) with EC2.
They act as a virtual firewall for your instances to control inbound and outbound traffic When you launch an instance in a VPC, you can assign up to five security groups to the instance an security groups act at the instance level, not the subnet level.

---

- Security Groups control inbound and outbound traffic for your instances (they act as a Firewall for EC2 Instances) while NACLs control inbound and outbound traffic for your subnets (they act as a Firewall for Subnets). Security Groups usually control the list of ports that are allowed to be used by your EC2 instances and the NACLs control which network or list of IP addresses can connect to your whole VPC.

- Every time you make a change to a security group, that change occurs immediately

- Whenever you create an inbound rule, an outbound rule is created immediately. This is because Security Groups are **stateful**. This means that when you create an ingress rule for a sercurity group, a corresponding egress rule is created to match it. This is in contrast with NACLs which are stateless and require manual intervention for creating both inbound and outbound rules.

- Security Group rules are based on ALLOWs and there is no concept of DENY when in comes to Security Groups. This means you cannot explicitly deny or blacklist specific ports via Security Groups, you can only implicitly deny then by excluding then in you ALLOWs list
    Because of this, everything is blocked by default. You must go in and intentionally allow access for certain ports. If you need to block specific IP addresses, use NACLs instead

- Security groups are specific to a single VPC, so you can't share a Security Group between multiple VPCs. However, you can copy a Security Group to create a new Security Group with the same ruls in another VPC for the same AWS Account.

- Security Groups are regional and can span AZs, but can't be cress-regional.

- Outbound rules exist if you need to connect your server to a different service such as an API endpoint or a DB backend. You need to enable the ALLOW rule for the correct port though so that traffic can leave EC2 and enter the other AWS service.

- You can attach multiple security groups to one EC2 instance and you can have multiple EC2 instances under the umbrella of one security group.

- You can specify the source of you security groups (basically who is allowed to bypass the virtual firewall) to be a single **/32** IP address, an IP range, or even a separate security group.

---
reference
- https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html
- https://docs.aws.amazon.com/vpc/latest/userguide/security-groups.html

Use AWS Direct Connect gateway to connect your VPCs. You associate an AWS Direct Connect gateway with either of the following gateways:

- A transit gateway when you have multiple VPCs in the same Region
- A virtual private gateway

You can also use a virtual private gateway to **extend your Local Zone**. This configuration allows the VPC associated with the Local Zone to connect to a Direct Connect gateway. The Direct Connect gateway connects to a Direct Connect location in a Region. The on-premises data center has a Direct Connect connection to the Direct Connect location.

A Direct Connect gateway is a globally available resource. You can connect to any Region globally using a Direct Connect gateway.

Customers using Direct Connect with VPCs that currently bypass a parent AZ will not be able to migrate their Direct Connect connections or virtual interfaces.


### Senarios

The follwing describe senario where you can use a Direct Connect gateway.

- A Direct Connect gateway does not allow gateway associations that are on the same Direct Connect gateway to send traffic to each other (for example, a virtual pricate gateway to another virtual pricate gateway).

- An exception to this rule, is when a supernet is advertised across two or more VPCs, which have their attached virtual private gateways(VGWs) associated to the same Direct Connect gateway and on the same virtual interface.
  
- In this case, VPCs can communicate with each other via the Direct Connect endpoint. For example, if you advertise a supernet (for example, `10.0.0.0/8` or `0.0.0.0/0`) that overlaps with the VPCs attached to a Direct Connect gateway (for example, `10.0.0.0/24` or `10.0.1.0/24`), and on the same virtual interface, then from your on-premises network. the VPCs can communicate with each other.

- If you want to block VPC-to-VPC communication within a Direct Connect gateway, do the follwing:

    1. **Set up security groups** on the instances and other resources in the VPC to block traffic between VPCs, also using this as part of the default security group in the VPC.

    2. **Avoid advertising a supernet from your on-premises network that overlaps with your VPCs.** Instead you can advertise more specific routes from your on-premises network that do not overlap with your VPCs.

    3. **Provision a single Direct Connect Gateway for each VPC** that you want to connect to your on-premises network instead of using the same Direct Connect Gateway for multiple VPCs. 
        For example, instead of using a single Direct Connect Gateway for your development and production VPCs, use separate Direct Connect Gateways for each of these VPCs.

- A Direct Connect gateway does not prevent traffic from being sent from one gateway association back to the gateway association itself (for example when you have an on-premises supernet route that contains the prefixed from the gateway association).
  
- If you have a configuration with multiple VPCs connected to transit gateways associated to same Direct Connect gateway, the VPCs could communicate. To prevent the VPCs from communicating, associate a route table with the VPC attachments that have the blackhole option set.

<img width="541" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/788c6226-fb76-4365-8832-5b8335f2721b">

- In the above diagram, the Direct Connect gateway enables you to use your AWS Direct Connect connection in the US East (N. Virginia) Region to access VPCs in your account in both the US East (N. Virginia) and US West (N. California) Regions.

- Each VPC has a virtual private gateway that connects to the Direct Connect gateway using a virtual private gateway association. The Direct Connect gateway uses a private virtual interface for the connection to the AWS Direct Connect location. There is an AWS Direct Connect connection from the location to the customer data center.

---
reference
- https://docs.aws.amazon.com/directconnect/latest/UserGuide/direct-connect-gateways-intro.html
- https://docs.aws.amazon.com/vpc/latest/userguide/Extend_VPCs.html#access-local-zone
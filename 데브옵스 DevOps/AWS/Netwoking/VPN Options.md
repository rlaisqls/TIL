# VPN Options

### AWS Site-to-Site VPN	

- You can create an IPsec VPN connection between your VPC and your remote network.
- On the AWS side of the Site-to-Site VPN connection, a virtual private gateway or transit gateway provides two VPN endpoints (tunnels) for automatic failover.
- You configure your customer gateway device on the remote side of the Site-to-Site VPN connection. For more information, see the AWS Site-to-Site VPN User Guide.

### AWS Client VPN

- AWS Client VPN is a managed client-based VPN service that enables you to securely access your AWS resources or your on-premises network.
- With AWS Client VPN, you configure an endpoint to which your users can connect to establish a secure TLS VPN session.
- This enables clients to access resources in AWS or on-premises from any location using an OpenVPN-based VPN client. For more information, see the AWS Client VPN Administrator Guide.
  
### AWS VPN CloudHub

- If you have more than one remote network (for example, multiple branch offices), you can create multiple AWS Site-to-Site VPN connections via your virtual private gateway to enable communication between these networks.
- For more information, see [Providing secure communication between sites using VPN CloudHub](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPN_CloudHub.html) in the AWS Site-to-Site VPN User Guide.
  
### Third party software VPN appliance

- You can create a VPN connection to your remote network by using an Amazon EC2 instance in your VPC that's running a third party software VPN appliance.
- AWS does not provide or maintain third party software VPN appliances; however, you can choose from a range of products provided by partners and open source communities. Find third party software VPN appliances on the AWS Marketplace.

---

<img width="675" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/3a47f6ac-8c9e-4d59-b072-5c8a5d63efe7">

---
reference
- https://docs.aws.amazon.com/vpc/latest/userguide/vpn-connections.html
- https://aws.amazon.com/ko/blogs/korea/improving-security-architecture-controls-for-wfh/
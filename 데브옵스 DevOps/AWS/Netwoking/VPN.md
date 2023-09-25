# VPC

- VPCs can also serve as a bridge between your corporate data center and the WAS cloud. With a VPC Virtual Private Network (VPN), your NPC bocomes an extension of your ono-prem environment.

- Naturally, your instances that you launch in your VPC can't communicate with your own on-premise servers. You can allow the access by first:
  - attaching a virtual private gateway to the VPC.
  - creating a custom route table for the connection.
  - updating your security group rules to allow traffic from the connection.
  - creating the managed VPN connection itself.

- To bring up VPN connection, you must also define a customer gateway resource in AWS, which provides AWS information abour your customer gateway device. Ans you have to set up an Internet-routable IP address of the customer gateway's external interface.

- A customer gateway is a physical device or software application on th on-premise side of the VPN connection.

- Although the term "VPN connection" is a general concept, a VPN connection for AWS always refers to the connection between your VPC and your own network. AWS supports Internet Protocal security (IPsec) VPN connections.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/372f3d84-ea05-4c1c-a486-64252ad657a2)


- The above VPC has an attached virtual private gateway (note: not an internet gateway) and there is a remote network that includes a customer gateway which you must configure to enable the VPN connection. You set up the routing so that any traffic from the VPC bound for your network is routed to the virtual private gateway.

- In summary, VPNs connect your on-prem with your VPC over the internet.

---


# Transit Gateway

AWS Transit Gateway connects your Amazon Virtual Private Clouds (VPCs) and on-premises networks through a central hub. This connection simplifies your network and puts an end to complex peering relationships. Transit Gateway acts as a highly scalable cloud router—each new connection is made only once.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/f2537ad9-58e3-4cc9-9375-e5a009f29c30" height=400px>

## Use cases

- **Deliver applications around the world:** Build, deploy, and manage applications across thousands of Amazon VPCs without having to manage peering connections or update routing tables.

- **Rapidly move to global scale:** Share VPCs, Domain Name System (DNS), Microsoft Active Directory, and IPS/IDS across Regions with inter-Region peering.

- **Smoothly respond to spikes in demand:** Quickly add Amazon VPCs, AWS accounts, virtual private networking (VPN) capacity, or AWS Direct Connect gateways to meet unexpected demand.

- **Host multicast applications on AWS:** Host multicast applications that scale based on demand, without the need to buy and maintain custom hardware.

## vs. VPC peering

AWS VPC Peering connection is a networking connection between two VPCs that enables you to route traffic between them privately. Instances in either VPC can communicate with each other as if they are within the same network.

AWS Transit Gateway is a fully managed service that connects VPCs and On-Premises networks through a central hub without relying on numerous point-to-point connections or Transit VPC.

You can attach all your hybrid connectivity (VPN and Direct Connect connections) to a single Transit Gateway instance, consolidating and controlling your organization’s entire AWS routing configuration in one place.

VPC has low cost since you need to pay only for data transfer, however transit gateway has 2 times more cost since provide more complex features as simplify network management architecture, reduce operational overhead, and centrally manage external connectivity at scale. Below is a summary of the characteristics of each service.

|Service|Advantages|Disadvantages|
|-|-|-|
|VPC|- Low cost since you need to pay only for data transfer.<br>- No bandwidth limit.|- Complex at scale. Each new VPC increases the complexity of the network. Harder to maintain route tables compared to TGW.<br>- No transit routing.<br>- Maximum 125 peering connections per VPC.|
|Transit Gateway|- Simplified management of VPC connections. Each spoke VPC only needs to connect to the TGW to gain access to other connected VPCs.<br>- Supports more VPCs compared to VPC peering.<br>- TGW Route Tables per attachment allow for fine-grained routing.|- Additional hop introduces some latency.<br>- Extra cost of hourly charge per attachment in addition to data fees.|

**Choose VPC Peering if:**
- Number of VPCs to be connected is lower (~<10).
- You need multiple VPC's connectivity to On-premises.
- You want to minimize data transfer costs when significant volumes of data transfer across regions, VPC Peering is cost-effective.
- Need for low latency.
- You need high throughput. Network bandwidth requirement is more than 50 Gbps.

**Choose Transit Gateway if:**
- You need VPC connectivity at scale. Number of VPCs to be connected is higher (~>10) or scale in the future as the business grows.
- You need network-level segmentation. (possible with multiple TGW route tables)
- You need multiple VPCs connectivity to On-premises.

<img width="593" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/89a9273a-31bd-43a4-bcbd-fb7eef007d33">
<img width="584" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/ff829cf2-57d0-4c1e-a9a4-34f84872659f">

---

reference
- https://aws.amazon.com/transit-gateway/?nc1=h_ls
- https://medium.com/awesome-cloud/aws-difference-between-vpc-peering-and-transit-gateway-comparison-aws-vpc-peering-vs-aws-transit-gateway-3640a464be2d
- https://dev.classmethod.jp/articles/different-from-vpc-peering-and-transit-gateway/
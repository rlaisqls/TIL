
A VPC endpoint enables customers to privately connect to supported AWS services and VPC endpoint services powered by AWS PrivateLink. Amazon VPC instances do not require public IP addresses to communicate with resources of the service. Traffic between an Amazon VPC and a service does not leave the Amazon network.

VPC endpoints are virtual devices. They are horizontally scaled, redundant, and highly available Amazon VPC components that allow communication between instances in an Amazon VPC and services without imposing availability risks or bandwidth constraints on network traffic. There are two types of VPC endpoints:

### Interface endpoints

Interface endpoints enable connectivity to services over AWS PrivateLink. These services include some AWS managed services, services hosted by other AWS customers and partners in their own Amazon VPCs (referred to as endpoint services), and supported AWS Marketplace partner services. The owner of a service is a serviceprovider. The principal dreating the interface endpoint and using that service is a service consumer.

An interface endpoint is a collection of one or more elastic network interfaces with a private IP address that serves as an entry point for traffic destined to a supported service.

### Gateway endpoints

A gateway endpoint targets specific IP routes in an Amazon VPC rout table, in the form of a prefix-list, used for traffic destined to Amazon DynamoDB or S3. Gateway endpoints do not enable AWS PrivateLink.

---

Instances in an Amazon VPC do not require public IP addresses to communicate with VPC endpoints, as interface endpoints use local IP addresses within the consumer Amazon VPC. Gateway endpoints are destinations that are reachable from within an Amazon VPC through prefix-lists within the Amazon VPC’s route table. Refer to the following figure, which shows connectivity to AWS services using VPC endpoints.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/a46fa3fe-0747-44bb-b304-67179f3449af)


---
reference
- https://docs.aws.amazon.com/whitepapers/latest/aws-privatelink/what-are-vpc-endpoints.html
- https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/vpc-endpoints-dynamodb.html
- https://tech.cloud.nongshim.co.kr/2023/03/16/%EC%86%8C%EA%B0%9C-vpc-endpoint%EB%9E%80/
- A CRM web application was written as a monolith in PHP and is facing scaling issues because of performance bottlenecks. The CTO wants to re-engineer towards microservices architecture and expose their application from the same load balancer, linked to different target groups with different URLs: checkout.mycorp.com, www.mycorp.com, yourcorp.com/profile and yourcorp.com/search. The CTO would like to expose all these URLs as HTTPS endpoints for security purposes.
    As a solutions architect, which of the following would you recommend as a solution that requires MINIMAL configuration effort?

- Keyword: SNI

- Answer: **Use SSL certificates with SNI**

  - You can host multiple TLS secured applications, each with its own TLS certificate, behind a single load balancer. **To use SNI, all you need to do is bind multiple certificates to the same secure listener on your load balancer.** ALB will automatically choose the optimal TLS certificate for each client.

  - ALB’s smart certificate selection goes beyond SNI. In addition to containing a list of valid domain names, certificates also describe the type of key exchange and cryptography that the server supports, as well as the signature algorithm (SHA2, SHA1, MD5) used to sign the certificate.

  - With SNI support AWS makes it easy to use more than one certificate with the same ALB. The most common reason you might want to use multiple certificates is to handle different domains with the same load balancer.
  
  - It’s always been possible to use wildcard and subject-alternate-name (SAN) certificates with ALB, but these come with limitations. Wildcard certificates only work for related subdomains that match a simple pattern and while SAN certificates can support many different domains, the same certificate authority has to authenticate each one. That means you have to reauthenticate and reprovision your certificate every time you add a new domain.
  
  - https://aws.amazon.com/blogs/aws/new-application-load-balancer-sni/
  - https://docs.aws.amazon.com/ko_kr/elasticloadbalancing/latest/network/create-tls-listener.html

- Change the ELB SSL Security Policy - ELB SSL Security Policy will not provide multiple secure endpoints for different URLs such as `checkout.mycorp.com` or `www.mycorp.com`, therefore it is incorrect for the given use-case.

---

- A company wants to adopt a hybrid cloud infrastructure where it uses some AWS services such as S3 alongside its on-premises data center. The company wants a dedicated private connection between the on-premise data center and AWS. **In case of failures though, the company needs to guarantee uptime and is willing to use the public internet for an encrypted connection.**
    What do you recommend?

Answer:
- **Use Direct Connect as a primary connection**
  
  - AWS Direct Connect lets you establish a **dedicated network connection between your network and one of the AWS Direct Connect locations.** Using industry-standard 802.1q VLANs, this dedicated connection can be partitioned into multiple virtual interfaces.
  
  - AWS Direct Connect does not involve the Internet; instead, it uses dedicated, private network connections between your intranet and Amazon VPC.
  
  - (Direct Connect is a highly secure, physical connection. It is also a costly solution and hence does not make much sense to set up the connection and keep it only as a backup.)

- **Use Site to Site VPN as a backup connection**
  
  - AWS Site-to-Site VPN enables you to securely connect your on-premises network or branch office site to your Amazon Virtual Private Cloud (Amazon VPC).
  
  - You can securely extend your data center or branch office network to the cloud with an AWS Site-to-Site VPN connection. A VPC VPN Connection utilizes IPSec to establish encrypted network connectivity between your intranet and Amazon VPC over the Internet. VPN Connections can be configured in minutes and are a good solution if you have an immediate need, have low to modest bandwidth requirements, and can tolerate the inherent variability in Internet-based connectivity.
  
  - Direct Connect as a primary connection guarantees great performance and security (as the connection is private). Using Direct Connect as a backup solution would work but probably carries a risk it would fail as well. **As we don't mind going over the public internet (which is reliable, but less secure as connections are going over the public route), we should use a Site to Site VPN which offers an encrypted connection to handle failover scenarios.**

---

- A financial services firm has traditionally operated with an on-premise data center and would like to create a disaster recovery strategy leveraging the AWS Cloud.
  As a Solutions Architect, you would like to ensure that a scaled-down version of a fully functional environment is always running in the AWS cloud, and in case of a disaster, the recovery time is kept to a minimum. Which disaster recovery strategy is that?

- Answer: Warm Standby
  - The term warm standby is used to describe a DR scenario in which **a scaled-down version of a fully functional environment is always running in the cloud.** A warm standby solution extends the pilot light elements and preparation. It further decreases the recovery time because some services are always running. By identifying your business-critical systems, you can fully duplicate these systems on AWS and have them always on.

Incorrect options:

- **Backup and Restore**
  - In most traditional environments, data is backed up to tape and sent off-site regularly. If you use this method, it can take a long time to restore your system in the event of a disruption or disaster. Amazon S3 is an ideal destination for backup data that might be needed quickly to perform a restore. Transferring data to and from Amazon S3 is typically done through the network, and is therefore accessible from any location. Many commercial and open-source backup solutions integrate with Amazon S3.

- **Pilot Light**
  - The term pilot light is often used to describe a DR scenario in **which a minimal version of an environment is always running in the cloud.** The idea of the pilot light is an analogy that comes from the gas heater. In a gas heater, a small flame that’s always on can quickly ignite the entire furnace to heat up a house. This scenario is similar to a backup-and-restore scenario. For example, with AWS you can maintain a pilot light by configuring and running the most critical core elements of your system in AWS. When the time comes for recovery, you can rapidly provision a full-scale production environment around the critical core.

- **Multi Site**
  - A multi-site solution runs in AWS as well as on your existing on-site infrastructure, in an active-active configuration. The data replication method that you employ will be determined by the recovery point that you choose.

---

- A CRM company has a SaaS (Software as a Service) application that feeds updates to other in-house and third-party applications. The SaaS application and the in-house applications are being migrated to use AWS services for this inter-application communication.
    As a Solutions Architect, which of the following would you suggest to asynchronously decouple the architecture?

- Answer: Use Amazon EventBridge to decouple the system architecture
  
  - Both Amazon EventBridge and Amazon SNS can be used to develop event-driven applications, but for this use case, EventBridge is the right fit.
  
  - **Amazon EventBridge is recommended when you want to build an application that reacts to events from SaaS applications and/or AWS services.** Amazon EventBridge is the only event-based service that integrates directly with third-party SaaS partners.
  
  - Amazon EventBridge also automatically ingests events from over 90 AWS services without requiring developers to create any resources in their account. Further, Amazon EventBridge uses a defined JSON-based structure for events and allows you to create rules that are applied across the entire event body to select events to forward to a target.

  - Amazon EventBridge currently supports over 15 AWS services as targets, including AWS Lambda, Amazon SQS, Amazon SNS, and Amazon Kinesis Streams and Firehose, among others. At launch, Amazon EventBridge is has limited throughput (see Service Limits) which can be increased upon request, and typical latency of around half a second.

---

- You have developed a new REST API leveraging the API Gateway, AWS Lambda and Aurora database services. Most of the workload on the website is read-heavy. The data rarely changes and it is acceptable to serve users outdated data for about 24 hours. Recently, the website has been experiencing high load and the costs incurred on the Aurora database have been very high.
    How can you easily **reduce the costs while improving performance, with minimal changes?**

- Answer: **Enable API Gateway Caching**
  - Amazon API Gateway is a fully managed service that makes it easy for developers to create, publish, maintain, monitor, and secure APIs at any scale. APIs act as the "front door" for applications to access data, business logic, or functionality from your backend services. Using API Gateway, you can create RESTful APIs and WebSocket APIs that enable real-time two-way communication applications. API Gateway supports containerized and serverless workloads, as well as web applications.
  - You can enable API caching in Amazon API Gateway to cache your endpoint's responses. With caching, you can reduce the number of calls made to your endpoint and also improve the latency of requests to your API. When you enable caching for a stage, API Gateway caches responses from your endpoint for a specified time-to-live (TTL) period, in seconds. API Gateway then responds to the request by looking up the endpoint response from the cache instead of requesting your endpoint. The default TTL value for API caching is 300 seconds. The maximum TTL value is 3600 seconds. TTL=0 means caching is disabled. Using API Gateway Caching feature is the answer for the use case, as we can accept stale data for about 24 hours.

Incorrect options:
- Add Aurora Read Replicas
  - Adding Aurora Read Replicas would greatly increase the cost, therefore this option is ruled out.

---

- A Big Data analytics company writes data and log files in Amazon S3 buckets. The company now wants to stream the existing data files as well as any ongoing file updates from Amazon S3 to Amazon Kinesis Data Streams.
    As a Solutions Architect, which of the following would you suggest as the fastest possible way of building a solution for this requirement?

- Answer: **Leverage AWS Database Migration Service (AWS DMS) as a bridge between Amazon S3 and Amazon Kinesis Data Streams**

  - You can achieve this by using AWS Database Migration Service (AWS DMS). AWS DMS enables you to seamlessly migrate data from supported sources to relational databases, data warehouses, streaming platforms, and other data stores in AWS cloud.

  - The given requirement needs the functionality to be implemented in the least possible time. You can use AWS DMS for such data-processing requirements. AWS DMS lets you expand the existing application to stream data from Amazon S3 into Amazon Kinesis Data Streams for real-time analytics without writing and maintaining new code.
  
  - AWS DMS supports specifying Amazon S3 as the source and streaming services like Kinesis and Amazon Managed Streaming of Kafka (Amazon MSK) as the target. AWS DMS allows migration of full and change data capture (CDC) files to these services. AWS DMS performs this task out of box without any complex configuration or code development. You can also configure an AWS DMS replication instance to scale up or down depending on the workload.

  - AWS DMS supports Amazon S3 as the source and Kinesis as the target, so data stored in an S3 bucket is streamed to Kinesis. Several consumers, such as AWS Lambda, Amazon Kinesis Data Firehose, Amazon Kinesis Data Analytics, and the Kinesis Consumer Library (KCL), can consume the data concurrently to perform real-time analytics on the dataset. Each AWS service in this architecture can scale independently as needed.

Incorrect options:
- Configure EventBridge events for the bucket actions on Amazon S3. An AWS Lambda function can then be triggered from the EventBridge event that will send the necessary data to Amazon Kinesis Data Streams 
  - You will need to enable a Cloudtrail trail to use object-level actions as a trigger for EventBridge events. Also, using Lambda functions would require significant custom development to write the data into Kinesis Data Streams, so this option is not the right fit.

---

- As a Solutions Architect, you are tasked to design a distributed application that will run on various EC2 instances. This application needs to have the highest performance local disk to cache data. Also, data is copied through an EC2 to EC2 replication mechanism. It is acceptable if the instance loses its data **when stopped or terminated**.
    Which storage solution do you recommend?

- Answer: Instance Store

   - An instance store provides temporary block-level storage for your instance. This storage is located on disks that are physically attached to the host computer. Instance store is ideal for the temporary storage of information that changes frequently, such as buffers, caches, scratch data, and other temporary content, or for data that is replicated across a fleet of instances, such as a load-balanced pool of web servers.

   - Instance store volumes are included as part of the instance's usage cost. Some instance types use NVMe or SATA-based solid-state drives (SSD) to deliver high random I/O performance. This is a good option when you need storage with very low latency, but you don't need the data to persist when the instance terminates.

---

- The engineering team at a social media company has recently migrated to AWS Cloud from its on-premises data center. The team is evaluating CloudFront to be used as a CDN for its flagship application. The team has hired you as an AWS Certified Solutions Architect Associate to advise on CloudFront capabilities on routing, security, and high availability.
    Which of the following would you identify as correct regarding CloudFront?

Answer:

- **CloudFront can route to multiple origins based on the content type**

  - You can configure a single CloudFront web distribution to serve different types of requests from multiple origins. For example, if you are building a website that serves static content from an Amazon Simple Storage Service (Amazon S3) bucket and dynamic content from a load balancer, you can serve both types of content from a CloudFront web distribution.
 
- **Use an origin group with primary and secondary origins to configure CloudFront for high availability and failover**

  - You can set up CloudFront with origin failover for scenarios that require high availability. To get started, you create an origin group with two origins: a primary and a secondary. If the primary origin is unavailable or returns specific HTTP response status codes that indicate a failure, CloudFront automatically switches to the secondary origin.

  - To set up origin failover, you must have a distribution with at least two origins. Next, you create an origin group for your distribution that includes two origins, setting one as the primary. Finally, you create or update a cache behavior to use the origin group.

  - https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/high_availability_origin_failover.html

- **Use field level encryption in CloudFront to protect sensitive data for specific content**

  - Field-level encryption allows you to enable your users to securely upload sensitive information to your web servers. The sensitive information provided by your users is encrypted at the edge, close to the user, and remains encrypted throughout your entire application stack. This encryption ensures that only applications that need the data—and have the credentials to decrypt it—are able to do so.

  - To use field-level encryption, when you configure your CloudFront distribution, specify the set of fields in POST requests that you want to be encrypted, and the public key to use to encrypt them. You can encrypt up to 10 data fields in a request. (You can’t encrypt all of the data in a request with field-level encryption; you must specify individual fields to encrypt.)

---

- The engineering team at an e-commerce company has been tasked with migrating to a serverless architecture. The team wants to focus on the key points of consideration when using Lambda as a backbone for this architecture.
    As a Solutions Architect, which of the following options would you identify as correct for the given requirement?

Answer: 
- **By default, Lambda functions always operate from an AWS-owned VPC and hence have access to any public internet address or public AWS APIs.** Once a Lambda function is VPC-enabled, it will need a route through a NAT gateway in a public subnet to access public resources
  - Lambda functions always operate from an AWS-owned VPC. By default, your function has the full ability to make network requests to any public internet address
  - this includes access to any of the public AWS APIs. For example, your function can interact with AWS DynamoDB APIs to PutItem or Query for records. You should only enable your functions for VPC access when you need to interact with a private resource located in a private subnet. An RDS instance is a good example.
  - Once your function is VPC-enabled, all network traffic from your function is subject to the routing rules of your VPC/Subnet. If your function needs to interact with a public resource, you will need a route through a NAT gateway in a public subnet.
  - https://aws.amazon.com/blogs/architecture/best-practices-for-developing-on-aws-lambda/

- Since Lambda functions can scale extremely quickly, its a good idea to **deploy a CloudWatch Alarm that notifies your team** when function metrics such as **ConcurrentExecutions or Invocations exceeds the expected threshold**
  - Since Lambda functions can scale extremely quickly, this means you should have controls in place to notify you when you have a spike in concurrency. A good idea is to deploy a CloudWatch Alarm that notifies your team when function metrics such as ConcurrentExecutions or Invocations exceeds your threshold. You should create an AWS Budget so you can monitor costs on a daily basis.

- **If you intend to reuse code in more than one Lambda function, you should consider creating a Lambda Layer for the reusable code**
  - You can configure your Lambda function to pull in additional code and content in the form of layers. A layer is a ZIP archive that contains libraries, a custom runtime, or other dependencies. With layers, you can use libraries in your function without needing to include them in your deployment package. Layers let you keep your deployment package small, which makes development easier. A function can use up to 5 layers at a time.
  - You can create layers, or use layers published by AWS and other AWS customers. Layers support resource-based policies for granting layer usage permissions to specific AWS accounts, AWS Organizations, or all accounts. The total unzipped size of the function and all layers can't exceed the unzipped deployment package size limit of 250 MB.  
  - https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html

---

- A social media company wants the capability to dynamically alter the size of a geographic area from which traffic is routed to a specific server resource.
    Which feature of Route 53 can help achieve this functionality?

- Answer: Geoproximity routing
  - Geoproximity routing lets Amazon Route 53 route traffic to your resources based on the geographic location of your users and your resources. You can also optionally choose to route more traffic or less to a given resource by specifying a value, known as a bias. A bias expands or shrinks the size of the geographic region from which traffic is routed to a resource.
  - To optionally change the size of the geographic region from which Route 53 routes traffic to a resource, specify the applicable value for the bias: 1. To expand the size of the geographic region from which Route 53 routes traffic to a resource, specify a positive integer from 1 to 99 for the bias. Route 53 shrinks the size of adjacent regions.
  - <img src="https://github.com/rlaisqls/TIL/assets/81006587/991830b2-6f38-4541-bbdd-efd5f5f583ed" height=400px>

---

- A retail company is using AWS Site-to-Site VPN connections for secure connectivity to its AWS cloud resources from its on-premises data center. Due to a surge in traffic across the VPN connections to the AWS cloud, users are experiencing slower VPN connectivity.
    Which of the following options will **maximize the VPN throughput**?

- Answer: **Create a transit gateway with equal cost multipath routing and add additional VPN tunnels**

  - VPN connection is a secure connection between your on-premises equipment and your VPCs. Each VPN connection has two VPN tunnels which you can use for high availability. A VPN tunnel is an encrypted link where data can pass from the customer network to or from AWS. The following diagram shows the high-level connectivity with virtual private gateways.

  - With AWS Transit Gateway, you can simplify the connectivity between multiple VPCs and also connect to any VPC attached to AWS Transit Gateway with a single VPN connection. **AWS Transit Gateway also enables you to scale the IPsec VPN throughput with equal cost multi-path (ECMP) routing support over multiple VPN tunnels.** A single VPN tunnel still has a maximum throughput of 1.25 Gbps. If you establish **multiple VPN tunnels to an ECMP-enabled transit gateway**, it can scale beyond the default maximum limit of 1.25 Gbps. You also must enable the dynamic routing option on your transit gateway to be able to take advantage of ECMP for scalability.

---

- A company uses Application Load Balancers (ALBs) in multiple AWS Regions. The ALBs receive inconsistent traffic that varies throughout the year. The engineering team at the company needs to allow the IP addresses of the ALBs in the on-premises firewall to enable connectivity.
    Which of the following represents the MOST scalable solution with minimal configuration changes?

- Answer: **Set up AWS Global Accelerator. Register the ALBs in different Regions to the Global Accelerator. Configure the on-premises firewall's rule to allow static IP addresses associated with the Global Accelerator**
  
  - AWS Global Accelerator is a networking service that helps you improve the availability and performance of the applications that you offer to your global users. AWS Global Accelerator is easy to set up, configure, and manage. It provides static IP addresses that provide a fixed entry point to your applications and eliminate the complexity of managing specific IP addresses for different AWS Regions and Availability Zones.
 
  - Associate the static IP addresses provided by AWS Global Accelerator to regional AWS resources or endpoints, such as Network Load Balancers, Application Load Balancers, EC2 Instances, and Elastic IP addresses. The IP addresses are anycast from AWS edge locations so they provide onboarding to the AWS global network close to your users.
 
  - Simplified and resilient traffic routing for multi-Region applications using Global Accelerator:

---

- The development team at a social media company wants to handle some complicated queries such as "What are the number of likes on the videos that have been posted by friends of a user A?".
    As a solutions architect, which of the following AWS database services would you suggest as the BEST fit to handle such use cases?

- Answer: **Amazon Neptune Amazon Neptune**
  - It is a fast, reliable, fully managed graph database service that makes it easy to build and run applications that work with highly connected datasets. The core of Amazon Neptune is a purpose-built, high-performance graph database engine optimized for storing billions of relationships and querying the graph with milliseconds latency. Neptune powers graph use cases such as recommendation engines, fraud detection, knowledge graphs, drug discovery, and network security.

  - Amazon Neptune is highly available, with read replicas, point-in-time recovery, continuous backup to Amazon S3, and replication across Availability Zones. Neptune is secure with support for HTTPS encrypted client connections and encryption at rest. Neptune is fully managed, so you no longer need to worry about database management tasks such as hardware provisioning, software patching, setup, configuration, or backups.

  - Amazon Neptune can quickly and easily process large sets of user-profiles and interactions to build social networking applications. Neptune enables highly interactive graph queries with high throughput to bring social features into your applications. For example, if you are building a social feed into your application, you can use Neptune to provide results that prioritize showing your users the latest updates from their family, from friends whose updates they ‘Like,’ and from friends who live close to them.

---

- A systems administrator is creating IAM policies and attaching them to IAM identities. After creating the necessary identity-based policies, the administrator is now creating resource-based policies.
    Which is the only resource-based policy that the IAM service supports?

- Answer: **Trust policy**
  - Trust policies define **which principal entities (accounts, users, roles, and federated users) can assume the role**. An IAM role is both an identity and a resource that supports resource-based policies. For this reason, you must attach both a trust policy and an identity-based policy to an IAM role. The IAM service supports only one type of resource-based policy called a role trust policy, which is attached to an IAM role.

Incorrect options:
- Access control list (ACL)
  - Access control lists (ACLs) are service policies that allow you to control which principals in another account can access a resource. **ACLs cannot be used to control access for a principal within the same account**. Amazon S3, AWS WAF, and Amazon VPC are examples of services that support ACLs.

---

- You are working for a SaaS (Software as a Service) company as a solutions architect and help design solutions for the company's customers. One of the customers is a bank and has a requirement to whitelist up to two public IPs when the bank is accessing external services across the internet.
    Which architectural choice do you recommend to maintain high availability, support scaling-up to 10 instances and comply with the bank's requirements?

- Answer: Use a Network Load Balancer with an Auto Scaling Group (ASG)
  - Network Load Balancer is best suited for use-cases involving low latency and high throughput workloads that involve scaling to millions of requests per second. Network Load Balancer operates at the connection level (Layer 4), routing connections to targets - Amazon EC2 instances, microservices, and containers – within Amazon Virtual Private Cloud (Amazon VPC) based on IP protocol data. A Network Load Balancer functions at the fourth layer of the Open Systems Interconnection (OSI) model. It can handle millions of requests per second.
  - Network Load Balancers expose a fixed IP to the public web, therefore allowing your application to be predictably reached using these IPs, while allowing you to scale your application behind the Network Load Balancer using an ASG.

Incorrect options:
  - Classic Load Balancers and Application Load Balancers use the private IP addresses associated with their Elastic network interfaces as the source IP address for requests forwarded to your web servers.

  - These IP addresses can be used for various purposes, such as allowing the load balancer traffic on the web servers and for request processing. It's a best practice to use security group referencing on the web servers for whitelisting load balancer traffic from Classic Load Balancers or Application Load Balancers.

  - However, because Network Load Balancers don't support security groups, based on the target group configurations, the IP addresses of the clients or the private IP addresses associated with the Network Load Balancers must be allowed on the web server's security group.

---

- Use Exponential Backoff
  - While this may help in the short term, as soon as the request rate increases, you will see the ProvisionedThroughputExceededException exception again.

- Increase the number of shards
  - Increasing shards could be a short term fix but will substantially increase the cost, so this option is ruled out.

- Decrease the Stream retention duration
  - This operation may result in data loss and won't help with the exceptions, so this option is incorrect.

---
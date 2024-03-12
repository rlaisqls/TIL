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

  -  AWS Direct Connect does not involve the Internet; instead, it uses dedicated, private network connections between your intranet and Amazon VPC. **Direct Connect involves significant monetary investment and takes at least a month to set up.**

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

- The EBS volume was configured as the root volume of the Amazon EC2 instance. On termination of the instance, the default behavior is to also terminate the attached root volume

---

- A company hires experienced specialists to analyze the customer service calls attended by its call center representatives. Now, the company wants to move to AWS Cloud and is looking at an automated solution to analyze customer service calls for sentiment analysis via ad-hoc SQL queries.
    As a Solutions Architect, which of the following solutions would you recommend?

- Answer: Use Amazon Transcribe to convert audio files to text and Amazon Athena to understand the underlying customer sentiments
  - Amazon Transcribe is an automatic speech recognition (ASR) service that makes it easy to convert audio to text. One key feature of the service is called speaker identification, which you can use to label each individual speaker when transcribing multi-speaker audio files. You can specify Amazon Transcribe to identify 2–10 speakers in the audio clip.
  - Amazon Athena is an interactive query service that makes it easy to analyze data in Amazon S3 using standard SQL. Athena is serverless, so there is no infrastructure to manage, and you pay only for the queries that you run. To leverage Athena, you can simply point to your data in Amazon S3, define the schema, and start querying using standard SQL. Most results are delivered within seconds.
  - Analyzing multi-speaker audio files using Amazon Transcribe and Amazon Athena:
  - ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/270f3abd-a126-419d-b81e-66b4cf277dea)

---

- A retail company wants to establish encrypted network connectivity between its on-premises data center and AWS Cloud. The company wants to get the solution up and running in the fastest possible time and it should also support encryption in transit.
    As a solutions architect, which of the following solutions would you suggest to the company?

- Answer: Use Site-to-Site VPN to establish encrypted network connectivity between the on-premises data center and AWS Cloud
  - You can securely extend your data center or branch office network to the cloud with an AWS Site-to-Site VPN connection. A VPC VPN Connection utilizes IPSec to establish encrypted network connectivity between your on-premises network and Amazon VPC over the Internet. IPsec is a protocol suite for securing IP communications by authenticating and encrypting each IP packet in a data stream.

  - To encrypt the data in transit that traverses AWS Direct Connect, you must use the transit encryption options for that service. As **AWS Direct Connect does not support encrypted network connectivity between an on-premises data center and AWS Cloud**, therefore this option is incorrect.

---

**it is not possible to modify a launch configuration once it is created. Hence, this option is incorrect.**

---

- An application hosted on Amazon EC2 contains sensitive personal information about all its customers and needs to be protected from all types of cyber-attacks. The company is considering using the AWS Web Application Firewall (WAF) to handle this requirement.
    Can you identify the correct solution leveraging the capabilities of WAF?

- Answer: Create a CloudFront distribution for the application on Amazon EC2 instances. Deploy AWS WAF on Amazon CloudFront to provide the necessary safety measures
  
  - When you use AWS WAF with CloudFront, you can protect your applications running on any HTTP webserver, whether it's a webserver that's running in Amazon Elastic Compute Cloud (Amazon EC2) or a web server that you manage privately. You can also configure CloudFront to require HTTPS between CloudFront and your own webserver, as well as between viewers and CloudFront.
  
  - **AWS WAF is tightly integrated with Amazon CloudFront and the Application Load Balancer (ALB)**, services that AWS customers commonly use to deliver content for their websites and applications.
  
  - When you use AWS WAF on Amazon CloudFront, your rules run in all AWS Edge Locations, located around the world close to your end-users. This means security doesn’t come at the expense of performance. Blocked requests are stopped before they reach your web servers. When you use AWS WAF on Application Load Balancer, your rules run in the region and can be used to protect internet-facing as well as internal load balancers.

---

- S3 One Zone-IA is a good choice for storing secondary backup copies of on-premises data or easily re-creatable data. The given scenario clearly states that the business-critical data is not easy to reproduce, so this option is incorrect.

---

- A financial services firm uses a high-frequency trading system and wants to write the log files into Amazon S3. The system will also read these log files in parallel on a near real-time basis. The engineering team wants to address any data discrepancies that might arise when the trading system overwrites an existing log file and then tries to read that specific log file.
    Which of the following options BEST describes the capabilities of Amazon S3 relevant to this scenario?

- Answer: **A process replacas an existing object and immediately tries to read it. Amazon S3 always returns the latest version of the object**

  - Amazon S3 delivers strong read-after-write consistency automatically, without changes to performance or availability, without sacrificing regional isolation for applications, and at no additional cost.

  - After a successful write of a new object or an overwrite of an existing object, any subsequent read request immediately receives the latest version of the object. S3 also provides strong consistency for list operations, so after a write, you can immediately perform a listing of the objects in a bucket with any changes reflected.

  - Strong read-after-write consistency helps when you need to immediately read an object after a write. For example, strong read-after-write consistency when you often read and list immediately after writing objects.

  - To summarize, all S3 GET, PUT, and LIST operations, as well as operations that change object tags, ACLs, or metadata, are strongly consistent. What you write is what you will read, and the results of a LIST will be an accurate reflection of what’s in the bucket.

---

- An application with global users across AWS Regions had suffered an issue when the Elastic Load Balancer (ELB) in a Region malfunctioned thereby taking down the traffic with it. The manual intervention cost the company significant time and resulted in major revenue loss.
    What should a solutions architect recommend to reduce internet latency and add automatic failover across AWS Regions?

- Answer: **Set up AWS Global Accelerator and add endpoints to cater to users in different geographic locations**

  - As your application architecture grows, so does the complexity, with longer user-facing IP lists and more nuanced traffic routing logic. AWS Global Accelerator solves this by providing you with two static IPs that are anycast from our globally distributed edge locations, giving you a single entry point to your application, regardless of how many AWS Regions it’s deployed in. This allows you to add or remove origins, Availability Zones or Regions without reducing your application availability. Your traffic routing is managed manually, or in console with endpoint traffic dials and weights. If your application endpoint has a failure or availability issue, AWS Global Accelerator will automatically redirect your new connections to a healthy endpoint within seconds.

  - By using AWS Global Accelerator, you can:

        1. Associate the static IP addresses provided by AWS Global Accelerator to regional AWS resources or endpoints, such as Network Load Balancers, Application Load Balancers, EC2 Instances, and Elastic IP addresses. The IP addresses are anycast from AWS edge locations so they provide onboarding to the AWS global network close to your users.

        2. Easily move endpoints between Availability Zones or AWS Regions without needing to update your DNS configuration or change client-facing applications.

        3. Dial traffic up or down for a specific AWS Region by configuring a traffic dial percentage for your endpoint groups. This is especially useful for testing performance and releasing updates.

        4. Control the proportion of traffic directed to each endpoint within an endpoint group by assigning weights across the endpoints.

- Incorrect: Set up an Amazon Route 53 geoproximity routing policy to route traffic
  - Geoproximity routing lets Amazon Route 53 route traffic to your resources based on the geographic location of your users and your resources.
  - Unlike Global Accelerator, managing and routing to different instances, ELBs and other AWS resources will become an operational overhead as the resource count reaches into the hundreds. With inbuilt features like Static anycast IP addresses, fault tolerance using network zones, Global performance-based routing, TCP Termination at the Edge - Global Accelerator is the right choice for multi-region, low latency use cases.

---

**Database cloning is only available for Aurora and not for RDS.**

---

**Data transfer pricing over Direct Connect is lower than data transfer pricing over the internet.**

---

- A company wants to ensure high availability for its RDS database. The development team wants to opt for Multi-AZ deployment and they would like to understand what happens when the primary instance of the Multi-AZ configuration goes down.
    As a Solutions Architect, which of the following will you identify as the outcome of the scenario?

- Answer: **The CNAME record will be updated to point to the standby DB**
  - Amazon RDS provides high availability and failover support for DB instances using Multi-AZ deployments. Amazon RDS uses several different technologies to provide failover support. Multi-AZ deployments for MariaDB, MySQL, Oracle, and PostgreSQL DB instances use Amazon's failover technology. SQL Server DB instances use SQL Server Database Mirroring (DBM) or Always On Availability Groups (AGs).

  - In a Multi-AZ deployment, Amazon RDS automatically provisions and maintains a synchronous standby replica in a different Availability Zone. The primary DB instance is synchronously replicated across Availability Zones to a standby replica to provide data redundancy, eliminate I/O freezes, and minimize latency spikes during system backups. Running a DB instance with high availability can enhance availability during planned system maintenance, and help protect your databases against DB instance failure and Availability Zone disruption.

  - Failover is automatically handled by Amazon RDS so that you can resume database operations as quickly as possible without administrative intervention. When failing over, Amazon RDS simply flips the canonical name record (CNAME) for your DB instance to point at the standby, which is in turn promoted to become the new primary. Multi-AZ means the URL is the same, the failover is automated, and the CNAME will automatically be updated to point to the standby database.

---

- An engineering team wants to orchestrate multiple Amazon ECS task types running on EC2 instances that are part of the ECS cluster. The output and state data for all tasks need to be stored. The amount of data output by each task is approximately 20 MB and there could be hundreds of tasks running at a time. As old outputs are archived, the storage size is not expected to exceed 1 TB.
    As a solutions architect, which of the following would you recommend as an optimized solution for high-frequency reading and writing?

Amazon EFS file systems are distributed across an unconstrained number of storage servers. This distributed data storage design enables file systems to grow elastically to petabyte scale. It also enables massively parallel access from compute instances, including Amazon EC2, Amazon ECS, and AWS Lambda, to your data.

- **Use Amazon EFS with Provisioned Throughput mode**
  
  - Provisioned Throughput mode is available for applications with high throughput to storage (MiB/s per TiB) ratios, or with requirements greater than those allowed by the Bursting Throughput mode. For example, say you're using Amazon EFS for development tools, web serving, or content management applications where the amount of data in your file system is low relative to throughput demands. Your file system can now get the high levels of throughput your applications require without having to pad your file system.
  
  - If your file system is in the Provisioned Throughput mode, you can increase the Provisioned Throughput of your file system as often as you want. You can decrease your file system throughput in Provisioned Throughput mode as long as it's been more than 24 hours since the last decrease. Additionally, you can change between Provisioned Throughput mode and the default Bursting Throughput mode as long as it’s been more than 24 hours since the last throughput mode change.

- **Use Amazon EFS with Bursting Throughput mode**
  
  - With Bursting Throughput mode, a file system's throughput scales as the amount of data stored in the standard storage class grows. File-based workloads are typically spiky, driving high levels of throughput for short periods of time, and low levels of throughput the rest of the time. To accommodate this, Amazon EFS is designed to burst to high throughput levels for periods of time. By default, AWS recommends that you run your application in the Bursting Throughput mode. But, if you're planning to migrate large amounts of data into your file system, consider switching to Provisioned Throughput mode.

  - The use-case mentions that the solution should be optimized for high-frequency reading and writing even when the old outputs are archived, therefore Provisioned Throughput mode is a better fit as it guarantees high levels of throughput your applications require without having to pad your file system.

---

- You are deploying a critical monolith application that must be deployed on a single web server, as it hasn't been created to work in distributed mode. Still, you want to make sure your setup can automatically recover from the failure of an AZ.
    Which of the following options should be combined to form the MOST cost-efficient solution? (Select three)

- **Create an auto-scaling group that spans across 2 AZ, which min=1, max=1, desired=1**

  - Amazon EC2 Auto Scaling helps you ensure that you have the correct number of Amazon EC2 instances available to handle the load for your application. You create collections of EC2 instances, called Auto Scaling groups. You can specify the minimum number of instances in each Auto Scaling group, and Amazon EC2 Auto Scaling ensures that your group never goes below this size.
  - So we have an ASG with desired=1, across two AZ, so that if an instance goes down, it is automatically recreated in another AZ. So this option is correct.

- Create an Elastic IP and use the EC2 user-data script to attach it

  - Application Load Balancer (ALB) operates at the request level (layer 7), routing traffic to targets – EC2 instances, containers, IP addresses, and Lambda functions based on the content of the request. Ideal for advanced load balancing of HTTP and HTTPS traffic, Application Load Balancer provides advanced request routing targeted at delivery of modern application architectures, including microservices and container-based applications.

  - An Elastic IP address is a static IPv4 address designed for dynamic cloud computing.
    - An Elastic IP address is associated with your AWS account. With an Elastic IP address, you can mask the failure of an instance or software by rapidly remapping the address to another instance in your account.

  - Now, between the ALB and the Elastic IP. If we use an ALB, things will still work, but we will have to pay for the provisioned ALB which sends traffic to only one EC2 instance. Instead, to minimize costs, we must use an Elastic IP.

- Assign an EC2 Instance Role to perform the necessary API calls

  - For that Elastic IP to be attached to our EC2 instance, we must use an EC2 user data script, and our EC2 instance must have the correct IAM permissions to perform the API call, so we need an EC2 instance role.

---

**Redis does not support multi-threading**

---

DB 엔진 유지 관리
- 데이터베이스 엔진 수준으로 업그레이드하려면 가동 중지가 필요합니다. RDS DB 인스턴스가 다중 AZ 배포를 사용하더라도 기본 및 대기 DB 인스턴스는 동시에 업그레이드됩니다. 이로 인해 업그레이드가 완료될 때까지 가동 중지가 발생하고 가동 중지 기간은 DB 인스턴스의 크기에 따라 달라집니다. 자세한 내용은 DB 인스턴스 엔진 버전 업그레이드의 DB 엔진 섹션을 참조하세요.

- 참고: SQL Server DB 인스턴스를 다중 AZ 배포로 업그레이드하는 경우 기본 및 대기 인스턴스가 모두 업그레이드됩니다. Amazon RDS는 롤링 업그레이드를 수행하므로 장애 조치 기간에만 중단됩니다. 자세한 내용은 다중 AZ 및 인 메모리 최적화 고려 사항을 참조하세요.

---

- The engineering team at a startup is evaluating the most optimal block storage volume type for the EC2 instances hosting its flagship application. The storage volume should support very low latency but it does not need to persist the data when the instance terminates. As a solutions architect, you have proposed using Instance Store volumes to meet these requirements.
    Which of the following would you identify as the key characteristics of the Instance Store volumes? (Select two)

- **You can't detach an instance store volume from one instance and attach it to a different instance**
  - You can specify instance store volumes for an instance only when you launch it. You can't detach an instance store volume from one instance and attach it to a different instance. The data in an instance store persists only during the lifetime of its associated instance. If an instance reboots (intentionally or unintentionally), data in the instance store persists.

- **If you create an AMI from an instance, the data on its instance store volumes isn't preserved**
  - If you create an AMI from an instance, the data on its instance store volumes isn't preserved and isn't present on the instance store volumes of the instances that you launch from the AMI.

Incorrect options:

- Instance store is reset when you stop or terminate an instance. Instance store data is preserved during hibernation
  - **When you stop, hibernate, or terminate an instance, every block of storage in the instance store is reset.** Therefore, this option is incorrect.

- You can specify instance store volumes for an instance when you launch or restart it
  - **You can specify instance store volumes for an instance only when you launch it.**

- An instance store is a network storage type
  - **An instance store provides temporary block-level storage for your instance.** This storage is located on disks that are physically attached to the host computer.


---

**you should create a read-replica with the same compute capacity and the same storage capacity as the primary.**

---

- A company runs an ecommerce application on Amazon EC2 instances behind an Application Load Balancer. The instances run in an Amazon EC2 Auto Scaling group across multiple Availability Zones. The Auto Scaling group scales based on CPU utilization metrics. The ecommerce application stores the transaction data in a MySQL 8.0 database that is hosted on a large EC2 instance.
  The database's performance degrades quickly as application load increases. The application handles more read requests than write transactions. The company wants a solution that will automatically scale the database to meet the demand of unpredictable read workloads while maintaining high availability. Which solution will meet these requirements?

- I would recommend option C: Use AWS Network Firewall to create the required rules for traffic inspection and traffic filtering for the production VPC.
  AWS Network Firewall is a managed firewall service that provides filtering for both inbound and outbound network traffic. It allows you to create rules for traffic inspection and filtering, which can help protect your production VPC.
  Option A: Amazon GuardDuty is a threat detection service, not a traffic inspection or filtering service.
  Option B: Traffic Mirroring is a feature that allows you to replicate and send a copy of network traffic from a VPC to another VPC or on-premises location. It is not a service that performs traffic inspection or filtering.
  Option D: AWS Firewall Manager is a security management service that helps you to centrally configure and manage firewalls across your accounts. It is not a service that performs traffic inspection or filtering.

---

 Incorrect: Amazon QuickSight only support users(standard version) and groups (enterprise version). QuickSight don't support IAM. We use users and groups to view the QuickSight dashboard

---

- A development team runs monthly resource-intensive tests on its general purpose Amazon RDS for MySQL DB instance with Performance Insights enabled. The testing lasts for 48 hours once a month and is the only process that uses the database. The team wants to reduce the cost of running the tests without reducing the compute and memory attributes of the DB instance.
  Which solution meets these requirements MOST cost-effectively?

- A. Stop the DB instance when tests are completed. Restart the DB instance when required.
  - By stopping the DB although you are not paying for DB hours you are still paying for Provisioned IOPs, the storage for Stopped DB is more than Snapshot of underlying EBS vol. and Automated Back ups.
- C. Create a snapshot when tests are completed. Terminate the DB instance and restore the snapshot when required.
  - Create a manual Snapshot of DB and shift to S3- Standard and Restore form Manual Snapshot when required.

---

- The data stored on the Snowball Edge device can be copied into the S3 bucket and later transitioned into AWS Glacier via a lifecycle policy. You can't directly copy data from Snowball Edge devices into AWS Glacier.

---

- **Only Standard SQS queue is allowed as an Amazon S3 event notification destination, whereas FIFO SQS queue is not allowed.**

- The Amazon S3 notification feature enables you to receive notifications when certain events happen in your bucket. To enable notifications, you must first add a notification configuration that identifies the events you want Amazon S3 to publish and the destinations where you want Amazon S3 to send the notifications.
  - Amazon S3 supports the following destinations where it can publish events:
  - Amazon Simple Notification Service (Amazon SNS) topic
  - Amazon Simple Queue Service (Amazon SQS) queue
  - AWS Lambda

- Currently, the Standard SQS queue is only allowed as an Amazon S3 event notification destination, whereas the FIFO SQS queue is not allowed.

https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventNotifications.html

---

- Use a Web Application Firewall and setup a rate-based rule

- AWS WAF is a web application firewall that helps protect your web applications or APIs against common web exploits that may affect availability, compromise security, or consume excessive resources. AWS WAF gives you control over how traffic reaches your applications by enabling you to create security rules that block common attack patterns, such as SQL injection or cross-site scripting, and rules that filter out specific traffic patterns you define.
  The correct answer is to use WAF (which has integration on top of your ALB) and define a rate-based rule.


- AWS Shield Advanced will **give you DDoS protection overall, and you cannot set up rate-based rules in Shield.**

---

**Any database engine level upgrade for an RDS DB instance with Multi-AZ deployment triggers both the primary and standby DB instances to be upgraded at the same time. This causes downtime until the upgrade is complete
**

---

**Multi-Attach is supported exclusively on Provisioned IOPS SSD volumes.**

---

<img width="653" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/7ed50244-bf79-4a79-b7c6-66e0fc8ff360">

> https://www.examtopics.com/exams/amazon/aws-certified-solutions-architect-associate-saa-c03/

---
 
- A company is moving its on-premises Oracle database to Amazon Aurora PostgreSQL. The database has several applications that write to the same tables.
- The applications need to be migrated one by one with a month in between each migration.
- Management has expressed concerns that the database has a high number of reads and writes. The data must be kept in sync across both databases throughout the migration.
- What should a solutions architect recommend?

  - A. Use AWS DataSync for the initial migration. Use AWS Database Migration Service (AWS DMS) to create a change data capture (CDC) replication task and a table mapping to select all tables.
  - B. Use AWS DataSync for the initial migration. Use AWS Database Migration Service (AWS DMS) to create a full load plus change data capture (CDC) replication task and a table mapping to select all tables.
  - C. Use the AWS Schema Conversion Tool with AWS Database Migration Service (AWS DMS) using a memory optimized replication instance. Create a full load plus change data capture (CDC) replication task and a table mapping to select all tables. Most Voted
  - D. Use the AWS Schema Conversion Tool with AWS Database Migration Service (AWS DMS) using a compute optimized replication instance. Create a full load plus change data capture (CDC) replication task and a table mapping to select the largest tables.

  - Answer: C. 
    - The AWS SCT is used to convert the schema and code of the Oracle database to be compatible with Aurora PostgreSQL. AWS DMS is utilized to migrate the data from the Oracle database to Aurora PostgreSQL. Using a memory-optimized replication instance is recommended to handle the high number of reads and writes during the migration process.
    - By creating a full load plus CDC replication task, the initial data migration is performed, and ongoing changes in the Oracle database are continuously captured and applied to the Aurora PostgreSQL database. Selecting all tables for table mapping ensures that all the applications writing to the same tables are migrated.
    - Option A & B are incorrect because using AWS DataSync alone is not sufficient for database migration and data synchronization.
    - Option D is incorrect because using a compute optimized replication instance is not the most suitable choice for handling the high number of reads and writes.

---

- A company wants to experiment with individual AWS accounts for its engineer team. The company wants to be notified as soon as the Amazon EC2 instance usage for a given month exceeds a specific threshold for each account.
  What should a solutions architect do to meet this requirement MOST cost-effectively?

  - A. Use Cost Explorer to create a daily report of costs by service. Filter the report by EC2 instances. Configure Cost Explorer to send an Amazon Simple Email Service (Amazon SES) notification when a threshold is exceeded.
  - B. Use Cost Explorer to create a monthly report of costs by service. Filter the report by EC2 instances. Configure Cost Explorer to send an Amazon Simple Email Service (Amazon SES) notification when a threshold is exceeded.
  - C. Use AWS Budgets to create a cost budget for each account. Set the period to monthly. Set the scope to EC2 instances. Set an alert threshold for the budget. Configure an Amazon Simple Notification Service (Amazon SNS) topic to receive a notification when a threshold is exceeded. Most Voted
  - D. Use AWS Cost and Usage Reports to create a report with hourly granularity. Integrate the report data with Amazon Athena. Use Amazon EventBridge to schedule an Athena query. Configure an Amazon Simple Notification Service (Amazon SNS) topic to receive a notification when a threshold is exceeded.

  - Answer: C, AWS Budgets allows you to set a budget for costs and usage for your accounts and you can set alerts when the budget threshold is exceeded in real-time which meets the requirement.
    - Why not B: B would be the most cost-effective if the requirements didn't ask for real-time notification. You would not incur additional costs for the daily or monthly reports and the notifications. **But doesn't provide real-time alerts.**

---

- A company is implementing a shared storage solution for a media application that is hosted in the AWS Cloud. The company needs the ability to use SMB clients to access data. The solution must be fully managed.
- Which AWS solution meets these requirements?

- D. Create an Amazon FSx for Windows File Server file system. Attach the file system to the origin server. Connect the application server to the file system
  - SMB + fully managed = fsx for windows imo

---

- A company recently announced the deployment of its retail website to a global audience. The website runs on multiple Amazon EC2 instances behind an Elastic Load Balancer. The instances run in an Auto Scaling group across multiple Availability Zones.
  The company wants to **provide its customers with different versions of content based on the devices that the customers use to access the website.** Which combination of actions should a solutions architect take to meet these requirements? (Choose two.)

- A. Configure Amazon CloudFront to cache multiple versions of the content. Most Voted
- C. Configure a Lambda@Edge function to send specific objects to users based on the User-Agent header.

---

- A company plans to use Amazon ElastiCache for its multi-tier web application. A solutions architect creates a Cache VPC for the ElastiCache cluster and an App VPC for the application’s Amazon EC2 instances. Both VPCs are in the us-east-1 Region.
  The solutions architect must implement a solution to provide the application’s EC2 instances with access to the ElastiCache cluster.
  Which solution will meet these requirements MOST cost-effectively?

- Create a peering connection between the VPCs. Add a route table entry for the peering connection in both VPCs. Configure an inbound rule for the ElastiCache cluster’s security group to allow inbound connection from the application’s security group.

---

- A company is using a centralized AWS account to store log data in various Amazon S3 buckets. A solutions architect needs to ensure that the data is encrypted at rest before the data is uploaded to the S3 buckets. The data also must be encrypted in transit.
  Which solution meets these requirements?

- Use client-side encryption to encrypt the data that is being uploaded to the S3 buckets.
  - here keyword is "before" "the data is encrypted at rest before the data is uploaded to the S3 buckets."

---

- A company runs an application on Amazon EC2 instances. The company needs to implement a disaster recovery (DR) solution for the application. The DR solution needs to have a recovery time objective (RTO) of less than 4 hours. The DR solution also needs to use the fewest possible AWS resources during normal operations.

- B. Create Amazon Machine Images (AMIs) to back up the EC2 instances. Copy the AMIs to a secondary AWS Region. Automate infrastructure deployment in the secondary Region by using AWS CloudFormation.
  - Creating AMIs for backup and using AWS CloudFormation for infrastructure deployment in the secondary Region is a more streamlined and automated approach. CloudFormation allows you to define and provision resources in a declarative manner, making it easier to maintain and update your infrastructure. This solution is more operationally efficient compared to Option A.

---

- A company has an application that is backed by an Amazon DynamoDB table. The company’s compliance requirements specify that database backups must be taken every month, must be available for 6 months, and must be retained for 7 years.
  Which solution will meet these requirements?

- A. Create an AWS Backup plan to back up the DynamoDB table on the first day of each month. Specify a lifecycle policy that transitions the backup to cold storage after 6 months. Set the retention period for each backup to 7 years. Most Voted
- B. Create a DynamoDB on-demand backup of the DynamoDB table on the first day of each month. Transition the backup to Amazon S3 Glacier Flexible Retrieval after 6 months. Create an S3 Lifecycle policy to delete backups that are older than 7 years.

---

- A research company runs experiments that are powered by a simulation application and a visualization application. The simulation application runs on Linux and outputs intermediate data to an NFS share every 5 minutes. The visualization application is a Windows desktop application that displays the simulation output and requires an SMB file system.
  The company maintains two synchronized file systems. This strategy is causing data duplication and inefficient resource usage. The company needs to migrate the applications to AWS without making code changes to either application.
  Which solution will meet these requirements?


- Answer: D. Migrate the simulation application to Linux Amazon EC2 instances. Migrate the visualization application to Windows EC2 instances. Configure Amazon FSx for NetApp ONTAP for storage.

---

**EBS volumes can only attach to a single EC2 instance.** They cannot be mounted by multiple servers concurrently and do not provide a shared file system.

---

- A university research laboratory needs to migrate 30 TB of data from an on-premises Windows file server to Amazon FSx for Windows File Server. The laboratory has a 1 Gbps network link that many other departments in the university share.
  The laboratory wants to implement a data migration service that will maximize the performance of the data transfer. However, the laboratory needs to be able to control the amount of bandwidth that the service uses to minimize the impact on other departments. The data migration must take place within the next 5 days.
  Which AWS solution will meet these requirements?

---

- A company is designing a shared storage solution for a gaming application that is hosted in the AWS Cloud. The company needs the ability to use SMB clients to access data. The solution must be fully managed.
  Which AWS solution meets these requirements?

- Answer: C, Create an Amazon FSx for Windows File Server file system. Attach the file system to the origin server. Connect the application server to the file system.
  - Amazon FSx for Windows File Server provides a fully managed native Windows file system that can be accessed using the industry-standard SMB protocol. This allows Windows clients like the gaming application to directly access file data.
  - FSx for Windows File Server handles time-consuming file system administration tasks like provisioning, setup, maintenance, file share management, backups, security, and software patching - reducing operational overhead.
  - FSx for Windows File Server supports high file system throughput, IOPS, and consistent low latencies required for performance-sensitive workloads. This makes it suitable for a gaming application.
  - The file system can be directly attached to EC2 instances, providing a performant shared storage solution for the gaming servers.

--- 

AWS Storage Gateway Volume Gateway provides two configurations for connecting to iSCSI storage, namely, stored volumes and cached volumes, The storaed volume configuration stores the entire data set on-premises and asynchronoudly backs up the date to AWS> The cached volume configuration stores recently accessed data on-premises, and the remaining data is stored in S3.
- https://docs.amazonaws.cn/en_us/storagegateway/latest/vgw/StorageGatewayConcepts.html#storage-gateway-cached-concepts
  
---

- A solutions architect needs to optimize storage costs. The solutions architect must identify any Amazon S3 buckets that are no longer being accessed or are rarely accessed.
  Which solution will accomplish this goal with the LEAST operational overhead?

- Answer: A. Analyze bucket access patterns by using the S3 Storage Lens dashboard for advanced activity metrics.
  - S3 Storage Lens is a cloud-storage analytics feature that provides you with 29+ usage and activity metrics, including object count, size, age, and access patterns. This data can help you understand how your data is being used and identify areas where you can optimize your storage costs.
  - https://aws.amazon.com/ko/blogs/aws/s3-storage-lens/

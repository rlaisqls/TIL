- The founder has provisioned an EC2 instance 1A which is running in region A. Later, he takes a snapshot of the instance 1A and then creates a new AMI in region A from this snapshot. This AMI is then copied into another region B. The founder provisions an instance 1B in region B using this new AMI in region B.
    At this point in time, what entities exist in region B?

- Keyword: AMI

- Answer: 1 EC2 instance, 1 AMI and 1 snapshot exist in region B
  - An Amazon Machine Image (AMI) provides the information required to launch an instance. You must specify an AMI when you launch an instance.
  - When the new AMI is copied from region A into region B, **it automatically creates a snapshot in region B because AMIs are based on the underlying snapshots.** Further, an instance is created from this AMI in region B. Hence, we have 1 EC2 instance, 1 AMI and 1 snapshot in region B.

---

- A company uses Amazon S3 buckets for storing sensitive customer data. The company has defined different retention periods for different objects present in the Amazon S3 buckets, based on the compliance requirements. But, the retention rules do not seem to work as expected.
    Which of the following options represent a valid configuration for setting up retention periods for objects in Amazon S3 buckets? (Select two)

- Keyword: S3

- Answer:
  - **When you apply a retention periond to an object version ecplictly, you specify a `Retain Until Date` for the object version**
    - You can place a retention period on an object version either explictly or through a bucket default setting. When you apply a retention period to an object version expliciyly, you specify a `Retain Until Date` for the object version. Amazon S3 stores the Retain Until Date setting in the object version's metadata and protects the object version until the retention period expires.
  - **Defferent versions of a single object can have different retention mades and periods.**
    - Like all other Object Lock settings, retention periods apply to individual object versions. Defferent versions of a single object can have different retention modes and periods.
    - For example, suppose that you have an object that is 15 days into a 30-day retention period, and you PUT an object into S3 with the same name and a 60-day retention period. In this case, your PUT succeeds, and S3 creates a new cersion of the object with a 60-day retention period. The olderversion maintains its original retention period and becomes deletable in 15 days.

---

- Can you identify those storage volume types that CANNOT be used as boot volumes while creating the instances? (Select two)

- Keyword: EBS

- Answer:
  - **Throughput Optimized HDD (st1)**
  - **Cold HDD (sc1)**

- The EBS volume types fall into two categories:

- SSD-backed volumes optimized for transactional workloads involving frequent read/write operations with small I/O size, where the dominant performance attribute is IOPS.

- HDD-backed volumes optimized for large streaming workloads where throughput (measured in MiB/s) is a better performance measure than IOPS.

- Throughput Optimized HDD (st1) and Cold HDD (sc1) volume types CANNOT be used as a boot volume, so these two options are correct.


- https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock-overview.html
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html
---

- A gaming company uses Amazon Aurora as its primary database service. The company has now deployed 5 multi-AZ read replicas to increase the read throughput and for use as failover target. The replicas have been assigned the following failover priority tiers and corresponding instance sizes are given in parentheses: tier-1 (16TB), tier-1 (32TB), tier-10 (16TB), tier-15 (16TB), tier-15 (32TB).
    In the event of a failover, Amazon Aurora will promote which of the following read replicas?

- Keyword: EBS

- Answer: **Tier-1 (32TB)**
  - For Amazon Aurora, each Read Replica is associated with a priority tier (0-15). In the event of a failover, Amazon Aurora will promote the Read Replica that has the highest priority (the lowest numbered tier).
  - If two or more Aurora Replicas share the same priority, then Amazon RDS promotes the replica **that is largest in size**. If two or more Aurora Replicas share the same priority and size, then Amazon Aurora promotes an arbitrary replica in the same promotion tier.
  - Therefore, for this problem statement, the Tier-1 (32TB) replica will be promoted.

---

- An IT company wants to review its security best-practices after an incident was reported where a new developer on the team was assigned full access to DynamoDB. The developer accidentally deleted a couple of tables from the production environment while building out a new feature.
    Which is the MOST effective way to address this issue so that such incidents do not recur?

- Keyword: permissions boundary

- Answer: **Use permissions boundary to control the maximum permissions employees can grant to the IAM principals.**
  - A permissions boundary can be used to control the maximum permissions employees can grant to the IAM principals (that is, users and roles) that they create and manage. As the IAM administrator, you can define one or more permissions boundaries using managed policies and allow your employee to create a principal with this boundary. The employee can then attach a permissions policy to this principal. However, the effective permissions of the principal are the intersection of the permissions boundary and permissions policy. As a result, the new principal cannot exceed the boundary that you defined. Therefore, using the permissions boundary offers the right solution for this use-case.

- Permission Boundary Example:
    ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/ee05fc00-8110-407a-a8a9-6cdfeb5589d4)

---

- A large financial institution operates an on-premises data center with hundreds of PB of data managed on **Microsoft’s Distributed File System (DFS)**. The CTO wants the organization to transition into a hybrid cloud environment and run data-intensive analytics workloads that support DFS.
    Which of the following AWS services can facilitate the migration of these workloads?

- Keyword: FSx

- Answer: **Amazon FSx for Windows File Server**
    - Amazon FSx for Windows File Server provides fully managed, highly reliable file storage that is accessible over the industry-standard Service Message Block (SMB) protocol. It is built on Windows Server, delivering a wide range of administrative features such as user quotas, end-user file restore, and Microsoft Active Directory (AD) integration.
    - Amazon FSx supports the use of Microsoft’s Distributed File System (DFS) to organize shares into a single folder structure up to hundreds of PB in size. So this option is correct.
    - wrong answer: Amazon FSx for Lustre makes it easy and cost-effective to launch and run the world’s most popular high-performance file system. It is used for workloads such as machine learning, high-performance computing (HPC), video processing, and financial modeling. Amazon FSx enables you to use Lustre file systems for any workload where storage speed matters. FSx for Lustre does not support Microsoft’s Distributed File System (DFS), so this option is incorrect.

---

- An IT security consultancy is working on a solution to **protect data stored in S3 from any malicious activity as well as check for any vulnerabilities on EC2 instances.**
    As a solutions architect, which of the following solutions would you suggest to help address the given requirement?

- Keyword: GuardDuty

- Answer: Use **Amazon GuardDuty to monitor any malicious activity** on data stored in S3. Use security assessments provided by **Amazon Inspector to check for vulnerabilities** on EC2 instances

- Amazon GuardDuty offers threat detection that enables you to continuously monitor and protect your AWS accounts, workloads, and data stored in Amazon S3. GuardDuty analyzes continuous streams of meta-data generated from your account and network activity found in AWS CloudTrail Events, Amazon VPC Flow Logs, and DNS Logs. It also uses integrated threat intelligence such as known malicious IP addresses, anomaly detection, and machine learning to identify threats more accurately.

- How GuardDuty works:
    ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/9edace56-7058-4b52-af83-3d28dbab1f92)

- Amazon Inspector security assessments help you check for unintended network accessibility of your Amazon EC2 instances and for vulnerabilities on those EC2 instances. Amazon Inspector assessments are offered to you as pre-defined rules packages mapped to common security best practices and vulnerability definitions.

---

- A file-hosting service uses Amazon S3 under the hood to power its storage offerings. Currently all the customer files are uploaded directly under a single S3 bucket. The engineering team has started seeing scalability issues where customer file uploads have started failing during the peak access hours with more than 5000 requests per second.
    Which of the following is the MOST resource efficient and cost-optimal way of addressing this issue?

- Keyword: S3

- Answer: Change the application architecture to create **customer-specific custom prefixes** within the single bucket and then upload the daily files into those prefixed locations
    - Amazon Simple Storage Service (Amazon S3) is an object storage service that offers industry-leading scalability, data availability, security, and performance. Your applications can easily achieve thousands of transactions per second in request performance when uploading and retrieving storage from Amazon S3. Amazon S3 automatically scales to high request rates. For example, your application can achieve at least 3,500 `PUT`/`COPY`/`POST`/`DELETE` or 5,500 GET/HEAD requests per second per prefix in a bucket.
  
    - There are no limits to the number of prefixes in a bucket. You can increase your read or write performance by parallelizing reads. For example, if you create 10 prefixes in an Amazon S3 bucket to parallelize reads, you could scale your read performance to 55,000 read requests per second. Please see this example for more clarity on prefixes: if you have a file f1 stored in an S3 object path like so `s3://your_bucket_name/folder1/sub_folder_1/f1`, then `/folder1/sub_folder_1/`` becomes the prefix for file f1.

    - Some data lake applications on Amazon S3 scan millions or billions of objects for queries that run over petabytes of data. These data lake applications achieve single-instance transfer rates that maximize the network interface used for their Amazon EC2 instance, which can be up to 100 Gb/s on a single instance. These applications then aggregate throughput across multiple instances to get multiple terabits per second. Therefore creating customer-specific custom prefixes within the single bucket and then uploading the daily files into those prefixed locations is the BEST solution for the given constraints.

    - https://docs.aws.amazon.com/AmazonS3/latest/dev/optimizing-performance.html

---

- A retail company uses Amazon EC2 instances, API Gateway, Amazon RDS, Elastic Load Balancer and CloudFront services. To improve the security of these services, the Risk Advisory group has suggested a feasibility check for using the Amazon GuardDuty service.
    Which of the following would you identify as data sources supported by GuardDuty?

- Keyword: Guard Duty

- Answer: **VPC Flow Logs, DNS logs, CloudTrail events**
  - Amazon GuardDuty is a threat detection service that continuously monitors for malicious activity and unauthorized behavior to protect your AWS accounts, workloads, and data stored in Amazon S3. 
  - With the cloud, the collection and aggregation of account and network activities is simplified, but it can be time-consuming for security teams to continuously analyze event log data for potential threats. With GuardDuty, you now have an intelligent and cost-effective option for continuous threat detection in AWS.
  - The service uses machine learning, anomaly detection, and integrated threat intelligence to identify and prioritize potential threats.
  - GuardDuty analyzes tens of billions of events across multiple AWS data sources, such as AWS CloudTrail events, Amazon VPC Flow Logs, and DNS logs.
  - With a few clicks in the AWS Management Console, GuardDuty can be enabled with no software or hardware to deploy or maintain. 
  - By integrating with Amazon EventBridge Events, GuardDuty alerts are actionable, easy to aggregate across multiple accounts, and straightforward to push into existing event management and workflow systems.

---

- A leading carmaker would like to build a new car-as-a-sensor service by leveraging fully serverless components that are provisioned and managed automatically by AWS. The development team at the carmaker does not want an option that requires the capacity to be manually provisioned, as it does not want to respond manually to changing volumes of sensor data.
    Given these constraints, which of the following solutions is the BEST fit to develop this car-as-a-sensor service?

- Keyword: SQS

- Answer: Ingest the sensor data in an Amazon SQS standard queue, which is polled by a Lambda function in batches and the data is written into an auto-scaled DynamoDB table for downstream processing.
  
  - AWS manages all ongoing operations and underlying infrastructure needed to provide a highly available and scalable message queuing service. With SQS, there is no upfront cost, no need to acquire, install, and configure messaging software, and no time-consuming build-out and maintenance of supporting infrastructure. SQS queues are dynamically created and scale automatically so you can build and grow applications quickly and efficiently.
  - As there is no need to manually provision the capacity, so this is the correct option.

  - **Incorrect options:** Ingest the sensor data in Kinesis Data Firehose, which directly writes the data into an auto-scaled DynamoDB table for downstream processing
  - Amazon Kinesis Data Firehose is a fully managed service for delivering real-time streaming data to destinations such as Amazon Simple Storage Service (Amazon S3), Amazon Redshift, Amazon OpenSearch Service, Splunk, and any custom HTTP endpoint or HTTP endpoints owned by supported third-party service providers, including Datadog, Dynatrace, LogicMonitor, MongoDB, New Relic, and Sumo Logic.
  - **Firehose cannot directly write into a DynamoDB table, so this option is incorrect.**

---

- A gaming company is looking at improving the availability and performance of its global flagship application which utilizes UDP protocol and needs to support fast regional failover in case an AWS Region goes down. The company wants to continue using its own custom DNS service.
    Which of the following AWS services represents the best solution for this use-case?

- Keyword: Global Accelerator

- Answer: **AWS Global Accelerator**
  - AWS Global Accelerator utilizes the Amazon global network, allowing you to improve the performance of your applications by lowering first-byte latency (the round trip time for a packet to go from a client to your endpoint and back again) and jitter (the variation of latency), and increasing throughput (the amount of time it takes to transfer data) as compared to the public internet.
  - Global Accelerator improves performance **for a wide range of applications over TCP or UDP by proxying packets at the edge to applications running in one or more AWS Regions.** Global Accelerator is a good fit for non-HTTP use cases, such as gaming (UDP), IoT (MQTT), or Voice over IP, as well as for HTTP use cases that specifically require static IP addresses or deterministic, fast regional failover.

---

- A junior scientist working with the Deep Space Research Laboratory at NASA is trying to upload a high-resolution image of a nebula into Amazon S3. The image size is approximately 3GB. The junior scientist is using S3 Transfer Acceleration (S3TA) for faster image upload. It turns out that S3TA did not result in an accelerated transfer.
    Given this scenario, which of the following is correct regarding the charges for this image transfer?

- Keyword: S3

- Answer: The junior scientist does not need to pay any transfer charges for the image upload
  - **There are no S3 data transfer charges when data is transferred in from the internet. Also with S3TA, you pay only for transfers that are accelerated.** Therefore the junior scientist does not need to pay any transfer charges for the image upload because S3TA did not result in an accelerated transfer.

---

- The engineering team at a Spanish professional football club has built a notification system for its website using Amazon SNS notifications which are then handled by a Lambda function for end-user delivery. During the off-season, the notification systems need to handle about 100 requests per second. During the peak football season, the rate touches about 5000 requests per second and it is noticed that a significant number of the notifications are not being delivered to the end-users on the website.
    As a solutions architect, which of the following would you suggest as the BEST possible solution to this issue?

- Keyword: SNS

- Answer: Amazon SNS message deliveries to AWS Lambda have crossed the account concurrency quota for Lambda, so the team needs to contact AWS support to raise the account limit.
  - AWS Lambda currently supports 1000 concurrent executions per AWS account per region. If your Amazon SNS message deliveries to AWS Lambda contribute to crossing these concurrency quotas, your Amazon SNS message deliveries will be throttled. You need to contact AWS support to raise the account limit. Therefore this option is correct.


---

- A technology blogger wants to write a review on the comparative pricing for various storage types available on AWS Cloud. The blogger has created a test file of size 1GB with some random data. Next he copies this test file into AWS S3 Standard storage class, provisions an EBS volume (General Purpose SSD (gp2)) with 100GB of provisioned storage and copies the test file into the EBS volume, and lastly copies the test file into an EFS Standard Storage filesystem. At the end of the month, he analyses the bill for costs incurred on the respective storage types for the test file.
    What is the correct order of the storage charges incurred for the test file on these three storage types?

- Answer: **Cost of test file storage on S3 Standard < Cost of test file storage on EFS < Cost of test file storage on EBS**

  - With Amazon EFS, you pay only for the resources that you use. The EFS Standard Storage pricing is $0.30 per GB per month. Therefore the cost for storing the test file on EFS is $0.30 for the month.

  - For EBS General Purpose SSD (gp2) volumes, the charges are $0.10 per GB-month of provisioned storage. Therefore, for a provisioned storage of 100GB for this use-case, the monthly cost on EBS is $0.10*100 = $10. This cost is irrespective of how much storage is actually consumed by the test file.

  - For S3 Standard storage, the pricing is $0.023 per GB per month. Therefore, the monthly storage cost on S3 for the test file is $0.023.

  - Therefore this is the correct option.

---

- A video analytics organization has been acquired by a leading media company. The analytics organization has 10 independent applications with an on-premises data footprint of about 70TB for each application. The CTO of the media company has set a timeline of two weeks to carry out the data migration from on-premises data center to AWS Cloud and establish connectivity.
    Which of the following are the MOST cost-effective options for completing the data transfer and establishing connectivity? (Select two)

- Keyword: Snowball
  - Keyword: VPN

- Answer-1: **Order 10 Snowball Edge Storage Optimized devices to complete the one-time data transfer**
    - Snowball Edge Storage Optimized is the optimal choice if you need to securely and quickly transfer dozens of terabytes to petabytes of data to AWS. It provides up to 80 TB of usable HDD storage, 40 vCPUs, 1 TB of SATA SSD storage, and up to 40 Gb network connectivity to address large scale data transfer and pre-processing use cases.
    - As each Snowball Edge Storage Optimized device can handle 80TB of data, you can order 10 such devices to take care of the data transfer for all applications.
    - Exam Alert:
      - The original Snowball devices were transitioned out of service and Snowball Edge Storage Optimized are now the primary devices used for data transfer. You may see the Snowball device on the exam, just remember that the original Snowball device had 80TB of storage space.

- Answer-2: **Setup Site-to-Site VPN to establish on-going connectivity between the on-premises data center and AWS Cloud**
  - **AWS Site-to-Site VPN enables you to securely connect your on-premises network or branch office site to your Amazon Virtual Private Cloud (Amazon VPC)**. You can securely extend your data center or branch office network to the cloud with an AWS Site-to-Site VPN connection. A VPC VPN Connection utilizes IPSec to establish encrypted network connectivity between your intranet and Amazon VPC over the Internet. VPN Connections can be configured in minutes and are a good solution if you have an immediate need, have low to modest bandwidth requirements, and can tolerate the inherent variability in Internet-based connectivity.
  - Therefore this option is the right fit for the given use-case as the connectivity can be easily established within the given timeframe.


---

- A geological research agency maintains the seismological data for the last 100 years. The data has a velocity of 1GB per minute. You would like to store the data with only the most relevant attributes to build a predictive model for earthquakes.
    What AWS services would you use to build the most cost-effective solution with the LEAST amount of infrastructure maintenance?

- Keyword: Kinesis

- Answer: Ingest the data in **Kinesis Data Firehose** and use an intermediary Lambda function to filter and transform the incoming stream before the output is **dumped on S3**

---

**DAX is a DynamoDB-compatible caching service that enables you to benefit from fast in-memory performance for demanding applications.**

- Keyword: DAX

---

A company is transfering a cluster of NoSQL databases to Amazon EC2. The database automatically duplicates data so as to retain at leasy three copies of it. I/O throughput of the servers is most vital. What sort of instance a solutions architect should suggest for the migration?

- A. Bustable general purpost instance with an EBS volume
- B. Memory optimized instance with an EBS optimization enabled
- C. Compute optimized instance with an EBS optimization enabled
- D. Instance store with storage optimized instances

- Keyword: EBS

- answer: D

- A and C is relate with CPU intensive workloads. Instead we need I/O throughput intensive as per the question. And memory optimization(B) is no connection with I/O throuput.

- However Storage optimized instances are porvide `high, sequential read and write access to very large data sets on local storage`. So, answer is D.

<img width="844" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/f895f61e-2eb9-4a62-9342-4b496ab6844a">

--- 

You need to design a solution for migrating a persistent database from on-premise to AWS. The database needs 64000 IOPS, which needs to be hosted on database instance on a single EBS volume. Which solution will meet the goal?

- Keyword: EBS

- Answer: Provision **Nitro**-based EC2 instances with Amazon **EBS provisioned IOPS SSD (io1)** volume attaches. Configure the volume to have 6400 IOPS

Nitro is the underlying platform for the latest generation of EC2 instances that enables AWS to innovate faster, further reduce cost for our customers, and deliver added benefits like increased security and new instance types.

It is possible to reach 64000 IOPS when use Nitro system

---

- Keyword: Aurora

Aurora replication differs from RDS replicas in the sense that **it is possible for Aurora's replicas to be both a standby as part of a multi-AZ configuration as well as a target for read traffic**. In RDS, the multi-AZ standby cannot be configured to be a read endpoint and only read replicas can serve that function.

---

A company wants to create a multi-instance application which requires low latency between the instances. What recommendation should you make?

- Answer: Implement auto scaling group with cluster placement group.

---

A e-commerce company hosts its internet-facing containerized web application on an Amazon **EKS cluster**. The EKS cluster is situated within a VPC's private subnet. The EKS cluster is accessed by developers using a bastion server on a public network. **As per new compliance requirement, security policy prohibits use of bastion hosts and public internet access to the EKS cluster.** Which of the following is most cost-effective solution?

- Keyword: VPN

- Answer: **Establish a VPN connection.**

---

- To improve the performance and security of the application, the engineering team at a company has created a CloudFront distribution with an Application Load Balancer as the custom origin. The team has also set up a Web Application Firewall(WAF) with CloudFront distribution. The security team at the company has noticed a surge in malicious attacks from a specific IP address to steal sensitive data stored on the EC2 instances.
    As a solutions architect, which of the following actions would you recommend to stop the attacks?

- Keyword: WAF

- Answer: **Create IP match condition in the WAF to block the malicious IP address**
    - AWS WAF is a web application firewall that helps protect your web applications or APIs against common web exploits that may affect availability, compromise security, or consume excessive resources. AWS WAF gives you control over how traffic reaches your applications by enabling you to create secuirty rules that block common attack patterns, such as SQL injection or cross-dite scripting, and rules that filter out specific traffic patterns you define.
    - If you want to aloow or block web requests based on the IP addresses that the requests originate from, create one or more IP match conditions. An IP match condition lists up to 10,000 UP addresses or UP address ranges that your requests originate from. So, this option is correct.
    - **NACLs are not associated with instances.**

---

- You have multiple AWS accounts within a single AWS Region managed by AWS Organizations and you would like to ensure all EC2 instances in all these accounts can communicate privately, Which of the following solutions provides the capability at the CHEAPEST cost?

- Keyword: RAM

  - Answer: **Create a VPC in an account and share one or more of its subnets with the other accounts usning Resource Access Manager.**
    - AWS Resource Access Manager is a service that enables you to easily and securely share AWS resources with any AWS account or within your AWS Organization.
    - You can share AWS Transit Gatewayss, Subnets, AWS License Manager configurations. and Amazon Route 53 Resolver rules resources with RAM.
    - RAM eliminates the need to create suplicate resources in multiple accounts, reducing the operational overhead of managing those resources in every sigle account you own You can create resources centrally in a multi-account environment, and use RAM to share those resources across account's in three simple steps: create a Resource Share, specify resources, and specify accounts. RAM is available to you at no additional charge.
    - The correct solution i s to share the subnet(s) within a VPC using RAM. This will aloow all EC2 instances to be deployed in the same VPC (although from different accounts) and easily communicate with on another. 
  - **Incorect option : Create a Private Link between all the EC2 instances**
    - AWS PrivateLink simplifies the **security of data shared with cloud-based applications** by eliminating the exposure of data to the public Internet.
    - AWS PrivateLink provides private connectivity between VPCs, AWS services, and on-premises applications, securely on the Amazon network. Private Link is a distractor in this question.
    - Private Link is leveraged to create a private connection between an application that is fronted by an NLB in an account, and an Elastic Network Interface (ENI) in another account, without the need of VPC peering and allowing the connections between the two to remain within the AWS network.

---

- The engineering team at a logistics company has noticed that the Auto Scaling group (ASG) is not terminating an unhealthy Amazon EC2 instance.
    As a Solutions Architect, which of the following options would you suggest to troubleshoot the issue? (Select three)

- Keyword: Auto Scaling

Answer:
- **The health check grace period for the instance has not expired**
  - Amazon EC2 Auto Scaling doesn't terminate an instance that came into service based on EC2 status checks and ELB health checks until the health check grace period expires.
  - https://docs.aws.amazon.com/autoscaling/ec2/userguide/healthcheck.html#health-check-grace-period

- **The instance maybe in Impaired status**
  - Amazon EC2 Auto Scaling does not immediately terminate instances with an Impaired status. Instead, Amazon EC2 Auto Scaling waits a few minutes for the instance to recover. Amazon EC2 Auto Scaling might also delay or not terminate instances that fail to report data for status checks. This usually happens when there is insufficient data for the status check metrics in Amazon CloudWatch.

- **The instance has failed the ELB health check status**
  - By default, Amazon EC2 Auto Scaling doesn't use the results of ELB health checks to determine an instance's health status when the group's health check configuration is set to EC2. As a result, Amazon EC2 Auto Scaling doesn't terminate instances that fail ELB health checks. If an instance's status is OutofService on the ELB console, but the instance's status is Healthy on the Amazon EC2 Auto Scaling console, confirm that the health check type is set to ELB.

---

- Your company has a monthly big data workload, running for about 2 hours, which can be efficiently distributed across multiple servers of various sizes, with a variable number of CPUs. The solution for the workload should be able to withstand server failures.
    Which is the MOST cost-optimal solution for this workload?

- Keyword: Spot Fleet

- Answer: **Run the workload on a Spot Fleet**
  - The Spot Fleet selects the Spot Instance pools that meet your needs and launches Spot Instances to meet the target capacity for the fleet. By default, Spot Fleets are set to maintain target capacity by launching replacement instances after Spot Instances in the fleet are terminated.
  
  - A Spot Instance is an unused EC2 instance that is available for less than the On-Demand price. Spot Instances provide great cost efficiency, **but we need to select an instance type in advance.** In this case, we want to use the most cost-optimal option and leave the selection of the cheapest spot instance to a Spot Fleet request, which can be optimized with the lowestPrice strategy. So this is the correct option.

---

- Amazon EC2 Auto Scaling needs to terminate an instance from Availability Zone (AZ) us-east-1a as it has the most number of instances amongst the AZs being used currently. There are 4 instances in the AZ us-east-1a like so: 
  - Instance A has the oldest launch template
  - Instance B has the oldest launch configuration
  - Instance C has the newest launch configuration
  - Instance D is closest to the next billing hour.
- Which of the following instances would be terminated per the default termination policy?

- Keyword: Auto Scaling

- Answer: Instance B
  - Per the default termination policy, the first priority is given to any allocation strategy for On-Demand vs Spot instances. As no such information has been provided for the given use-case, so this criterion can be ignored.
  - The next priority is to consider any instance with the oldest launch template unless there is an instance that uses a launch configuration. So this rules out Instance A.
  - Next, you need to consider any instance which has the oldest launch configuration. This implies Instance B will be selected for termination and Instance C will also be ruled out as it has the newest launch configuration.
  - Instance D, which is closest to the next billing hour, is not selected as this criterion is last in the order of priority.

---

- A retail company wants to rollout and test a **blue-green deployment** for its global application in the next 48 hours. Most of the customers use mobile phones which are **prone to DNS caching**. The company has only two days left for the annual Thanksgiving sale to commence.
    As a Solutions Architect, which of the following options would you recommend to test the deployment on as many users as possible in the given time frame?

- Keyword: Global Accelerator

- Answer: **Use AWS Global Accelerator to distribute a portion of traffic to a particular deployment**
  
  - AWS Global Accelerator is a network layer service that directs traffic to optimal endpoints over the AWS global network, this improves the availability and performance of you r internet applications.
  
  - It provides two static anycast IP addresses that act as a fixed entry porint to your application endpoints in a single or multiple regions, such as your Amazon EC2 instances, in a single or in multiple regions.
  
  - Global Accelerator uses **endpoint weights to determine the proportion of traffic** that is directed to endpoints in an endpoint group, and traffic dials to control the percentage of traffic that is directed to an endpoint group (an AWS regions where your application is deployed)
  
  - While relying on the DNS service is a great option for blue/green deployments, it may not fit use-cases that require a fast and controlled transition of the traffic. Some client devices and internet resolvers cache DNS answers for long periods; this DNS feature improves the efficiency of the DNS service as it resuces the DNS traffic across the Internet, and serves as a resiliency technique by preventing authoritative name-server overloads.
  
  - The downside of this in blue/green deployments is that you don't know how long it will take before all of your users receive updated UP addresses when you update a record, change your routing preference or when thate is an application failure.
  
  - **With Global Accelerator, you can shift traffic gradually or all at once between the blue and the green environment** and vice-versa without being subject to DNS caching on client devices and internet resolvers, traffic dials an dendpoint weights changes are effective within seconds.

---

- You have a team of developers in your company, and you would like to ensure they can quickly experiment with AWS Managed Policies by attaching them to their accounts, but you would like to prevent them from doing an escalation of privileges, by granting themselves the AdministratorAccess managed policy. How should you proceed?

- Keyword: IAM

- Answer: **For each developer, define an IAM permission boundary that will restrict the managed policies they can attach to themselves**
  - AWS supports permissions boundaries for IAM entities (users or roles). A permissions boundary is an advanced feature for using a managed policy to set the maximum permissions that an identity-based policy can grant to an IAM entity. An entity's permissions boundary allows it to perform only the actions that are allowed by both its identity-based policies and its permissions boundaries. Here we have to use an IAM permission boundary. They can only be applied to roles or users, not IAM groups.
  - https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html
  - Attach an IAM policy to your developers, that prevents them from attaching the AdministratorAccess policy - This option is incorrect as the developers can remove this policy from themselves and escalate their privileges.

---

- Keyword: S3
  
**By default, an S3 object is owned by the AWS account that uploaded it. So the S3 bucket owner will not implicitly have access to the objects written by Redshift cluster**

---

- Keyword: User data
- Keyword: EC2

- An engineering team wants to examine the feasibility of the `user data` feature of Amazon EC2 for an upcoming project.
    - User Data is generally used to perform common automated configuration tasks and even run scripts after the instance starts. When you launch an instance in Amazon EC2, you can pass two types of user data - shell scripts and cloud-init directives. You can also pass this data into the launch wizard as plain text or as a file.
    - **By default, scripts entered as user data are executed with root user privileges** - Scripts entered as user data are executed as the root user, hence do not need the sudo command in the script. Any files you create will be owned by root; if you need non-root users to have file access, you should modify the permissions accordingly in the script.
    - **By default, user data runs only during the boot cycle when you first launch an instance** - By default, user data scripts and cloud-init directives run only during the boot cycle when you first launch an instance. You can update your configuration to ensure that your user data scripts and cloud-init directives run every time you restart your instance.
    - https://docs.aws.amazon.com/ko_kr/AWSEC2/latest/UserGuide/user-data.html

---

- An e-commerce application uses an **Amazon Aurora Multi-AZ deployment** for its database. While analyzing the performance metrics, the engineering team has found that the database **reads are causing high I/O and adding latency to the write requests against the database.**
    As an AWS Certified Solutions Architect Associate, what would you recommend to separate the read requests from the write requests?

- Keyword: Aurora

- Answer: **Set up a read replica and modify the application to use the appropriate endpoint**
  
  - An Amazon Aurora DB cluster consists of one or more DB instances and a cluster volume that manages the data for those DB instances. An Aurora cluster volume is a virtual database storage volume that spans multiple Availability Zones, with each Availability Zone having a copy of the DB cluster data. Two types of DB instances make up an Aurora DB cluster:
  
  - **Primary DB instance** – Supports read and write operations, and performs all of the data modifications to the cluster volume. Each Aurora DB cluster has one primary DB instance.
  
  - **Aurora Replica** – Connects to the same storage volume as the primary DB instance and supports only read operations. Each Aurora DB cluster can have up to 15 Aurora Replicas in addition to the primary DB instance. Aurora automatically fails over to an Aurora Replica in case the primary DB instance becomes unavailable. You can specify the failover priority for Aurora Replicas. Aurora Replicas can also offload read workloads from the primary DB instance.
  
  - You use the reader endpoint for read-only connections for your Aurora cluster. This endpoint uses a load-balancing mechanism to help your cluster handle a query-intensive workload. The reader endpoint is the endpoint that you supply to applications that do reporting or other read-only operations on the cluster. The reader endpoint load-balances connections to available Aurora Replicas in an Aurora DB cluster.

  - Provision another Amazon Aurora database and link it to the primary database as a read replica - **You cannot provision another Aurora database and then link it as a read-replica for the primary database**. This option is ruled out.
  - Activate read-through caching on the Amazon Aurora database - **Aurora does not have built-in support for read-through caching**, so this option just serves as a distractor. To implement caching, you will need to integrate something like ElastiCache and that would need code changes for the application.

---

- A media company has created an AWS Direct Connect connection for migrating its flagship application to the AWS Cloud. The on-premises application writes hundreds of video files into a mounted NFS file system daily. Post-migration, the company will host the application on an Amazon EC2 instance with a mounted EFS file system. Before the migration cutover, the company must build a process that will replicate the newly created on-premises video files to the EFS file system.
    Which of the following represents the MOST operationally efficient way to meet this requirement?

- Answer: Configure an AWS DataSync agent on the on-premises server that has access to the NFS file system. Transfer data over the Direct Connect connection to an AWS PrivateLink interface VPC endpoint for Amazon EFS by using a private VIF. Set up a DataSync scheduled task to send the video files to the EFS file system every 24 hours

- **You cannot use the S3 VPC endpoint to transfer data over the Direct Connect connection from the on-premises systems to S3.**

---

- A company has historically operated only in the `us-east-1` region and stores encrypted data in S3 using SSE-KMS.
- As part of enhancing its security posture as well as improving the backup and recovery architecture, the company wants to store the encrypted data in S3 that is replicated into the `us-west-1` AWS region. The security policies mandate that the data must be encrypted and decrypted using the same key in both AWS regions.
    Which of the following represents the best solution to address these requirements?

- Keyword: KMS

- Answer: Create a new S3 bucket in the `us-east-1` region with replication enabled from this new bucket into another bucket in `us-west-1` region. Enable SSE-KMS encryption on the new bucket in `us-east-1` region by using an **AWS KMS multi-region key.** Copy the existing data from the current S3 bucket in `us-east-1` region into this new S3 bucket in `us-east-1` region

- https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html

- **You cannot share an AWS KMS key to another region.**

---

- A financial services company wants a **single log processing model** for all the log files (consisting of system logs, application logs, database logs, etc) that can be processed in a serverless fashion and then durably stored for downstream analytics. The company wants to use an AWS managed service that automatically scales to match the throughput of the log data and requires no ongoing administration.
    As a solutions architect, which of the following AWS services would you recommend solving this problem?

- Answer: Kinesis Data Firehose

---

- A financial services company has deployed its flagship application on EC2 instances. Since the application handles sensitive customer data, the security team at the company wants to ensure that any third-party SSL/TLS certificates configured on EC2 instances via the AWS Certificate Manager (ACM) are renewed before their expiry date. The company has hired you as an AWS Certified Solutions Architect Associate to build a solution that notifies the security team 30 days before the certificate expiration. The solution should require the least amount of scripting and maintenance effort.

- Answer: Leverage **AWS Config managed rule** to check if any third-party SSL/TLS certificates imported into ACM are marked for expiration within 30 days. Configure the rule to trigger an SNS notification to the security team if any certificate expires within 30 days

  - **AWS Certificate Manager** is a service that lets you easily provision, manage, and deploy public and private Secure Sockets Layer/Transport Layer Security (SSL/TLS) certificates for use with AWS services and your internal connected resources. SSL/TLS certificates are used to secure network communications and establish the identity of websites over the Internet as well as resources on private networks.

  - **AWS Config provides a detailed view of the configuration of AWS resources in your AWS account.** This includes <u>how the resources are related to one another and how they were configured in the past so that you can see how the configurations and relationships change over time.</u>

  - https://docs.aws.amazon.com/config/latest/developerguide/how-does-config-work.html
  
  - AWS Config provides **AWS-managed rules**, which are predefined, customizable rules that AWS Config uses to evaluate whether your AWS resources comply with common best practices. <u>You can leverage an AWS Config managed rule to check if any ACM certificates in your account are marked for expiration within the specified number of days.</u> Certificates provided by ACM are automatically renewed. ACM does not automatically renew the certificates that you import. The rule is NON_COMPLIANT if your certificates are about to expire.
  
  - You can configure AWS Config to stream configuration changes and notifications to an Amazon SNS topic. For example, when a resource is updated, you can get a notification sent to your email, so that you can view the changes. You can also be notified when AWS Config evaluates your custom or managed rules against your resources.

  - It is certainly possible to use the days to expiry CloudWatch metric to build a CloudWatch alarm to monitor the imported ACM certificates. The alarm will, in turn, trigger a notification to the security team. But this option needs more configuration effort than directly using the AWS Config managed rule that is available off-the-shelf.

---

- You would like to migrate an AWS account from an AWS Organization A to an AWS Organization B. What are the steps do to it?

- Answer:
  - Remove the member account from the old organization.
  - Send an invite to the member account from the new Organization.
  - Accept the invite to the new organization from the member account

---

- The engineering team at an e-commerce company is working on cost optimizations for EC2 instances. The team wants to manage the workload using a mix of on-demand and spot instances across multiple instance types. They would like to create an Auto Scaling group with a mix of these instances.
    Which of the following options would allow the engineering team to provision the instances for this use-case?

- Answer: **You can only use a launch template to provision capacity across multiple instance types using both On-Demand Instances and Spot Instances to achieve the desired scale, performance, and cost.**
    - A launch template is similar to a launch configuration, in that it **specifies instance configuration information such as the ID of the Amazon Machine Image (AMI), the instance type, a key pair, security groups, and the other parameters that you use to launch EC2 instances.** Also, defining a launch template instead of a launch configuration allows you to have multiple versions of a template.
    - With launch templates, you can provision capacity across multiple instance types using both On-Demand Instances and Spot Instances to achieve the desired scale, performance, and cost. Hence this is the correct option.
    - A launch configuration is an instance configuration template that an Auto Scaling group uses to launch EC2 instances. When you create a launch configuration, you specify information for the instances such as the ID of the AMI, the instance type, a key pair, one or more security groups, and a block device mapping.
    - You cannot use a launch configuration to provision capacity across multiple instance types using both On-Demand Instances and Spot Instances. Therefore that options are incorrect.

---

- What is true about RDS Read Replicas encryption?

- Keyword: RDS

- Answer: If the master database is encrypted, the read replicas are encrypted
  - Amazon RDS Read Replicas provide enhanced performance and durability for RDS database (DB) instances. They make it easy to elastically scale out beyond the capacity constraints of a single DB instance for read-heavy database workloads. For the MySQL, MariaDB, PostgreSQL, Oracle, and SQL Server database engines, Amazon RDS creates a second DB instance using a snapshot of the source DB instance. It then uses the engines' native asynchronous replication to update the read replica whenever there is a change to the source DB instance. read replicas can be within an Availability Zone, Cross-AZ, or Cross-Region.
  - **On a database instance running with Amazon RDS encryption, data stored at rest in the underlying storage is encrypted, as are its automated backups, read replicas, and snapshots**. Therefore, this option is correct.
  - ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/d7c2173b-5fcc-479a-bdd1-0ae026e9dda8)
  - https://aws.amazon.com/rds/features/read-replicas/

---

- A social media application is hosted on an EC2 server fleet running behind an Application Load Balancer. The application traffic is fronted by a CloudFront distribution. The engineering team wants to decouple the user authentication process for the application, so that the application servers can just focus on the business logic.
    As a Solutions Architect, which of the following solutions would you recommend to the development team so that it requires minimal development effort?

- Keyword: Cognito

- Answer: Use Cognito Authentication via Cognito User Pools for your Application Load Balancer
  - Application Load Balancer can be used to securely authenticate users for accessing your applications. This enables you to offload the work of authenticating users to your load balancer so that your applications can focus on their business logic. You can use Cognito User Pools to authenticate users through well-known social IdPs, such as Amazon, Facebook, or Google, through the user pools supported by Amazon Cognito or through corporate identities, using SAML, LDAP, or Microsoft AD, through the user pools supported by Amazon Cognito. You configure user authentication by creating an authenticate action for one or more listener rules.
  - **There is no such thing as using Cognito Authentication via Cognito Identity Pools for managing user authentication for the application. **

---

- You would like to store a database password in a secure place, and enable automatic rotation of that password every 90 days. What do you recommend?

- Keyword: Secrets Manager

- Answer: "Secrets Manager"
    - AWS Secrets Manager helps you protect secrets needed to access your applications, services, and IT resources. The service enables you to easily rotate, manage, and retrieve database credentials, API keys, and other secrets throughout their lifecycle. Users and applications retrieve secrets with a call to Secrets Manager APIs, eliminating the need to hardcode sensitive information in plain text. Secrets Manager offers secret rotation with built-in integration for Amazon RDS, Amazon Redshift, and Amazon DocumentDB. The correct answer here is Secrets Manager

--- 

- A big data consulting firm needs to set up a data lake on Amazon S3 for a Health-Care client. The data lake is split in raw and refined zones. For compliance reasons, the source data needs to be kept for a minimum of 5 years. The source data arrives in the raw zone and is then processed via an AWS Glue based ETL job into the refined zone. The business analysts run ad-hoc queries only on the data in the refined zone using AWS Athena. The team is concerned about the cost of data storage in both the raw and refined zones as the data is increasing at a rate of 1TB daily in each zone. As a solutions architect, which of the following would you recommend as the MOST cost-optimal solution? (Select two)

Answer:
- Setup a lifecycle policy to transition the raw zone data into Glacier Deep Archive after 1 day of object creation
  - You can manage your objects so that they are stored cost-effectively throughout their lifecycle by configuring their Amazon S3 Lifecycle. An S3 Lifecycle configuration is a set of rules that define actions that Amazon S3 applies to a group of objects. For example, you might choose to transition objects to the S3 Standard-IA storage class 30 days after you created them, or archive objects to the S3 Glacier storage class one year after creating them.
  - For the given use-case, the raw zone consists of the source data, so it cannot be deleted due to compliance reasons. Therefore, you should use a lifecycle policy to transition the raw zone data into Glacier Deep Archive after 1 day of object creation.
  -  https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html

- Use Glue ETL job to write the transformed data in the refined zone using a compressed file format
  - AWS Glue is a fully managed extract, transform, and load (ETL) service that makes it easy for customers to prepare and load their data for analytics. You cannot transition the refined zone data into Glacier Deep Archive because it is used by the business analysts for ad-hoc querying. Therefore, the best optimization is to have the refined zone data stored in a compressed format via the Glue job. The compressed data would reduce the storage cost incurred on the data in the refined zone.

---

- A big-data consulting firm is working on a client engagement where the ETL workloads are currently handled via a Hadoop cluster deployed in the on-premises data center. The client wants to migrate their ETL workloads to AWS Cloud. The AWS Cloud solution needs to be highly available with about 50 EC2 instances per Availability Zone.
    As a solutions architect, which of the following EC2 placement groups would you recommend handling the distributed ETL workload?

- Keyword: tenancy

- Answer: Partition placement group
    - You can use placement groups to influence the placement of a group of interdependent instances to meet the needs of your workload. Depending on the type of workload, you can create a placement group using one of the following placement strategies:
    - Partition – spreads your instances across logical partitions such that groups of instances in one partition do not share the underlying hardware with groups of instances in different partitions. This strategy is typically **used by large distributed and replicated workloads, such as Hadoop, Cassandra, and Kafka. Therefore, this is the correct option for the given use-case.**
    - Spread – strictly places a small group of instances across distinct underlying hardware to reduce correlated failures. This is not suited for distributed and replicated workloads such as Hadoop.
    - Cluster – packs instances close together inside an Availability Zone. This strategy enables workloads to achieve the low-latency network performance necessary for tightly-coupled node-to-node communication that is typical of HPC applications. This is not suited for distributed and replicated workloads such as Hadoop.

---

- An IT company is looking to move its on-premises infrastructure to AWS Cloud. The company has a portfolio of applications with a few of them using server bound licenses that are valid for the next year. To utilize the licenses, the CTO wants to use dedicated hosts for a one year term and then migrate the given instances to default tenancy thereafter.
    As a solutions architect, which of the following options would you identify as CORRECT for changing the tenancy of an instance after you have launched it? (Select two)

- Keyword: tenancy

Answer:
- You can change the tenancy of an instance from dedicated to host
- You can change the tenancy of an instance from host to dedicated
**You can only change the tenancy of an instance from dedicated to host, or from host to dedicated after you've launched it.**

---

- The development team at a retail company wants to optimize the cost of EC2 instances. The team wants to move certain nightly batch jobs to spot instances. The team has hired you as a solutions architect to provide the initial guidance.

- Keyword: spot instance

Answer: 
- If a spot request is persistent, then it is opened again after your Spot Instance is interrupted
- Spot blocks are designed not to be interrupted
- When you cancel an active spot request, it does not terminate the associated instance

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/1a852d0d-2647-4609-a0df-1906a804b813)

- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html

- Spot Instances with a defined duration (also known as Spot blocks) are designed not to be interrupted and will run continuously for the duration you select. You can use a duration of 1, 2, 3, 4, 5, or 6 hours. In rare situations, Spot blocks may be interrupted due to Amazon EC2 capacity needs. Therefore, the option - "Spot blocks are designed not to be interrupted" - is correct.

- If your Spot Instance request is active and has an associated running Spot Instance, or your Spot Instance request is disabled and has an associated stopped Spot Instance, canceling the request does not terminate the instance; you must terminate the running Spot Instance manually. Moreover, to cancel a persistent Spot request and terminate its Spot Instances, you must cancel the Spot request first and then terminate the Spot Instances. Therefore, the option - "When you cancel an active spot request, it does not terminate the associated instance" - is correct.

---

- A gaming company uses Application Load Balancers (ALBs) in front of Amazon EC2 instances for different services and microservices. The architecture has now become complex with too many ALBs in multiple AWS Regions. Security updates, firewall configurations, and traffic routing logic have become complex with too many IP addresses and configurations.
    The company is looking at an easy and effective way to bring down the number of IP addresses allowed by the firewall and easily manage the entire network infrastructure. Which of these options represents an appropriate solution for this requirement?

- Keyword: Global accelerator

- Answer: Launch AWS Global Accelerator and create endpoints for all the Regions. Register the ALBs of each Region to the corresponding endpoints
  - AWS Global Accelerator is a networking service that sends your user’s traffic through Amazon Web Service’s global network infrastructure, improving your internet user performance by up to 60%. When the internet is congested, Global Accelerator’s automatic routing optimizations will help keep your packet loss, jitter, and latency consistently low.
  - With Global Accelerator, you are provided two global static customer-facing IPs to simplify traffic management. On the back end, add or remove your AWS application origins, such as Network Load Balancers, Application Load Balancers, Elastic IPs, and EC2 Instances, without making user-facing changes. To mitigate endpoint failure, Global Accelerator automatically re-routes your traffic to your nearest healthy available endpoint.

---

CloudFormation templates cannot be used to deploy the same template across AWS accounts and regions.

---

"Use AWS Config to review resource configurations to meet compliance guidelines and maintain a history of resource configuration changes"

- AWS Config is a service that enables you to assess, audit, and evaluate the configurations of your AWS resources. With Config, you can review changes in configurations and relationships between AWS resources, dive into detailed resource configuration histories, and determine your overall compliance against the configurations specified in your internal guidelines. You can use Config to answer questions such as - “What did my AWS resource look like at xyz point in time?”.

---

- An e-commerce company runs its web application on EC2 instances in an Auto Scaling group and it's configured to handle consumer orders in an SQS queue for downstream processing. The DevOps team has observed that the performance of the application goes down in case of a sudden spike in orders received.
    As a solutions architect, which of the following solutions would you recommend to address this use-case?

- Keyword: Auto Scaling

- Answer: **Use a target tracking scaling policy based on a custom Amazon SQS queue metric**
  - If you use a target tracking scaling policy based on a custom Amazon SQS queue metric, dynamic scaling can adjust to the demand curve of your application more effectively. You may use an existing CloudWatch Amazon SQS metric like ApproximateNumberOfMessagesVisible for target tracking but you could still face an issue so that the number of messages in the queue might not change proportionally to the size of the Auto Scaling group that processes messages from the queue. 
  -  The main issue with simple scaling is that after a scaling activity is started, **the policy must wait for the scaling activity or health check replacement to complete and the cooldown period to expire before responding to additional alarms.** This implies that the application would not be able to react quickly to sudden spikes in orders.

---

**You cannot use EventBridge events to directly trigger the recovery of the EC2 instance.**

---

- As part of the on-premises data center migration to AWS Cloud, a company is looking at using multiple AWS Snow Family devices to move their on-premises data.

- Which Snow Family service offers the feature of storage clustering?

- Keyword: Snow Family

- Answer: Among the AWS Snow Family services, **AWS Snowball Edge Storage Optimized device offers the feature of storage clustering.**
  - The AWS Snowball Edge Storage Optimized device is designed for data migration, edge computing, and storage purposes. It provides a large amount of on-premises storage capacity and supports clustering, which allows you to combine multiple Snowball Edge devices into a cluster for increased storage capacity and data processing capabilities.
  - By creating a storage cluster with multiple Snowball Edge Storage Optimized devices, you can aggregate their storage capacities and manage them as a single logical storage unit. This clustering feature enables you to work with larger datasets and perform distributed computing tasks using the combined resources of the clustered devices.
  - Note that AWS Snowcone and AWS Snowmobile do not offer storage clustering capabilities. AWS Snowcone is a smaller and more portable device, while AWS Snowmobile is a massive data transfer solution for extremely large datasets.

--- 

- A video conferencing application is hosted on a fleet of EC2 instances which are part of an Auto Scaling group (ASG). The ASG uses a Launch Configuration (LC1) with "dedicated" instance placement tenancy but the VPC (V1) used by the Launch Configuration LC1 has the instance tenancy set to default. Later the DevOps team creates a new Launch Configuration (LC2) with "default" instance placement tenancy but the VPC (V2) used by the Launch Configuration LC2 has the instance tenancy set to dedicated.
    Which of the following is correct regarding the instances launched via Launch Configuration LC1 and Launch Configuration LC2?

- Keyword: Auto Scaling

- Answer: The instances launched by both Launch Configuration LC1 and Launch Configuration LC2 will have dedicated instance tenancy
  - When you create a launch configuration, the default value for the instance placement tenancy is **null** and the instance tenancy is **controlled by the tenancy attribute of the VPC.**
  - If you set the Launch Configuration Tenancy to default and the VPC Tenancy is set to dedicated, then the instances have dedicated tenancy. If you set the Launch Configuration Tenancy to dedicated and the VPC Tenancy is set to default, then again the instances have dedicated tenancy.

---

- The engineering team at a social media company wants to use Amazon CloudWatch alarms to automatically recover EC2 instances if they become impaired. The team has hired you as a solutions architect to provide subject matter expertise.
    As a solutions architect, which of the following statements would you identify as CORRECT regarding this automatic recovery process? (Select two)

- Keyword: Cloud watch

- Answer: **A recovered instance is identical to the original instance, including the instance ID, private IP addresses, Elastic IP addresses, and all instance metadata**

- **If your instance has a public IPv4 address, it retains the public IPv4 address after recovery**

Terminated EC2 instances can be recovered if they are configured at the launch of instance - This is incorrect as **terminated instances cannot be recovered.**

---

- A startup has created a new web application for users to complete a risk assessment survey for COVID-19 symptoms via a self-administered questionnaire. The startup has purchased the domain covid19survey.com using Route 53. The web development team would like to create a Route 53 record so that all traffic for covid19survey.com is routed to `www.covid19survey.com`.
    As a solutions architect, which of the following is the MOST cost-effective solution that you would recommend to the web development team?

- Keyword: Route 53

- Answer: **Create an alias record for covid19survey.com that routes traffic to** `www.covid19survey.com`
    - Alias records provide a Route 53–specific extension to DNS functionality. Alias records let you route traffic to selected AWS resources, such as CloudFront distributions and Amazon S3 buckets.
    - You can create an alias record at the top node of a DNS namespace, also known as the zone apex, however, **you cannot create a CNAME record for the top node of the DNS namespace.** So, if you register the DNS name covid19survey.com, the zone apex is covid19survey.com. You can't create a CNAME record for covid19survey.com, but you can create an alias record for covid19survey.com that routes traffic to `www.covid19survey.com`.
    - Exam Alert:
      - You should also note that **Route 53 doesn't charge for alias queries to AWS resources but Route 53 does charge for CNAME queries**. Additionally, an alias record can only redirect queries to selected AWS resources such as S3 buckets, CloudFront distributions, and another record in the same Route 53 hosted zone; however a CNAME record can redirect DNS queries to any DNS record. So, you can create a CNAME record that redirects queries from app.covid19survey.com to app.covid19survey.net.

---

- **Internet gateways cannot be provisioned in private subnets of a VPC.**

---

- **Use ElastiCache to improve latency and throughput for read-heavy application workloads**
- **Use ElastiCache to improve the performance of compute-intensive workloads**

---

- A big data analytics company is working on a real-time vehicle tracking solution. The data processing workflow involves both I/O intensive and throughput intensive database workloads. The development team needs to store this real-time data in a NoSQL database hosted on an EC2 instance and needs to support up to 25,000 IOPS per volume.
    As a solutions architect, which of the following EBS volume types would you recommend for this use-case?

- Keyword: EBS

- Answer:
  - Provisioned IOPS SSD (io1)
    - Provisioned IOPS SSD (io1) is backed by solid-state drives (SSDs) and is a high-performance EBS storage option designed for critical, I/O intensive database and application workloads, as well as throughput-intensive database workloads. io1 is designed to deliver a consistent baseline performance of up to **50 IOPS/GB to a maximum of 64,000 IOPS** and **provide up to 1,000 MB/s of throughput per volume.** Therefore, the io1 volume type would be able to meet the requirement of 25,000 IOPS per volume for the given use-case.

- Incorrect options:
    - General Purpose SSD (gp2)
      - gp2 is backed by solid-state drives (SSDs) and is suitable for a broad range of transactional workloads, including dev/test environments, low-latency interactive applications, and boot volumes. It supports **max IOPS/Volume of 16,000.**
    - Cold HDD (sc1)
      - sc1 is backed by hard disk drives (HDDs). It is ideal for less frequently accessed workloads with large, cold datasets. It supports **max IOPS/Volume of 250.**
    - Throughput Optimized HDD (st1)
      - st1 is backed by hard disk drives (HDDs) and is ideal for frequently accessed, throughput-intensive workloads with large datasets and large I/O sizes, such as MapReduce, Kafka, log processing, data warehouse, and ETL workloads. It supports **max IOPS/Volume of 500.**

- https://aws.amazon.com/ebs/volume-types/

---

- A retail company uses AWS Cloud to manage its IT infrastructure. The company has set up "AWS Organizations" to manage several departments running their AWS accounts and using resources such as EC2 instances and RDS databases. The company wants to provide shared and centrally-managed VPCs to all departments using applications that need a high degree of interconnectivity.
    As a solutions architect, which of the following options would you choose to facilitate this use-case?

- Answer: Use VPC sharing to share one or more subnets with other AWS accounts belonging to the same parent organization from AWS Organizations
  - **VPC sharing (part of Resource Access Manager)** allows multiple AWS accounts to create their application resources such as EC2 instances, RDS databases, Redshift clusters, and Lambda functions, into shared and centrally-managed Amazon Virtual Private Clouds (VPCs).
  - To set this up, **the account that owns the VPC (owner) shares one or more subnets with other accounts (participants) that belong to the same organization from AWS Organizations.** After a subnet is shared, the participants can view, create, modify, and delete their application resources in the subnets shared with them. Participants cannot view, modify, or delete resources that belong to other participants or the VPC owner.
  - You can share Amazon VPCs to leverage the implicit routing within a VPC for applications that require a high degree of interconnectivity and are within the same trust boundaries. This reduces the number of VPCs that you create and manage while using separate accounts for billing and access control.

- **The owner account cannot share the VPC itself.**

---

- An AWS Organization is using Service Control Policies (SCP) for central control over the maximum available permissions for all accounts in their organization. This allows the organization to ensure that all accounts stay within the organization’s access control guidelines.
    Which of the given scenarios are correct regarding the permissions described below? (Select three)

- Keyword: SCP

Answer:
- **If a user or role has an IAM permission policy that grants access to an action that is either not allowed or explicitly denied by the applicable SCPs, the user or role can't perform that action**
- **SCPs affect all users and roles in attached accounts, including the root user**
- **SCPs do not affect service-linked role**

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html

---

- The DevOps team at an IT company has recently migrated to AWS and they are configuring security groups for their two-tier application with public web servers and private database servers. The team wants to understand the allowed configuration options for an inbound rule for a security group.
    As a solutions architect, which of the following would you identify as an **INVALID** option for setting up such a configuration?

- Keyword: Security Group

- Answer: You can use an Internet Gateway ID as the custom source for the inbound rule
  - IGW ID is can not be a set as security groups inbound rules.

![image](https://github.com/rlaisqls/TIL/assets/81006587/cb7a5608-fd31-45da-b8a7-e71dfbf4f744)
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html

---

- A healthcare company has deployed its web application on Amazon ECS container instances running behind an Application Load Balancer (ALB). The website slows down when the traffic spikes and the website availability is also reduced. The development team has configured CloudWatch alarms to receive notifications whenever there is an availability constraint so the team can scale out resources. The company wants an automated solution to respond to such events.
    Which of the following addresses the given use case?

- Answer: **Configure AWS Auto Scaling to scale out the ECS cluster when the ECS service's CPU utilization rises above a threshold**

  - You use the Amazon ECS first-run wizard to create a cluster and a service that runs behind an Elastic Load Balancing load balancer. Then you can configure a **target tracking scaling policy that scales your service automatically based on the current application load as measured by the service's CPU utilization** (from the ECS, ClusterName, and ServiceName category in CloudWatch).

  - When the average CPU utilization of your service rises above 75% (meaning that more than 75% of the CPU that is reserved for the service is being used), a scale-out alarm triggers Service Auto Scaling to add another task to your service to help out with the increased load.

  - Conversely, when the average CPU utilization of your service drops below the target utilization for a sustained period, a scale-in alarm triggers a decrease in the service's desired count to free up those cluster resources for other tasks and services.

---
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







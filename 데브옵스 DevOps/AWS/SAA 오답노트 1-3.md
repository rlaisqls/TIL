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








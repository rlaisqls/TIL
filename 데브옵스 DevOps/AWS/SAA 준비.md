참고링크

- https://www.youtube.com/watch?v=BFKs3zkl0Cw&list=PLyABYqulvUwaow4m_e2AJYlOjmWTOIjcM&pp=iAQB
- https://explore.skillbuilder.aws/learn/course/external/view/elearning/14776/exam-prep-aws-certified-solutions-architect-associate-saa-c03-english-with-practice-material


A company runs a public-facing three-tier web application in a VPC across multiple Availability Zones. Amazon EC2 instances for the application tier running in private subnets need to download software patches from the internet. However, the EC2 instances cannot be directly accessible from the internet. 
Which actions should be taken to allow the EC2 instances to download the needed patches? 

- Configure a NAT gateway in a public subnet
- Define a custom route table with a route to the NAT gateway for internet traffic and associate it with the private subnets for the application server.

A NAT gateway forwards traffic from the EC2 instances in the private subnet to the internet or other AWS services, and then sends the response back to the instances. After a NAT gateway is created, the route tables for private subnets must be updated to point internet traffic to the NAT gateway.

---

A solutions architect wants to design a solution to save costs for Amazon EC2 instances that do not need to run during a 2-week company shotdown. The applications running on the EC2 instances store data in instance mamory that must be present when the instances resume operation.
Which approach should the solutions architect recommend to shut dowm and resume the EC2 instances?

- Run the applications on EC2 instances enabled for hibernation. Hibernate the instances before the 2-week company shutdown.

Hibernate EC2 instances save the contents of instance memory to an Amazon Elastic Block Store(EBS) root volume. When the instances restart, the instance memory contents are reloaded.

---

A company plans to run a monitoring application on an Amazom EC2 instance in the VPC. Connections are made to the EC2 instance usin gthe instance's private IPv4 address. A solutions architect needs to design a solution that will allow traffic to be quickly directed to a standby EC2 instance if the application fails and becomes unreachable.

Which approach will meet these requirements?

- Attach a secondary elastic network interface to the EC2 instance configured with the private IP address. Mobe the network interface to the standby EC2 instance if the primary EC2 instance becomes unreachable.

--- 

An analytics company is planning to offer a web analytics service to its users. The service will require that the users’ webpages include a JavaScript script that makes authenticated GET requests to the company’s Amazon S3 bucket.
What must a solutions architect do to ensure that the script will successfully execute?

- Enable cross-origin resource sharing (CORS) on the S3 bucket.

---

A company uses Amazon Ec2 Reserved Instances to run its data processing workload. The nightly job typically takes 7 hours to run and must finish within a 10-hour time window. The company anticipates temporary increases in demand at the end of each month that will cause the job to run over the time limit with the capaciry of the current resources. Once started, the **processing job cannot be interrupted before completion.** The company wants to implement a solution that would provide increades resource capacity as cost-effectively as possible.

- Depoly On-Demand Instances during periods of high demand.

While Spot Instances would be the least costly option, they are not suitable for jobs that cannot be interrupted or must complete within a certain time period. On-Demand Instances would be billed for the number of seconds they are running.

--- 

A website runs a custom web application that receives a burst of traffic each day at noon. The users upload new pictures and content daily, but have been complaining of timeouts. The architecture uses Amazon EC2 Auto Scaling groups, and the application consistently takes 1 minute to initiate upon boot up before responding to user requests.

- Configure an Auto Scaling step scaling policy with an EC2 instance warmup condition.

The current configuration puts new EC2 instances into service before they are able to respond to transactions. This could also cause the instances to overscale. With a step scaling policy, you can specify the number of seconds that it takes for a newly launched instance to warm up. Until its specified warm-up time has expired, an EC2 instance is not counted toward the aggregated metrics of the Auto Scaling group.

While scaling out, the Auto Scaling logic does not consider EC2 instances that are warming up as part of the current capacity of the Auto Scaling group. Therefore, multiple alarm breaches that fall in the range of the same step adjustment result in a single scaling activity. This ensures that you do not add more instances than you need.
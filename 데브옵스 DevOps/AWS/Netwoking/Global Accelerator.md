
AWS Global Accelerator is a networking service that helps you improve the availability and performance of the applications that you offer to your global users. AWS Global Accelerator is easy to set up, configure, and manage. It provides static IP addresses that provide a fixed entry point to your applications and eliminate the complexity of managing specific IP addresses for different AWS Regions and Availability Zones. 

AWS Global Accelerator utilizes the Amazon global network, allowing you to improve the performance of your applications by lowering first byte latency (the round trip time for a packet to go from a client to your endpoint and back again) and jitter (the variation of latency), and increasing throughput (amount of data transferred in a second) as compared to the public internet.

By using AWS Global Accelerator, you can:

- Associate the static IP addresses provided by AWS Global Accelerator to regional AWS resources or endpoints, such as Network Load Balancers, Application Load Balancers, EC2 Instances, and Elastic IP addresses. The IP addresses are anycast from AWS edge locations so they provide onboarding to the AWS global network close to your users.

- Easily move endpoints between Availability Zones or AWS Regions without needing to update your DNS configuration or change client-facing applications.

- Dial traffic up or down for a specific AWS Region by configuring a traffic dial percentage for your endpoint groups. This is especially useful for testing performance and releasing updates.

- Control the proportion of traffic directed to each endpoint within an endpoint group by assigning weights across the endpoints.
 
## Benefits

- **Instant regional failover:**
  - AWS Global Accelerator automatically checks the health of your applications and routes user traffic only to healthy application endpoints. If the health status changes or you make configuration updates, AWS Global Accelerator reacts instantaneously to route your users to the next available endpoint.

- **High availability:**
  - AWS Global Accelerator has a fault-isolating design that increases the availability of your application. 
  - When you create an accelerator, you are allocated two IPv4 static IP addresses that are serviced by independent network zones. Similar to Availability Zones, these network zones are isolated units with their own physical infrastructure and serve static IP addresses from a unique IP subnet.
  - If one static IP address becomes unavailable due to IP address blocking or unreachable networks, AWS Global Accelerator provides fault tolerance to client applications by rerouting to a healthy static IP address from the other isolated network zone.

- **No variability around clients that cache IP addresses:**
  - Some client devices and internet resolvers cache DNS answers for long periods of time. So when you make a configuration update, or there’s an application failure or change in your routing preference, you don’t know how long it will take before all of your users receive updated IP addresses.
  - With AWS Global Accelerator, you don’t have to rely on the IP address caching settings of client devices. Change propagation takes a matter of seconds, which reduces your application downtime.

- **Improved performance:**
  - AWS Global Accelerator ingresses traffic from the edge location that is closest to your end clients through anycast static IP addresses. Then traffic traverses the congestion-free and redundant AWS global network, which optimizes the path to your application that is running in an AWS Region. AWS Global Accelerator chooses the optimal AWS Region based on the geography of end clients, which reduces first-byte latency and improves performance by as much as 60%.

---

Related question in SAA dump:

- A company uses Application Load Balancers (ALBs) in multiple AWS Regions. The ALBs receive inconsistent traffic that varies throughout the year. The engineering team at the company needs to allow the IP addresses of the ALBs in the on-premises firewall to enable connectivity.
    Which of the following represents the MOST scalable solution with minimal configuration changes?

- Answer: **Set up AWS Global Accelerator. Register the ALBs in different Regions to the Global Accelerator. Configure the on-premises firewall's rule to allow static IP addresses associated with the Global Accelerator**
  
  - AWS Global Accelerator is a networking service that helps you improve the availability and performance of the applications that you offer to your global users. AWS Global Accelerator is easy to set up, configure, and manage. It provides static IP addresses that provide a fixed entry point to your applications and eliminate the complexity of managing specific IP addresses for different AWS Regions and Availability Zones.
 
  - Associate the static IP addresses provided by AWS Global Accelerator to regional AWS resources or endpoints, such as Network Load Balancers, Application Load Balancers, EC2 Instances, and Elastic IP addresses. The IP addresses are anycast from AWS edge locations so they provide onboarding to the AWS global network close to your users.
 
  - Simplified and resilient traffic routing for multi-Region applications using Global Accelerator:

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

# Elastic Load Balancers (ELB)

Elastic Load Balancing automatically distributes incoming application traffic acress multiple targets, such as Amazon EC2 instances, Docker containers, IP addresses, and Lambda functions. It can handel the varying load of your application traffic in a single Availability Zone or acress multiple Availability Zones. Elastic Load Balancing offers three types of load balancers that all feature the high cailability, automatic scaling, and robust security necessary to make your applications fault tolerant.

---

- Load balancers can be internet facing or application internal.

- To route domain traffic to an ELS load balancer, use Amazon Route 53 to create an Alias record that points to your load balancer. An Alias record is preferable over a CName, but both can work.

- ELBs do not have predefined IPv4 addresses; you must resolve them with DNS instead. Your load balanver will never have its own IP by default, but you can create a static IP for a network load balancer because network LBs are for high performance purposes.

- Instances behind the ELB are reported as `InService` or `OutOfService`. When an EC2 instance behind an ELB fails a health check, the ELB stops sending traffic to that instance.

- A dual stack configuration for a load balancer means load balancing over IPv4 and IPv6

- In AWS, there are three types of LBs:
    - Application LBs
    - Network LBs
    - Classic LBs

- **Application LBs** are best suited for HTTP(S) traffic and thy balance load on layer 7 OSI. They are intelligent enough to be application aware and Application Load Balancers also support path-based routing, host-based routing and support for containerized applications. As an example, if you change your web browser's language into French, an Application LB has visibility of the metadata it receives from your browser which contains details about the language you use.
    To optimize your browsing experience, it will then route you to the French-language servers on the backend behind the LB. You can also create advanced request routing, moving traffic into specific servers based on rules that you set yourself for specific cases.
  - If you need flexible application management and TLS termination then you should use the Application Load Balancer.

- **Network LBs** are best suited for TCP traffic where performance is required and they balance load on layer 4. They are capable of managing millions of requests per second while maintaining extremely low ltency.  
  - If extreme performance and a static IP is needed for your application then you should use the Network Load Balancer.

- **Classic LBs** are the legacy ELB product and they balance either on HTTPS(S) or TCP, but not both. Even though they are the oldest LBs, they still support features like sticky sessions ans X-Forwarded-For headers.
  - If your application is built within the EC2 Classic network then you sould use the Classic Load Balancer.

- The lifecycle of a request to view a eabsite behind an ELB:
    1. The browser requests the IP address for the load balancer from DBS.
    2. DNS provides the IP.
    3. With the IP at hand, your browser then makes an HTTP request for an HTML page from the Load Balancer.
    4. AWS perimeter devices checks and verifies your request befor passing it onto the LB.
    5. The LB finds an active webserver to pass on the HTTP request.
    6. The browser returns the HTML file it requested and renders the graphical representation of it on the screen.

-  Load balancers are a regional service. They do not balance load acress diffent regions. You must provision a new ELB in each region that you operate out of.

- If your application stops responding, you'll recive a 504 error when hitting your load balancer. This means the application is having issues and the error could habe bubbled up to the load balancer from the services behind it. It does not necessatily mewn's a problem with the LB itself.

## Advanced Features

- To enable IPv6 DNS resolution, you need to create a second DNS resource record so that the ALIAS AAAA record resolves to the load balancer along with the IPv4 record.

- The X-Forwarded-For header, via the Proxy Protocol, is simply the idea for load balancers to forward the requester's IP address along with the actual request for information from the servers behind the LBs. Normally the servers behind the LBs only see that the IP sending it traffic belongs to the Load Balancer. They usually have no idea about the true origin of the request as they only know about the computer (the LB) that asks them to do something. But sometimes we may want to route the original IP to the backend servers for specific usecases and have the LB's IP address ignored. The X-Forwarded-For header makes this possible.

- Sticky Sessions bind a given user to a specific instance throughout the duration of their stay on the application or website. This means all of their interactions with the application will be directed to the same host each time. If you need local disk for your application to work, sticky sessions are great as users are guaranteed cnsistent access to the same ephemeral storage on a particular instance. The downside of sticky sessions is that, if done improperly, it can defeat the purpose of load balancing. All traffic could hypothetivally be bound to the same instance instead of being evenly distributed.

- Path Patterns create a listener with rules to forward requests based on the URL path set within those user requests. This method, known as path-based routing. ensures that traffic can be specifically directed to multiple back-end services. For example. with Path Patterns you can route general requests to one target group and requests to render images to another target group. So the URL, "www.example.com" will be forswwarded to a server that is used for general content while "www.example.com/photes" will be forwarded to another server that renders images.

## Cross Zone Load Balancing

- Cross Zone load balancing guarantees even distribution acress AZs tathe than just withing a single AZ.

- If Cross Zone load balancing is disabled, Each load balancer nede distributes requests evenly acress the registered instances in its Availability Zone only.

- Cross Zone load balancing reduces the need to maintain equivalent numbers of instances in each enabled Availability Zone, and improves your application's ability to handle the loss of one or more instances.
  
- However, it is still recommend that you maintain approximately equivalent numbers of instance in each enabled Availability Zone for higher fault tolerance.

- For environments where clients cache DNS lookups, incoming requests might favor one of the Availability Zones. Using Cross Zone load balancing, this imbalance in the request load is spread acress all available instances in the region instead.

## Security

- ELS supports SSL/TLS & HTTPS termination. Termination at load balancer is desired because decryption is resource and CPU intensive. Putting the decryption burden on the load balancer enables the EC2 instances to spend their processing power on application tests, which helps improve overall performance. 

- Elastic Load Balanvers (along with CloudFront) support Perfect Forward Secrecy. This is a feature that procides additional safeguards against the eavesdropping of encrypted data in transit through the use of a uniquely random session key. This is done by ensuring that the in-use part of an encryptoin system automatically and frequently changes the keys it uses to envrypt and decrypt information. So if this latest key is compromised at all, it will only expose a small portion of the user's recent data.

- Classic Load Balancers donot support Server Name Indication (SNI). SNI allows the server (the LB in this case) to safely host multiple TLS Certificates for multiple sites all under a single IP address (the Alias record or CName record in this case). To allow SNI, you have to use an Application Load Balancer instead or use it with a CloudFront web distribution.

---
reference
- https://aws.amazon.com/ko/blogs/aws/new-elastic-load-balancing-feature-sticky-sessions/
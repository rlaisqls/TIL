## Reverse Proxy

You can think of the reverse proxy as that old-school phone operator, you know, back when there used to be call centers and phone operators. Back then, when someone was picking up the phone, they were connected to a call center, the caller stated the name and the address of the person they wanted to call, and the phone operator connected them. A reverse proxy does a similar job by receiving user requests and then forwarding said requests to the appropriate server, as you can see in the diagram below.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/60b223c5-7550-4e37-b31e-1940f625933c)

Reverse proxies have a very simple function — they are used in front of an application or group of applications and act as the middleman between the client and the application.

As I mentioned earlier, reverse proxies route user requests to the appropriate server, assuming that you are utilizing multiple servers. So, naturally, those of you using a single server are probably wondering whether or not it makes sense for you to even implement a reverse proxy.

In fact, reverse proxies are useful even in single-server scenarios where you can take advantage of features like rate limiting, IP filtering and access control, authentication, request validation, and caching.

## Ingress Controller

In a nutshell, an ingress controller is a reverse proxy for the Kubernetes universe. It acts as a reverse proxy, routing traffic from the outside world to the correct service within a Kubernetes cluster, and allows you to configure an HTTP or HTTPS load balancer for the said cluster.

To better understand this, let’s take a step back first and look at the Ingress itself. A Kubernetes Ingress is an API object that determines how incoming traffic from the internet should reach the internal cluster Services, which then in turn send requests to groups of Pods. The Ingress itself has no power over the system — it is actually a configuration request for the ingress controller.

The ingress controller accepts traffic from outside the Kubernetes platform and load balances it to Pods running inside the platform, this way adding a layer of abstraction to traffic routing. Ingress controllers convert configurations from Ingress resources into routing rules recognized and implemented by reverse proxies.

Ingress controllers are used to expose multiple services from within your Kubernetes cluster to the outside world, using a single endpoint — for example, a DNS name or IP address —  to access them. Specifically, ingress controllers are used to:

- Expose multiple services under a single DNS name
- Implement path-based routing, where different URLs map to different services
- Implement host-based routing, where different hostnames map to different services
- Implement basic authentication or other access control methods for your applications
- Implement rate limiting for your applications
- Offload SSL/TLS termination from your applications to the ingress controller

##  API gateway

Deployed at the edge of your infrastructure, an API gateway acts as a single entry point that routes client API requests to your backend microservices. Essentially, an API gateway is a reverse proxy handling incoming user requests and, although it includes many of the functionalities commonly found in reverse proxies, there is a key difference between the two.  

Contrary to reverse proxies, API gateways have the ability to address cross-cutting, or system-wide, concerns. Concerns refer to the parts of your system's architecture that have been branched based on its functionality. Cross-cutting concerns are concerns that are shared among a number of different system components or APIs and include, among others, configuration management, security, auditing, exception management, and logging.

API gateways are commonly used in architectures where you need to expose multiple microservices or serverless functions to the outside world through a set of APIs, and they handle a number of tasks. On top of the functions we already saw as part of a typical reverse proxy, API gateways can handle:

- **Load balancing**: Distributing incoming traffic across multiple servers to improve performance and availability.
- **Rate limiting**: Matching the flow of traffic to your infrastructure’s capacity.
- **Access control**: Adding an extra layer of security by authenticating incoming connections before they reach the web servers, and by hiding the internal IP addresses and network structure of the web servers from external clients.
- **SSL/TLS termination**: Offloading the task of handling SSL/TLS connections from the web servers to the reverse proxy, allowing the web servers to focus on handling requests.
- **Caching**: Improving performance by caching frequently-requested content closer to the client.
- **Request/response transformation**: Modifying incoming requests or outgoing responses to conform to specific requirements, such as adding or removing headers, compressing/decompressing, and encrypting/decrypting content.
- **Logging and monitoring**: Collecting API usage and performance data.
  
API Gateways also come with a few extra handy functionalities, namely service discovery, circuit breaker, and request aggregation.

## Reverse proxy vs. ingress controller vs. API gateway

- An ingress controller does the same job as a reverse proxy or an API gateway when it comes to handling incoming traffic and routing it to the appropriate server/Service. However, the ingress controller operates at a different level of the network stack.

- Ingress controller operates in a Kubernetes environment. In that sense, the ingress controller is a specific type of reverse proxy designed to operate within Kubernetes clusters.

- The ingress controller sits at the edge of the cluster listening for incoming traffic, and then routes it to the appropriate Kubernetes Service within the cluster, based on the rules defined in the Ingress resource, as we saw earlier.

- The API gateway sits at the edge of your infrastructure. API gateway is a specific type of reverse proxy, too — a reverse proxy on "steroids” if you will — while the service mesh is a network proxy tailored for microservices

## Usecase

- You can set up a reverse proxy in front of your ingress controller and API gateway to handle SSL/TLS termination, caching, load balancing, and request/response transformation.
 
- You can set up an ingress controller to handle the routing of incoming traffic from your reverse proxy to the appropriate Kubernetes Service within your cluster.
  
- You can set up an API gateway to handle authentication, rate limiting, and request/response transformation for your microservices within the cluster.
  
- You can set up a service mesh to handle internal communication (i.e. load balancing, traffic shaping, and service discovery) between your microservices.

---
reference
- https://projectcontour.io/docs/v1.18.0/config/fundamentals/
- https://traefik.io/blog/reverse-proxy-vs-ingress-controller-vs-api-gateway/
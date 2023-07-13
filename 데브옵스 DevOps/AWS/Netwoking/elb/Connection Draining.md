# Connection Draining

Connection Draining is a feature provided by Elastic Load Balancer that allows in-flight requests to complete before terminating an unhealthy instance.

When an instance becomes unhealthy, the ELB stops sending new requests to that instance but allows existing requests to complete within a specified timeout period. This helps prevent the loss of in-flight requests and provides a smooth transition when instances are taken out of service.

By enabling Connection Draining on your ELB, you ensure that requests in progress are given time to complete before terminating an unhealthy instance. This helps maintain the availability and reliability of your flagship application by minimizing disruptions caused by instances going out of service.

---
reference
- https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html
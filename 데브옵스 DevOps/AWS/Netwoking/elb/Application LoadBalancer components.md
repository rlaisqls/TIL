
A load balancer serves as the single point of contact for clients. The load balancer distributes incoming application traffic across multiple targets, such as EC2 instances, in multiple Availability Zones. This increases the availability of your application. You add one or more listeners to your load balancer.

**A listener** checks for connection requests from clients, using the protocol and port that you configure. The rules that you define for a listener determine how the load balancer routes requests to its registered targets. Each rule consists of a priority, one or more actions, and one or more conditions. When the conditions for a rule are met, then its actions are performed. You must define a default rule for each listener, and you can optionally define additional rules.

**Each target group** routes requests to one or more registered targets, such as EC2 instances, using the protocol and port number that you specify. You can register a target with multiple target groups. You can configure health checks on a per target group basis. Health checks are performed on all targets registered to a target group that is specified in a listener rule for your load balancer.

The following diagram illustrates the basic components. Notice that each listener contains a default rule, and one listener contains another rule that routes requests to a different target group. One target is registered with two target groups.

![image](https://github.com/rlaisqls/TIL/assets/81006587/5c10632a-359b-4493-a8d3-7e2515e1b2d0)

---

### Why can't ALB have a fixed IP allocation

When AWS creates ALB, EC2 is created in the corresponding subnet. The EC2 is managed by AWS, so we can't recognize it, but ALB's load balancing works internally in EC2.

> The ENI bound to EC2, which cannot be seen, can be found in the ENI menu.

Depending on the load on ALB, ALBEC2 automatically scales in and out. Fixed IP allocation is not possible for scaling load balancers for flexible traffic processing.

---
reference
- https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html
- https://repost.aws/ko/knowledge-center/alb-static-ip
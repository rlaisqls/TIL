
AWS Load Balancer Controller is a controller to help manage Elastic Load Balancers for a Kubernetes cluster.

- It satisfies Kubernetes Ingress resources by provisioning Application Load Balancers.
- It satisfies Kubernetes Service resources by provisioning Network Load Balancers.

This project was formerly known as "AWS ALB Ingress Controller", we rebranded it to be "AWS Load Balancer Controller".

## Design

The following diagram details the AWS components this controller creates. It also demonstrates the route ingress traffic takes from the ALB to the Kubernetes cluster.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/021fb689-acb2-42ac-aa67-b083f9f19fe6)

> The controller manages the configurations of the resources it creates, and we do not recommend out-of-band modifications to these resources because the controller may revert the manual changes during reconciliation. We recommend to use configuration options provided as best practice, such as ingress and service annotations, controller command line flags and IngressClassParams.

## Ingress Creation

This section describes each step (circle) above. This example demonstrates satisfying 1 ingress resource.

1. The controller watches for ingress events from the API server. When it finds ingress resources that satisfy its requirements, it begins the creation of AWS resources.

2. An ALB (ELBv2) is created in AWS for the new ingress resource. This ALB can be internet-facing or internal. You can also specify the subnets it's created in using annotations.

3. Target Groups are created in AWS for each unique Kubernetes service described in the ingress resource.

4. Listeners are created for every port detailed in your ingress resource annotations. When no port is specified, sensible defaults (80 or 443) are used. Certificates may also be attached via annotations.

5. Rules are created for each path specified in your ingress resource. This ensures traffic to a specific path is routed to the correct Kubernetes Service.

Along with the above, the controller also...

- deletes AWS components when ingress resources are removed from k8s.
- modifies AWS components when ingress resources change in k8s.
- assembles a list of existing ingress-related AWS components on start-up, allowing you to recover if the controller were to be restarted.

## Ingress Traffic

AWS Load Balancer controller supports two traffic modes:

- Instance mode
- IP mode

By default, Instance mode is used, users can explicitly select the mode via alb.ingress.kubernetes.io/target-type annotation.

### Instance mode

Ingress traffic starts at the ALB and reaches the Kubernetes nodes through each service's NodePort. This means that services referenced from ingress resources must be exposed by type:NodePort in order to be reached by the ALB.

### IP mode

Ingress traffic starts at the ALB and reaches the Kubernetes pods directly. CNIs must support directly accessible POD ip via secondary IP addresses on ENI.

## Status Code

### HTTP 408: Request timeout

The client did not send data before the idle timeout period expired. Sending a TCP keep-alive does not prevent this timeout. Send at least 1 byte of data before each idle timeout period elapses. Increase the length of the idle timeout period as needed.
HTTP 413: Payload too large

Possible causes:

    The target is a Lambda function and the request body exceeds 1 MB.

    The request header exceeded 16 K per request line, 16 K per single header, or 64 K for the entire request header.

### HTTP 414: URI too long

The request URL or query string parameters are too large.

### HTTP 460

The load balancer received a request from a client, but the client closed the connection with the load balancer before the idle timeout period elapsed.

Check whether the client timeout period is greater than the idle timeout period for the load balancer. Ensure that your target provides a response to the client before the client timeout period elapses, or increase the client timeout period to match the load balancer idle timeout, if the client supports this.

### HTTP 463

The load balancer received an X-Forwarded-For request header with too many IP addresses. The upper limit for IP addresses is 30.

### HTTP 464

The load balancer received an incoming request protocol that is incompatible with the version config of the target group protocol.

Possible causes:

    The request protocol is an HTTP/1.1, while the target group protocol version is a gRPC or HTTP/2.

    The request protocol is a gRPC, while the target group protocol version is an HTTP/1.1.

    The request protocol is an HTTP/2 and the request is not POST, while target group protocol version is a gRPC.

---
reference

- <https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.1/guide/service/nlb_ip_mode/>
- <https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.5/>
- <https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html#http-460-issues>


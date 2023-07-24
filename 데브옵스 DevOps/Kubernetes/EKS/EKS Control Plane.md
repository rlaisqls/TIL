# EKS Control Plane

## EKS Control Plane Communication

EKS has two ways to control access to the cluster endpoint. Endpoint access control lets you choose whether the endpoint can be reached from the public internet or only through your VPC. You can turn on the public endpoint (which is the default), the private endpoint, or both at once.

The configuration of the cluster API endpoint determines the path that nodes take to communicate to the control plane. Note that these endpoint settings can be changed at any time through the EKS console or API.

### Public Endpoint

This is the default behavior for new Amazon EKS clusters. When only the public endpoint for the cluster is enabled, Kubernetes API requests that originate from within your cluster's VPC (such as worker node to control plane communication) leave the VPC, but not Amazon's network. In order for nodes to connect to the control plan, they must have a public IP address and a route to an internet gateway or a route to a NAT gateway or a route to a NAT gateway where they can use the public IP address of the NAI gateway.

### Public and private Endpoint

When both the public and private endpoints are enabled, Kubernetes API requests from within the VPC communicate to the control plane via the X-ENIs with in your VPC. Your cluster API server is accessible from the internet.

### Private Endpoint

There is no public access to your API server from the internet when only private endpoint is enabled. All traffic to your cluster API server must come from within your cluster's VPC or a connected network. The nodes communicate to API server via X-ENIs within your VPC. Note that cluster management tools must have access to the private endpoint. Learn more about [how to connect to a private Amazon EKS cluster endpoint from outside the Amazon VPC.](https://aws.amazon.com/premiumsupport/knowledge-center/eks-private-cluster-endpoint-vpc/)

Note that the **cluster's API server endpoint is resolved by public DNS servers to a private IP address from the VPC**. In the past, the endpoint could only be resolved from within the VPC.

---
reference
- https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html
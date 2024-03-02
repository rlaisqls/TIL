
EKS is a managed Kubernetes service that mekes it easy for you to run Kubernetes on AWS without needing to install, operate, and main your own Kubernetes control plane or worker nodes. It runs ipstream Kubernetes and is certified Kubernetes conformant.

EKS automatically manages the availability and scalability of the Kubernetes control plane nodes, and it automatically replaces unhealthy control plane nodes.

## EKS Architecture

EKS architecture is designed to eliminate any single points of failure that may compromise the availabilty and durability of the Kubernetes control plane.

The Kubernetes control plane managed by EKS **runs inside an EKS managed VPC**. The EKS control plane conprises the Kubernetes API server nodes, etcd cluster. Kubernetes API server nodes that run components like the API server, scheduler, ans `kube-controller-manager` run in an auto-scailing group. EKS runs a minimum of two API server nodes in distinct Availability Zones (AZs) within in AWS region. Likewise, for durability, the etcd server nodes also run in an auto-scailing group that spans three AZs.

EKS runs a NAT Gateway in each AZ, and API servers and etcd servers run in a private subnet. This architecture ensures that an event in a single AZ doesn't affect the EKS cluster's availability.

When you create a new cluster, Amazon EKS creates a highly-avaiilable endpoint for the managed Kubernetes API server that you use to communicate with your cluster (using tools like `kubectl`). The managed endpoint uses NLB to load balance Kubernetes API servers. EKS also provisions two [ENI](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html)s in different AZs to facilitate communication to your worker nodes.

![image](https://github.com/rlaisqls/TIL/assets/81006587/2fd7669f-69a6-49bb-88d5-a2fa9eabd544)

You can configure whether your Kubernetes cluster's API server is reachable from the publiv internet (using public endpoint) or through your VPC (using the EKS-managed ENIs) or both.

Whether users and worker nodes connect to the API server using the public endpoint or the EKS-managed ENI, there are redundant paths for connection.

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
- https://aws.github.io/aws-eks-best-practices/reliability/docs/controlplane/
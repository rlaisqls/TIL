It is critical to understand Kubernetes networking to operate you cluster and applications efficiently. Pod networkin, also called the cluster networking, is the center of Kubernetes networkin. Kubernetes supports [Container Network Interface](https://github.com/containernetworking/cni)(CNI) plugins for cluster networking.

Amazon EKS officially supports VPC CNI plugin to implement Kubernetes Pod networking. The VPC CNI provides native integration with AWS VPC and works in underlay mode. In underlay mode, Pods and hosts are located at the same network layer and share the network namespace. The IP address of the Pod is consistent from the cluster and VPC perspective.

Let's more know about Amazon VPC CNI in the context of Kubernetes cluster networking. The VPC CNI is the default networking plugin supported by EKS, so it is important to fully understand that. Check the[ EKS Alternate CNI](https://docs.aws.amazon.com/eks/latest/userguide/alternate-cni-plugins.html) documentation for a list of partners and resources for managing alternate CNIs effectively.

### [Kubernetes Networking Model](../Kubernetes Networking Model.md)

Kubernetes sets the following requirements on cluster networking:
- Pords scheduled on the same node must be able to communicate with other Pods without using NAT.
- All system daemons (background processes, for example, [kublet](https://kubernetes.io/docs/concepts/overview/components/)) running on a particular node can communicate with the Pods runnign on the same node.
- Pods that use the [host network](https://docs.docker.com/network/host/) must be able to contact all other pods on all othe nodes without using NAT.

See the [Kubernetes network model](https://kubernetes.io/docs/concepts/services-networking/#the-kubernetes-network-model) for details on what k9s expect from compatible networking implementations. The following figure illustrates the relationship between Pod network namespaces and the host network namespace.

![image](https://github.com/rlaisqls/TIL/assets/81006587/e83e30d5-c00c-4c90-88a6-873244274a70)

### Container Networking Interface (CNI)

Kubernetes supports CNI specifications and plugins to implement Kubernetes network model. A CNI consists of a specification and libraries for writing plugins to configure network interfaces in containers, along with a number of supported plugins. CNI concerns itself only with network connectivity of containers and removing allocated resources when the container is deleted.

- The CNI plugin is enabled by passing kubelet the `--network-plugin=cni` command-line option.
- Kubelet reads a file from `--cni-conf-dir` (default /etc/cni/net.d) and uses the CNI configuration from that file to set up each Pod’s network.
- The CNI configuration file must match the CNI specification (minimum v0.4.0) and any required CNI plugins referenced by the configuration must be present in the `--cni-bin-dir` directory (default /opt/cni/bin).
 
If there are multiple CNI configuration files in the directory, the kubelet uses the configuration file that comes first by name in lexicographic order.

## Amazon Virtual Private Cloud(VPC) CNI

The AWS-provided VPC CNI is the default networking add-on for EKS clusters. VPC CNI add-on is installed by default when you provision EKS clusters.

VPC CNI runs on Kubernetes worker nodes.

The VPC CNI provides configuration options for pre-allocation of ENIs and IP addresses for fast Pod startup times. Refer to [Amazon VPC CNI](Amazon VPC CNI.md) for recommended plugin management best practices. 


### secondary IP mode

Amazon VPC CNI alloacates **a warm pool of ENIs and secondary IP addresses from the subnet attached to the node's primary ENI**. This mode of VPC CNI is called the ["Secondary IP mode"](https://aws.github.io/aws-eks-best-practices/networking/vpc-cni/). The number of IP addresses and hence the number of Pods (Pod density) is defined by the number of ENIs and the IP address per ENI (limits) as defined by the instance type. The secondary mode is the default and workd well for small clusters with smaller instance types.  Please consider using [prefix mode](https://aws.github.io/aws-eks-best-practices/networking/prefix-mode/index_linux/) if you are experiencing pod density challenges. You can also increase the available IP addresses on node for Pods by assigning prefixes to ENIs.

### security groups for Pods

Amazon VPC CNI natively integrates with AWS VPC and allows usets to apply existing AWS VPC networking and security best practices for building Kubernetes clusters. This includes the ability to use VPC flow logs, VPC routing policis, and security groups for network traffic isolation. By default the Amazon VPC CNI applies security group associated with the primary ENI on the node to the Pods. Consider enabling security groups for Pods when you would like to assign different network rules for Pod.

### custom networking

By default, VPC CNI assigns IP addresses to Pods from the subnet assigned to the primary ENI of a node. It is common **to experience a shortage of IPv4 addresses when running large clusters** with thousands of workloads. AWS VPC allows you to extend available IPs by [assigning a secondary CIDRs](https://docs.aws.amazon.com/vpc/latest/userguide/configure-your-vpc.html#add-cidr-block-restrictions) to work around exhaustion of IPv4 CIDR blocks. AWS VPC CIN is called [custom networking](https://aws.github.io/aws-eks-best-practices/networking/custom-networking/). You might consider using custom networking to use `100.64.0.0/10` and `198.19.0.0/16` CIDRs (CG-NAT) with EKS. This effectively allows you to create an environment where Pods no longer consume any RFC1918 UP addresses from you VPC.

Custom networking is one option to address the IPv4 address achaustion problem, but it requires operational overhead. AWS recommend IPv6 clusters over custom networking to resolve this problem. Specifically, aws recommend migrating to [IPv6 clusters](https://aws.github.io/aws-eks-best-practices/networking/ipv6/) if you have completely exhausted all available IPv4 address space for your VPC. Evaluate you organization's plans to support IPv5, and consider if investing in IPv6 may have more long-term value.

## VPC and Subnet

Amazon EKS recommends you specify subnets in at least two availability zones when you craete a cluster. Amazon VPC CNI allocates IP addresses to Pods from the node subnets. We strongly recommend checking the subnets for available IP addresses. 

### EKS Cluster Architecture

An EKS cluster consists of two VPCs:

- An AWS-managed VPC that hosts the Kubernetes control plane. This VPC does not appear in the customer account.
- A customer-managed VPC that hosts the Kubernetes nodes. This is where containers run, as well as other customer-managed AWS infrastructure such as load balancers used by the cluster. This VPC appears in the customer account. You need to create customer-managed VPC prior creating a cluster. The eksctl creates a VPC if you do not privide one.

The nodes in the customer VPC need the ability to connect to the managed API server endpoint in the AWS VPC. This allows the nodes to register with the Kubernetes control plane and recieve requests to run application Pods.

The nodes connect to the EKS control plane through (a) an EKS public endpoint or (b) a Cross-Account elastic network interfaces (X-ENI) managed by EKS. When a cluster is created, you need to specify at least two VPC subnets. EKS places a X-ENI in each subnet specified during cluster create (also called cluster subnets). The Kubernetes API server uses these Cross-Account ENIs to cmmunicate with nodes deployed on the customer-manages cluster VPC subnets. 

![image](https://github.com/rlaisqls/TIL/assets/81006587/e85fe0ee-03c5-4223-bea8-e07115883a03)

### VPC configurations

**Amazon VPC supports IPv4 and IPv6 addressing.** Amazon EKS supports IPv4 by default. A VPC must have an IPv4 CIDR block associated with it. You can optionally associate multiple IPv4 CIDR blocks and multiple IPv6 CIDR blocks to your VPC. When you create a VPC, you must specify an IPv4 CIDR block for the VPC from the private IPv4 address ranges as specified in RFC 1918. The allowed block size is between a `/16` prefix (65,536 IP addresses) and `/28` prefix (16 IP addresses).

Amazon EKS **recommends you use at least two subnets that are in different Availability Zones during cluster creation.** The subnets you pass in during cluster creation are known as cluster subnets. When you create a cluster, Amazon EKS creates up to 4 cross account (x-account or x-ENIs) ENIs in the subnets that you specify. The x-ENIs are always deployed and are used for cluster administration traffic such as log delivery, exec, and proxy. 

Kubernetes worker nodes can run in the sluster subnets, but it is not recommended. You can create new subnets dedicated to run nodes and any Kubernetes resources. Nodes can run in either a public or a private subnet. Whether a subnet is public or private refers to whether traffic within the subnet is routed through an igw. 

---

reference
- https://github.com/aws/aws-eks-best-practices
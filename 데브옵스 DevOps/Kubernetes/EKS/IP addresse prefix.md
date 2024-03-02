
Each Amazon EC2 instance supports a maximum number of elastic network interfaces and a maximum number of IP addresses that can be assigned to each network interface. Each node requires one IP address for each network interface. All other available IP addresses can be assigned to Pods. Each Pod requires its own IP address. As a result, you might have nodes that have available compute and memory resources, but can't accommodate additional Pods because the node has run out of IP addresses to assign to Pods.

We can significantly increase the number of IP addresses that nodes can assign to Pods by assigning **IP prefixes**, rather than assigning individual secondary IP addresses to your nodes. Each prefix includes several IP addresses.

If you don't configure your cluster for IP prefix assignment, your cluster must make more Amazon EC2 application programming interface (API) calls to configure network interfaces and IP addresses necessary for Pod connectivity.

As clusters grow to larger sizes, the frequency of these API calls can lead to longer Pod and instance launch times. This results in scaling delays to meet the demand of large and spiky workloads, and adds cost and management overhead because you need to provision additional clusters and VPCs to meet scaling requirements. For more information, see [Kubernetes Scalability threshold](https://github.com/kubernetes/community/blob/master/sig-scalability/configs-and-limits/thresholds.md)s on GitHub.

## Considerations

- Each Amazon EC2 instance type supports a maximum number of Pods. If your managed node group consists of multiple instance types, the smallest number of maximum Pods for an instance in the cluster is applied to all nodes in the cluster.

- By default, the maximum number of Pods that you can run on a node is 110, but you can change that number. If you change the number and have an existing managed node group, the next AMI or launch template update of your node group results in new nodes coming up with the changed value.

- When transitioning from assigning IP addresses to assigning IP prefixes, we recommend that you create new node groups to increase the number of available IP addresses, rather than doing a rolling replacement of existing nodes. Running Pods on a node that has both IP addresses and prefixes assigned can lead to inconsistency in the advertised IP address capacity, impacting the future workloads on the node. For the recommended way of performing the transition, see Replace all nodes during migration from [Secondary IP mode to Prefix Delegation mode or vice versa](https://github.com/aws/aws-eks-best-practices/blob/master/content/networking/prefix-mode/index_windows.md#replace-all-nodes-during-migration-from-secondary-ip-mode-to-prefix-delegation-mode-or-vice-versa) in the Amazon EKS best practices guide.

- For clusters with Linux nodes.
  - Once you configure the add-on to assign prefixes to network interfaces, you can't downgrade your Amazon VPC CNI plugin for Kubernetes add-on to a version lower than `1.9.0` (or `1.10.1`) without removing all nodes in all node groups in your cluster.
  - If you're also using security groups for Pods, with `POD_SECURITY_GROUP_ENFORCING_MODE=standard` and AWS_VPC_K8S_CNI_EXTERNALSNAT=false, when your Pods communicate with endpoints outside of your VPC, the node's security groups are used, rather than any security groups you've assigned to your Pods.
  - If you're also using security groups for Pods, with `POD_SECURITY_GROUP_ENFORCING_MODE=strict`, when your Pods communicate with endpoints outside of your VPC, the Pod's security groups are used.

## Prerequisites

- An existing cluster. To deploy one, see Creating an Amazon EKS cluster.

- The subnets that your Amazon EKS nodes are in must have sufficient contiguous `/28` (for IPv4 clusters) or /80 (for IPv6 clusters) Classless Inter-Domain Routing (CIDR) blocks. You can only have Linux nodes in an IPv6 cluster. Using IP prefixes can fail if IP addresses are scattered throughout the subnet CIDR. We recommend that following:

- Using a subnet CIDR reservation so that even if any IP addresses within the reserved range are still in use, upon their release, the IP addresses aren't reassigned. This ensures that prefixes are available for allocation without segmentation.

- Use new subnets that are specifically used for running the workloads that IP prefixes are assigned to. Both Windows and Linux workloads can run in the same subnet when assigning IP prefixes.

- To assign IP prefixes to your nodes, your nodes must be AWS Nitro-based. Instances that aren't Nitro-based continue to allocate individual secondary IP addresses, but have a significantly lower number of IP addresses to assign to Pods than Nitro-based instances do.

- For clusters with Linux nodes – If your cluster is configured for the IPv4 family, you must have version 1.9.0 or later of the Amazon VPC CNI plugin for Kubernetes add-on installed. You can check your current version with the following command.
  
```bash
kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2
```

- If your cluster is configured for the IPv6 family, you must have version 1.10.1 of the add-on installed. If your plugin version is earlier than the required versions, you must update it. For more information, see the updating sections of Working with the Amazon VPC CNI plugin for Kubernetes Amazon EKS add-on.

## To increase the amount of available IP addresses for your Amazon EC2 nodes

Configure your cluster to assign IP address prefixes to nodes. Complete the procedure on the tab that matches your node's operating system.

### for Linux

1. Enable the parameter to assign prefixes to network interfaces for the Amazon VPC CNI DaemonSet. When you deploy a `1.21` or later cluster, version `1.10.1` or later of the Amazon VPC CNI plugin for Kubernetes add-on is deployed with it. If you created the cluster with the IPv6 family, this setting was set to true by default. If you created the cluster with the IPv4 family, this setting was set to false by default.
    ```bash
    kubectl set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true
    ```
    - Even if your subnet has available IP addresses, if the subnet does not have any contiguous `/28` blocks available, you will see the following error in the Amazon VPC CNI plugin for Kubernetes logs.
    - `InsufficientCidrBlocks: The specified subnet does not have enough free cidr blocks to satisfy the request`
    - This can happen due to fragmentation of existing secondary IP addresses spread out across a subnet. To resolve this error, either create a new subnet and launch Pods there, or use an Amazon EC2 subnet CIDR reservation to reserve space within a subnet for use with prefix assignment. For more information, see [Subnet CIDR reservations](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-cidr-reservation.html) in the Amazon VPC User Guide.

- If you plan to deploy a managed node group without a launch template, or with a launch template that you haven't specified an AMI ID in, and you're using a version of the Amazon VPC CNI plugin for Kubernetes at or later than the versions listed in the prerequisites, then skip to the next step. Managed node groups automatically calculates the maximum number of Pods for you.
    If you're deploying a self-managed node group or a managed node group with a launch template that you have specified an AMI ID in, then you must determine the Amazon EKS recommend number of maximum Pods for your nodes. Follow the instructions in Amazon EKS recommended maximum Pods for each Amazon EC2 instance type, adding `--cni-prefix-delegation-enabled` to step 3. Note the output for use in a later step.

- Create one of theh following types of node groups with at least one Amazon EC2
- 


---
reference 
- https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
- [Amazon VPC CNI](./Amazon VPC CNI.md)
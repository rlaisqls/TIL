# Amazon VPC CNI

- The AWS-provided VPC CNI is the default networking add-on that runs on Kubernetes worker nodes for EKS clusters. VPC CNI add-on is installed by default when you provision EKS clusters.

- The VPC CNI provides configuration options for pre-allocation of ENIs and IP addresses for fast Pod startup times.\

### VPC CNI components

Amazon VPC CNI has two components:

- **CNI Binary**: which will setup Pod network to enable Pod-to-Pod communication. The CNI binary runs on a node root file system and is invoked by the kubelet when a new Pod gets added to, or an existing Pod removed from the node.
- **ipamd**: a long-running node-local IP Address Management (IPAM) daemon and is responsible for:
  - managing ENIs on a node, and
  - maintaining a warm-pool of available IP addresses or prefix

When an instance is created, EC2 creates and attaches a primary ENI associated with a primary subnet. The primary subnet may be public or private. The Pods that run in hostNetwork mode use the primary IP address assigned to the node primary ENI and share the same network namespace as the host.

**The CNI plugin manages ENI on the node.** When a node is provisioned, the CNI plugin automatically allocates a pool of slots (IPs or Prefix's) from the node's subnet to the primary ENI. This pool is known as the _warm pool_, and its size id determined by the node's instance type.

---

Depending on CNI settings, a slot may be an <u>IP address or a prefix</u>. When a slot on an ENI has been assigned, the CNI may attach additional ENIs with warm pool of slots to the nodes. 

These additional ENIs are called **Secondary ENIs**. Each ENI can only support a certain number of slots, based oninstance type. The CNI attaches more ENIs to instances based on the number of slots needed, which usually corresponds to the number of Pods, This process continues until the node can no longer support additinal ENI.

The CNI also preallocates "warm" ENIs and slots for faster Pord startup. Note each instance type has a maximum number of ENIs that may be attached. This one constraint on Pod densiry (number of Pods per node), in addition to compute resources.

![image](https://github.com/rlaisqls/TIL/assets/81006587/a98b50c6-e189-4b4c-8136-ac0a20cb58fe)

The maximum number of network interfaces, and the maximum number of slots of slots that you can use varies by the type of EC2 instance. Since each Pod consumes an IP address on a slot, the number of Pord you can run on a particular EC2 Instance depends on how many ENIs can be attached to it and how many slots each ENI supports.

AWS suggests setting the maximum Pods per EKS user guide to avoid exhaustion of the instance’s CPU and memory resources. Pods using `hostNetwork` are excluded from this calculation. You may consider using a script called [max-pod-calculator.sh](https://github.com/awslabs/amazon-eks-ami/blob/master/files/max-pods-calculator.sh) to calculate EKS’s recommended maximum Pods for a given instance type.

## Secondary IP mode

Secondary IP mode is the default mode for VPC CNI. This guide provides a generic overview of VPC CNI behavior when Secondary IP mode is enabled. The functionality of ipamd (allocation of IP addresses) may vary depending on the configuration settings for VPC CNI, such as [Prefix Mode](https://aws.github.io/aws-eks-best-practices/networking/prefix-mode/index_linux/), [Security Groups Per Pod](https://aws.github.io/aws-eks-best-practices/networking/sgpp/), and [Custom Networking.](https://aws.github.io/aws-eks-best-practices/networking/custom-networking/)

The Amazon VPC CNI is deployed as a Kubernetes Daemonset named aws-node on worker nodes. When a worker node is provisioned, it has a default ENI, called the primary ENI, attached to it.

The CNI allocates a warm pool of ENIs and secondary IP addresses from the subnet attached to the node's primary ENI. By default, ipamd attempts to allocate an additional ENI to the node. The IPAMD allocates additional ENI when a single Pod is scheduled and assigned a secondary IP address from the primay ENI. This "warm" ENI enables faster Pod networking. As the pool of secondary IP addresses runs out, the CNI adds another ENI to assign more.

The number of ENIs and IP addreses in a pool are configured through environment variables called `WARM_ENI_TARGET`, `WARM_IP_TARGET`, `MINIMUM_IP_TARGET`. The `aws-node` Daemonset will periodically check that a sufficient number of ENIs are attached. A sufficient number of ENIs are attached when all pf the `WARM_ENI_TARGET`, or `WARM_IP_TARGET` and `MINIMUM_IP_TARGET` conditions are met. If there are insufficient ENIs attached, the CNI will make an API call to EC2 to attach more until `MAX_ENI` limit is reached.

- `WARM_ENI_TARGET` - Integer, Values > 0 indicate requirement Enabled
  - The number of Warm ENIs to be maintained. An ENI is "warm" when it is attached as a secondary ENI to a node, but it is not in use by any Pod. More specifically, no IP addresses of the ENI have been associated with a Pod.
  
  - Example: Consider an instance with 2 ENIs, each ENI supporting 5 IP addresses. `WARM_ENI_TARGET` is set to 1. If exactly 5 addresses are associated with the instance, the CNI maintains 2 ENIs attached to the instance. The first ENI is in use, and all 5 possible IP addresses of this ENI are used.
    The second ENI is “warm” with all 5 IP addresses in pool. If another Pod is launched on the instance, a 6th IP address will be needed. The CNI will assign this 6th Pod an IP address from the second ENI and from 5 IPs from the pool. The second ENI is now in use, and no longer in a “warm” status. The CNI will allocate a 3rd ENI to maintain at least 1 warm ENI.

    > The warm ENIs still consume IP addresses from the CIDR of your VPC. IP addresses are “unused” or “warm” until they are associated with a workload, such as a Pod.

- `WARM_IP_TARGET`, Integer, Values > 0 indicate requirement Enabled
  - The number of Warm IP addresses to be maintaines. A warm IP is available on an actively attached ENI, but has not been assigned to a Pod. In other words, the number of Warm IPs available is the number of IPs that may be assigned to a Pod without requiring an additional ENI.
  - Example: Consider an instance with 1 ENI, each ENI supporting 20 IP addresses `WARM_IP_TARGET` is set to 5. `WARM_ENI_TARGET` is set to 0. Only 1 ENI will be attached until a 16th IP address is needed. Then, the CNI will attach a second ENI, consuming 20 possible addresses from the subnet CIDR.
  
- `MINIMUM_IP_TARGET`, Integer, Values > 0 indicate requirement Enabled
  - The minimum number of IP addresses to be allocated at any time. This is commonly used to front-load the assignment of multiple ENIs at instance launch.
  - Example: Consider a newly launched instance. It has 1 ENI and each ENI supports 10 IP addresses. `MINIMUM_IP_TARGET` is set to 100. The ENI immediately attaches 9 more ENIs for a total of 100 addresses. This happens regardless of any `WARM_IP_TARGET` or WARM_ENI_TARGET values.

<img width="456" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/f4f36d14-53f8-442d-b96e-b4c640db7ebb">

When Kubelet recieves an add Pod request, the CNI binary queries ipamd for an available IP address, which ipamd then provides to the Pod. The CNI binary wires up the host and Pod network.

Pods deployed on a node are, by default, assigned to the same security groups as the primary ENI. Alternatively, Pord ay be configured with defferent security groups.

<img width="456" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/8e41a54d-d6be-4275-8919-9bad152761fd">

As the pool of IP addresses is depleted, the plugin automatically attaches another elastic network interface to the instance and allocates another set of secondary IP addresses to that interface. This process continues until the node can non longer support addtional elastic network interfaces.

<img width="456" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/5714cb27-3b81-44fa-ab62-39a267ffca71">

When a Pod is deleted, VPC CNI places the Pod's IP address in a 30-second cool down cache. The IPs in a coll down cache are not assigned to new Pords. When the colling-off period is over, VPC CNI moves Pod IP back to the warm pool. The cooling-off periond prevents Pod IP addresses from being recycled prematurely and allows kube-proxy on all cluster nodes to finish updating the iptables rules. When the number of IPs or ENIs exceeds the number of warm pool settings, the ipamd plugin return IPs and ENIs to the VPC.

As described above in Secondary IP mode, each Pod receives one secondary private IP address form one of the ENIs attached to an instance. Since each Pod uses an IP address, the number of Pods you can run on a particular EC2 Instance depends on how many ENIs can be attached to it and how many IP addresses it supports. The VPC CNI checks the limits file to find out how many ENIs and IP addresses are allowed for each type of instance.

You can use the following formula to determin maximum number of Pods you can deploy on a node.

```bash
(Number of network interfaces for the instance type × (the number of IP addresses per network interface - 1)) + 2
```

The +2 indicates Pods that require host networking, such as kube-proxy and VPC CNI. Amazon EKS requires kube-proxy and VPC CNI to be operating on each node, and these requirements are factored into the max-pods value. If you want to run additional host networking pods, consider updating the max-pods value.

The +2 indicates Kubernetes Pods that use host networking, such as kube-proxy and VPC CNI. Amazon EKS requires kube-proxy and VPC CNI to be running on every node and are calculated towards max-pods. Consider updating max-pods if you plan to run more host networking Pods. You can specify `--kubelet-extra-args "—max-pods=110"` as user data in the launch template.

As an example, on a cluster with 3 c5.large nodes (3 ENIs and max 10 IPs per ENI), when the cluster starts up and has 2 CoreDNS pods, the CNI will consume 49 IP addresses and keeps them in warm pool. The warm pool enables faster Pod launches when the application is deployed.

- Node 1 (with CoreDNS pod): 2 ENIs, 20 IPs assigned

- Node 2 (with CoreDNS pod): 2 ENIs, 20 IPs assigned

- Node 3 (no Pod): 1 ENI. 10 IPs assigned.

Keep in mind that infrastructure pods, often running as daemon sets, each contribute to the max-pod count. These can include:

- CoreDNS
- Amazon Elastic LoadBalancer
- Operational pods for metrics-server

We suggest that you plan your infrastructure by combining these Pod's capacities. For a list of the maximum number of Pods supported by each instance type, see [eni-max-Pods.txt](https://github.com/awslabs/amazon-eks-ami/blob/master/files/eni-max-pods.txt) on GitHub.

![image](https://github.com/rlaisqls/TIL/assets/81006587/d74d2bc1-b54b-4e5c-a30c-a30c36bce9fd)

### Use Secondary IP Mode when
Secondary IP mode is an ideal configuration option for ephemeral EKS clusters. Greenfield customers who are either new to EKS or in the process of migrating can take advantage of VPC CNI in secondary mode.

### Avoid Secondary IP Mode when
If you are experiencing Pod density issues, we suggest enabling prefix mode. If you are facing IPv4 depletion issues, we advise migrating to IPv6 clusters. If IPv6 is not on the horizon, you may choose to use custom networking.

## Deploy VPC CNI Managed Add-On

When you provision a cluster, Amazon EKS installs VPC CNI automatically. Amazon EKS nevertheless supports managed add-ons that enable the cluster to interact with underlying AWS resources such as computing, storage, and networking. AWS highly recommends that you deploy clusters with managed add-ons including VPC CNI.

Amazon EKS managed add-on offer VPC CNI installation and management for Amazon EKS clusters. Amazon EKS add-ons include the latest security patches, bug fixes, and are validated by AWS to work with Amazon EKS. The VPC CNI add-on enables you to continuously ensure the security and stability of your Amazon EKS clusters and decrease the amount of effort required to install, configure, and update add-ons. Additionally, a managed add-on can be added, updated, or deleted via the Amazon EKS API, AWS Management Console, AWS CLI, and eksctl.

You can find the managed fields of VPC CNI using `--show-managed-fields` flag with the kubectl get command.

```
kubectl get daemonset aws-node --show-managed-fields -n kube-system -o yaml
```

Managed add-ons prevents configuration drift by automatically overwriting configurations every 15 minutes. This means that any changes to managed add-ons, made via the Kubernetes API after add-on creation, will overwrite by the automated drift-prevention process and also set to defaults during add-on update process.

The fields managed by EKS are listed under managedFields with manager as EKS. Fields managed by EKS include service account, image, image url, liveness probe, readiness probe, labels, volumes, and volume mounts.

> The most frequently used fields such as `WARM_ENI_TARGET`, `WARM_IP_TARGET`, and `MINIMUM_IP_TARGET` are not managed and will not be reconciled. The changes to these fields will be preserved upon updating of the add-on.<br>AWS suggests testing the add-on behavior in your non-production clusters for a specific configuration before updating production clusters. Additionally, follow the steps in the EKS user guide for add-on configurations.

## Understand Security Context

AWS strongly suggests you to understand the security contexts configured for managing VPC CNI efficiently. Amazon VPC CNI has two components CNI binary and ipamd (aws-node) Daemonset. The CNI runs as a binary on a node and has access to node root file syetem, also has privileged access as it deals with iptables at the node level. The CNI binary is invoked by the kubelet when Podfs gets added or removed.

The aws-node Daemonset is a long-running process responsible for IP address management at the node level. The aws-node runs in `hostNetwork` mode and allows access to the loopback device, and network activity of other pods on the same node. The aws-node init-container runs in privileged mode and mounts the CRI socket allowing the Daemonset to monitor IP usage by the Pods running on the node. Amazon EKS is working to remove the privileged requirement of aws-node init container. Additionally, the aws-node needs to update NAT entries and to load the iptables modules and hence runs with `NET_ADMIN` privileges.

Amazon EKS recommends deploying the security policies as defined by the aws-node manifest for IP management for the Pods and networking settings. 

## Monitor IP Address Inventory

You can monitor the IP addresses inventory of subnets using [CNI Metrics Helper](https://docs.aws.amazon.com/eks/latest/userguide/cni-metrics-helper.html).

- maximum number of ENIs the cluster can support
- number of ENIs already allocated
- number of IP addresses currently assigned to Pods
- total and maximum number of IP address available
You can also set CloudWatch alarms to get notified if a subnet is running out of IP addresses. Please visit EKS user guide for install instructions of CNI metrics helper. Make sure `DISABLE_METRICS` variable for VPC CNI is set to false.

## Configure IP and ENI Target values in address constrained environments

> Improving your VPC design is the recommended response to IP address exhaustion. Consider solutions like IPv6 and Secondary CIDRs. Adjusting these values to minimize the number of Warm IPs should be a temporary solution after other options are excluded. Misconfiguring these values may interfere with cluster operation.

In the default configuration, VPC CNI keeps an entire ENI (and associated IPs) in the warm pool. This may consume a large number of IPs, especially on larger instance types.

If your cluster subnet has a limited number of free IP addresses, scrutinize these VPC CNI configuration environment variables:

- `WARM_IP_TARGET`
- `MINIMUM_IP_TARGET`
- `WARM_ENI_TARGET`

Configure the value of `MINIMUM_IP_TARGET` to closely match the number of Pods you expect to run on your nodes. Doing so will ensure that as Pods get created, and the CNI can assign IP addresses from the warm pool without calling the EC2 API.

Avoid setting the value of `WARM_IP_TARGET` too low as it will cause additional calls to the EC2 API, and that might cause throttling of the requests. For large clusters use along with `MINIMUM_IP_TARGET` to avoid throttling of the requests.

To configure these options, download `aws-k8s-cni.yaml` and set the environment variables. At the time of writing, the latest release is located here. Check the version of the configuration value matches the installed VPC CNI version.

---
reference
- https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/prefix-and-ip-target.md
- https://team-xquare.notion.site/node-pod-b6ba5bf5b75145869e0797f3ee601458?pvs=4
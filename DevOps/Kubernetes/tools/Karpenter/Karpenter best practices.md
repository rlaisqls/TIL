
### Use Karpenter for workloads with changing capacity needs

karpenter brings scailing management closer to Kubernetes native APIs than do [Autoscaling Groups](https://aws.amazon.com/blogs/containers/amazon-eks-cluster-multi-zone-auto-scaling-groups/) (ASGs) and [Managed Node Groups](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/managed-node-groups.html) (MNGs). ASGs and MNGs are AWS-native abstractions where scaling is triggered based on AWS level metrics, such as EC2 CPU load. 

[Cluster Autoscaler bridges](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/autoscaling.html#cluster-autoscaler) the Kubernetes abstractions into AWS abstractions, but loses some flexibility because of that, such ad scheduling for a specifiv availity zone.

Karpenter removes a layer of AWS abstraction to bring some of the flexibility directly into Kubernetes. Karpenter is best used for clusters with workloads that encounter periods of high, spiky demant or have diverse compute requirements. MNGs and ASGs are good for clusters running workloads that tend to be more static and consistent. You can use a mix of dynamically and statically managed nodes, depending on your requirements.

### Consider other autoscaling projects when...

You need features that are still being developed in Karpenter. Because Karpenter is a relatively new project, consider other autoscaling projects for the time being if you have a need for features that are not yet part of Karpenter.

### Run the Karpenter controller on EKS Fargate or on a worker node that belongs to a node group

Karpenter is installed using a Helm chart. The Helm chart installs the Karpenter controller and a webhook pod as a Deployment that needs to run before the controller can be used for scaling your cluster.

A minimum of one small node group with at least one worker node is recommended. As an alternative, you can run these pods on EKS Fargate by creating a Fargate profile for the karpenter namespace. Doing so will cause all pods deployed into this namespace to run on EKS Fargate. Do not run Karpenter on a node that is managed by Karpenter.

### Avoid using custom launch templates with Karpenter

Karpenter strongly recommends **against using custom launch templates**. Using custom launch templates prevents multi-architecture support, the ability to automatically upgrade nodes, and securityGroup discovery. Using launch templates may also cause confusion because certain fields are duplicated within Karpenter’s provisioners while others are ignored by Karpenter, e.g. subnets and instance types.

You can often avoid using launch templates by using custom user data and/or directly specifying custom AMIs in the AWS node template. More information on how to do this is available at Node Templates.

### Exclude instance types that do not fit your workload

Consider excluding specific instances types with the node.kubernetes.io/instance-type key if they are not required by workloads running in your cluster.

The following example shows how to avoid provisioning large Graviton instances.

```yaml
- key: node.kubernetes.io/instance-type
    operator: NotIn
    values:
      'm6g.16xlarge'
      'm6gd.16xlarge'
      'r6g.16xlarge'
      'r6gd.16xlarge'
      'c6g.16xlarge'
```

### Enable Interruption Handling when using Spot¶

Karpenter supports [native interruption handling](https://karpenter.sh/docs/concepts/deprovisioning/#interruption), enabled through the `aws.interruptionQueue` value in Karpenter settings. Interruption handling watches for upcoming involuntary interruption events that would cause disruption to your workloads such as:

Spot Interruption Warnings
Scheduled Change Health Events (Maintenance Events)
Instance Terminating Events
Instance Stopping Events#
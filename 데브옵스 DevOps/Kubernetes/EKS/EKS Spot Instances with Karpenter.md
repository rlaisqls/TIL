
Karpenter is a **dynamic, high performance cluster auto scaling solution** for the Kubernetes platform. Customers choose an auto scaling solution for a number of reasons, including improving the high availability and reliability of their workloads at the same reduced costs. With the introduction of [Amazon EC2 Spot Instances](https://aws.amazon.com/ec2/spot/), customers can reduce costs up to 90% compared to On-Demand prices. Combining a high performing cluster auto scaler like Karpenter with EC2 Spot Instances, EKS clusters can acquire compute capacity within minutes while keeping costs low.

## Getting started

To get started with Karpenter in AWS, you need a Kubernetes cluster. We will be using an EKS cluster throughout this blog post. To provision an Amazon Elastic Kubernetes Service (Amazon EKS) cluster and install Karpenter, please follow the getting started docs from the Karpenter [documentation](https://karpenter.sh/docs/getting-started/).

Karpenter’s single responsibility is to **provision compute for your Kubernetes clusters**, which is configured by a custom resource called Provisioner.

Currently, when a pod is newly created, kube-scheduler is responsible for finding the best feasible node so that kubelet can run it. If none of the scheduling criteria are met, the pod stays in a pending state and remains unscheduled. Karpenter <u>relies on the kube-scheduler and waits for unscheduled events and then provisions new node(s) to accommodate the pod(s)</u>. The following code snippet shows an example of Spot Provisioner configuration specifying instance types, Availability Zones, and capacity type.

```yaml
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: spot-fleet
spec:
  requirements:
    - key: "node.kubernetes.io/instance-type" 
      operator: In
      values: ["m5.large", "m5.2xlarge"]
    - key: "topology.kubernetes.io/zone" 
      operator: In
      values: ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
    - key: "karpenter.sh/capacity-type" # Defaults to on-demand
      operator: In
      values: ["spot"] # ["spot", "on-demand"]
  provider:
    subnetSelector:
      karpenter.sh/discovery: ${CLUSTER_NAME}
  ttlSecondsUntilExpired: 2592000
```

The constraints `ttlSecondsUntilExpired` defines the node expiry so a newer node will be provisioned, and `ttlSecondsAfterEmpty` defines when to delete a node since the last workload stops running. (Note: DaemonSets are not taken into account.)

## Node selection

Karpenter default settings should satisfy for most types of workloads when acquiring capacity. It uses an approximation between lowest-price and capacity-optimized allocation strategy when selecting a node for provisioning. In most cases, we don’t have to specify the instance type in the Provisioner unless you have specific constraints for your workloads.

When you choose an instance type, it does not have to be similarly sized, as Karpenter automatically selects the best instance type for unscheduled pod(s). There are a couple of ways to provide Karpenter a better chance to acquire capacity when you specify your own instance types.

One handy tool to get a list of instance types based on vCPU and memory is [amazon-ec2 instance-selector](https://github.com/aws/amazon-ec2-instance-selector) CLI. It takes input parameters such as memory, vCPU, architecture, and Region to provide the list of EC2 instances that satisfy the constraints.

```bash
$ ec2-instance-selector --memory 4 --vcpus 2 --cpu-architecture x86_64 -r ap-southeast-1
c5.large
c5a.large
c5ad.large
c5d.large
c6i.large
t2.medium
t3.medium
t3a.medium
```

Secondly, provision the instances across multiple Availability Zones to further increase the number of Spot Instance pools.

It is recommended to use a wide range of instance types to acquire the compute capacity for your cluster and, as a general rule, to not mix burstable and non-burstable instances in the same Provisioner. For example, t3 instances do not support pod security groups, so mixing t3 and m5 instance types will cause unpredictable issues when pod security group is enabled.

```yaml
spec:
  requirements:
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["c5.large","c5a.large", "c5ad.large", "c5d.large", "c6i.large", "t2.medium", "t3.medium", "t3a.medium"]
```

## Capacity type

When creating a provisioner, we can use either Spot, On-Demand Instances, or both. When you specify both, and if the pod does not explicitly specify whether it needs to use Spot or On-Demand, then Karpenter opts to use Spot when provisioning a node.

If the Spot capacity is not available, then Karpenter falls back to On-Demand Instances to schedule the pods. However, if a Spot quota limit has been reached at the account level, you might get a `MaxSpotInstanceCountExceeded` exception. In this case, Karpenter won’t perform a fallback. The users have to implement adequate monitoring for quotas and exceptions to create necessary alerts and reach AWS support for the necessary quota increase.

```yaml
    - key: "karpenter.sh/capacity-type" 
      operator: In
      values: ["spot", "on-demand"]
```

## Resiliency

Karpenter does not handle Spot Instance interruption natively, although this feature is in the roadmap. Therefore, a separate solution needs to be implemented. **AWS Node Termination Handler (NTH)** is a dedicated project that helps to make sure the **NTH control plane** acts appropriately during EC2 Spot Instance interruptions, EC2 scheduled maintenance windows, or scaling events.

Node Termination Handler operates in two modes, using Instance Metadata Services (IMDS) or using a Queue Processor.

1. **The IMDS service** runs a pod on each node to **monitor the events and act accordingly**.
2. Whereas the **queue processor** uses Amazon Simple Queue Service (Amazon SQS) to receive Auto Scaling Group (ASG) lifecycle events, EC2 status change events, Spot interruption termination notice events, and Spot rebalance recommendation events. These events can be configured to be published to Amazon EventBridge.
   
In Karpenter’s case, Auto Scaling Group lifecycle events should not be considered because the instances provisioned using Karpenter are not part of an ASG. Running NTH using queue processor mode is more recommended because it provides more functionality.

Please refer to the table below.

|Feature|IMDS Processor	Queue|Processor|
|-|-|-|
|Spot Instance Termination Notifications (ITN)|O|O|
|Scheduled Events|O|O|
|Instance Rebalance Recommendation|O|O|
|AZ Rebalance Recommendation|X|O|
|ASG Termination Lifecycle Hooks|X|O|
|Instance State Change Events|X|O|

One important event that is **worth mentioning when using Spot Instances is the rebalance recommendations signal**. It either arrives sooner or along with the Spot termination notice. When rebalance reconnendations signals arrive ahead of a Spot Instance termination notice, it doesn't mean Spot is interrepting the node.

It's just a recommendation to give an opportunity to **proactively manage the capacity needs**. This can occur if you are overly constraining the instance pools configured, which is why it is recommended to use the Karpenter as default for all instance types (with some exceptions).

As mentioned before, instances provisioned by Karpenter **do not belong to any auto scaling group**. Therefore, in the installation instruction, skip steps for Set up a Termination Lifecycle Hook on an Auto Scaling group and Tag the Auto Scaling groups. In the step Create Amazon Eventbridge Rules, skip the step to create Auto Scaling event rules. When deploying the Helm chart for NTH Queue Processor, refer to the following values:

```yaml
## Queue processor values.yaml

enableSqsTerminationDraining: true
queueURL: "<specify your queue URl>"
awsRegion: "<specify your region>"
serviceAccount:
  create: false
  name: nth # <-- adjust to your service account
checkASGTagBeforeDraining: false # <-- set to false as instances do not belong to any ASG
enableSpotInterruptionDraining: true
```

Depending on your choice of mode to implement Node Termination Handler, use the appropriate values.yaml file and install NTH using helm.

```yaml
helm upgrade --install aws-node-termination-handler \
  --namespace kube-system \
  -f values.yaml \
  eks/aws-node-termination-handler
```

## Monitoring

Spot interruptions can occur at any time. Monitoring Kubernetes cluster metrics and logs can help to create notifications when Karpenter fails to acquire capacity. We have to set up adequate monitoring at the Kubernetes cluster level for all the Kubernetes objects and monitor the Karpenter provisioner. We will use Prometheus and Grafana to collect the metrics for the Kubernetes cluster and Karpenter. CloudWatch Logs will be used to collect the logs.

To get started with Prometheus and Grafana on Amazon EKS, please follow the Prometheus and Grafana installation instruction from the [Karpenter getting started guide](https://karpenter.sh/v0.6.0/getting-started/#deploy-a-temporary-prometheus-and-grafana-stack-optional). The Grafana dashboards are preinstalled with dashboards containing controller metrics, node metrics, and pod metrics.

Using the panel Pod Distribution by Phase included in the prebuilt Grafana dashboard named General / Pod Statistic, you can check for pods that have Pending status for more than a predefined period (for example, three minutes). This will help us to understand if there are any workloads that can’t be scheduled.

<img width="571" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/f5a5afde-573f-47ca-ae58-72014913eee0">

Karpenter controller logs can be sent to CloudWatch Logs using either Fluent Bit or FluentD. (Here’s information on [how to get started with CloudWatch Logs for Amazon EKS](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-EKS-logs.html).) To view the Karpenter controller logs, go to the log group `/aws/containerinsights/cluster-name/application` and search for Karpenter.

In the log stream, search for Provisioning failed log messages in the Karpenter controller logs for any provisioning failures. The example below shows provisioning failure due to reaching the account limit for Spot Instances.

```log
2021-12-03T23:45:29.257Z        ERROR   controller.provisioning Provisioning failed, launching capacity, launching instances, with fleet error(s), UnfulfillableCapacity: Unable to fulfill capacity due to your request configuration. Please adjust your request and try again.; MaxSpotInstanceCountExceeded: Max spot instance count exceeded; launching instances, with fleet error(s), MaxSpotInstanceCountExceeded: Max spot instance count exceeded   {"commit": "6984094", "provisioner": "default"}
```

### Clean up

To avoid incurring any additional charges, clean up the resources depending on the Getting Started guide that you used or how you have provisioned Karpenter.

1. Uninstall Karpenter controller (depending on how you installed Karpenter; the following example shows using Helm).
    ```bash
    helm uninstall karpenter --namespace karpenter
    ```
2. Delete the service account; the following command assumes that you have used eksctl.
    ```bash
    eksctl delete iamserviceaccount 
        --cluster ${CLUSTER_NAME} 
        --name karpenter 
        --namespace karpenter
    ```
    
3. Delete the stack using
    ```bash
    aws cloudformation delete-stack --stack-name Karpenter-${CLUSTER_NAME} or
    terraform destroy -var cluster_name=$CLUSTER_NAME 
    ```

4. Delete the cluster using
    ```bash
    eksctl delete cluster --name ${CLUSTER_NAME}
    ```

## Conclusion

In this post, we did a quick overview of Karpenter and how we can use EC2 Spot Instances with Karpenter to scale the compute needs in an Amazon EKS cluster. We encourage you to check out the Further Reading section below to discover more about Karpenter.

---
reference
- https://aws.amazon.com/ko/blogs/containers/using-amazon-ec2-spot-instances-with-karpenter/
- https://karpenter.sh/v0.6.1/faq/#what-if-there-is-no-spot-capacity-will-karpenter-fallback-to-on-demand
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-best-practices.html#be-instance-type-flexible
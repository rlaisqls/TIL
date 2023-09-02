# Node Termination Handler

Node Termination Handler is the tool that ensures that the Kubernetes control plane responds appropriatly to events that can cause EC2 instance to become unavailable, such as [EC2 maintenance events](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-instances-status-check_sched.html), [EC2 Spot interruptions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html), [ASG Scale-In](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroupLifecycle.html#as-lifecycle-scale-in), ASG AZ Rebalance, and EC2 Instance Termination via the API or Console. If not handled, applocation on kuberneteses may not stop gracefully, take longer to recover full availability, or accidentally schedule work to nodes that are going down.

## modes

The aws-node-termination-handler (NTH) can operate in two different modes: Instance Metadata Service (IMDS) or the Queue Processor.

### IMDS mode

The aws-node-termination-handler [Instance Metadata Service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) Monitor will run a small pod on each host to perform monitoring of IMDS paths like /spot or /events and react accordingly to drain and/or cordon the corresponding node.
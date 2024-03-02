
Karpenter is **an open-source, flexible, high-performance Kubernetes cluster autoscaler** built with AWS. It helps improve your application availability and cluster efficiency by rapidly launching right-sized compute resources in response to changing application load. Karpenter also provides just-in-time compute resources to meet your application’s needs and will soon automatically optimize a cluster’s compute resource footprint to reduce costs and improve performance.

Before Karpenter, Kubernetes users needed to dynamically adjust the compute capacity of their clusters to support applications using Amazon EC2 Auto Scaling groups and the Kubernetes Cluster Autoscaler. Nearly half of Kubernetes customers on AWS report that configuring cluster auto scaling using the Kubernetes Cluster Autoscaler is challenging and restrictive.

When Karpenter is installed in your cluster, Karpenter observes the aggregate resource requests of unscheduled pods and makes decisions to launch new nodes and terminate them to reduce scheduling latencies and infrastructure costs. Karpenter does this by **observing events within the Kubernetes cluster and then sending commands to the underlying cloud provider’s compute service**, such as Amazon EC2.

## Getting Started with Karpenter on AWS

To get started with Karpenter in any Kubernetes cluster, ensure there is some compute capacity available, and install it using the Helm charts provided in the public repository. Karpenter also requires permissions to provision compute resources on the provider of your choice.

Once installed in your cluster, the default Karpenter provisioner will observe incoming Kubernetes pods, which cannot be scheduled due to insufficient compute resources in the cluster and automatically launch new resources to meet their scheduling and resource requirements.

Let's see a quick start using Karpenter in an Amazon EKS cluster based on Getting Started with Karpenter on AWS. It requires the installation of AWS Command Line Interface (AWS CLI), kubectl, eksctl, and Helm (the package manager for Kubernetes). After setting up these tools, create a cluster with eksctl. This example configuration file specifies a basic cluster with one initial node.

```yaml
cat <<EOF > cluster.yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: eks-karpenter-demo
  region: us-east-1
  version: "1.20"
managedNodeGroups:
  - instanceType: m5.large
    amiFamily: AmazonLinux2
    name: eks-kapenter-demo-ng
    desiredCapacity: 1
    minSize: 1
    maxSize: 5
EOF
$ eksctl create cluster -f cluster.yaml
```

Karpenter itself can run anywhere, including on self-managed node groups, managed node groups, or AWS Fargate. Karpenter will provision EC2 instances in your account.

Next, you need to create necessary IAM resources using the AWS CloudFormation template and IAM Roles for Service Accounts (IRSA) for the Karpenter controller to get permissions like launching instances following the documentation. You also need to install the Helm chart to deploy Karpenter to your cluster.

```bash
$ helm repo add karpenter https://charts.karpenter.sh
$ helm repo update
$ helm upgrade --install --skip-crds karpenter karpenter/karpenter --namespace karpenter \
  --create-namespace --set serviceAccount.create=false --version 0.5.0 \
  --set controller.clusterName=eks-karpenter-demo \
  --set controller.clusterEndpoint=$(aws eks describe-cluster --name eks-karpenter-demo --query "cluster.endpoint" --output json) \
  --wait # for the defaulting webhook to install before creating a Provisioner
```

Karpenter provisioners are a Kubernetes resource that enables you to configure the behavior of Karpenter in your cluster.

When you create a default provisioner, without further customization besides what is needed for Karpenter to provision compute resources in your cluster, Karpenter automatically discovers node properties such as instance types, zones, architectures, operating systems, and purchase types of instances. You don’t need to define these spec:requirements if there is no explicit business requirement.

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
name: default
spec:
#Requirements that constrain the parameters of provisioned nodes. 
#Operators { In, NotIn } are supported to enable including or excluding values
  requirements:
    - key: "node.kubernetes.io/instance-type" #If not included, all instance types are considered
      operator: In
      values: ["m5.large", "m5.2xlarge"]
    - key: "topology.kubernetes.io/zone" #If not included, all zones are considered
      operator: In
      values: ["us-east-1a", "us-east-1b"]
    - key: "kubernetes.io/arch" #If not included, all architectures are considered
	  operator: In
      values: ["arm64", "amd64"]
    - key: " karpenter.sh/capacity-type" #If not included, the webhook for the AWS cloud provider will default to on-demand
      operator: In
      values: ["spot", "on-demand"]
  provider:
    instanceProfile: KarpenterNodeInstanceProfile-eks-karpenter-demo
  ttlSecondsAfterEmpty: 30  
EOF
```

The `ttlSecondsAfterEmpty` value configures Karpenter to terminate empty nodes. If this value is disabled, nodes will never scale down due to low utilization. 

Karpenter is now active and ready to begin provisioning nodes in your cluster. Create some pods using a deployment, and watch Karpenter provision nodes in response.

```bash
$ kubectl create deployment inflate \
          --image=public.ecr.aws/eks-distro/kubernetes/pause:3.2 \
		  --requests.cpu=1
```

Let’s scale the deployment and check out the logs of the Karpenter controller.

```bash
$ kubectl scale deployment inflate --replicas 10
$ kubectl logs -f -n karpenter $(kubectl get pods -n karpenter -l karpenter=controller -o name)
2021-11-23T04:46:11.280Z        INFO    controller.allocation.provisioner/default       Starting provisioning loop      {"commit": "abc12345"}
2021-11-23T04:46:11.280Z        INFO    controller.allocation.provisioner/default       Waiting to batch additional pods        {"commit": "abc123456"}
2021-11-23T04:46:12.452Z        INFO    controller.allocation.provisioner/default       Found 9 provisionable pods      {"commit": "abc12345"}
2021-11-23T04:46:13.689Z        INFO    controller.allocation.provisioner/default       Computed packing for 10 pod(s) with instance type option(s) [m5.large]  {"commit": " abc123456"}
2021-11-23T04:46:16.228Z        INFO    controller.allocation.provisioner/default       Launched instance: i-01234abcdef, type: m5.large, zone: us-east-1a, hostname: ip-192-168-0-0.ec2.internal    {"commit": "abc12345"}
2021-11-23T04:46:16.265Z        INFO    controller.allocation.provisioner/default       Bound 9 pod(s) to node ip-192-168-0-0.ec2.internal  {"commit": "abc12345"}
2021-11-23T04:46:16.265Z        INFO    controller.allocation.provisioner/default       Watching for pod events {"commit": "abc12345"}
Bash
The provisioner’s controller listens for Pods changes, which launched a new instance and bound the provisionable Pods into the new nodes.
```

Now, delete the deployment. After 30 seconds (`ttlSecondsAfterEmpty = 30`), Karpenter should terminate the empty nodes.

```bash
$ kubectl delete deployment inflate
$ kubectl logs -f -n karpenter $(kubectl get pods -n karpenter -l karpenter=controller -o name)
2021-11-23T04:46:18.953Z        INFO    controller.allocation.provisioner/default       Watching for pod events {"commit": "abc12345"}
2021-11-23T04:49:05.805Z        INFO    controller.Node Added TTL to empty node ip-192-168-0-0.ec2.internal {"commit": "abc12345"}
2021-11-23T04:49:35.823Z        INFO    controller.Node Triggering termination after 30s for empty node ip-192-168-0-0.ec2.internal {"commit": "abc12345"}
2021-11-23T04:49:35.849Z        INFO    controller.Termination  Cordoned node ip-192-168-116-109.ec2.internal   {"commit": "abc12345"}
2021-11-23T04:49:36.521Z        INFO    controller.Termination  Deleted node ip-192-168-0-0.ec2.internal    {"commit": "abc12345"}
```

If you delete a node with kubectl, Karpenter will gracefully cordon, drain, and shut down the corresponding instance. Under the hood, Karpenter adds a finalizer to the node object, which blocks deletion until all pods are drained, and the instance is terminated.

### Things to Know

**Accelerated Computing**:
- Karpenter works with all kinds of Kubernetes applications, but it performs particularly well for use cases that require rapid provisioning and deprovisioning large numbers of diverse compute resources quickly.
- For example, this includes batch jobs to train machine learning models, run simulations, or perform complex financial calculations. You can leverage custom resources of nvidia.com/gpu, amd.com/gpu, and aws.amazon.com/neuron for use cases that require accelerated EC2 instances.

**Provisioners Compatibility:**
- Kapenter provisioners are designed to work alongside static capacity management solutions like Amazon EKS managed node groups and EC2 Auto Scaling groups. You may choose to manage the entirety of your capacity using provisioners, a mixed model with both dynamic and statically managed capacity, or a fully static approach.
- We recommend not using Kubernetes Cluster Autoscaler at the same time as Karpenter because both systems scale up nodes in response to unschedulable pods. If configured together, both systems will race to launch or terminate instances for these pods.

---
reference
- https://karpenter.sh/docs/s
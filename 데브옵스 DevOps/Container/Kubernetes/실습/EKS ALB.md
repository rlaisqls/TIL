# EKS ALB 

When you create a Kubernetes `ingress`, an AWS Application Load Balancer (ALB) is provisioned that load balances application traffic. ALBs can be used with Pods that are deployed to nodes or to AWS Fargate. You can deploy an ALB to public or private subnets.

Before you can load balance application traffic to an application, you must meet the following requirements.

#### Prerequisites

- Have an existing cluster. If you don't have an existing cluster
- Have the AWS Load Balancer Controller deployed on your cluster. 
- At least two subnets in different Availability Zones. The AWS Load Balancer Controller chooses one subnet from each Availability Zone. When multiple tagged subnets are found in an Availability Zone, the controller chooses the subnet whose subnet ID comes first lexicographically. Each subnet must have at least eight available IP addresses.
    If you're using multiple security groups attached to worker node, exactly one security group must be tagged as follows. Replace my-cluster with your cluster name.
    **Key** – `kubernetes.io/cluster/my-cluster`
    **Value** – `shared or owned`

- Your public and private subnets must meet the following requirements. This is unless you explicitly specify subnet IDs as an annotation on a service or ingress object. Assume that you provision load balancers by explicitly specifying subnet IDs as an annotation on a service or ingress object.
- In this situation, Kubernetes and the AWS load balancer controller use those subnets directly to create the load balancer and the following tags aren't required.
  - **Private subnets** – Must be tagged in the following format. This is so that Kubernetes and the AWS load balancer controller know that the subnets can be used for internal load balancers. If you use eksctl or an Amazon EKS AWS CloudFormation template to create your VPC after March 26, 2020, the subnets are tagged appropriately when created. For more information about the Amazon EKS AWS CloudFormation VPC templates, see Creating a VPC for your Amazon EKS cluster.
    - **Key** – `kubernetes.io/role/internal-elb`
    - **Value** – `1`
  - **Public subnets** – Must be tagged in the following format. This is so that Kubernetes knows to use only the subnets that were specified for external load balancers. This way, Kubernetes doesn't choose a public subnet in each Availability Zone (lexicographically based on their subnet ID). If you use eksctl or an Amazon EKS AWS CloudFormation template to create your VPC after March 26, 2020, the subnets are tagged appropriately when created. For more information about the Amazon EKS AWS CloudFormation VPC templates, see Creating a VPC for your Amazon EKS cluster.
    - **Key** – `kubernetes.io/role/elb`
    - **Value** – `1`

If the subnet role tags aren't explicitly added, the Kubernetes service controller examines the route table of your cluster VPC subnets. This is to determine if the subnet is private or public. We recommend that you don't rely on this behavior. Rather, explicitly add the private or public role tags. The AWS Load Balancer Controller doesn't examine route tables. It also requires the private and public tags to be present for successful auto discovery.

### Considerations

- The AWS Load Balancer Controller creates ALBs and the necessary supporting AWS resources whenever a Kubernetes ingress resource is created on the cluster with the `kubernetes.io/ingress.class: alb` annotation. The ingress resource configures the ALB to route HTTP or HTTPS traffic to different Pods within the cluster. To ensure that your ingress objects use the AWS Load Balancer Controller, add the following annotation to your Kubernetes ingress specification. [More information](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/spec/)

```yml
annotations:
    kubernetes.io/ingress.class: alb
    # If you want to use IPv6
    # alb.ingress.kubernetes.io/ip-address-type: dualstack 
```

- The AWS Load Balancer Controller supports the following traffic modes:
  - **Instance** – Registers nodes within your cluster as targets for the ALB. <u>Traffic reaching the ALB is routed to NodePort for your service and then proxied to your Pods.</u> This is the default traffic mode. You can also explicitly specify it with the `alb.ingress.kubernetes.io/target-type: instance` annotation.
  - **IP** – Registers Pods as targets for the ALB. Traffic reaching the ALB is <u>directly routed to Pods for your service</u>. You must specify the `alb.ingress.kubernetes.io/target-type`: ip annotation to use this traffic mode. The IP target type is required when target Pods are running on Fargate.

- To tag ALBs created by the controller, add the following annotation to the controller: `alb.ingress.kubernetes.io/tags`. For a list of all available annotations supported by the AWS Load Balancer Controller, see [Ingress annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/annotations/) on GitHub.

- Upgrading or downgrading the ALB controller version can introduce breaking changes for features that rely on it. For more information about the breaking changes that are introduced in each release, see[ the ALB controller release notes](https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases) on GitHub.

- **To share an application load balancer across multiple service resources using IngressGroups**
    To join an ingress to a group, add the following annotation to a Kubernetes ingress resource specification.
    ```yml
    alb.ingress.kubernetes.io/group.name: my-group
    ```

## (Optional) Deploy a sample application

#### Prerequisites

- At least one public or private subnet in your cluster VPC.
- Have the AWS Load Balancer Controller deployed on your cluster. For more information, see Installing the AWS Load Balancer Controller add-on. We recommend version 2.4.7 or later.

#### To deploy a sample application

You can run the sample application on a cluster that has Amazon EC2 nodes, Fargate Pods, or both.

1. If you're not deploying to Fargate, skip this step. If you're deploying to Fargate, create a Fargate profile. You can create the profile by running the following command or in the AWS Management Console using the same values for name and namespace that are in the command. Replace the `example values` with your own.

```bash
eksctl create fargateprofile \
    --cluster my-cluster \
    --region region-code \
    --name alb-sample-app \
    --namespace game-2048
```

2. Deploy the game [2048](https://play2048.co/) as a sample application to verify that the AWS Load Balancer Controller crates an AWS ALB as a result of the ingress object. Complete the steps for the type of subnet you're deploying to.

  - **Public**
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/examples/2048/2048_full.yaml
    ```
  - **Private**
    1. Download the manifest
      ```bash
      curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/examples/2048/2048_full.yaml
      ```
    2. Edit the file and find the line that says `alb.ingress.kubernetes.io/scheme: internet-facing.`
    3. Change `internet-facing` to `internal` and save the file
    4. Apply the manifest to your cluster.
      ```bash
      kubectl apply -f 2048_full.yaml
      ```

3. After a few minutes, verify that the ingress resource was created with the following command.

  ```bash
  $ kubectl get ingress/ingress-2048 -n game-2048
  NAME           CLASS    HOSTS   ADDRESS                                                                   PORTS   AGE
  ingress-2048   <none>   *       k8s-game2048-ingress2-xxxxxxxxxx-yyyyyyyyyy.region-code.elb.amazonaws.com   80      2m32s
  ```

4. If you deployed to a public subnet, open a browser and navigate to the ADDRESS URL from the previous command output to see the sample application. If you don't see anything, refresh your browser and try again. If you deployed to a private subnet, then you'll need to view the page from a device within your VPC, such as a bastion host.

5. When you finish experimenting with your sample application, delete it by running one of the the following commands.

- If you applied the manifest, rather than applying a copy that you downloaded, use the following command.

  ```bash
  kubectl delete -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/examples/2048/2048_full.yaml
  ```

- If you downloaded and edited the manifest, use the following command.

  ```bash
  kubectl delete -f 2048_full.yaml
  ```
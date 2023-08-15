# EBS CSI driver

If you want to persist your own data to EBS in EKS environment, you can use EBS CSI driver addon provided by AWS.

Beforehand we need to enable the IAM OIDC provider and create the IAM role for the EBS CSI driver. The easiest way to do both is to use eksctl (other ways like using plain aws cli or the AWS GUI are described in the docs).

### 1. Enable IAM OIDC provider

A prerequisite for the EBS CSI driver to work is to have an existing AWS Identity and Access Management (IAM) OpenID Connect (OIDC) provider for your cluster. This IAM OIDC provider can be enabled with the following command:

```bash
eksctl utils associate-iam-oidc-provider --region=eu-central-1 --cluster=YourClusterNameHere --approve
```

### 2. Create Amazon EBS CSI driver IAM role

Now having eksctl in place, create the IAM role:

```bash
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster YourClusterNameHere \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole
```

As you can see AWS maintains a managed policy for us we can simply use (AWS maintains a managed policy, available at ARN `arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy`). Only if you use encrypted EBS drives you need to additionally add configuration to the policy.

> deploys an AWS CloudFormation stack that creates an IAM role, attaches the IAM policy to it, and annotates the existing ebs-csi-controller-sa service account with the Amazon Resource Name (ARN) of the IAM role.

### 4. Add the Amazon EBS CSI add-on

Now we can finally add the EBS CSI add-on. Therefore we also need the AWS Account id which we can obtain by running `aws sts get-caller-identity --query Account --output text` (see Quick way to get AWS Account number from the AWS CLI tools?). Now the eksctl create addon command looks like this:

```bash
eksctl create addon --name aws-ebs-csi-driver --cluster YourClusterNameHere --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AmazonEKS_EBS_CSI_DriverRole --force
```

Now your PersistentVolumeClaim should get the status Bound while a EBS volume got created for you - and the Tekton Pipeline should run again.

---
reference
- https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/
- https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html
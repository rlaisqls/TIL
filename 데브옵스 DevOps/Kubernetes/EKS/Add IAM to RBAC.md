## Add new IAM user or role to the Kubernetes RBAC, using kubectl or eksctl

Before you choose the kubectl or eksctl tool to edit the aws-auth ConfigMap, make sure that you complete step 1. Then, follow steps 2-4 to edit with kubectl. To edit with eksctl, proceed to step 5.

1. After you identify the cluster creator or admin, configure AWS CLI to use the cluster creator IAM. See Configuration basics for more information.

To verify that AWS CLI is correctly configured with the IAM entity, run the following command:

```bash
$ aws sts get-caller-identity
```
The output returns the ARN of the IAM user or role. For example:
```json
{
    "UserId": "XXXXXXXXXXXXXXXXXXXXX",
    "Account": "XXXXXXXXXXXX",
    "Arn": "arn:aws:iam::XXXXXXXXXXXX:user/testuser"
}
```
> Note: If you receive errors when running the CLI commands, make sure that you're using the most recent version of AWS CLI.

**2. To modify the aws-auth ConfigMap with kubectl, you must have access to the cluster.**

Run the following kubectl command:

```bash
$ kubectl edit configmap aws-auth -n kube-system
```

The console shows the current configMap.

If you can't connect to the cluster, then try updating your kubeconfig file. Run the file with an IAM identity that has access to the cluster. The identity that created the cluster always has cluster access.

```bash
aws eks update-kubeconfig --region region_code --name my_cluster
```
> Note: Replace region_code with your EKS cluster AWS Region code and my_cluster with your EKS cluster name.

The kubectl commands must connect to the EKS server endpoint. If the API server endpoint is public, then you must have internet access to connect to the endpoint. If the API server endpoint is private, then you must connect to the EKS server endpoint from within the VPC where the EKS cluster is running.

3. To edit the aws-auth ConfigMap in the text editor as the cluster creator or admin, run the following command:
```bash
$ kubectl edit configmap aws-auth -n kube-system
```

**4. Add an IAM user or role:**

```bash
mapUsers: |
  - userarn: arn:aws:iam::XXXXXXXXXXXX:user/testuser
    username: testuser
    groups:
    - system:bootstrappers
    - system:nodes
```
-or-

Add the IAM role to mapRoles. For example:

```bash
mapRoles: |
  - rolearn: arn:aws:iam::XXXXXXXXXXXX:role/testrole
    username: testrole    
    groups:
    - system:bootstrappers
    - system:nodes
```

### Consider the following information:

`system:masters` allows a superuser access to perform any action on any resource. This isn't a best practice for production environments.
It’s a best practice to minimize granted permissions. Consider creating a role with access to only a specific namespace. See Using RBAC Authorization on the Kubernetes website for information. Also, see Required permissions, and review the View Kubernetes resources in a specific namespace section for an example on the Amazon EKS console’s restricted access.
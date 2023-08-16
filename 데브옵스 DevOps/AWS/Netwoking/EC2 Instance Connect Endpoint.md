# EC2 Instance Connect Endpoint

Imagine trying to connect to an EC2 instance within your VPC over the Internet. Typically, you’d first have to connect to a bastion host with a public IP address that your administrator set up over an IGW in your VPC, and then use port forwarding to reach your destination.

[EC2 Instance Connect (EIC) Endpoint](https://aws.amazon.com/about-aws/whats-new/2023/06/amazon-ec2-instance-connect-ssh-rdp-public-ip-address/), a new feature that allows you to connect securely to you instances and other VPC resources from the Internet. With EIC Endpoint, **you no longer need an IGW** in your VPC, a public IP address on your resource, a bastion host, or any agent to connect to your resources. EIC Endpoint combines identity-based and network-based access controls, providing the isolation, control, and logging needed to meet your organization's security requirements.

As a bonus, your organization administrator is also relieved of the **operational overhead** of maintaining and patching bastion hosts for connectivity. EIC Endpoint works with the [AWS Management Console](https://aws.amazon.com/console/) and [AWS CLI](https://aws.amazon.com/cli/). Futhermore, it gives you the flexibility to continue using your favorite tools, such as PuTTY and OpenSSH.

Let's take a quick look at how EIC Endpoint works and the security measures it adopts. Then we'll finish by learning how to create an EIC Endpoint and use it to SSH from the Internet to an instance.

## EIC Endpoint product overview

EIC Endpoint is an **identity-aware TCP proxy**.

It has two modes: first, AWS CLI client is used to create a secure, WebSocket tunnel from your workstation to the endpoint with your AWS Identity and Access Management (IAM) credentials. Once you’ve established a tunnel, you point your preferred client at your loopback address (127.0.0.1 or localhost) and connect as usual.

Second, when not using the AWS CLI, the Console gives you secure and seamless access to resources inside your VPC. Authentication and authorization is evaluated before traffic reaches the VPC. The following figure shows an illustration of a user connecting via an EIC Endpoint:

![image](https://github.com/rlaisqls/TIL/assets/81006587/e587769d-1fec-4560-94d5-378442eb8371)

### flexibility

EIC Endpoints provide a high degree of flexibility.

1. They don't require you VPC to have direct Internet connectivity  using an IGW ar NAT gateway.
2. No agent is needed on the resource you wich to connect to, allowing for easy remote administration of resources which may not support agents, like third-party applience.
3. They preserve existing workflows, enabling you to continue using your preferred client software on your local workstation to connect and manage your resources.
4. IAM and [Security Groups](./security/Security Groups.md) can be used to control access, which we discuss in more detail in the next section.

### key services to help manage access

Prior to the launch of EIC Endpoints, AWS offered two key services to help manage access from public address space into a VPC more carefully. 

1. [EC2 Instance Connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Connect-using-EC2-Instance-Connect.html), which provides a mechanism that uses IAM credentials to push ephemeal SSH keys to an instance, making long-lived keys unnecessary. You can use EC2 Instance Connect with EIC Endpoints, combining the two capabilities to give you ephemeral-key-based SSH to your instances without exposure to the public Internet.

2. As an alternative to EC2 instance Connect and EIC Endpoint based connectivity, AWS also offers [Systems Manager Session Manager (SSM)](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html), which provides **agent-based** connectivity to instances. SSM uses **IAM** for authentication and authorization, and is ideal for environments where an agent can be configured to run.

Given that EIC Endpoint enables access to private resources from public IP space, let’s review the security controls and capabilities in more detail before discussing creating your first EIC Endpoint.

## Security capabilities and controls

Many AWS customers remotely managing resource inside their VPCs from the Internet still use either public IP addresses on the relevant resources, or at best a bastion host appreach combined with long-lived SSH Keys. Using public IPs can be locked down somewhat using IGW routes and/or security groups.

However, in a dynamic environment those controls can be hard to manage. As a result, careful management of long-lived SSH keys remains **the only layer of defense**, which isn't great since we all know that these controls sometimes fail, and so defense-in-depth is important. Although bastion hosts can help, they increase the operational overhead of managing, patching, and maintaining infrastructure significantly.

### IAM authorization

IAM authorization is required to **create** EIC Endpoint and also to **establish a connection** via the endpoint's secure tunneling technology. 

Along with identity-based access controls goberning who, how, when, and how long used can connect, more traditional network access controls like security groups can also be used. Security groups associated with your VPC resources can be used to grant/deny access. Whether it's IAM policies or security groups, the default behavior is to deny traffic unless it is explicitly allowed.

### Privilege and access management

EIC Endpoint meets impotant security requirements in terms of **separation of privileges** for the control plane and data plane. An administrator with full EC2 IAM privileges can create and control EIC Endpoints (that control plane). However, they cannot use those endpoints without also having EC2 Instance Connect IAM privileges (the data plane).

Conversely, DevOps engineers who may need to use EIC Endpint to tunnel into VPC resources do not require control-plane privileges to do so. In all cases, IAM principals using an EIC Endpoint must be part of the same AWS account (either directly or by cross-account role assumption).

Security administrators and auditors have a **centralized view** of endpoint activity ad all API calls for configuring and connecting via the EIC Endpoint API are recorded in AWS CloudTrail. Records of data-plane connections include the IAM principal making the request, their source IP address, the requested destication IP address, and the destination port. See the following figure for an example CloudTrail entry.

<img height=300px src="https://github.com/rlaisqls/TIL/assets/81006587/3984028a-d37a-4998-bd07-98040a061f9a">

## Getting started

### Creating your EIC Endpoint

Only one endpoint is required per VPC. To create or modify an endpoint and connect to a resource, a user must have the required IAM permissions, and any security groups associated with your VPC resources must have a rule to allow connectivity. Refer to the following resources for more details on configuring security groups and sample IAM permissions.

The AWS CLI or Console can be used to create an EIC Endpoint, and we demonstrate the AWS CLI in the following. To create an EIC Endpoint using the Console, refer to the documentation.

### Creating an EIC Endpoint with the AWS CLI

To create an EIC Endpoint with the AWS CLI, run the following command, replacing [SUBNET] with your subnet ID and [SG-ID] with your security group ID:

```bash
aws ec2 create-instance-connect-endpoint \
    --subnet-id [SUBNET] \
    --security-group-id [SG-ID]
```

After creating an EIC Endpoint using the AWS CLI or Console, and granting the user IAM permission to create a tunnel, a connection can be established. Now we discuss how to connect to Linux instances using SSH. However, note that you can also use the OpenTunnel API to connect to instances via RDP.

### Connecting to your Linux Instance using SSH

With your EIC Endpoint set up in your VPC subnet, you can connect using SSH. Traditionally, access to an EC2 instance using SSH was controlled by key pairs and network access controls.

With EIC Endpoint, an additional layer of control is enabled through IAM policy, leading to an enhanced security posture for remote access. We describe two methods to connect via SSH in the following.

### One-click command

To further reduce the operational burden of creating and rotating SSH keys, you can use the new `ec2-instance-connect ssh` command from the AWS CLI. With this new command, we generate ephemeral keys for you to connect to your instance. Note that this command requires use of the OpenSSH client and the latest version of the AWS CLI. To use this command and connect, you need IAM permissions as detailed [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/permissions-for-ec2-instance-connect-endpoint.html).

![image](https://github.com/rlaisqls/TIL/assets/81006587/59625e87-e15a-4837-b842-079167c889a5)

To test connecting to your instance from the AWS CLI, you can run the following command where [INSTANCE] is the instance ID of your EC2 instance:

```bash
aws ec2-instance-connect ssh --instance-id [INSTANCE]
```

Note that you can still use long-lived SSH credentials to connect if you must maintain existing workflows, which we will show in the following. However, note that dynamic, frequently rotated credentials are generally safer.

### Open-tunnel command

You can also connect using SSH with standard tooling or using the proxy command. To establish a private tunnel (TCP proxy) to the instance, you must run one AWS CLI command, which you can see in the following figure:

![image](https://github.com/rlaisqls/TIL/assets/81006587/952bf24a-365c-4cd7-b7c3-9d3c507b2ed8)

You can run the following command to test connectivity, where [INSTANCE] is the instance ID of your EC2 instance and [SSH-KEY] is the location and name of your SSH key. For guidance on the use of SSH keys, refer to our documentation on [Amazon EC2 key pairs and Linux instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).

```bash
ssh ec2-user@[INSTANCE] \
    -i [SSH-KEY] \
    -o ProxyCommand='aws ec2-instance-connect open-tunnel \
    --instance-id %h'
```

Once we have our EIC Endpoint configured, we can SSH into our EC2 instances without a public IP or IGW using the AWS CLI.

## Conclusion

EIC Endpoint provides a secure solution to connect to your instances via SSH or RDP in private subnets without IGWs, public IPs, agents, and bastion hosts. By configuring an EIC Endpoint for your VPC, you can securely connect using your existing client tools or the Console/AWS CLI.

---
reference
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html
- https://aws.amazon.com/ko/blogs/compute/secure-connectivity-from-public-to-private-introducing-ec2-instance-connect-endpoint-june-13-2023/
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Connect-using-EC2-Instance-Connect-Endpoint.html


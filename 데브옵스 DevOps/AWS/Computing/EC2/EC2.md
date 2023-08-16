# Elastic Compute Cloud (EC2)

EC2 spins up resizable server instances that can sacle up an down quickly. An instance is a virtual server in the cloud. With Amazon EC2, you can set up and configure the operating system and appplications that run on your instance.

Its configuration at launch is a live copy of Amazon Machine Image (AMI) that you specify when you launched the instance.

EC2 has an extemely reduced time frame for provisioning and booting new instances and EX2 enwures that you pay as you go, pay for what you use, pay less as you use more, and pay even less when you reserve capacity. When your EC2 instance is running, you are only charged on CPU, memory, storage, ans networking. When it is stopped, you are only charged for EBS storage.

## Key Details

- You can launch different types of instances from a single AMI. An instance type essentially determines the hardware of the host computer used for your instance. Each instance type offers different compute and memory capabilities. You should select an instance type based on the amount of memory and computing power that you need for the applicatio or software that you plan to run on top of the instance.

- You can lanch multiple instances of an AMI, as shown in the follwing figure:<br>
    ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/8805dad9-5b2e-4017-a9ca-bd5efb754c8b)
  
- You have the option of using dedicated tenancy with your instance. This means that with an AWS data center, you have exclusive access to physical hardware. Dedicated tenancy ensures that your EC2 instances are run on hardware specific to your account.
  Naturally, this option incurs a high cost, but is makes sense if you work with technology that has a strict licensing policy. 
  <img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/7a908a35-9415-4bf9-82a7-95ed6d4950ce" height=300px/>

- With EC2 VM Import, you can import existing VMs into AWS as long as those hosts use VMware ESX, CMware Workstation, Microsoft Hyper-V, or Citrix Xen vietualization formats.

- When you launch a new EC2 instance, EC2 attempts to place the instance in such a way that all of your VMs are spread out across different hardware to limit failure to a single location. You can use placement groups to influence the placement of a group of interdependent instances that meet the needs of your workload. 

  <img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/7a908a35-9415-4bf9-82a7-95ed6d4950ce" height=300px/>

- When you launch an instance in Amazon EC2, you have the option of passing user data to the instance when the instance starts. This user data can be used to run common automated configuration tasks or scripts. For example, you can pass a bash script that ensures htop is installed on the new EC2 host and is always active.

- By default, the public IP address of an EC2 Instance is released when the instance is stopped even if its stopped temporarliy. Therefor, it is best to refer to an instance by its external DNS hostname. If you require a persistent public IP address that can be associated to the same instancee, use an Elestic IP address which is basically a static IP address instead.

- If you have requirements to self-manage a SQL database, EC2 can be a solid alternative to RDS. To ensure high availability, remember to have at least one other EC2 Instance in a separate Availability zone so even if a DB instance goes down, the other(s) will still be available.

- A golden image is simply an AMI that you have fully customized to your liking with all necessary software/data/configuration details set and ready to go once. This personal AMI can then be the source from which you launch new instances.

- Instance status checks check the health of the running EC2 server, systems status check monitor the health of the underlying hypervisor. If you ever notice a systems status issue, just stop the instance and start it again (no need to reboot) as the VM will start up again on a new hypervisor.

## Instance Pricing

- **On-Demand instances** are based on a fixed rate by the hour or second. As the name implies, you can start an On-Demand instance whenever you need one and can stop it when you no longer need it. Ther is no requirement for a long-term commitment.

- **Reserved instance** ensure that you keep exclusive use of an instance on 1 or 3 year contract terms. The long-term commitment procides significantly reduced discounts at the hourly rate.

- **Spot instances** take advantage of Amazon's excess capacity and work in an interesting manner. In order to use them, you must financially bid for access. 

## Standard Reserved vs. Converible Reserved vs. Scheduled Reserved

- **Standard Reserved Instances** have inflexible reservations that are discounted at 75% off of On-Demand instances. Standard Reserved Instances cannot be moved between regions. You can choose if a Reserved Instance applies to either a specific Availability Zone, or an Entire Resion, but you cannot change the region.

- **Converible Reserved Instances** are instances that are discounted at 54% off of On-Demand instances, but you can also modify the instance type at any point. For example, you suspect that ofter a few months your CM might need to change from general purpose to memory optimized, but you aren't sure just yet. So if you think that in the future you might need to change your VM type or upgrade you VMs capacity, choose Convertible Reserved Instances. There is no downgrading instance type with this option though.

- **Scheduled Reserved Instances** are reserved according to a specified timeline that you set. For example, you might use Scheduled Reserved Instances if you run education software that only needs to be available during school hours. This option allows you to better match your your needed capacity with a recurring schedule so that you can save money.

## EC2 Instance Lifecycle

The following table highlights the many instance states that a VM can be in at a given time.

|Instance state|Description|Billing|
|-|-|-|
|`pending`|The instance is preparing to enter the running state. An instance enters the pending state when it launches for the first time, or when it is started after being in the stopped state.|Not billed|
|`running`|The instance is running and ready for use.|Billed|
|`stopping`|The instance is preparing to be stopped or stop-hibernated.|Not billed if preparing to stop. Billed if preparing to hibernate|
|`stopped`|The instance is shut down and cannot be used. The instance can be started at any time.|Not billed|
|`shutting-down`|The instance is preparing to be terminated.|Not billed|
|`terminated`|The instance has been permanently deleted and cannot be started.|Not billed|

Note: Reserved Instances that are terminated are billed until the end of their term.

## EC2 Security

- When you deploy an Amazon EC2 instance, you are responsible for management of the guest operating system (including updates and security patches), any application software or utilitied installed on the instances, and the configuration of the AWS-provided firewall (called a security group) on each instance.
  
- With EC2, termination protection of the instance is disabled by default. This means that you do not have a safe-quard in place from accidentally terminating your instance. You must turn this feature on if tou want that extra bit of protection.

- Amazon EC2 uses public–key cryptography to encrypt and decrypt login information. Public–key cryptography uses a public key to encrypt a piece of data, such as a password, and the recipient uses their private key to decrypt the data. The public and private keys are known as a key pair.

- You can encrypt your root device volume which is where you install the underlying OS. You can do this during creation time of the instance or with third-party tools like bit locker. Of course, additional or secondary EBS vulumed are also enxryptable as well.

- By default, an EC2 instance with an attached EBS root volume will be deleted together when the instance is terminated. However, any additional or secondary EBS volume that is also attached to the same instance will be preserved. This is because the root EBS volume is for OS installations and other low-level settings. This rule can be modified, bur it is usually easier to boot a new instance with a fresh root device volume than make use of an old one.

## Placement Groups

- When you launch a new EC2 instance, the EC2 service attempts to place the instance in such a way that all of your instances are spread out across underlying hardware to minimize correlated failures. You can use placement groups to influence the placement of a group of interdependent instances to meet the needs of your workload.
  Placement groups balance the tradeoff between risk tolerance and network performance when it comed to your fleet of EC2 instances. The more you care about risk, the more isolated you want your instances to be from each other. The more you care about performance, the more conjoined you want your instances to be with each other.
  
- There are three different types of EC2 placement groups:
    1. Clustered Placement Groups
       - Clustered Placement Grouping is when you put all of your EC2 instances in a single availability zone. This is recommended for applications that need the lowest latency possible and require the highest neywork throughput.
       - Only certain instances can be launched into this group (compute optimized, GPU optimized, storage optimized, and memory optimized).<br>
        ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/05388d12-24f0-425c-8c15-a2e6d6da00f2)

    2. Spread Placement Groups
       - Spread Placement Grouping is when you put each individual EC2 instance on top of its own distinct hardware so that failure is isolated.
       - Your VMs live on separate racks, with separate network inputs and separate power requirements. Spread placement groups are recommended for applications that have a small number of critical instances that should be kept separate from each other.<br>
        ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/ef0d7b55-c74b-4b49-9457-17b51f9a49b2)

    3. Partitioned Placement Groups
        - Partitioned Placement Grouping is similar to Spread placement grouping, but differs because you can have multiple EC2 instances within a single partition. Failure instead is isolated to a partition (say 3 or 4 instances instead of 1), yet you enjoy the benefits of close proximity for improved network performance.
        - With this placement group, you have multiple instances livingtogether on the same hardware inside of different availity zones acress one or more regions.
        - If you would like a balance of risk tolerance and network performance, use Partitioned Placement Groups.<br>
        ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/19af9966-f14a-4509-a324-9a17ad0ad624)

- Each placement group name within your AWS must be unique
  
- You can move an existing instance into a placement group provided that it is in a stopped state. You can move the instance via the CLI or an AWS SDK, but not the console. You can also take a snapshot of the existing instance, convert it into an AMI, and launch it into the placement group where you desire it to be. 

## AWS Nitro System

The AWS Nitro System is the underlying platform for the latest generation of EC2 instances that enables AWS to innovate faster, further reduce cost for our customers, and deliver added benefits like increased security and new instance types. With the latest set of enhancements to the Nitro system, all new C5/C5d/C5n, M5/M5d/M5n/M5dn, R5/R5d/R5n/R5dn, and P3dn instances now support 36% higher EBS-optimized instance bandwidth, up to 19 Gbps. Also, 6, 9, and 12 TB Amazon EC2 High Memory instances can now support 19 Gbps of EBS-optimized instance bandwidth, a 36% increase from 14 Gbps. 

This performance increase enables you to speed up sections of your workflows dependent on EBS-optimized instance performance. For storage intensive workloads, you will have an opportunity to use smaller instance sizes and still meet your EBS-optimized instance performance requirement, thereby saving costs. With this performance increase, you will be able to handle unplanned spikes in EBS-optimized instance demand without any impact to your application performance. 

## Instance Familiy

Amazon EC2 provides a variety of instance types so you can choose the type that best meets your requirements. Instance types are named based on their family, generation, additional capabilities, and size. The first position of the instance type name indicates the instance family, for example c. The second position indicates the instance generation, for example 5. The remaining letters before the period indicate additional capabilities, such as instance store volumes. After the period (.) is the instance size, such as small or 4xlarge, or metal for bare metal instances.

#### Instance families

- C – Compute
- D – Dense storage
- F – FPGA
- G – GPU
- Hpc – High performance computing
- I – I/O
- Inf – AWS Inferentia
- M – Most scenarios
- P – GPU
- R – Random access memory
- T – Turbo
- Trn – AWS Tranium
- U – Ultra-high memory
- VT – Video transcoding
- X – Extra-large memory

#### Additional capabilities

- a – AMD processors
- g – AWS Graviton processors
- i – Intel processors
- d – Instance store volumes
- n – Network and EBS optimized
- e – Extra storage or memory
- z – High performance

---
reference
- https://aws.amazon.com/ec2/faqs/
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/placement-groups.html
- https://docs.aws.amazon.com/ko_kr/AWSEC2/latest/WindowsGuide/instance-types.html

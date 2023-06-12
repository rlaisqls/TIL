## Elastic Block Store (EBS)

An Amazon EBS volume is a durable, block-level storage device that you can attach to a single EC2 instance. You can think of EBS as a cloud-based virtual hard dist. You can use EBS volumes as primary storage for data that requires frequent updates, such as the system drive for an instance or storage for a database application. You can also use them for throughput-intensive applications that perform continuous disk scans.

<img width="629" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/819d29a7-008a-44bf-9db0-25ea9e810e9f">

---

- EBS columes persist independently from the runnign life of an EV2 instance. 

- Each EBS volume is automatically replicated within its Availability Zone to protect from both component faulure and disaster recovery (similar to Standard S3).

- There are five differnt types of EBS Storage:
    - General Purpose (SSD)
    - Provisioned IOPS (SSD, built for speed)
    - Throughput Optimized Hard Disk Drive (magnetic, built for lager data loads)
    - cold Hard Disk Drive (magnetic, built for less frequently accessed workloads)
    - Magnetic

- EBS Volumes offer 99.999% SLA.

- Wherever you Ec2 instance is, your volume for it is going to be in the same availability zone.

- Amazon EBS provides the ability to create snapshots (backups) of any EBS volume and write a copy of the data in the volume to S3, where it is stored redundantly in multiple Availability Zones.

- An EBS snapshot reflects the contents of the volume during a concrete instant in time.

- An image (AMI) is the same this, but includes an operating system and a boot loader so it can be used to boot an instance.

- AMIs can also be thought of as pre-baked, launchable servers. AMIs are always used when launching an instance.

- When you provision an EC2 instance, an AMI is actually the first thing you are asked to specify. You can choose a pre-made aAMI or choose your own made from an EBS snapshot.

- You can also use the following criteria to help pick you AMI:
    - Operating System
    - Architecture (32-bit or 64-bit)
    - Region
    - Launch permissions
    - Root Device Storage (more in the relevant section below)

- You can copy AMIs into entirely new reginos.

- When copying AMIs to new regions, Amazon won't copy launch permissions, user-defined tags, or Amazon S3 bucket permissions from the source AMI to the new AMI. You must ensure those details are properly set for the instances in the new region.

- You can change EBS volumes on the fly, including the size and storage type.

## SSD vs. HDD

- SSD-backed volumes are built for transactional workloads involving frequent read/write operations, where the dominant performance attribute is IOPS. Rule of thumb: Will your workload be IOPS heavy? Plan for SSD.

- HHD-backed volumes are built for large streaming workloads where throughput (measured in MiB/s) is a better performance measure than IOPS. Rule of thumb: Will your workload be throughput heavy? Plan for HDD.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/628b819e-754f-4ee5-ac37-6bb7f3494f0a)

## EBS Snapshots

- EBS Snapshots are point in time copies of volumes. You can think of Snapshots as photographs of the disk's current state and the state of everything within it.

- A snapshot is constriained to the region where it was created. 

- Snapshots only capture the state of change from when the last snapshot was taken. This is what is recorded in each new snapshot, not the entire state of the server.

- Because of this, it may take some time for your first snapchot to be created. This is because the very first snapshot's change of state is the entire new volume. Only afterwards will the delta be captured because there will then be something previous to compare against.

- EBS snapshots occur asynchronoudly which means thhat a volume can be used as normal while a snapshot is taking place.

- When creating a snapshot for a future root device, it is considered best practices to stop the running instance where the original device is before taking the snapshot.

- The easiest way to move an EC@ instance and a volume to another availability zone to take a snapshot.

- When creating an image from a snapshot, if you want to deploy a different volume type for new image (e.g. General Purpose SSD -> Throughput Optimized HDD)

- A short summary for creating copies of EC2 instances: Old instance -> Snapshot -> Image(AMI) -> New instance

- You cannot delete a snapshot of an EBS Volume that is used as the root device of a registered AMI, If the original snapshot was deleted, then the AMI would not be able to use it as the basis to create new instances. For this reason, AWS protects you from accidentally deleting the EBS Snapshot, since it could be critical to your systems. To delete an EBS Snapshot attached to a registered AMI, first remove the AMI, then the snapshot can be deleted. 

## EBS Root Device Storage

- All AMI root voulumes (where teh EC2's OS is installed) are of two types: EBS-backed or Instance Store-backed.

- When you delete an EC2 instance that was using an Instance Store-backed root volume, your root volume will also be deleted. Any additional or secondary velumes will persist however.

- If you use an EBS-backed root volume, the root volume will not be terminated with its EC2 instance when the instance is brought offline. EBS-backed volumes are not temporary storage devices like Instance Store-backed volumes.

- EBS-backed Volumes are launched from an AWS EBS snapshot, as the name implies.

- Instance Store-backed Volumes are launched from an AWS S3 stored template. They are ephemeral, so be carefuel when shutting down an instance.

- Secondary instance stores for an instance store backed root device must be installed during the original provisioning of the server. You cannot add more after the fack. However, you can add EBS volumes to the came instance after the server's creation.

- With these drawbacks of Insstance Store volumes, why pick one? Because they have a very high IOPS reate. So while an Instance Store can't provide data persistence, it can provide mush higher IOPS compared to network attached storage like EBS.

- Further, Instance stores are ideal for temporary storage of information that changes frequently such as buffers, caches, scratch data, and other temporary content, or for data that is replicated across a fleet of instances, such as a load-balanced pool of web servers.

- When to use one over the other?
    - Use EBS for DB data, critical logs, and application configs.
    - Use instance storage for in-process data, non-critical logs, and transient application state.
    - Use S3 for data shared between systems like input data sets and processed results, or for static data needed by each new system when launched.

## EBS ncryption

- EBS encryption offers a straight-forward encryption solution for EBS resources that doesn't require you to build, maintain, and sercure your own key management infrastructure.

- it uses AWS key Management Service ([KMS](../Security/KMS.md)) customer master keys(CMK) when creating encrypted volumes and snapshots.
- > Amazon EBS sends a GenerateDataKeyWithoutPlaintext request to AWS KMS, specifying the CMK that you chose for volume encryption.

- You can encrypt both the root device and secondary volumes of an EC2 instance. When you create an encrypted EBS volume and attach it to a supported instance type, the following types of data are encrypted:
    - Data at rest inside the volume
    - All data moving between the volume and the instance
    - All snapshots created from the volume
    - All volumes created from those snapshots

- EBS encrypts your volume with a data key using the AES-256 algorithm.
- Snapshots of encrypted snapthoys are also encrypted. You can only share unencrypted snapshots.
- The old way of encrypting a root device was to create a snapshot of a procisioned EC2 instance. While making a copy of that snapshot, you then enabled encryption during the copy's creation. Finally, once the copy was encryptes, you then created an AMI from the encrypted copy and used to have an EC2 instance with encryption on the root device. Because of how complex this is, you can now simply encrypt root devices as part of the EC2 provisioning options.

---
reference
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonEBS.html
- https://stackoverflow.com/questions/62805025/aws-cmk-vs-data-key-clarification-question
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html?icmpid=docs_ec2_console
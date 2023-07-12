- The founder has provisioned an EC2 instance 1A which is running in region A. Later, he takes a snapshot of the instance 1A and then creates a new AMI in region A from this snapshot. This AMI is then copied into another region B. The founder provisions an instance 1B in region B using this new AMI in region B.
    At this point in time, what entities exist in region B?

- Answer: 1 EC2 instance, 1 AMI and 1 snapshot exist in region B
  - An Amazon Machine Image (AMI) provides the information required to launch an instance. You must specify an AMI when you launch an instance. When the new AMI is copied from region A into region B, **it automatically creates a snapshot in region B because AMIs are based on the underlying snapshots.** Further, an instance is created from this AMI in region B. Hence, we have 1 EC2 instance, 1 AMI and 1 snapshot in region B.

---

- A company uses Amazon S3 buckets for storing sensitive customer data. The company has defined different retention periods for different objects present in the Amazon S3 buckets, based on the compliance requirements. But, the retention rules do not seem to work as expected.
    Which of the following options represent a valid configuration for setting up retention periods for objects in Amazon S3 buckets? (Select two)

- Answer:
  - When you apply a retention periond to an object version ecplictly, you specify a `Retain Until Date` for the object version
    - You can place a retention period on an object version either explictly or through a bucket default setting. When you apply a retention period to an object version expliciyly, you specify a `Retain Until Date` for the object version. Amazon S3 stores the Retain Until Date setting in the object version's metadata and protects the object version until the retention period expires.
  - Defferent versions of a single object can have different retention medes and periods.
    - Like all other Object Lock settings, retention periods apply to individual object versions. Defferent versions of a single object can have different retention medes and periods.
    - For example, suppose that you have an object that is 15 days into a 30-day retention period, and you PUT an object into S3 with the same name and a 60-day retention period. In this case, your PUT succeeds, and S3 creates a new cersion of the object with a 60-day retention period. The olderversion maintains its original retention period and becomes deletable in 15 days.

---

- Can you identify those storage volume types that CANNOT be used as boot volumes while creating the instances? (Select two)

- Answer:
  - Throughput Optimized HDD (st1)
  - Cold HDD (sc1)

- The EBS volume types fall into two categories:

- SSD-backed volumes optimized for transactional workloads involving frequent read/write operations with small I/O size, where the dominant performance attribute is IOPS.

- HDD-backed volumes optimized for large streaming workloads where throughput (measured in MiB/s) is a better performance measure than IOPS.

- Throughput Optimized HDD (st1) and Cold HDD (sc1) volume types CANNOT be used as a boot volume, so these two options are correct.


- https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock-overview.html
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html
---

- A gaming company uses Amazon Aurora as its primary database service. The company has now deployed 5 multi-AZ read replicas to increase the read throughput and for use as failover target. The replicas have been assigned the following failover priority tiers and corresponding instance sizes are given in parentheses: tier-1 (16TB), tier-1 (32TB), tier-10 (16TB), tier-15 (16TB), tier-15 (32TB).
    In the event of a failover, Amazon Aurora will promote which of the following read replicas?

- Answer: Tier-1 (32TB)
  - Amazon Aurora features a distributed, fault-tolerant, self-healing storage system that auto-scales up to 128TB per database instance. It delivers high performance and availability with up to 15 low-latency read replicas, point-in-time recovery, continuous backup to Amazon S3, and replication across three Availability Zones (AZs).
  - For Amazon Aurora, each Read Replica is associated with a priority tier (0-15). In the event of a failover, Amazon Aurora will promote the Read Replica that has the highest priority (the lowest numbered tier).
  - If two or more Aurora Replicas share the same priority, then Amazon RDS promotes the replica that is largest in size. If two or more Aurora Replicas share the same priority and size, then Amazon Aurora promotes an arbitrary replica in the same promotion tier.
  - Therefore, for this problem statement, the Tier-1 (32TB) replica will be promoted.

---

- An IT company wants to review its security best-practices after an incident was reported where a new developer on the team was assigned full access to DynamoDB. The developer accidentally deleted a couple of tables from the production environment while building out a new feature.
    Which is the MOST effective way to address this issue so that such incidents do not recur?

- Answer: Use permissions boundary to control the maximum permissions employees can grant to the IAM principals.
  - A permissions boundary can be used to control the maximum permissions employees can grant to the IAM principals (that is, users and roles) that they create and manage. As the IAM administrator, you can define one or more permissions boundaries using managed policies and allow your employee to create a principal with this boundary. The employee can then attach a permissions policy to this principal. However, the effective permissions of the principal are the intersection of the permissions boundary and permissions policy. As a result, the new principal cannot exceed the boundary that you defined. Therefore, using the permissions boundary offers the right solution for this use-case.

- Permission Boundary Example:
    ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/ee05fc00-8110-407a-a8a9-6cdfeb5589d4)


---

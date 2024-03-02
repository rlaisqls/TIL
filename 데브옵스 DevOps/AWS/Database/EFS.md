
EFS provides a simple and fully managed elastic NFS file system for use within AWS. EFS automatically and instantly scales your file system storage capacity up or down as you add or remove files withour disrupting you application.

---

- In EFS, storage capacity is elastic (grows and shrinks automatically) and its size shanges based on adding or removing files.

- While EVS mounts one EBS volume to one instance, you can attach one EFS volume acress muliple EC2 instances.

- The EC2 instances communicate to the remote file system using the NFSv4 protocol. This makes it required to open up the NFS port for our security group (EC2 firewall rules) to allow inbound traffic on the port.

- Within an EFS volume, the mount target state will let you know what instances are available for mounting/

- With EFS, you only pay for th storage that you use so you pay as you go. No pre-provisioning required.

- EFS can scale up to the petabyte and van support thousands of concurrent NFS connections.

- Data is stored across multiple AZs in a region and EFS ensures read after write consistency.

- It is best for file storage that is accessed by a fleet of servers rather than just one server.

---
reference
- https://aws.amazon.com/efs/
- https://aws.amazon.com/ko/efs/faq/
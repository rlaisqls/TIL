# EFS

EFS provides a simple and fully managed elastic NFS file system for use within AWS. EFS automatically and instantly scales you file system storage capacity up or down as you add or remove files without disrupting your application.

--- 

- In EFS, storage capacity is elastic (grows and shrinks automatically) and its size changes based on adding or removing files.

- While EBS mounts on EBS volume to one instance, you can attach one EFS volume across multiple EC2 instances.

- The EC2 instances communicate to the remote file system using the NFSv4 protocol. This makes it required to open up the NFS port for our security group (EC2 firewall rules) to allow inbound traffic on that port.

- Within an EFS volume, the mount target state will let you know what instances are available for mounting

- With EFS, you only pay for the storage that you use so you pay as you go. No pre-provisioning required.

- EFS can scale up to the petabytes and can support thousands of concurrent NFS connections.

- Data is stored across multiple AZs in a region and EFS ensures read after write consistency.

- It is best for file storage that is accessed by a fleet of servers rather than just one server
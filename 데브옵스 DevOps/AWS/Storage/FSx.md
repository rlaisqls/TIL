
Amazon FSx for windows File Server provides a fully managed native Microsoft File System. 

- With FSx for Windows, you can easily move your Windows-based applications that require file storage in AWS.

- It is built on Windows Server and exists solely for Microsoft-based applications so if you need SMB-based file storage then choose FSx.

- FSx for Windows also permits connectivity between on-premise servers and AWS so those same on-premise servers can make use of Amazon FSx too.

- You can use Microsoft Active Directory to authenticate into the file system.

- Amazon FSx for Windows provides multiple levels of security and compliance to help ensure your data is protected. Amazon FSx automatically encrypts your data at-rest and in-transit.
  
- You can access Amazon FSx for Windows from a variety of compute resources, not just EC2.

- You can deploy your Amazon FSx for Windows in a single AZ or in a Multi-AZ configuration.

- You can use SSD or HDD for the storage device depending on your requirements.

- FSx for Windows support daily automated backups and admins in taking backups when needed as well.

- FSx for Windows removes duplicated content and compresses common content. By default, all data is encrypted at rest.


# Amazon FSx for Lustre

Amazon FSx for Lustre makes it easy and cost effective to launch and run the open source Lustre file system for high-performance computing applications. With FSx for Lustre, you can launch and run a file system that can process massive data sets at up to hundreds of gigabytes per second of throughput, millions of IOPS, and sub-millisecond latencies.

- FSx for Lustre is compatible with the most popular Linux-based AMIs, including Amazon Linux, Amazon Linux 2, Red Hat Enterprise Linux (RHEL), CentOS, SUSE Linux and Ubuntu.

- Since the Lustre file system is designed for high-performance computing workloads that typically run on compute clusters, choose EFS for normal Linux file system if your requirements don't match this use case.

- FSx Lustre has the ability to store and retrieve data directly on S3 on its own.

## Amazon FSx for NetApp ONTAP

- Amazon FSx for NetApp ONTAP is a storage service that allows you to launch and run fully managed NetApp ONTAP file systems in the AWS Cloud. It provides the familiar features, performance, capabilities, and APIs of NetApp file systems with the agility, scalability, and simplicity of a fully managed AWS service.

- Amazon FSx for NetApp ONTAP offers high-performance file storage that’s broadly accessible from Linux, Windows, and macOS compute instances via the industry-standard NFS, SMB, and iSCSI protocols. It enables you to use ONTAP’s widely adopted data management capabilities, like snapshots, clones, and replication, with the click of a button. In addition, it provides low-cost storage capacity that’s fully elastic and virtually unlimited in size, and supports compression and deduplication to help you further reduce storage costs.

---
reference
- https://aws.amazon.com/fsx/
- https://aws.amazon.com/ko/fsx/windows/
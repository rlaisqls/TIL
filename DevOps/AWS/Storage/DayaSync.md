
AWS DataSync is a secure, online service that automates and accelerates moving data between on premises and AWS Storage services.

DataSync can copy data between belows:

- Network File System (NFS)
- Server Message Block (SMB)
- Hadoop Distributed File Systems (HDFS)
- self-managed object storage
- AWS Snowcone
- Amazon Simple Storage Service (Amazon S3) buckets
- Amazon Elastic File System (Amazon EFS) file systems
- Amazon FSx for Windows File Server file systems
- Amazon FSx for Lustre file systems
- Amazon FSx for OpenZFS file systems
- Amazon FSx for NetApp ONTAP file systems

## Use cases

- **Migrate your data: **Quickly move file and object data to AWS. Your data is secure with in-flight encryption and end-to-end data validation.

- **Protect your data: **Securely replicate your data into cost-efficient AWS storage services, including any Amazon S3 storage class.

- **Archive your cold data: ** Reduce on-premises storage costs by moving data directly to Amazon S3 Glacier archive storage classes.

- **Manage your hybrid data workflows: **Seamlessly move data between on-premises systems and AWS to accelerate your critical hybrid workflows.

## diffence with other migration services

|Other service|Difference|
|-|-|
|Snowball Edge|AWS DataSync is ideal for **online data** transfers. You can use DataSync to migrate active data to AWS, transfer data to the cloud for analysis and processing, archive data to free up on-premises storage capacity, or replicate data to AWS for business continuity.<br>AWS Snowball Edge is ideal for **offline data** transfers, for customers who are bandwidth constrained, or transferring data from remote, disconnected, or austere environments.
|AWS Storage Gateway|Use AWS DataSync to migrate existing data to Amazon S3, and subsequently use the File Gateway configuration of AWS Storage Gateway to retain access to the migrated data and for ongoing updates from your on-premises file-based applications.<br>You can use a combination of DataSync and File Gateway to minimize your on-premises infrastructure while seamlessly connecting on-premises applications to your cloud storage. AWS DataSync enables you to automate and accelerate online data transfers to AWS Storage services. After the initial data transfer phase using AWS DataSync, File Gateway provides your on-premises applications with low latency access to the migrated data. When using DataSync with NFS shares, POSIX metadata from your source on-premises storage is preserved, and permissions from the source storage apply when accessing your files using File Gateway.
|S3 Transfer Acceleration|If your applications are already integrated with the Amazon S3 API, and you want **higher throughput for transferring large files to S3, you can use S3 Transfer Acceleration.**<br>If you want to **transfer data from existing storage systems** (e.g., Network Attached Storage), or from instruments that cannot be changed (e.g., DNA sequencers, video cameras), or if you want multiple destinations, you use AWS DataSync. DataSync also automates and simplifies the data transfer by providing additional functionality, such as built-in retry and network resiliency mechanisms, data integrity verification, and flexible configuration to suit your specific needs, including bandwidth throttling, etc.
|Transfer Family|If you currently use SFTP to exchange data with third parties, AWS Transfer Family provides a fully managed **SFTP, FTPS, and FTP transfer directly into and out of Amazon S3**, while reducing your operational burden.<br>If you want an **accelerated and automated data transfer between NFS servers, SMB file shares, Hadoop clusters, self-managed or cloud object storage, AWS Snowcone, Amazon S3, Amazon EFS, and Amazon FSx,** you can use AWS DataSync. DataSync is ideal for customers who need online migrations for active data sets, timely transfers for continuously generated data, or replication for business continuity.|

---

reference
- https://aws.amazon.com/datasync/faqs/
- https://aws.amazon.com/datasync
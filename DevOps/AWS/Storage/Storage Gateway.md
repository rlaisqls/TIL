
Storage Gateway is a service that connects on-premise environments with cloud-based storage in order to seamlessly and securely intergrate an on-prem application with a cloud storage backend. Storage Gateway comes in three flavors: File Gateway, Volume Gateway and Tape Gateway.

## Storage Gateway Key Details:

- The Storage Gateway service can either be a **physical device or a VM image downloaded onto a host in an on-prem data center**. It acts as a bridge to send or receive data from AWS.

- Storage Gateway can sit on top of VMWare's EXCi Hypervisor for Linux machine and Microsoft's Hyper-V hypervisor for Windows machines.
  
- The three types of Storage Gateways are below:
    - **File Gateway** - Operates via NFS or SMB and is used to store files in S3 over a network filesystem mount point in the supplied virtual machine. Simply put, you can think of a File Gateway as a file system mount on S3.
    - **Volume Gateway** - Operates via iSCSI and is used to store copies of hard disk drives or virtual hard disk drives in S3. These can be achieved via Stored Volumes or Cached Volumes. Simply put, you can think of Volume Gateway as a way of storing virtual hard disk drives in the cloud.
    - **Tape Gateway** - Operates as a Virtual Tape Library

- Relevant file information passing through Storage Gateway like file ownership, permissions, timestamps, etc. are stored as metadata for the objects that they belong to. Once these file details are stored in S3, they can be managed natively. This mean all S3 features like versiong, lifecycle management, bucket policies, cross region replication, etc. can be applied as a part of Storage Gateway.

- Applications interfacing with AWS over the Volume Gateway is done over the iSCSI block protocol. Data written to these volumes can be asynchronously backed up into AWS Elastic Blok Store (EBS) as point-in-time snapshots of the volumes' content. These kind of snapshots act as increamental backups that capture only changed state similar to a pull request in Git. Further, all snapshots are compressed to reduce storage costs.

- Tape Gateway offers a durable, cost-effective way of archiving and replicating data into S3 while getting rid of tapes (old-school data storage). The Virtual Yape Library (VTL), leveages existing tape-based backup infrastructure to store data on virtual tape cartridges that you create on the Tape Gateway. It's a great way to modernize and move backups into the cloud.

## Stored Volumes VS Cached Volumes

- Volume Gateway's **Stored Volumes** let you store data locally on-prem and backs the data up to AWS as a secondary data source. Stored Volumes allow low-latency access to entire datasets, while providing high availability over a hybrid cloud solution. Further, you can mount Stored Volumes on application infrastructure as iSCSI drives so when data is written to these volumes, the data is both written onto the on-prem hardware and asynchronously backed up as snapshots in AWS EBS or S3.
  - In the following diagram of a Stored Volume architecture, data is served to the user from the Storage Area Network, Network Attached, or Direct Attached Stoage within you data center. S3 exists just as a secure ans reliable backup.
    ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/c3037bd8-5280-4346-867d-83def895e911)

- Volume Gateway's Cached Volumes differ as they do not store the entire dataset locally like Stored Volumes. Instead, AWS is used as the primary data source and the local hardware is used as a caching layer. Only the most frequenfly used components are retained onto the on-prem-infrastructure while the remaining data is served from AWS. The minimizes the need to scale on-prem infrastructure while still maintaining low-latency access to the most referenced data.
  - In ther following diagram of a Cached Volume architecture, the most frequently accessed data is served to the user from the Storage Area Network, Network Attaches, or Direct Attached Storage within your data center. S3 serves the rest of the data from AWS. 
    ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/35ba8705-bb7e-4a0f-93bc-a8f41c0ba2e5)

---
reference
- https://docs.amazonaws.cn/storagegateway/index.html
- https://docs.amazonaws.cn/en_us/storagegateway/latest/vgw/StorageGatewayConcepts.html#storage-gateway-stored-volume-concepts
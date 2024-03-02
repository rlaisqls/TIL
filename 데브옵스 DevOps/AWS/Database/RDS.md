
RDS is managed service that makes it easy to set up, operate and scale a relational database in AWS. It provides cost-efficient and resizable capacity while automating or outsourcing time-consuming adming administration tasks such as hardware provisioning, database setup, patching and backups.

- RDS comes in six different flavors:
    - SQL Server
    - Oracle
    - MySQL Server
    - PostgreSQL
    - MariaDB
    - Aurora
- Think of RDS as the DB engine which various DBs sit on top of.
- RDS has two key features when scaling out:
  - Read replication for improved performance
  - Multi-AZ for high availablity
  
- In the database world, Online Transaction Processing (OLTP) differs from Online Analytical Processing (OLAP) in terms of the type of querying that you would do. OLTP serves up data for business logic that ultimately composes the core functioning of you platform or application. OLAP is to gain insights into the data that you have stored in order to make better strategic decisions as a company.

- RDS runs on virtual machine, but you do not have access to those machins. You cannot SSH into an RDS instance so therefore you cannot patch the OS. This means that AWS is responsible for th security and maintenance of RDS. You can provision an EC2 instance as a database if you need or want to manage the underlying server yourselt, but not with a RDS engine.

- SQS queues can be used to store pending database writes if you applicatio is struggling under a high write load. These writes can then be added to the database when the database is ready to process them. Adding more IOPS will also help, but this alone will not wholly eliminate the chance of writes being lost. A queue however ensures that writes to the DB do not become lost.
  
## RDS Multi-AZ

- Disaster recovery in AWS always looks to ensure standby copies of resources are maintained in a seperate geographical area. This way, if a diater (natural disaster, political conflict, etc.) ever struck where your original resources are, the copies would be unaffected.

- When you provision a Multi-DB Instance Amazon RDS auttomatically creates a primary DB instance and synchronously replicates the data to a standby instance in a differnt AZ. Each AZ runs on its own physically distinct, independent infrastructure, and is engineered to be highly reliable.

- With a Multi-AZ configuration, EC2 connects to its RDS data store using a DNS address macked as a connection string. If the primary DB fails, Multi-AZ is smart enough to detext that failure and automatically update the DNS address to point at the secondary. No manual intervention is required and AWS takes care of swapping the IP address in DNS.

- Multi-AZ feature allows for high availability across availability zones and not regions.

- During a failover, the recovered former primary becomes the new secondary and the promoted secondary becomes primary. Once the original DB is recovered, there will be a sync process kucked off where the two DBs mirror each other one to sync up on the new data that the failed former primary might have missed out on.

- You can force a failover for a Multi-AZ setup by rebooting the primary instance.

- With a Multi-AZ RDS configuration, backups are taken from the standby.

## RDS Read Replicas

- Read Replication is exclusively used for perfoemance enhancement.

- With a Read Replica configuration, EC2 connects to the RDS backend using a DNS address and every write that is received by the master satabase is also passed onto a DB secondary so that it becomes a perfect copy of the master because the secondary DBs can be queried for the same data.

- However, if the master DB were to fail, there is no automatic failover. You would have to manually create a new connection string to sync with one of the read replicas so that it becomes a master on its own. Then you'd have to update your EC2 instances to point at the read replica. You can have up to five copies of your master DB with read replication.

- You can promote read replicas to be their very own production database if needed.

- Each Read Replica will have its own DNS endpoint.
 
- Automated backups must be enabled in order to use read replicas.
  
- You can have read replicas with Multi-AZ turned on or have the read replica in an entirely separate region. You can even have read replicas of read replicas, but watch out for latency or replication lag.
    The caveat for Read Replicas is that they are subject to small amounts of replication lag. This is because they might be missing some of the latest transactions as they are not updated as quickly as primaries. Application designers need to consider which queries have tolerance to slightly stale data. Those queries should be executed on the read replica, while those demanding completely up-to-date data should run on the primary node.


---
reference 
- https://aws.amazon.com/ko/rds/
- https://aws.amazon.com/ko/rds/features/
- https://aws.amazon.com/ko/rds/faqs/
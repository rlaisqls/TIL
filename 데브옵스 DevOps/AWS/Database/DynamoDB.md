# DynamoDB

Amazon DynamoDB is a key-balue and document database that delivers single-digit milisecond performance at any scal. It's a fully managed, multiregion, millisecond performance at any scale. It's a fully managed, multiregion, muultimaster, durable non-SQL database, It comes with build-in security, backup and restore, and in-memory caching for internet-scale applications.

---

- The main components of DynamoDB are:
    - a collection which serves as the foundational table
    - a document which is equivalent to a row in a SQL database
    - key-value pairs which are the fields within the document or row

- The convenience of non-relational DBs is that each row can look entirely differnt based on your usecase. There doesn't need to be uniformity. For example, if you need a new column for a particular entry you don't also need to ensure that that column exists for the other entries.

- DynamoDB supports both document and key-value based models. It is a great fit for mobile, web, gaming, ad-tech, IoT, etc.

- DynamoDB is stored via SSD which is why it is so fast.

- It is spread across 3 geographically distinct data centers.

- The default consistency model is Eventually Consistent Reads, but there are also Strongly Consistent Reads.

- The differnce between the two consistency models is the one second rule.
    With Eventual Consistent Reads, all copies off data are usually identical within one second after a write operation. A repeated read after a short period of time should return the updated data.
    However, if you need to read updated data within or less than a second and this needs to be a guarantee, then strongly consistent reads are your best bet.

- If you face a scenario that the schema, or the structure of your data, to change frequently, then you have to pick a database which procides a non-rigid and flexible way of adding or removing new types of data. This is a classic example of choosing between a relational database and non-relational (NoSQL) database. In this scenario, pick DynamoDB.

- A relational database system does not scale well for the following readons:
    - It normalizes data and stores it on multiple tables that require multiple queries to write to disk.
    - It generally incurs the performance costs of an ACID-compliant transaction system.
    - It uses expensive joins to reassemble required views of query results.

- High cardinality is good for DynamoDB I/O performance. The more distinct your partition ket calues are, the better. It make it so that the requests sent will be spread acress the partitioned space.

- DynamoDB makes use of parallel processing to achieve predictable performance. You can visualize each pertition or node as an independent DB server of fixed size with each partition or node responsible for a defined block of data. In SQL terminology, this conceppt is known as sharding but of course DynamoDB is not a SQL-based DB. With DynamoDB, data is dtored on SSD.

## DynamoDB Accelerator (DAX)

<img width="717" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/34fe0551-7aff-494b-a7bc-30cd4f168938">

- Amazon DynamoDB Accelerator (DAX) is a fully managed, highly available, in-memory cache that can reduce Amazon DynamoDB response times from millisecond to microseconds, even at millions of requests per second.

- With DAX, your applications remain fast and responsice, even when unprecedented request volumes come your way. There is no tuning requires.

- DAX lets you scale on-demand out to a ten-node cluster, giving you milions of requests per second. And is does more than just increase read performance by having write through cache. This improves write performance as well.

- Just like DynamoDB, DAX is fully managed. You no loger need to worry about management tasks such as hardware or software provisioning, setup and configuration, software patching, operaiting, a reliable, distributed cache cluster, or relication data over multiple instances as you scale.
    This means there is no need for developers to manage the caching logic. DAX is completely compatible with existing DynamoDB API calls.

- DAX is designed for HA so in the event of a failure of one AZ, it will fail over to one of its replicas in another AZ. This is also managed automatically.

## DynamoDB Streams

- A DynamoDB stream is an ordered flow of information about changes to items in an Amazon DynamoDB table. When you enable a stream on a table, DynamoDB captures information about every modification to data items in the table.

- Amazon DynamoDB is integrated with AWS Lambda so that you can create triggers_piece of code that automatically respond to events in DynamoDB Streams.
    Immediately after an item in the table is modified, a new record appears in the table's stream. AWS Lambda polls the stream and invokes your Lambda function synchronously when it detects new stream records. The Lambda function can perform any actions you specify, such as sending a notification or initiating a workflow.

- Whenever an application creates, updates, or deletes items in the table, DynamoDB Streams writes a stream record with the primary key attribute(s) of the items that were modified. A stream record contains information about a data modification to a single item in a DynamoDB table. You can configure the stream so that the stream records capture additional information, such as the "before" and "after" images of modified items.

---
reference
- https://docs.aws.amazon.com/pdfs/AWSEC2/latest/UserGuide/ec2-ug.pdf#AmazonEBS
- https://aws.amazon.com/ko/dynamodb/dax/
- https://www.daddyprogrammer.org/post/13990/dynamodb-stream/
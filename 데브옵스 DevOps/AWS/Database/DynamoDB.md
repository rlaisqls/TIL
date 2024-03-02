
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

## Read/write capacity mode

Amazon DynamoDB has two read/write capacity modes for processing reads and writes on your tables:

- On-demand
- Provisioned (default, free-tier eligible)

The read/write capacity mode controls how you are charged for read and write throughput and how you manage capacity. You can set the read/write capacity mode when creating a table or you can change it later.

When you switch a table from provisioned capacity mode to on-demand capacity mode, DynamoDB makes several changes to the structure of your table and partitions. **This process can take several minutes**. During the switching period, your table delivers throughput that is consistent with the previously provisioned write capacity unit and read capacity unit amounts. When switching from on-demand capacity mode back to provisioned capacity mode, your table delivers throughput consistent with the previous peak reached when the table was set to on-demand capacity mode.

Consider the following when you update a table from on-demand to provisioned mode:

- If you're using the AWS CLI or AWS SDK, choose the right provisioned capacity settings of your table and global secondary indexes by using Amazon CloudWatch to look at your historical consumption (ConsumedWriteCapacityUnits and ConsumedReadCapacityUnits metrics) to determine the new throughput settings.
- If you are switching from on-demand mode back to provisioned mode, make sure to set the initial provisioned units high enough to handle your table or index capacity during the transition.

### On-demand mode

Amazon DynamoDB on-demand is a flexible billing option capable of serving thousands of requests per second without capacity planning. DynamoDB on-demand offers pay-per-request pricing for read and write requests so that you pay only for what you use.

When you choose on-demand mode, DynamoDB instantly accommodates your workloads as they ramp up or down to any previously reached traffic level.

If a workload’s traffic level hits a new peak, DynamoDB adapts rapidly to accommodate the workload. Tables that use on-demand mode deliver the same single-digit millisecond latency, service-level agreement (SLA) commitment, and security that DynamoDB already offers. You can choose on-demand for both new and existing tables and you can continue using the existing DynamoDB APIs without changing code.

On-demand mode is a good option if any of the following are true:

- You create new tables with unknown workloads.
- You have unpredictable application traffic.
- You prefer the ease of paying for only what you use.

The request rate is only limited by the DynamoDB throughput default table quotas, but it can be raised upon request. For more information, see [Throughput default quotas.](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ServiceQuotas.html#default-limits-throughput)

Tables can be switched to on-demand mode once every 24 hours. Creating a table as on-demand also starts this 24-hour period. Tables can be returned to provisioned capacity mode at any time.

**Read request units and write request units**

- For on-demand mode tables, you don't need to specify how much read and write throughput you expect your application to perform. DynamoDB charges you for the **reads and writes that your application performs on your tables in terms of read request units and write request units.**

- DynamoDB read requests can be either strongly consistent, eventually consistent, or transactional.

  - A strongly consistent read request of an item up to 4 KB requires one read request unit.
  - An eventually consistent read request of an item up to 4 KB requires one-half read request unit.
  - A transactional read request of an item up to 4 KB requires two read request units.

- If you need to read an item that is larger than 4 KB, DynamoDB needs additional read request units. The total number of read request units required depends on the item size, and whether you want an eventually consistent or strongly consistent read.

- For example, if your item size is 8 KB, you require 2 read request units to sustain one strongly consistent read, 1 read request unit if you choose eventually consistent reads, or 4 read request units for a transactional read request.

- For more information, see [here](https://docs.aws.amazon.com/ko_kr/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html).

**Peak traffic and scaling properties**

- DynamoDB tables using on-demand capacity mode automatically adapt to your application’s traffic volume. On-demand capacity mode instantly accommodates up to double the previous peak traffic on a table.

- For example, if your application’s traffic pattern varies between 25,000 and 50,000 strongly consistent reads per second where 50,000 reads per second is the previous traffic peak, on-demand capacity mode instantly accommodates sustained traffic of up to 100,000 reads per second. If your application sustains traffic of 100,000 reads per second, that peak becomes your new previous peak, enabling subsequent traffic to reach up to 200,000 reads per second.

- If you need more than double your previous peak on table, DynamoDB automatically allocates more capacity as your traffic volume increases to help ensure that your workload does not experience throttling.

- However, throttling can occur if you exceed double your previous peak within 30 minutes. For example, if your application’s traffic pattern varies between 25,000 and 50,000 strongly consistent reads per second where 50,000 reads per second is the previously reached traffic peak, DynamoDB recommends spacing your traffic growth over at least 30 minutes before driving more than 100,000 reads per second.

**Pre-warming a table for on-demand capacity mode**

- With on-demand capacity mode, the requests can burst up to double the previous peak on the table. Note that throttling can occur if the requests spikes to more than double the default capacity or the previously achieved peak request rate within 30 minutes. One solution is to pre-warm the tables to the anticipated peak capacity of the spike.

- To pre-warm the table, follow these steps:

  1. Make sure to check your account limits and confirm that you can reach the desired capacity in provisioned mode.

  2. If you're pre-warming a table that already exists, or a new table in on-demand mode, start this process at least 24 hours before the anticipated peak. You can only switch between on-demand and provisioned mode once per 24 hours.

  3. To pre-warm a table that's currently in on-demand mode, switch it to provisioned mode and wait 24 hours. Then go to the next step.
    If you want to pre-warm a new table that's in provisioned mode, or has already been in provisioned mode for 24 hours, you can proceed to the next step without waiting.

  4. Set the table's write throughput to the desired peak value, and keep it there for several minutes. You will incur cost from this high volume of throughput until you switch back to on-demand.

  5. Switch to On-Demand capacity mode. This should sustain the provisioned throughput capacity values.

### Provisioned mode

If you choose provisioned mode, you specify the number of reads and writes per second that you require for your application. You can use auto scaling to adjust your table’s provisioned capacity automatically in response to traffic changes.

This helps you govern your DynamoDB use to stay at or below a defined request rate in order to obtain cost predictability.

Provisioned mode is a good option if any of the following are true:

- You have predictable application traffic.
- You run applications whose traffic is consistent or ramps gradually.
- You can forecast capacity requirements to control costs.

**Read capacity units and write capacity units**

- If your application reads or writes larger items (up to the DynamoDB maximum item size of 400 KB), it will consume more capacity units.

- For example, suppose that you create a provisioned table with 6 read capacity units and 6 write capacity units. With these settings, your application could do the following:
  - Perform strongly consistent reads of up to 24 KB per second (4 KB × 6 read capacity units).
  - Perform eventually consistent reads of up to 48 KB per second (twice as much read throughput).
  - Perform transactional read requests of up to 12 KB per second.
  - Write up to 6 KB per second (1 KB × 6 write capacity units).
  - Perform transactional write requests of up to 3 KB per second.

---
reference
- https://docs.aws.amazon.com/pdfs/AWSEC2/latest/UserGuide/ec2-ug.pdf#AmazonEBS
- https://aws.amazon.com/ko/dynamodb/dax/
- https://www.daddyprogrammer.org/post/13990/dynamodb-stream/
- https://youtu.be/DdXK1XYJduw
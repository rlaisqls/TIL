
Amazon Glue is a serverless data integration service that makes it easy to discover, prepare, and combine data for analytics, machine learning, and application development.

AWS Glue uses other AWS services to orchestrate your ETL (extract, transform, and load) jobs to build data warehouses and data lakes and generate output streams. AWS Glue calls API operations to transform your data, create runtime logs, store your job logic, and create notifications to help you monitor your job runs. The AWS Glue console connects these services into a managed application, so you can focus on creating and monitoring your ETL work. The console performs administrative and job development operations on your behalf. You supply credentials and other properties to AWS Glue to access your data sources and write to your data targets.

AWS Glue takes care of provisioning and managing the resources that are required to run your workload. You don't need to create the infrastructure for an ETL tool because AWS Glue does it for you. When resources are required, to reduce startup time, AWS Glue uses an instance from its warm pool of instances to run your workload.

With AWS Glue, you create jobs using table definitions in your Data Catalog. **Jobs consist of scripts that contain the programming logic that performs the transformation**. You use triggers to initiate jobs either on a schedule or as a result of a specified event. You determine where your target data resides and which source data populates your target. With your input, AWS Glue generates the code that's required to transform your data from source to target. You can also provide scripts in the AWS Glue console or API to process your data.

### Data sources and destinations

AWS Glue for Spark allows you to read and write data from multiple systems and databases including:

- Amazon S3
- Amazon DynamoDB
- Amazon Redshift
- Amazon Relational Database Service (Amazon RDS)
- Third-party JDBC-accessible databases
- MongoDB and Amazon DocumentDB (with MongoDB compatibility)
- Other marketplace connectors and Apache Spark plugins

### Data streams

AWS Glue for Spark can stream data from the following systems:

- Amazon Kinesis Data Streams
- Apache Kafka

## Amazon Glue vs. Amazon EMR

- Amazon Glue works on top of the Apache Spark environment to provide a scale-out execution environment for your data transformation jobs. Amazon Glue infers, evolves, and monitors your ETL jobs to greatly simplify the process of creating and maintaining jobs.

- [Amazon EMR](EMR.md) provides you with direct access to your Hadoop environment, affording you lower-level access and greater flexibility in using tools beyond Spark.

## Glue Schema Registry

Amazon Glue Schema Registry, a serverless feature of Amazon Glue, enables you to validate and control the evolution of streaming data using schemas registered in Apache Avro and JSON Schema data formats, at no additional charge.

Through Apache-licensed serializers and deserializers, the Schema Registry integrates with:
- Java applications developed for Apache Kafka
- Amazon Managed Streaming for Apache Kafka (MSK)
- Amazon Kinesis Data Streams
- Apache Flink
- Amazon Kinesis Data Analytics for Apache Flink
- Amazon Lambda

When data streaming applications are integrated with the Schema Registry, you can improve data quality and safeguard against unexpected changes using compatibility checks that govern schema evolution. Additionally, you can create or update Amazon Glue tables and partitions using Apache Avro schemas stored within the registry.

---

- With AWS Glue DataBrew, you can explore and experiment with data directly from your data lake, data warehouses, and databases, including Amazon S3, Amazon Redshift, AWS Lake Formation, Amazon Aurora, and Amazon Relational Database Service (RDS). You can choose from over 250 prebuilt transformations in DataBrew to automate data preparation tasks such as filtering anomalies, standardizing formats, and correcting invalid values.
    <img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/97193cad-64e2-4194-87d6-99a9c67a6e3b" height=400px>

- Amazon Glue monitors job event metrics and errors, and pushes all notifications to Amazon CloudWatch. With Amazon CloudWatch, you can configure a host of actions that can be triggered based on specific notifications from Amazon Glue. For example, if you get an error or a success notification from Glue, you can trigger an Amazon Lambda function. Glue also provides default retry behavior that will retry all failures three times before sending out an error notification.

- Data integration is the process of preparing and combining data for analytics, machine learning, and application development. It involves multiple tasks, such as discovering and extracting data from various sources; enriching, cleaning, normalizing, and combining data; and loading and organizing data in databases, data warehouses, and data lakes. These tasks are often handled by different types of users that each use different products.

- Amazon Glue provides both visual and code-based interfaces to make data integration easier. Users can easily find and access data using the Amazon Glue Data Catalog. Data engineers and ETL (extract, transform, and load) developers can create and run ETL workflows. Data analysts and data scientists can use Amazon Glue DataBrew to visually enrich, clean, and normalize data without writing code.

- Amazon Glue provides all of the capabilities needed for data integration so that you can start analyzing your data and putting it to use in minutes instead of months.
  
---
reference
- https://docs.aws.amazon.com/ko_kr/glue/latest/dg/what-is-glue.html
- https://docs.aws.amazon.com/ko_kr/glue/latest/dg/how-it-works.html
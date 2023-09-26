# EMR

Amazon EMR (previously called Amazon Elastic MapReduce) is a managed cluster platform that simplifies running big data frameworks, such as Apache Hadoop and Apache Spark, on AWS to process and analyze vast amounts of data. 

[MapReduce](https://en.wikipedia.org/wiki/MapReduce) is a programming model and an associated implementation for processing and generating big data sets with a parallel, distributed algorithm on a cluster, EMR is provide feature to build  big data processing workload too.

Using these frameworks and related open-source projects, you can process data for analytics purposes and business intelligence workloads. Amazon EMR also lets you transform and move large amounts of data into and out of other AWS data stores and databases, such as Amazon Simple Storage Service (Amazon S3) and Amazon DynamoDB.

In a nutshell, EMR building and operating big data environments and applications. Related EMR features include easy provisioning, managed scaling, and reconfiguring of clusters, and EMR Studio for collaborative development. EMR lets you focus on transforming and analyzing your data without having to worry about managing compute capacity or open-source applications, and saves you money.

## Architecture

Amazon EMR service architecture consists of several layers, each of which provides certain capabilities and functionality to the cluster.

1. **Storage layer:** This layer includes the different file systems that are used with your cluster. There are several different types of storage options as follows.

2. **Cluster resource management layer:** The resource management layer is responsible for managing cluster resources and scheduling the jobs for processing data.

3. **Data processing frameworks layer:** This layer is the engine used to process and analyze data. There are many frameworks available that run on YARN or have their own resource management.
    Different frameworks are available for different kinds of processing needs, such as batch, interactive, in-memory, streaming, and so on. The framework that you choose depends on your use case.
    This impacts the languages and interfaces available from the application layer, which is the layer used to interact with the data you want to process. The main processing frameworks available for Amazon EMR are Hadoop MapReduce and Spark.

---

- Amazon EMR supports many applications, such as Hive, Pig, and the Spark Streaming library to provide capabilities such as using higher-level languages to create processing workloads, leveraging machine learning algorithms, making stream processing applications, and building data warehouses. In addition, Amazon EMR also supports open-source projects that have their own cluster management functionality instead of using YARN.

- You can set up CloudWatch alerts to notify you of changes in your infrastructure and take actions immediately. If you use Kubernetes, you can also use EMR to submit your workloads to Amazon EKS clusters. Whether you use EC2 or EKS, you benefit from EMR’s optimized runtimes which speed your analysis and save both time and money.

---
reference

- https://aws.amazon.com/emr/features/?nc=sn&loc=2&dn=1
- https://aws.amazon.com/emr/faqs/?nc=sn&loc=5

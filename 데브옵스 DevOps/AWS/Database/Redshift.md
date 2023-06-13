# Redshift

Amazon Redshift is a fully managed, petabyte-scale data warehouse service in the cloud. The Amazon Redshify service manages all of the work of setting up, operating, and scaling a data warehouse. These tasks include provisioning capacity, monitoring and backing up the cluster, and applying patches and upgrades to the Amazon Redshift engine.

---

- An Amazon Redshift cluster is a set of nodes which consistes of a leader node and one or more compute nodes. The type and number of compute nodes that you need depecds on the size of your data, the number of queries you will execute, and the query execution performance that you need.

- Redshify is used for business intelligence and pulls in very large and complex datasets to perform complex queries in order to gather insights from the data.

- It fits the usecase of Online Analytical Processing (OLAP). Redshift is a pworful technology for data discovery including capabilities for almost limitless report viewing, complex analytical calculations, and predictive "what if" scenario (budget, forecast, etc.) planning.

- Depending on your data warehoudsing needs you can start with a small single-node cluster and easily scale up to a leager, multi-node cluster as your requiremets change. You can add or remove compute nodes to the cluster withour any interruption to the service.

- If you intend to keep your cluster running for a year or longer, you can save money by reserving compute nodes for a one-year or three-year period.

- Redshift is able to achieve efficiency despite the many parts and pieces in its architecture through using columnar compression of data stores that contain similar data.
    In addition, Redshift does not require indexes or materialized views which means it can be relatively smaller in size compared to an OLTP database containing the same amount of information. Finally, when loading data into a Redshift table, Redshift will automatically down sample the data and pick the most appropriate compression scheme.

- Redshift is encrypted in transit using SSL and is encrypted at rest using AES-256. By default, Redshift will manage all keys, but you can do so too via AWS CloudHSM or AWS KMS.

## Redshift Spectrum:

- Amazon Redshift Spectrum is used to run queries against exabytes of unstructured data in Amazon S3, with no loading or ETL required.
  
- Redshift Spectrum queries employ massive parallelism to execute very fast against large datasets. Much of the processing occurs in the Redshift Spectrum layer, and most of the data remains in Amazon S3.

- Redshift Spectrum queries use much less of your cluster's processing capacity than other queries.

- The cluster and the data files in Amazon S3 must be in the same AWS Region.

- External S3 tables are read-only. You can't perform insert, update, or delete operations on external tables.

## Redshift Enhanced VPC Routing:

- When you use Amazon Redshift Enhanced VPC Routing, Redshift forces all traffic (such as COPY and UNLOAD traffic) between your cluster and your data repositories through your Amazon VPC.

- If Enhanced VPC Routing is not enabled, Amazon Redshift routes traffic through the Internet, including traffic to other services within the AWS network.

- By using Enhanced VPC Routing, you can use standard VPC features, such as VPC security groups, network access control lists (ACLs), VPC endpoints, VPC endpoint policies, internet gateways, and Domain Name System (DNS) servers.]

---
reference
- https://aws.amazon.com/redshift/?nc1=h_ls
- https://aws.amazon.com/redshift/features/?nc=sn&loc=2&dn=1
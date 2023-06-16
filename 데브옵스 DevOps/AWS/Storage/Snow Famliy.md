# Snowcone

Snowcone is the smallest AWS Snow family data transfer device. It can delivery 8TB Storage. Send data offline via device delivery or to AWS via AWS DataSync over the Internet

# Snowball

Snowball is a giant physical disk that is used for migrating high quantities of data into AWS. It is a peta-byte scale data transport solution. Using a large disk like Snowball helps to circumvent common large scale data transfer problems such as high network costs, long transfer times, and security concerns. Snowballs are extremely secure by defign and once the data transfer is complete, the snow balls are wiped clean of your data.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/30ca9d39-7718-4343-8764-679a0e86145f)

---

- Snowball is a strong choice for a data transfer job if you need a secure an dquick data transfer renging in the terabytes to many petabytes into AWS.

- Snowball can also be the right choice if you don't want to make expensice upgrades to your existing network infrastructure, if tou frequently experience large basklogs of data, if you're located in a physically isolated environment, or if you're in an area where high-speed internet connections are not available or cost-prohibitive.

- As a rule of thumb, if it takes more than one week to upload your data to AWS using the spare capacity of you existing internet connection, the you should condider using Snowball.

- For example, if you have a 100Mb connection that you can solely dedicate to transferring your data and you need to transfer 100TB of data in total, it will take more than 100 days for the transfer to complete over that connection. You can make the same transfer in about a week by using multiple Snowballs. 

- Here is a reference for when Snowball should be considered based on the number of days it would take to make the same transfer over san internet connection:
![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/1bdce7f4-49b4-4f94-844d-ea1256c3b5ad)

## Snowball Edge

- Snowball Edge is a specific type of Snowball that comes with both compute and storage capabilities via AWS Lambda and specvific EC2 instance types. This means you can run code within your snowball while your data is en route to an Amazon data center.
    This enables support of local workloads in remote or offline locations and as a result, Snowball Edge does not need to be limited to a data transfer service. An interesting use case is with airliners. Planes sometimes fly with snowball edges onboeard so they can store large amounts of flight data and compute necessary functions for the plane's own systems. Snobal Edges can also be clustered locally for even better performance.

Snowball Edge diveces have the following options for device donfigurations:

- **Snowball Edge Storage Optimized(for data transfer):** This Snowball Edge device option has a 100TB(80TB usable) storage capacity

- **Snowball Edge Storage Optimized (with EC2 compute functionality):** This Snowball Edge device optoion has up to 80TB of usable storage space, 40 vCPUs, and 80 GiB of memory for compute functionallity. It also comes with 1TB of additional SSD storage space for block volumes attached to EC2 AMIs.

- **Snowball Edge Compute Optimized:** This Snowball Edge device option has the most compute functionality. with 52 vCPUs, 208 GiB of memory, and 42TB(39.5 TB usable) plus 7.68 TB of dedicated MVMe SSD for compute instances for block storage volumes for EC2 compute instances, and 42 TB fo HDD capacity for either object storage or block storage volumes.

- **Snowball Edge Compute Optimizzed with GPU:** This Snowball Edge device option is identical to the Compute Optimized option, except for an installed GPU, equivalent to the on available in the P3 Amazon EC2 instance type. It has 42TB(39.5 TB of HDD storage that can be used for a combination of Amazon S3 compatible object storage and Amazon EBS compatible block storage volumes) plus 7.68 TB of dedicated NVMe SSD for compute instances. 

## Snowmobile

- Snowmobile is an exabyte-scale data transfer solution. It is a data transport solution for 100 petabytes of data and is contained within a 45-foot shipping container hauled by a semi-truck. This massive transfer makes sense if you want to move your entire data center with years of data into the cloud.

---
reference
- https://aws.amazon.com/blogs/storage/data-migration-best-practices-with-snowball-edge/
- https://aws.amazon.com/blogs/big-data/best-practices-using-aws-sct-and-aws-snowball-to-migrate-from-teradata-to-amazon-redshift/
- https://aws.amazon.com/blogs/architecture/migrating-to-an-amazon-redshift-cloud-data-warehouse-from-microsoft-aps/
# EBS gp2 vs gp3

- The main difference between gp2 and gp3, however, is gp3’s decoupling of IOPS, throughput, and volume size. This flexibility – the ability to configure each piece independently – is where the savings come in.

- On the opposite end of the spectrum, gp2 is quite inflexible. Sizing a gp2 volume involves considering both the storage and throughput requirements simultaneously, as volume performance has a baseline of 3 IOPS / GB, at a minimum of 100 IOPS. In other words, gp2 volume performance scales in proportion to volume size, until the 16,000 limit. As a result, gp2 volumes greater than 1TB are often oversized relative to the amount of data to be stored in order to increase the throughput.

- That’s why you’re probably paying too much for gp2. The extra TBs of storage capacity – and the money spent to enable it – are essentially wasted, as they were only necessary to increase the IOPS limit. Fortunately, there’s a better way: paying for only what you need with gp3.

|Volume Type|gp3|gp2|
|-|-|-|
|Short Description|Lowest cost SSD volume that balances price performance for a wide variety of transactional workloads|General Purpose SSD volume that balances price performance for a wide variety of transactional workloads|
|Durability|99.8% - 99.9% durability|99.8% - 99.9% durability|
|Use Cases|Virtual desktops, medium sized single instance databases such as Microsoft SQL Server and Oracle, latency sensitive interactive applications, boot volumes, and dev/test environments|Virtual desktops, medium sized single instance databases such as Microsoft SQL Server and Oracle, latency sensitive interactive applications, boot volumes, and dev/test environments|
|Volume Size|1 GB - 16 TB|1 GB - 16 TB|
|Max IOPS/Volume|16,000|16,000|
|Max Throughput/Volume|1,000 MB/s|250 MB/s|
|Max IOPS/Instance|260,000|260,000|
|Max Throughput/Instance|10,000 MB/s|7,500 MB/s|
|Price|$0.08/GB-month<br>3,000 IOPS free and<br>$0.005/provisioned IOPS-month over 3,000;<br>125 MB/s free and<br>$0.04/provisioned MB/s-month over 125|$0.10/GB-month|

---
reference
- https://aws.amazon.com/ebs/general-purpose/?nc1=h_ls
- https://cloudfix.aurea.com/blog/migrate-gp2-to-gp3-better-performance-lower-costs/#:~:text=The%20main%20difference%20between%20gp2,spectrum%2C%20gp2%20is%20quite%20inflexible.
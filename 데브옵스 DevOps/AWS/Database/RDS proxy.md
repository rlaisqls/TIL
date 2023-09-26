# RDS proxy

- By using Amazon RDS Proxy, you can allow your applications to pool and share database connections to improve their ability to scale.

- RDS Proxy **establishes a database connection pool and reuses connections in this pool**. This approach avoids the memory and CPU overhead of opening a new database connection each time. 

## Advantages

- RDS Proxy makes applications more resilient to database failures by automatically connecting to a standby DB instance while preserving application connections.
  
- By using RDS Proxy, you can also enforce AWS Identity and Access Management (IAM) authentication for databases, and securely store credentials in AWS Secrets Manager. And you can handle unpredictable surges in database traffic. Otherwise, these surges might cause issues due to oversubscribing connections or creating new connections at a fast rate.

- You can reduce the overhead to process credentials and establish a secure connection for each new connection. RDS Proxy can handle some of that work on behalf of the database.

---
reference
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.html
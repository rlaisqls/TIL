# CloudTrail

AWS CloudTrail is a service that enables governance, compliance, operational auditing, and risk auditing of your AWS account. With it, you can log, continously monitor, and retain account activity related to actions acress your AWS infrastructure. CloudTrail provieds event history of your AWS account activity including actions taken through the AWS Management Console, AWS SDKs, command line tools API calls, and other AWS services, It is a regional service, but you can configure Cloud Trail to collect trails in all regions.

---

- CloudTrail Events stores the last 90 days of events in its Event History. This is enabled by default and is no additional cost.
    This event history simplifies security analysis, resource change tracking, and troubleshooting.

- There are two types of events that can be logged in CloudTrail: management events and data events.

- Management events provide information about management operations that are performed on resources in your AWS account.

- Think of Management events as things normally done by people when they are in AWS. Examples:
    - a user sign in
    - a policy changed
    - a newly created security configuration
    - a logging rule deletion

- Data events provide information about the resource operations performed on or in a resource.

- Think of Data events as things normally done by software when hitting various AWS endpoints. Examples:
    - S3 object-level API activity
    - Lambda function execution activity

- By default, CloudTrail logs management events, but not data events. And CloudTrail Events log files are encrypted using Amazon S3 server-side encryption (SSE).
    You can also choose to encrypt your log files with an KMS key. As these logs are stored in S3, you can define Amazon S3 lifecycle rules to archive or delete log files automatically. If you want notifications about log file delivery and validation, you can set up Amazon SNS notifications.
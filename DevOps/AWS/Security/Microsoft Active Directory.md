
- In 2017, AWS introduced AWS Directory Service for Microsoft Active Directory, also known as AWS Microsoft AS, which is managed Microsotf Active Directory (AD) that is performance optimized for small and midsize businesses.

- AWS Microsoft AD offers you a highly available and cost-effective primary directory in the AWS Cloud that you can use to manage users, groups, and computers. It enables you to join Amazon EC2 instances to your domain easily and supports many AWS and third-party applications and services.
  
- It also can support most of the common usecases of small and midsize businesses. When you use AWS Mictosoft AD as your primary directory, you can manage access and provide SSO to cloud applications such as Microsoft Office 365. 

- If you have an existing Microsoft AD directory, you can also use AWS Microft AD as a resource forest that contains primarily computers and groups, allowing you to migrate your AD-aware applications to the AWS Cloud while using existing on-promises AD credentials.

### What do I get? 

- When you create an AWS Microsotf AD directory, AWS deploys two Microsoft AD domain controllers powerd by Microsoft Windows Server 2013 R2 in your VPC.
  
- As a managed service, AWS Microsoft AD configures directory replication, automates daily snapshots, and handles all patching and software updates. In addition, AWS Microsoft AD monitors and automatically recovers domain controllers in the event of a failure.

- AWS Microsoft AD has been optimized as a primary directory for small and midsize businesses with the capacity to support approximately 5,000 employees.
  
- With 1 GB of directory object storage, AWS Microsoft AD has the capacity to store 30,000 or more total directory objects (users, groups, and computers). AWS Microsoft AD also gives you the option to [add domain controllers](https://aws.amazon.com/blogs/security/how-to-increase-the-redundancy-and-performance-of-your-aws-directory-service-for-microsoft-ad-directory-by-adding-domain-controllers/) to meet the specific performance demands of your applications. You also can use AWS Microsoft AD as a resource forest with a [trust relationship](http://docs.aws.amazon.com/directoryservice/latest/admin-guide/tutorial_setup_trust.html) to your on-premises directory.

### How can I use it?

- With AWS Microsoft AD, you can share a single directory for multiple use cases.
  
- For example, you can share a directory to authenticate and authorize access for .NET applications, Amazon RDS for SQL Server with Windows Authentication enabled, and Amazon Chime for messaging and video conferencing.

- The following diagram shows some of the use cases for your AWS Microsoft AD directory, including the ability to grant your users access to external cloud applications and allow your on-premises AD users to manage and have access to resources in the AWS Cloud. 

<img width="709" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/829dea20-c9cb-4db0-8ac7-75567628b6cc">

- You can enable multiple AWS applications and services such as the AWS Management Console, Amazon WorkSpaces, and Amazon RDS for SQL Server to use your AWS Microsoft AD (Standard Edition) directory.

- When you enable an AWS application or service in your directory, your users can access the application or service with their AD credentials.

---
reference
- https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html
- https://learn.microsoft.com/ko-kr/training/modules/understand-azure-active-directory/3-compare-azure-active-directory-domain-services
- https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview


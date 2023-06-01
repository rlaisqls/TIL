# Identity Access Management (IAM)

**IAM** enables you to securely control access to AWS services and resources for your AWS users, groups, and roles. Using IAM, you can create and manage fine-grained access controls with permissions, specify who can access which services and resources, and under which conditions. IAM allows you to do the following:

## terms

**Users** - any individual end user such as an employee, system architect, CTO, etc.

**Groups** - any collection of similar people with shared permissions such as system administrators, HR employees, finance teams, etc. Each user within their specified group will inherit the permissions set for the group.

**Roles** - any software service that needs to be granted permissions to do its job, e.g- AWS Lambda needing write permissions to S3 or a fleet of EC2 instances needing read permissions from a RDS MySQL database.

**Policies** - the documented rule sets that are applied to grant or limit access. In order for users, groups, or roles to properly set permissions, they use policies. Policies are written in JSON and you can either use custom policies for your specific needs or use the default policies set by AWS.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/10ceb062-91ea-4921-a845-1932b4b272c2)

IAM Policies are separated from the other entities above because they are not an IAM Identity. Instead, they are attached to IAM Identities so that the IAM Identity in question can perform its necessary function.

## Key Details

- IAM is a global AWS services that is not limited by regions. Any user, group, role or policy is accessible globally.
  
- When creating you AWS account, you may have an existing identity provider internal to your company that offers Single Sign On(SSO). If this is the case, it is useful efficient, and entirely possible to reuse you existing identities on AWS. To do this, you let an IAM role be assumed by one of the Active Directories. This is because the IAM ID Fedeation feature allows an external service to have the ability to assume an IAM role.
  
- IAM Roles can be assigned to a service, such as an EC2 instance, prior to its first use/creation or after its been in used/created. You can change permissions as many times as you need. This can all be done by using both the AWS console and the AWS command line tools.
- 
- With IAM Policies, you can easily add tags that help define whish resources are accessible by whom. These tags are then used to control access via a particular IAM policy. For example, production an development EC2 instances might be tagged as such. This would ensure that people who should only be able to access development instances cannot access production instances.

- AWS has classified service processes into five levels of access: `List`, `Read`, `Write`, `Permissions management`, `Tagging `

## Priority Levels

- Explicit Deny: Denies access to a particular resource and this ruling cannot be overruled.

- Explicit Allow: Allows access to a particular resource so long as there is not an associated Explicit Deny.

- Default Deny (or Implicit Deny): IAM identities start off with no resource access. Access instead must be granted.

## IAM Security Tools:

### IAM Access Advisor(user level)
- Acess advisor shows service permissions granted to a user and when those services were last accessed.
- You can use this information to revise your policies.

### IAM Credentials Report(account level)
- a report that list all your account users and the status of their various credentials.

## best practice

- **Lock the root user's access key**
    Root access key has a most of the information related to the account, including credit cards, and payment information. So you should never create a root access key for security.
    Instead, you can make a seperate admin IAM to access to necessary.  If you apply an IAM policy to an individual or group, you must apply only the authentication required to perform the process.

- **Enable MFA to authenticated user**
    To enhance security, we apply multi-factor authentication (MFA) for IAM users who are granted access to critical resources or API operations.

- **Monitoring AWS account's activity**
    Use AWS's logging capabilities to increase security by checking what users have done on their accounts and the resources they have used.
    The log file shows the operation time and date, the source IP of the operation, and the operation that failed due to insufficient privileges. Through these records, it is possible to check whether there is an abnormal approach.
    

---
reference
- https://medium.com/@tkdgy0801/aws-solutions-architect-associate-certificate-study-%EA%B3%B5%EC%8B%9D-%EB%AC%B8%EC%84%9C-%EC%A0%95%EB%A6%AC-part-3-b14f3e4005b
- https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
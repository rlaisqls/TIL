
- **Change your account settings.** This includes the account name, email address, root user password, and root user access keys. Other account settings, such as contact information, payment currency preference, and AWS Regions, don't require root user credentials.

- **Restore IAM user permissions.** If the only IAM administrator accidentally revokes their own permissions, you can sign in as the root user to edit policies and restore those permissions.

- **Activate IAM access to the Billing and Cost Management console.**

- **View certain tax invoices.** An IAM user with the `aws-portal:ViewBilling` permission can view and download VAT invoices from AWS Europe, but not AWS Inc. or Amazon Internet Services Private Limited (AISPL).

- **Close your AWS account.**

- **Register as a seller in the Reserved Instance Marketplace.**

- **Configure an Amazon S3 bucket to enable MFA (multi-factor authentication).**

- **Edit or delete an Amazon Simple Queue Service (Amazon SQS) resource policy that denies all principals.**

- **Edit or delete an Amazon Simple Storage Service (Amazon S3) bucket policy that denies all principals.**

- **Sign up for AWS GovCloud (US).**

- **Request AWS GovCloud (US) account root user access keys from AWS Support.**

- **In the event that an AWS Key Management Service key becomes unmanageable, you can recover it by contacting AWS Support as the root user.**

---
reference
- https://docs.aws.amazon.com/accounts/latest/reference/root-user-tasks.html
- https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user.html

```bash
aws_iam_policy.codebuild: Modifying... [id=arn:aws:iam::<AWS Account ID>:policy/bot-dev-CodeBuild-policy]
Error: Error updating IAM policy arn:aws:iam::<AWS Account ID>:policy/bot-dev-CodeBuild-policy: MalformedPolicyDocument: Policy document should not specify a principal.
 status code: 400, request id: ...
```

Here is the relevant fragment of the policy document (ref: Terraform doc) I was using:

```json
data "aws_iam_policy_document" "codebuild" {
  statement {
    sid = "EC2NICperms"
    effect = "Allow"
    actions   = [
      "ec2:CreateNetworkInterfacePermission"
    ]
  resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"]
  condition {
    test        = "StringEquals"
    variable    = "ec2:Subnet"
    values      = [
      var.pubnet1,
      var.pubnet2
    ]
  }
  principals {
    type = "Service"
    identifiers = ["codebuild.amazonaws.com"]
  }
}
```

This brings us to a fundamental (mis)unserstanding of [two different types of IAM policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html):

- **Identity Based**: attached to an IAM user, group or role
- **Resource based**: attached to AWS resources like S3 buckets, SQS queues etc.

> The Principal element specifies the user, account, service, or other entity that is allowed or denied access to a resource.

In simple terms, if access control defines Who has access to What, then the Principal is the Who, and the Resource is the What. In our case, the principal desired is exactly what is specified in the policy document, i.e. the AWS CodeBuild service.

An IAM role consists of a set of rules to allow or deny access to specified resources, i.e. an IAM policy and who is allowed to invoke the permissions listed in that IAM policy, i.e., a Trust relationship.

A role is an IAM identity, therefore we cannot use “Principal” in its policy. So how do we specify that only AWS CodeBuild service has access to the action and resource specified in the above policy? As the second quoted sentence above says, through a “Trust Policy” (seen in the console under “Trust relationships”). This is the Terraform version:

```json
data “aws_iam_policy_document” “sts_codebuild” {
    statement {
    sid = “STSassumeRole”
    effect = “Allow”
    actions = [“sts:AssumeRole”]
    principals {
      type = “Service”
      identifiers = [“codebuild.amazonaws.com”]
    }
  }
}
```

STS is Amazon’s Simple Token Service, which generates temporary credentials that allow the specified principals to “Assume Role”, which means take on the permissions mentioned in the IAM policies attached to this role. It is somewhat like Linux’s sudo mechanism, where you have users who are able to temporarily elevate privileges, and what privileges they elevate to are also defined in the sudoers file.

We can generate a role starting with the trust policy:

```json
resource “aws_iam_role” “codebuild” {
  name = “custom-codebuild-role”
  assume_role_policy = data.aws_iam_policy_document.sts_codebuild.json
}
```

And then attach the IAM policies to it:

```json
resource “aws_iam_policy” “codebuild” {
  name = “custom-CodeBuild-policy”
  policy = data.aws_iam_policy_document.codebuild.json
}
resource “aws_iam_role_policy_attachment” “codebuild” {
  role = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}
```

This fixes the “MalformedPolicyDocument” error and allows Terraform apply to run successfully, generating an IAM policy and trust relationship and an IAM role associated with them. This role can then be invoked by the principal specified (CodeBuild) in this case, to do whatever it needs to do, as long as you have included the appropriate permissions in the IAM policy document.

---
reference
- https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html
- https://stackoverflow.com/questions/70002403/malformedpolicydocument-policy-document-should-not-specify-a-principal
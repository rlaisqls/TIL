# CloudFormation

CloudFormation is an automated tool for provisioning entire cloud-based  environments. It is similar to Terraform where you cofify the instructions for what you want to have inside your application setup (X many web servers of Y type with a Z type DB on the backend, etc). It makes it a lot easier to just describe what you want in markup and have AWS do the actual provisioning work involved.

---

- The main usecase for CloudFormation is for advanced setups and production environments as it is complex ans has many robust features.
- CloudFormation templates can be used to create, update, and delete infrastructure.
- The templates are written in YAML or JSON
- A full CloudFormation setup is called a stack.
- Once a template is created, AWS will make the corresponding stack. This is the living and active representation of said template. One template can create an infinite number of stacks.
- The Resources field is the only mandatory field when creating a CloudFormation template
- Rollback triggers allow you to monitor the creation of the stack as it's built. If an error occurs, you can trigger a rollback as the name implies.
- [AWS Quick Starts is composed of many high-quality CloudFormation stacks designed by AWS engineers.](https://aws.amazon.com/quickstart/?quickstart-all.sort-by=item.additionalFields.updateDate&quickstart-all.sort-order=desc)
- An example template that would spin up an EC2 instance
  ```yml
    Resources:
        Type: 'AWS::EC2::Instance'
        Properties:
            ImageId: !Ref LatestAmiId
            Instance Type: !Ref Instance Type
            KeyName: !Ref Keyname
  ```

- For any Logical Resources in the stack, CloudFormation will make a corresponding Physical Resources in your AWS account. It is CloudFormation’s job to keep the logical and physical resources in sync.
- A template can be updated and then used to update the same stack.


---
reference
- https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/
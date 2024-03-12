
Terratest has a pretty simple premise. It is ans open-source testing framework created by Terragrunt the includes helper functions for testing terraform code by providing a simple, reusable, and easy-to-use interface for creating and running automated tests on cloud resources.

It's able to apply terraform code, provision the resources, run the test cases, and then destroy everything. Terratest is most beneficially used for testing terraform modules to make sure that the modules work as expected before being consumed to create real infrastructues.

There’s a common pitfall of testing for basic or obvious tests that don’t really provide any use. For instance, testing a terraform module that creates an s3 bucket to make sure it creates the s3 bucket is almost as bad as testing whether 1 == 1. We can trust terraform to create what we tell it to. And if there is a syntax error in the terraform code, it will be obvious when the apply fails and tells us what mistake we are making.

Tests should be insightful and designed to catch instances when the apply will still complete successfully, but the final infrastructure is not what we are expecting. That’s the sweet spot where terratest can truly shine.

# Interconnectivity and Functionality of Resources

- Let's say we have a terraform module that creates an ECS clustser and runs tasks on that cluster. If you've ever created an ECS cluster using EC2 as the launch type, you'll know we need to create a decent amount of infrastructure to run ECS on top of.
- Not only do we need to create the ECS cluster, ECR repository, ECS service, and ECS task definition, but we also need to create the EC2s that ECS will use to place tasks on. And that includes an ASG, launch template, capacity provider, etc.
- And we'll also need to create a load balancer to send traffic to our tasks running on ECS. For that we'll need an ALB, target group, listeners, stc. Not to mention all the additional resources you'll need to properly configure your networking and security, such as IAM roles and security groups.

<br/>

- Terraform is fully capable of creating each of these resources and we can trust that terraform will create whay we've declaratively defined. But what about how these resources interact with each other? A terraform apply will tell us that all the resources have been created, but what terraform can't tell us is whether our EC2 instances have joined the ECS cluster, or if the tasks running on ECS are in a running state, or if our app is even accessible through the load balancer. These are behaviors that happen outside of the resource creation.

- The interconnectivity between resources and their functionality is just as important as the creation of the resources. If not properly tested, we could end up with a broken environment that passes a terraform apply flawlessly.

- This is exactly the type of terraform module that could benefit from using terratest to validate its functionality. Let's look at some examples of how we would do that:

## Instance Count

Let's say we want to make sure that the EC2 instances are joining the cluster properly. There are a few issues that could cause our instances to not be able to join the cluster, ssuch as an issue with the ECS agent or IAM permissions. We want to make sure that any changes we make to the modulw don't affect the ability of our instances to join the cluster.

For this, we will create a test case in our terratest to make sure that our cluster's instance count is as expected.

```go
func TestECSClusterInstanceCount(t *testing.T) {

	// Generate a random AWS region to use for the test
	awsRegion := "us-west-2"

	// Generate a random name to use for the ECS cluster and Terraform resources
	ecsClusterName := fmt.Sprintf("ecs-cluster-%s", random.UniqueId())

	// Define the Terraform module that creates the ECS cluster
	terraformOptions := &terraform.Options{
		TerraformDir: "./ecs-cluster",
		Vars: map[string]interface{}{
			"ecs_cluster_name": ecsClusterName,
			"aws_region":       awsRegion,
			"instance_type":    "t2.micro",
			"instance_count":   3,
		},
	}

	// Create the ECS cluster using Terraform
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Create an AWS session to use for the test
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))

	// Create an ECS client using the AWS SDK
	ecsClient := ecs.New(sess, aws.NewConfig().WithRegion(awsRegion))

	// Get the ECS cluster by name
	describeClustersInput := &ecs.DescribeClustersInput{
		Clusters: []*string{aws.String(ecsClusterName)},
	}
	describeClustersOutput, err := ecsClient.DescribeClusters(describeClustersInput)
	if err != nil {
		t.Fatalf("Failed to describe ECS cluster: %s", err)
	}
	assert.Len(t, describeClustersOutput.Clusters, 1)

	// Get the instance count of the ECS cluster
	instanceCount := aws.Int64Value(describeClustersOutput.Clusters[0].RegisteredContainerInstancesCount)

	// Assert that the instance count matches the expected value
	expectedInstanceCount := int64(3)
	assert.Equal(t, expectedInstanceCount, instanceCount)
}
```

- This test functions as an important check on the terraform module to make sure that the EC2s and autoscaling group are properly associated with the cluster. It uses the AWS SDK to get the instance count of the cluster and assert that it matches the expected value. 

- Terraform alone would tell us that the instances have been created, but only terratest can tell us that the instances have joined the cluster.

## Running Task Count

- ECS is designed to run tasks on the cluster, but there are a multitude of issues that could cause our tasks to fail before reaching a steady state.

- It could be related to permissions, network connectivity, or even an issue with the application the task is running. Terraform can tell us that the ECS service is created ans starting tasks, but terraform has no idea if those tasks are constantly failing or stopping. Enter terratest:

```go
func TestECSServiceTaskCount(t *testing.T) {
	// Generate a random AWS region to use for the test
	awsRegion := "us-west-2"

	// Generate a random name to use for the ECS service, task definition, and Terraform resources
	ecsServiceName := fmt.Sprintf("ecs-service-%s", random.UniqueId())
	taskDefinitionName := fmt.Sprintf("task-def-%s", random.UniqueId())

	// Define the Terraform module that creates the ECS service and task definition
	terraformOptions := &terraform.Options{
		TerraformDir: "./ecs-service",
		Vars: map[string]interface{}{
			"ecs_service_name":       ecsServiceName,
			"task_definition_name":   taskDefinitionName,
			"aws_region":             awsRegion,
			"container_image":        "nginx:latest",
			"container_port":         80,
			"desired_task_count":     3,
			"launch_type":            "FARGATE",
			"fargate_platform_arn":   "arn:aws:ecs:us-west-2:123456789012:platform/awsvpc",
			"subnet_ids":             []string{"subnet-12345678", "subnet-23456789"},
			"security_group_ids":     []string{"sg-12345678"},
			"assign_public_ip":       true,
			"task_execution_role_arn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
		},
	}

	// Create the ECS service and task definition using Terraform
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Create an AWS session to use for the test
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))

	// Create an ECS client using the AWS SDK
	ecsClient := ecs.New(sess, aws.NewConfig().WithRegion(awsRegion))

	// Get the ECS service by name
	describeServicesInput := &ecs.DescribeServicesInput{
		Cluster:  aws.String("default"),
		Services: []*string{aws.String(ecsServiceName)},
	}
	describeServicesOutput, err := ecsClient.DescribeServices(describeServicesInput)
	if err != nil {
		t.Fatalf("Failed to describe ECS service: %s", err)
	}
	assert.Len(t, describeServicesOutput.Services, 1)

	// Get the task count of the ECS service
	taskCount := aws.Int64Value(describeServicesOutput.Services[0].RunningCount)

	// Assert that the task count matches the expected value
	expectedTaskCount := int64(3)
	assert.Equal(t, expectedTaskCount, taskCount)
}
```

- This terratest function uses the AWS SDK to get the running task count of the service and assert that is matches the expected value. If there is an issue with how the task is configured, terratest will inform the user.

## Network Health Checks

- Another important area that requires testing is the networking. It's great that terraform can verify that it's built all our resources, but that won't tell us that our resources are properly talking to each other.
- In our ECS example, we are creating a load balancer to send traffic to our tasks running in the cluster. A good way to verify that our endpoint can reach the application is to make sure we have health checks that aren't failing. That is something we can test with terratest.

```go
func TestTargetGroupHealthCheck(t *testing.T) {

	// Generate a random name to use for the Target Group
	targetGroupName := fmt.Sprintf("test-tg-%s", random.UniqueId())

	// Set up an AWS session and create a new Target Group
	awsRegion := "us-west-2" // Replace with your desired AWS region
	awsSession := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
	elbv2Client := elbv2.New(awsSession)
	targetGroupArn, err := aws.CreateALBTargetGroup(t, awsRegion, targetGroupName)
	if err != nil {
		t.Fatalf("Failed to create Target Group: %v", err)
	}

	// Wait for the Target Group to become active
	err = aws.WaitForALBTargetGroupAvailability(t, elbv2Client, targetGroupArn)
	if err != nil {
		t.Fatalf("Failed waiting for Target Group to become active: %v", err)
	}

	// Check the Target Group health checks
	targetGroupHealthCheckResult, err := elbv2Client.DescribeTargetHealth(&elbv2.DescribeTargetHealthInput{
		TargetGroupArn: targetGroupArn,
	})
	if err != nil {
		t.Fatalf("Failed to describe Target Group health: %v", err)
	}

	// Check that all targets in the Target Group are healthy
	for _, targetHealth := range targetGroupHealthCheckResult.TargetHealthDescriptions {
		assert.Equal(t, "healthy", *targetHealth.TargetHealth.State, "Target %s is not healthy", *targetHealth.Target.Id)
	}
}
```

- This terratest function will check the health of our target group to make sure that the target is healthy. This will help us verify that traffic can properly flow to our ECS cluster.

---
reference
- https://gist.github.com/DanielWsk/f2f9aef6aca0a9a3df597b1103cb8d02
- https://spacelift.io/blog/what-is-terratest
- https://opendevops.academy/terratest-test-a-kubernetes-deployment-and-service-890ec4d1bfd0
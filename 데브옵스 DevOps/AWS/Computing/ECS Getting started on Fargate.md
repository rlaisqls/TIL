
Amazon Elastic Container Service (Amazon ECS) is a highly scalable, fast, container management service that makes it easy to run, stop, and manage your containers. You can host your containers on a serverless infrastructure that is managed by Amazon ECS by launching your services or tasks on AWS Fargate.

Let's start to build ECS using linux container on Fargate

## Step 1: Create the cluster

Create a cluster that uses the default VPC.

Before you begin, assign the appropriate IAM permission. For more information, see Cluster examples.

1. Open the console at https://console.aws.amazon.com/ecs/v2.
2. From the navigation bar, select the Region to use.
3. In the navigation pane, choose Clusters.
4. On the Clusters page, choose Create cluster.
5. Under Cluster configuration, for Cluster name, enter a unique name.
6. (Optional) To turn on Container Insights, expand Monitoring, and then turn on Use Container Insights.
7. (Optional) To help identify your cluster, expand Tags, and then configure your tags.
    [Add a tag] Choose Add tag and do the following:
      - For Key, enter the key name.
      - For Value, enter the key value.
    [Remove a tag] Choose Remove to the right of the tag’s Key and Value.
8. Choose Create.

## Stap 2: Create task definition

A task definition is like a blueprint for your application. Each time you launch a task in Amazon ECS, you specify a task definition.

The service then know which Docker image to use for containers. how many containers to use in the task, and the resource allocation for each container.

1. In the navigation pane, choose Task Definitions.

2. Choose Create new Task Definition, Create new revision with JSON.

3. Copy and paste the following example task definition into the box and then choose Save.
   
```json
{
    "family": "sample-fargate", 
    "networkMode": "awsvpc", 
    "containerDefinitions": [
        {
            "name": "fargate-app", 
            "image": "public.ecr.aws/docker/library/httpd:latest", 
            "portMappings": [
                {
                    "containerPort": 80, 
                    "hostPort": 80, 
                    "protocol": "tcp"
                }
            ], 
            "essential": true, 
            "entryPoint": [
                "sh",
		"-c"
            ], 
            "command": [
                "/bin/sh -c \"echo '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
            ]
        }
    ], 
    "requiresCompatibilities": [
        "FARGATE"
    ], 
    "cpu": "256", 
    "memory": "512"
}
```

Let's look parameters on detail.

- **`name`**: string, required, maximum of 255 characters, numbers, hyphens, and lines
  
- **`image`**: String, required, image used to start the container. Images uploaded to Docker Hub are available by default.
When a new operation starts, the ECS container agent fetches the latest version of the designated image and tag to use in the container. (At this point, the job that is already running does not reflect the image update.)

**Memory**
There are hard and soft restrictions on how to limit the amount of memory in a container.

- **`memory`**: integer, non-required, amount of memory in MiB of the container to be hard limited. If the amount of memory is limited by the hard limit, the container stops when the specified memory is exceeded.  
  
- **`memoryReservation`**: integer, non-required, soft The amount of memory in the container to be restricted (MiB). If the amount of memory is limited by soft limitations.
    For example, if a container typically uses `128Mi`B of memory, but in some cases, its usage surges to `256MiB` for a short period of time, you can set the memory reservation to `128MiB` and the memory hard limit to `300MiB`.

- **`portMapping`**: Object array, non-essential, allows containers to access ports in host container instances to send and receive traffic. For job definitions using awsvpc network mode, only the container port should be specified. The hostPort should be empty or equal to the containerPort. This maps to the `-p` option in Docker run.
 
- **`ContainerPort`**: integer, required when using portMappings, container port number bound to the host port. If you use the container of the job as the Farge startup type, you must specify the exposed port using the container port.
 
- **`protocol`**: string, non-required, protocol used for port mapping ( tcp | udp ); default is tcp.

Define job definition parameters.

- **`family`**: Name of string, required, task definition, name to be versioned. The first job definition registered in a specific family is assigned a number 1, and thereafter, it is assigned a number sequentially.

- **`taskRoleArn`**: string, non-required, specify IAM roles allowed by job definition

- **`networkMode`**: A character string, not required, docker networking mode to be used for the container of the job. Valid values are none, bridge, awsvpc, host.
    - For none, the container is not connected to the external network.
    - For bridge, the task uses a docker base virtual network running on each container instance. (Default)
    - If host, maps the container port directly to the EC2 instance network interface.
    - The awsvpc network mode is required when using the Fargate start type.

## Step 3: Create the service

Create a service using the task definition.

1. In the navigation pane, choose Clusters, and then select the cluster you created in Step 1.
2. From the Services tab, choose Create.
3. Under Deployment configuration, specify how your application is deployes.
   1. For Task definition, choose the task definition you created in Step 2.
   2. For Service name, enter a name for your service.
   3. For Desired tasks, enter 1.
4. Under Networking, you can create a new security group or choose an existing security group for your task. 
5. Choose Create.

## Step 4: View you service

1. Open the console at https://console.aws.amazon.com/ecs/v2.
2. In the navigation pane, choose Clusters.
3. Choose the cluster where you ran the service.
4. In the Services tab, under Service name, choose the service you created in Step 3.
5. Choose the Tasks tab, and then choose the task in your service.
6. On the task page, in the Configuration section, under Public IP, choose Open address. The screenshot below is the expected output.

<img width="601" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/287a2039-7782-4ace-8460-5869a314a807">

## Step 5: Clean up

When you are finished using an Amazon ECS cluster, you should clean up the resources associated with it to avoid incurring charges for resources that you are not using.

Some Amazon ECS resources, such as tasks, services, clusters, and container instances, are cleaned up using the Amazon ECS console. Other resources, such as Amazon EC2 instances, Elastic Load Balancing load balancers, and Auto Scaling groups, must be cleaned up manually in the Amazon EC2 console or by deleting the AWS CloudFormation stack that created them.

1. In the navigation pane, choose Clusters.
2. On the Clusters page, select the cluster cluster you created for this tutorial.
3. Choose the Services tab.
4. Select the service, and then choose Delete.
5. At the confirmation prompt, enter delete and then choose Delete.
    Wait until the service is deleted.
6. Choose Delete Cluster. At the confirmation prompt, enter delete `cluster-name`, and then choose Delete. Deleting the cluster cleans up the associated resources that were created with the cluster, including Auto Scaling groups, VPCs, or load balancers.

---
reference
- https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/getting-started-fargate.html
# Cloud Agnostic Design

Agnostic is a term that refers to a kind of belief that does not determine the authenticity of religion, but it is often used in an extended sense in many fields. When it's commonly used, it means that you're not tied to a particular idea, concept, or theory.

It's same to Cloud Agnostic.

Storage, compute, and networking are at the heart of any cloud infrastructure. In addition, managed, unmanaged, and serverless services are available across multiple clouds. This enables you to design your workloads to run in the cloud of your choice while also providing the flexibility to switch to other clouds. If you aim for cloud-agnostic design.

It is sometimes necessary to be specific to cloud providers and locations. The utility used to detect sensitive data should not move data from the cloud, and scans should be performed locally. As a result, we should be able to deploy our solution and utility across multiple clouds, and cloud-agnostic design is the way to go.

Cloud Agnostic designs:

- Allows you to avoid vendor lock-in.
- Provides a broader range of location availability.
- Makes it easy to design hybrid cloud solutions.
- The ability to easily migrate to another cloud provider.

## Strategies

Let’s discuss strategies and most commonly used tools to achieve the cloud-agnostic design.

### 1. Containerization

- Containerization is supported by all major clouds. When deploying solutions with different stacks on different clouds, managed Kubernetes clusters come in handy. It assists you in orchestrating your microservices containers and is managed, so it offers excellent capabilities such as automated upgrades and HA features.

- Alternatively, you can also use RedHat OpenShift, DC/OS, and Docker Swarm for container orchestration.

### 2. Cloud Foundry

- CNCF ecosystem is vendor-neutral, made up of technologies that are open, accessible, resilient, manageable, and observable.

- Cloud Foundry provides flexible infrastructure which means you can deploy it to run your apps on your own computing infrastructure, or deploy on an IaaS like vSphere, AWS, Azure, GCP, or OpenStack.

<img width="547" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/20e8ecab-58d3-4d9a-91ca-380e98a87019">

### 3. Monitoring/instrumentation/observability

- Use open-source monitoring tools which can be easily integrated on all major clouds. Prometheus is used for monitoring and alerting, along with Grafana for dashboarding. It’s a popular and active CNCF supported open source project. below is the sample design on how Prometheus works with open-source tools such as Grafana.
    <img width="536" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/097b1b41-bab3-40db-8850-97246fc273b6">

### 4. Message Broker

- You have different options here as mentioned earlier you can have your own deployment of Kafka/RabbitMQ or you can use managed services available across all the clouds.
“KubeMQ is a Single Messaging Platform that runs on every environment, Edge, Multi-cloud, and On-prem. KubeMQ is deployable on all K8s platforms, eliminating the overhead of managing multiple messaging systems, creating true freedom, and control to run on any cloud without vendor lock-in.”

### 5. Serverless

- If your application needs serverless functions, all major cloud supports serverless functions (Azure Functions, AWS lambda function, and Google cloud functions) with all major programming language support.
In the example given below, Each AWS Lambda function has a corresponding Azure Functions.
    <img width="538" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/412668bb-dbbc-4ceb-9ad2-ab406032b27b">

### 6. Infrastructure as Code

Cloud service providers provide deployment templates that can be used to deploy resources on a specific cloud. Though it may be advantageous to deploy resources on a single cloud, more generic IaC configurations are more beneficial. For example, use Terraform templates or Ansible playbook to set up deployments on cloud providers.

---
reference
- https://medium.com/path-to-software-architect/cloud-agnostic-design-925c08e1d610
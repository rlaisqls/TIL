
Choosing the automation solution that works best for your organization is no easy task. There’s not a single "right" approach—you can automate your enterprise in multiple ways. Indeed, many IT organizations today use more than one automation tool, and a major consideration is how well they work together to achieve business goals. 

Other factors to keep in mind when evaluating automation tools include architecture (is it agent-based or agentless?), programming (is it declarative or procedural?), and language (is it data-serialized or domain-specific?). And of course your operating system.  It’s also important to understand the level of community support for each product and what each is primarily engineered to do, such as provisioning, configuration management, and compliance.    

# Each tool approaches IT automation differently

## Ansible

Known for its simplicity and ease of use, Ansible Automation Platform is an open source, command-line IT automation software application that uses YAML based `playbooks` to configure systems, deploy software, and orchestrate advanced workflows to support application deployment, system updates, networking configuration and operation, and more. It does not require the installation of an agent on managed nodes, which simplifies the deployment process. And it has strong support for cloud-based infrastructure.

### declarative and procedural programming

Ansible can be both **declarative and procedural**—many modules work declaratively, while other modules prefer a procedural programming approach. Additionally, some constructs in the Ansible language, such as conditionals and loops, allow the users to define a procedural logic. This mix offers you the flexibility to focus on what you need to do, rather than strictly adhere to one paradigm. 

### mutable infrastructure

Configuration mutability means that the configuration (of an infrastructure or an application) can be changed. For example, newer versions of applications can be provisioned by updating or modifying the existing resource instead of eliminating or replacing it. 

Ansible is designed assuming **configuration mutability**. The advantage of this approach is that the automation workflows are simple to understand and easy to troubleshoot. However, in certain scenarios, it can be challenging to deprovision resources without knowing the correct order of operations. 

### Configuration drift

Ansible helps you combat drift with Ansible Playbooks (automation workflows) that can be set up to detect drift. When drift is detected, it sends a notification to the appropriate person who can make the required modification and return the system to its baseline. 

Because Ansible uses a procedural programming approach, developers can more easily understand when and where their automation configuration is changing, making it faster to isolate a specific portion of the configuration and remediate the drift.

Depending on the complexity of the IT infrastructure, performing configuration changes on automation solutions that use a declarative programming approach (such as Terraform) can be much more challenging. As a result, sometimes IT organizations prefer to use Ansible to perform simple configuration changes rather than holistically reconfigure an entire IT system with a solution like Terraform.

## Terrafom

Terraform is a cloud infrastructure provisioning and deprovisioning tool with an [infrastructure as code (IaC)](https://www.redhat.com/en/topics/automation/what-is-infrastructure-as-code-iac) approach. It's a specific tool with a specific purpose-provisioning. Like Ansible, it has an active open source community and well=supported downstream commercial products. And it has strengths that-when combined with Andible Automation Platform-work well to create efficiencies for many businesses.

### declarative programming

Terraform uses an approach called **declarative programming**, which tries to preserve the configuration of an IT infrastructure by defining a desired state. Otherwise, that the sequence of commands that Terraform has to perform to achieve the required configuration changes are not visible or known to the end user. 

### immutable infrastructure

And Terraform uses an **immutable infrastructure** approach which the configuration (of an infrastructure or an application) can’t be changed. For example, provisioning the newer version of an app requires the previous version to be eliminated and replaced—rather than modified and updated. Resources are destroyed and recreated automatically. It can help users get started quickly as they can easily spin up resources, test something, then tear it down. However, depending on the size of the infrastructure, it can become complex and hard to manage.

## Puppet

Puppet is an automation application designed to manage large and complex infrastructuers. By using a model-driven approach with imperative task execution and declareative language to define configurations, it can enforce consistency across a laarge number of systems. It allso has strong reporting and monitoring capabilities, which can help IT teams identify and diagnose issues quickly.

Puppet is usually run as an agent-based solution, requiring a piece of software on every device it manages, though it also includes agentless capabilities.

### declarative programming

Puppet follows the concept of **declarative programming**, meaning the user defines the desired state of the machines being managed. Puppet uses a Domain-Specific Language (DSL) for defining these configurations. Puppet then automates the steps it takes to get the systems to their defined states. Puppet handles automation using a primary server (where you store the defined states) and a Puppet agent (which runs on the systems you specify).

### Agent-based architecture

Agent-based architecture describes an infrastructure and automation model that requires specific software components called agents to run on the inventory being managed. The agent and all of its dependencies need to be installed on every target node, requiring additional security checks and rules. This can become a challenge when it’s time to automate objects on which the agent is unavailable or not allowed to run. It also requires agents to be maintained as part of the maintenance support life cycle for organizations.

## Chef

Chef is an IT automation platform written in Ruby DSL that transforms infrastructure into code. Similar to Ansible Playbooks, Chef uses reusable definitions known as `cookbooks` and `recipes` to automate how infrastructure is configured. 

### Agent-based architecture

Chef operates with a master-client architecture. The server part runs on the master machine, while the client portion runs as an agent on every client machine. Chef also has an extra component named “workstation” that stores all of the configurations that are tested then pushed to the central server.

## Salt

Salt is a modular automation application written in Python. Desinged for high-speed data collection and execution, it's a configuration management tool with a lightweight ZeroMQ messaging library and concurrency framework that established persistent TCP connections between the server and agents.

### Agent(client)-based architecture

chef also has a Server-Client architecture.In contrast to Ansible, Chef uses an agent-based architecture. Here, the Chef server runs on the main machine and the Chef client runs as an agent on each client machine. In addition, there is an extra component called the workstation, which contains all the configurations that are tested and then pulled from the main Chef server to the client machines without any commands. Since managing these pull configurations requires programmer expertise, Chef is more complicated to use than other automation tools—even for seasoned DevOps professionals.      

---
reference
- https://www.redhat.com/en/topics/automation/understanding-ansible-vs-terraform-puppet-chef-and-salt
- http://kief.com/configuration-drift.html
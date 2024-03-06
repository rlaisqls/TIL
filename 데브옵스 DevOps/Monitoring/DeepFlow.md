
## What is DeepFlow 

DeepFlow is an **observability** product, designed to provide in-depth observability for complex cloud infrastructure and cloud-native application.

Based on eBPF, DeepFlow implements application performance metrics, distributed tracing, continuous profiling, and other observation signals with **zero-disturbance** (Zero Code) collection, integrating **intelligent tags** (SmartEncoding) technology to achieve a **full stack** (Full Stack) correlation. 

By using DeepFlow, cloud-native applications automatically attain deep observability, alleviating the burden on developers and providing monitoring and diagnostic capabilities from code to infrastructure for DevOps/SRE teams.

## Core Features

- **Universal map** of any Service:
  - Based on the leading **AutoMetrics** mechanism, eBPF is used to capture a universal service map of a production environment without disruption.
  - It provides interpretation abilities for a large number of application protocols and offers a Wasm plug-in mechanism to extend the interpretation of any private protocol. 
  - Zero-disturbance in calculating the **full-stack** goldel metrics for each call in the application and infrastructure quickly identifies performance bottlenecks. 

- **Distributed tracing of any Request**:
  - Based on the leading **AutoTracing** machanism, using eBPF and Wasm technology to achieve distributes tracing without disruption, it supports applications in any language and completely covers gateways, service mesh, databases, message queues, DNS, network cards and other infastructure, leacing no blind spots.
  - Full stack - automatically collects network perfoemance metrics and file read/write events associated with each Span. Starting from here, distributed tracing enters a new era of zero instrumentation.

- **Continuous profiling** of any Function:
  - Based on advanced **AutoProfiling** mechanizm, it leverages eBPF to collect production environment process profiling data with less than 1% overhead **zero-disturbance**, creates function level OnCPU and OffCPU FlameGraphs, and quickly locates **full-stack** perfoemance bottlenecks in application functions, library functions, and kernel functions, automatically associating them with distributed tracing data. 
  - Even under kernel version 2.6+, network performance profiling capabilities can still be provided to gain insight into code performance bottlenecks.

- Storage performance **10x ClickHouse**:
  - Based on the leading **SmartEncoding** mechanism, it injects standardized, pre-encoded meta tags into all observation signals, reducing storage overhead by 10x compared to ClickHouse's String or LowCard solution.
  - Custom tags are stored separately from observation data, so you can safely inject nearly infinite dimensions and cardinality of tags and enjoy an easy querying exxperience similar to **BigTable*

## Solving Two Major Pain Points

- In traditional solutions, APM aims to achieve application observability through code instrumentation. Through instrumentation, applications can expose a wealth of observation signals, including metrics, traces, logs, function performance profiling, etc. 
- However, the act of instrumentation actually changes the internal state of the original program, which does not logically conform to the requirement of observability to "determine internal state from external data". 
- In key business systems in important industries such as finance and telecommunications, the landing of APM Agent is very difficult. With the advent of the cloud-native era, this traditional method also faces more severe challenges.
- In general, the problems with APM are mainly reflected in two aspects: the invasiveness of the agent makes it difficult to land, and the observation blind spots make it impossible to triage.


1. Probe invasiveness makes it difficult to implement
  - The process of instrumentation requires modifying the source code of the application and redeploying it. Even technologies like Java Agent, which enhance bytecode, still need to modify the startup parameters of the application program and redeploy it. However, modifying the application code is just the first barrier, and there are usually many other problems encountered during the landing process:
    - **Code conflict**: Do you often encounter runtime conflicts between different Agents when you inject multiple Java Agents for distributed tracing, performance profiling, logs, and even service meshes? When you introduce an observability SDK, have you ever encountered a dependency library version conflict that prevented successful compilation? The conflict is more apparent when there are more business teams.
    - **Difficult to maintain**: If you are responsible for maintaining the company's Java Agent or SDK, how frequently can you update it? Right now, how many versions of the probe program are in your company's production environment? How long would it take to update them all to the same version? How many different languages of probe programs do you need to maintain at the same time? When the microservice framework and RPC framework of a company cannot be unified, these maintenance problems will become more serious.
    - **Blurred boundaries**: All instrumentation code seamlessly enters the running logic of the business code, not distinguishing between you and me, and not being controlled. This makes it often difficult to escape blame when performance degradation or running errors occur. Even if the probe has been through a long period of practical honing, it is inevitable to ask for suspicion when problems occur.
  - This is also why invasive instrumentation solutions are rarely seen in successful commercial products and more often seen in active open source communities. The activity of communities such as OpenTelemetry and SkyWalking prove this. In large corporations where division of labor is clear, overcoming collaboration difficulties is an obstacle that a technological solution cannot bypass for successful implementation. 
  - Especially in key industries such as finance, telecommunications, and power that bear the national economy and people's livelihood, the distinction of responsibilities and conflicts of interest between departments often make it "impossible" to implement an invasive solution. Even in open collaborating Internet companies, there are still problems such as developers' reluctance to implement instrumentation and the blame from operation and maintenance personnel when performance failures occur. 
  - After enduring a long period of effort, people have realized that intrusive solutions are only suitable for each business development team to actively introduce, maintain their versions of various Agents and SDKs, and be responsible for the risks of performance hiding and operation failure.

2. The observation blind spot makes it impossible to triage
   - Even though APM has landed in the enterprise, we still find that it is hard to define the fault boundary, especially in cloud-native infrastructure. 
   - This is because development and operation often use different languages to talk, for instance, when the call delay is too high the development will suspect the network is slow, the gateway is slow, the database is slow, the server is slow, but due to the lack of full-stack observability, the network, gateway, database give answers like the network card has not dropped any packets, the process CPU is not high, there are no slow logs in the DB, the server latency is very low, and a bunch of unrelated indicators still can't solve the problem. Triage is the most critical part of the fault handling process, and its efficiency is extremely important.
   - If you are a business development engineer, in addition to business itself, you should also be concerned about system calls and network transmission processes; if you are a Serverless tenant, you may also need to pay attention to the service mesh sidecar and its network transmission; if you directly use virtual machines or build your own K8s cluster, then container networking is a critical issue to pay attention to, especially paying attention to CoreDNS, Ingress Gateway and other basic services in K8s; if you are a private cloud computing service administrator, you should be concerned about the network performance on the KVM host; if you are a private cloud gateway, storage, security team, you also need to pay attention to the system calls and network transmission performance on the service nodes.
   - What is more important, in fact, is that the data used for error triage should be described in a similar language: how long each hop in the whole stack path takes for a single application call. We found that the observational data provided by developers through instrumentation may account for only 1/4 of the entire complete stack path. **In the cloud-native era, relying solely on APM to solve fault boundaries is itself a misconception**.

## eBPF Technology

- eBPF programs are event-driven, when the kernel or user program passes an eBPF Hook, the eBPF program loaded on the corresponding Hook point will be executed. The Linux kernel predefines a series of common Hook points, and you can also use kprobe and uprobe technology to dynamically add custom Hook points to the kernel and application programs.
- Thanks to Just-in-Time (JIT) technology, the operation efficiency of eBPF code can be as good as native kernel code and kernel modules. Thanks to the Verification mechanism, eBPF code will run safely and will not cause kernel crashes or enter dead loops.

    <img width="631" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/211e7dff-296a-4796-9c71-b29a61566109">

- The sandbox mechanism is where eBPF differs from the APM instrumentation mechanism. The "sandbox" delineates a clear boundary between eBPF code and application code, enabling us to ascertain its internal state by obtaining external data without making any modifications to the application. Let's analyze why eBPF is an excellent solution to the defects of APM code instrumentation:

  1. Zero-disturbance solves the problem of difficult implementation. 
     - Because eBPF programs don't need to modify the application program code, therefore, there are no runtime conflicts like Java Agent and SDK compilation conflicts, solving the problem of code conflict; running eBPF programs doesn't require changing and restarting application processes, doesn't require application program redeployment, it won't have the pain of maintaining Java Agent and SDK versions, solving the difficulty of maintenance problem; because eBPF runs efficiently and safely under the guarantee of JIT technology and Verification mechanism, you don't have to worry about causing unexpected performance degradation or runtime errors of application processes, solving the blurred boundary problem. In addition, from a management perspective, since only one independent eBPF Agent process needs to be run on each host, you can control its CPU and other resource consumption separately and accurately.

  2. Full-stack capabilities solve the problem of hard fault boundary definition. 
     - The capabilities of eBPF cover every layer from the kernel to the user program, thus we are able to trace the full-stack path of a request starting from the application program, going through system calls, network transmission, gateway services, security services, to the database service or peer microservice, **it provides sufficient neutral observation data to quickly complete the fault boundary delineation**.

- It is important to underline that this doesn't mean that DeepFlow only uses eBPF technology. Instead, DeepFlow supports seamless integration with popular observability technology stacks. For example, it can be used as the storage backend for observability signals from Prometheus, OpenTelemetry, SkyWalking, Pyroscope and others.

---

# Architecture

- DeepFlow mainly consists of two components: Agent and Server. 

- The Agent runs extensively in various environments like Serverless Pod, K8s Node, cloud servers, virtual hosts, etc., collecting observable data from all application processes in these environments. The Server, running in a K8s cluster, provides services like agent management, data tagging, data writing, data querying, and more.

    <img width="530" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/303c1de7-f887-4d54-902a-b8c6d02bdf99">


- The name DeepFlow comes from our understanding of achieving observability: a deep insight into every application call (Flow). All observable data in DeepFlow are organized around the call. 
- These data include original call logs, aggregated performance metrics and a universal service map created from the applications, related distributed tracing flame graphs, as well as network performance metrics, file read/write performance metrics, function call stack performance profiling within each lifecycle of a call. 
- Recognizing the complexities of collecting and correlating these observability data, we use eBPF technology for zero-intrusion (Zero Code) data collection, and our SmartEncoding mechanism brings full-stack data correlation.

    <img width="527" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/5d0c6e0c-0d40-4f68-924b-0c870d08af5c">

- Apart from utilizing eBPF technology for zero-intrusion data collection, DeepFlow also supports the integration of mainstream observability tech stacks. It can function as a storage backend for Prometheus, OpenTelemetry, SkyWalking, Pyroscope and more, providing SQL, PromQL, OTLP Export capabilities to serve as data sources for Grafana, Prometheus, OpenTelemetry, SkyWalking.
- This enables developers to quickly integrate it into their observability solutions. When serving as a storage backend, DeepFlow does more than just storing data. Using its advanced AutoTagging and SmartEncoding mechanisms, it injects unified attribute tags into all observability signals, eliminating data silos, and enhancing data drill-down capabilities.

## DeepFlow Agent

- Implemented in Rust language, DeepFlow Agent offers exceptional processing performance and memory safety. The data collected by the Agent can be classified into three categories:

- **eBPF Observability Signals**
  - **AutoMetrics**
    - Using eBPF (Linux Kernel 4.14+) to collect full-stack RED golden metrics of all services
    - Using cBPF (Linux Kernel 2.6+), Winpcap (Windows 2008+) to collect the full-stack RED golden metrics and network performance metrics of all services
  - **AutoTracing**
    - Using eBPF (Linux Kernel 4.14+), analyses the correlation of Raw Request data, and calculates the distributed tracing
    - With cBPF data (Linux Kernel 2.6+), writing Wasm Plugin to parse the business running numbers associated with Raw Request data for calculating distributed tracing
  - **AutoProfiling**
    - Based on eBPF (Linux Kernel 4.9+), collects function-level continuous profiling data and automatically associates it with distributed tracing data
    - With cBPF data (Linux Kernel 2.6+), Winpcap (Windows 2008+), analyses network packet sequence, generating network performance profiling data to deduce application performance bottlenecks
- Instrumentation Observability Signals: Collects observability data from leading open-source Agents, SDKs, such as Prometheus, OpenTelemetry, SkyWalking, Pyroscope, etc.
- Tag Data: Synchronizes resource and service information from Cloud APIs, K8s apiserver, CMDB, etc., for injecting unified tags into all observability signals.
  
Besides, the Agent offers a programmable interface based on WASM to developers for parsing those application protocols which the Agent has not yet recognized, and for building business analysis capabilities targeted at specific scenarios.

Agent runs in various workload environments in the following ways:

- As a process on Linux/Windows servers, collects observability data from all processes in the server
- As an independent Pod on each K8s Node, collects observability data from all Pods on the K8s Node
- As a Sidecar running on each K8s Pod, collecting observability data from all Containers in the Pod
- Runs in Android terminal device operating systems to collect observability data from all processes in the terminal
- As a process running on hosts like KVM, Hyper-V, etc., collects observability data from all virtual machines
- Runs on an exclusive virtual machine to collect and analyze the mirrored network traffic from VMware VSS/VDS
- Runs on a dedicated physical machine to collect and analyze mirrored network traffic from physical switches
  
## DeepFlow Server

Implemented in Golang, DeepFlow Server consists of modules like Controller, Labeler, Ingester, Querier, etc.:

- Controller: Manages Agents, balances the communication relationship between Agents and Servers, syncs Tag data collected by Agents.
- Labeler: Calculates unified attribute tags for all observability signals.
- Ingester: Stores observability data in ClickHouse, exports observability data to otel-collector.
- Querier: Queries observability data, offers unified SQL/PromQL interface to query all types of observability data.
  
The tagging mechanism of DeepFlow features:

- **AutoTagging**: Automatically injects unified attribute tags into all observability data including cloud resource attributes, container resource attributes, K8s Label/Annotation/Env, business attributes in CMDB, eliminating data silos and enhancing data drill-down capabilities.
- **SmartEncoding**: Only injects a few pre-encoded meta tags into the data, the vast majority of the tags (Custom Tag) are stored separately from the observability signals. This automatic association query mechanism provides users the experience of directly querying on a BigTable. The real-world data shows that SmartEncoding can reduce the storage cost of tags by an order of magnitude.

<img width="569" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/c6c44e1f-2519-4975-9e6d-9367028854ce">

DeepFlow Server runs in the form of a Pod in a K8s cluster and supports horizontal expansion. The Server cluster can automatically balance the communication relationship between Agents and Servers according to the data from the Agents. One Server cluster can manage Agents in multiple heterogeneous resource pools. The Enterprise Edition supports unified management across multiple Regions.

---
reference
- https://deepflow.io:7788/
- https://deepflow.io/docs/about/overview/
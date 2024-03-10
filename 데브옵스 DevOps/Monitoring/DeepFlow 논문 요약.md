
> https://github.com/deepflowio/deepflow/blob/main/docs/deepflow_sigcomm2023.pdf

DeepFlow is an **observability** product, designed to provide in-depth observability for complex cloud infrastructure and cloud-native application.

## Network-Centric Tracing Plane

### A narrow-waist instrumentation model with two sets of functions: ingress-egress and enter-exit

- DeepFlow instruments ten system call ABIs and classifies them as ingress or egress. DeepFlow stores information about each ingress or egress call as it **enters or exits** the kernel.

- Four categories of information are recorded for further processing in the user space: 
  1. Program information: process ID, thread ID, coroutine ID, program name, etc.
  2. Network information: the DeepFlow assigned global unique socket ID, five-tuple, the TCP sequence, etc.
  3. Tracing information, including data capture timestamp, ingress/egress direction, etc.
  4. System call information, such as the total length of read/write data, payload to be transferred to the DeepFlow agent, and so on.

### In-kernel hook-based instrumentation

- In accordance with the pre-defined instrumentation model, DeepFlow automatically registers hooks to collect trace data.

<img width="484" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/1bbbd90b-6df2-4e54-ab90-37a6a1dd1266">

- For message ingress (➀) or egress (➁), the corresponding system call will trigger the registered kprobe or tracepoint hooks when it enters (➃) and exits (➄) the kernel.
- The tracing process will retrieve the arguments (➆), wait for the kernel to complete its processing, and then retrieve the returned results (➇).
- The preliminary parser (➈) will integrate and enqueue the primary data into the buffer (➉), which will subsequently be transmitted to the user space for further processing.
- Additionally, DeepFlow utilizes uprobes and uretprobes to extract information (➅) from extended instrumentation points within the component’s logic (➂).
- All of the operations are executed automatically. Users can perform distributed tracing in zero code.

## Implicit Context Propagation

- Traditional distributed tracing frameworks modify the source code [64] or serialization libraries to explicitly insert context information into the headers or payloads of messages.

- Deepflow's key insight is that **the information required for context propagation is already contained in network-related data**. By maximizing the utilization of data from each network layer, DeepFlow does not need to explicitly include context information within the message.

- DeepFlow combines independent, fragmented, and primitive measurements into request-oriented traces containing precise causal correlations through the following two phases:
  1. constructing spans from the instrumentation data.
    - DeepFlow generates spans that always begin with a request and end with a response
    
        <img width="487" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/093a9b43-0596-4859-a91d-d60ff4f9923f">

     - Firstly, DeepFlow associates information captured during the enter and exit of the same system call by using process IDs and thread IDs. The association is predicated on the fact that the kernel can simultaneously handle only one selected system call for a given (𝑃𝑟𝑜𝑐𝑒𝑠𝑠_𝐼𝐷, 𝑇h𝑟𝑒𝑎𝑑_𝐼𝐷)
  
     - The combined data is referred to as message data, and its type is classified as ingress or egress based on the type of system call captured. To decrease the amount of data transferred, we only process the first system call for a message, not the subsequent ones that are used for further data transfers.

        > For languages such as Golang, DeepFlow monitors the creation of coroutines to save the parent-child coroutine relationship in a pseudo-thread structure and performs similar operations. DeepFlow temporarily saves the enter parameters in a hash map, retrieves them at exit time, and combines them with the exit parameters. 

        > Although deep packet inspection is unavoidable, DeepFlow as an open source project, typically only extracts information from the packet headers and does not examine the sensitive user data primarily located in the payload.

     - DeepFlow ensures accurate correspondence between messages in pipeline. If using Parallel protocols, either matching the order of requests and responses or utilizing distinguishing attributes embedded in the messages, such as IDs in DNS headers or stream identifiers in HTTP/2 headers.

     - DeepFlow implements a time window array and stores messages according to their timestamps. When aggregating, only messages in the same time slot or next to it will be queried. (DeepFlow presently sets the duration of each time slot to 60 seconds)
  
        <img width="476" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/996c4f1b-1835-4d6f-bfad-9dd8c9f6745c">

  2. assembling traces from spans using implicit causal relationships.

     - DeepFlow takes the spans that users query as starting points and merges the associated spans. Meanwhile, cross-layer correlation is supported by intrand inter-component association as well as third-party span integration

     - DeepFlow associates spans within the same thread using thread IDs. 
       - For coroutines in Golang, DeepFlow can also conduct association by tracking the invocation relationships between coroutines during

        <img width="487" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/902f939e-c8ac-4a63-859d-7c1af74b886c">

     - When threads are reused, the trace will be partitioned based on the time sequence.

     - DeepFlow manages multiple requests or responses. In a single thread, computing should not pause for scheduling, unlike network communication. Therefore, we assign the same systrace_id to two consecutive messages of different types and from different sockets.

     - Since network transmissions (Layer 2/3/4 forwarding) do not change the TCP sequence, DeepFlow leverages this for the inter-component association. During the instrumentation phase (Section 3.2), we calculate and record the TCP sequence for each message in the kernel. It is then used to differentiate and maintain the inter-component association of spans within the same flow.

## Trace assembling

- Below Algorithm demonstrates the final step of trace assembling

    <img width="483" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/cecf17ab-7965-4fbf-a5a6-6c1725158ce9">

- In each iteration, we add to the span set any new spans that share the same
  - systrace_id (Line 6)
  - pseudo-thread ID (Line 7)
  - X-Request-ID (Line 8)
  - TCP sequence (Line 9)
  - and trace ID (Line 10)
  
  as the current spans. The search is terminated if the number of related spans does not increase between two consecutive searches (Lines 13-14).

- In the second phase of the algorithm, we iterate over the span set and set the parent spans.
  The determination of parent spans is also based on the aforementioned intra- and inter-component associations, but with stricter conditions.
  - 16 rules were set based on the collection location (server or client), start time and finish time, span type, and message type (Line 20).
  - For instance, if an eBPF span collected on the client side has the same TCP sequence as an eBPF span collected on the server side, the parent of the client side span is set to the server side span
- Finally, sorting the span set by time and parent relationship (Line 25) to generate a display-friendly trace and transmit it to the front end.

## Tag-Based Correlation
- To achieve cross-component correlation in zero code, DeepFlow injects uniform tags into the spans.
- DeepFlow injects uniform tags into the spans. We enable the injection of Kubernetes resource tags (e.g., node, service, pod, etc.), self-defined labels (e.g., version, commit-ID, etc.), and cloud resource tags (e.g., region, availability zone, VPC, etc.).

- To minimize the tagging overhead, we introduce a technique called smart-encoding.

    <img width="479" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/1759d816-716c-4e63-b345-d9daacf8adff">

  - During the tag collection phase, DeepFlow Agents inside the cluster will collect Kubernetes tags (➀) and send them to the Server (➁)
  - while the cloud resource tags are gathered directly by the Server (➂)
  - In the smart-encoding phase, DeepFlow only injects virtual private cloud (VPC) tags and IP tags in Int format into traces (➃-➅)
  - The Server then injects the resource tags in Int format into the traces based on the VPC/IP tags and stores them in the database (➆)
  - At query time, DeepFlow Server determines the relationship between self-defined tags and resource tags, injects self-defined tags into traces, and then uploads the traces with all the tags to the front end (➇)
  - By partitioning the tag injection phases, DeepFlow reduces the calculation, transmission, and storage overhead.
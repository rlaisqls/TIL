
We had the chance to see quite a bit of clusters in our years of experience with Kubernetes (both managed and unmanaged - on GCP, AWS and Azure), and we see some mistakes being repeated. No shame in that, we've done most of these too! Let's try to show the ones we see very often and talk a bit about how to fix them.

## 1. resources - requests and limits

- CPU request are usually either **not set** or **sey very low** (so that we can fit a lot of pods on each node) and nodes are thus over commited. In time of high demand the CPUs of the node are fully utilized and our workload is getting only "what it had requested" and gets **CPU throttled**, causing increased application latency, timeouts, etc.

- On the other hand, having a CPU limit can unnecessarily throttle pods even if the node's CPU is not fully utilized which again can cause increased latency. There is a an open discussion around CPU CFS quota in linux kernel and cpu throttling based on set spu limits and turning off the CFS queta. CPU limits can cause more problems than they solve. See more in the link below.

- Memory overcommiting can get you in more trouble. Reaching a CPU limit result in throttling, reaching memory limit will get your pod killed(OOMKill). If you want to minimize how often it can happen, don't overcommit your memory and use Guaranteed Qos settign memory request equal to limit like in the example below. ([reference](https://www.slideshare.net/try_except_/optimizing-kubernetes-resource-requestslimits-for-costefficiency-and-latency-highload))

- Burstable (more likely to get OOMkilled more often):
    ```yaml
        resources:
        requests:
            memory: "128Mi"
            cpu: "500m"
        limits:
            memory: "256Mi"
            cpu: 2
    ```

- Guaranteed:
    ```yaml
        resources:
        requests:
            memory: "128Mi"
            cpu: 2
        limits:
            memory: "128Mi"
            cpu: 2
    ```

- You can see the current cpu and memory usage of pods (and containers in them) using metrics-server. It can help you when setting resources. Simply run these:
    ```bash
    kubectl top pods
    kubectl top pods --containers
    kubectl top nodes
    ```

- However these show just the current usage. That is great to get the rough idea about the numbers but you end up wanting to see these **usage metrics in time** (to answer questions like: what was the cpu usage in peak, yesterday morning, etc.). For that, you can use Prometheus, DataDog and many others. They just ingest the metrics from metrics-server and store them, then you can query & graph them.

- [VerticalPodAutoscaler](https://cloud.google.com/kubernetes-engine/docs/concepts/verticalpodautoscaler) can help you **automate way** this manual process - looking at cpu/mem usage in time and setting new requests and limits based on that all over again.

## 2. liveness and readiness probes

- Liveness probe restarts your pod if the probe fails
- Readiness probe disconnects on fail the failing pod from the kubernetes service (you can check this in kubectl get endpoints) and no more traffic is being sent to it until the probe succeeds again.

- By default there are no liveness and readiness probes specified. It stay that way, how else would your servie get restarted when there is an unrecoverable error? How does a loadbalancer know a specific pod can start handling traffic? Or handle more traffic? liveness and readiness probes are both run during the whole pod lifecycle, and that is very important for Important for recovering pods.

- Readiness probes run not only at the start to tell when the pod is Ready and can start servicing traffic but also at during a pod's life the pod becomes too hot handling too much traffic (or an expensive computation) so that we don't send her more work to do and lat her cool down, then the readiness probe succeed and we start dending in more traffic again.
  - In this case (when failing readiness probe) failing also liveness probe would be very counterproductive. Why would you restart a pod that is healthy and doing a lot of work?
  - Sometimes not having either probe defined is better than having them defined wrong. As mentioned above, if liveness probe is equal to readiness probe, you are in a big trouble. You might want to start with defining only the readiness probe alone as liveness probes are dangerous.

- Do not fail either of the probes if any of your shared dependencies is down, it would cause cascading failure of all the pods. You are shooting yourself in the foot.

## 3. non-kubernetes-aware cluster autoscaling

- When scheduling pods, you decide based on a log of **scheduling constraints** like pod & node affinities, taints and toleratoins, resource requests, QoS, etc. Having an external autoscaler that does not understand these constraints might be troublesome.

- Imagine there is a new pod to be scheduled but all of the CPU available is requested and pod is **stuck in Pending state**. External autoscaler sees the average CPU surrently used (not requested) and won't scale out (will not add another node). The pod won't be scheduled.

- Scaling-in (removing a node from the cluster) is always harder. Imagine you have a stateful pod (with persistent volume attached) and as **persistent volumes** are usually resources that **velong to a specific availability zone** and are not replicated in the region, your custom suto scaler removes a node with this pod on it and scheduler cannot schedule it onto a different node as it is very limited by the only availability zone with your persistent disk in it. Pod is again stuck in Pending state.

- The community is widely using **[cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)** which runs in your cluster and is integrated with most major public cloud vendors APIs, understands all these constraints and would scale-out in the mentioned cases. It will also figure out if it can gracefully scale-in without affecting any constraints we have set ans saves you money on compute.

## 4. Not using the power of IAM/RBAC

- Don't use IAM Users with permanent secrets for machines and applications rather than generating temporary ones using roles and service accounts.

- We see it often - hardcoding access and secret keys in application configuration, never rotating the secrets when you have Cloud IAM at hand. Use IAM Roles and service accounts instead of users where suitable. like below:
    ```yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
    annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/my-app-role
    name: my-serviceaccount
    namespace: default
    ```

- Also don’t give the service accounts or instance profiles admin and cluster-admin permissions when they don’t need it. That is a bit harder, especially in k8s RBAC, but still worth the effort.

## 5. self anti affinities for pods

- If you use many replicas in one deployment, you should define them explicitly.

- like this:
    ```yaml
        spec:
        topologySpreadConstraints:
        - maxSkew: 1
            topologyKey: kubernetes.io/hostname
            whenUnsatisfiable: DoNotSchedule
            labelSelector:
            matchLabels:
                ket: value
    ```

- or like this:
    ```yaml
        affinity:
            podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
                - labelSelector:
                    matchExpressions:
                    - key: "key"
                        operator: In
                        values:
                        - value
                topologyKey: "kubernetes.io/hostname"
    ```

- That's it. This will make sure the pods will be scheduled to different dones (this is being cheked only at scheduling time, not at execution time, hense the `requiredDuringSchedulingIgnoredDuringExecution`)

- We are talking about podAntiAffiniry on different node names, not different availability zones. If you really need proper HA, dig a bit deeper in this topic.

## 6. more tenants or envs in shared cluster

- Kubernetes namespaces don't provide any strong isolation.
  
- People seen to expect if they separated non-prod workload to one namespace and prod to prod namespace, one **workload won't ever affect the other**. It is possible to achieve some level of fairness - resource requests and limits, quotas, priorityClasses - and isolation - affinities, tolerations, taints (or nodeselectors) - to "physically" separate the workload in data plane but that separation is quite **complex**.

- If you need to have both types of workloads in the same cluster, you'll have to bear the complexity. If you don't need it and having **another cluster** is relatively cheap for you (like in public cloud), put it in different cluster to achieve much stronger level of isolation.

## 7. externalTrafficPolicy: Cluster

- Seeing this very often, all traffic is routed inside the cluster to a NoderPort service which has, by default, `externalTrafficPolicy: cluster`. That means the NodePort is opened on every node in the cluster so that you can use any of them to communicate with the desired sevice (set of pods).

<img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/4769b803-dbd6-4b9b-8368-4675300f5682" height=300px>

- More often than not the actual pods that are targeted with the NodePort service **run only on a subset of those nodes.** That means if I talk to a node which does not have the pod running it will forward the traffic to a different node, causing **additional network hop** and increased latency (if the nodes are in different AZs/datacenters, the latency can be quite high and there is additional egress cost to it).

- Setting `externalTrafficPolicy: Local` on the kubernetes service won't open that NodePort on every Node, but only on the nodes where the pods are actually running. If you use an external loadbalancer which is healthchecking its endpoints (like AWS ELB does) it will start to **send the traffic only to those nodes** where it is supposed to go, improving your latency, compute overhead, egress bill and anity.

- Chances are, you have something like traefic or nginx-ingress-controller being exposed as NodePort (or LoadBalancer, which uses NodePort too) to handler your ingress http traffic routing and this setting can greatly reduce the latency on such requests.

---
reference
- https://blog.pipetail.io/posts/2020-05-04-most-common-mistakes-k8s/
- https://medium.com/@SkyscannerEng/how-a-couple-of-characters-brought-down-our-site-356ccaf1fbc3
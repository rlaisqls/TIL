
Pord readiness is and additional indication of whether the pod is ready to serve traffic. Pod readiness determines whether the pod address shows up in the `Endpoints` object from an external source. Other Kubernetes resources that manage pods, like depolyments, take pod readiness into account for decision-making, such as advancing during a rolling update.

During rolling deployment, a new pod becomes ready, but a service, network policy, or load balancer is not yet prepared for the new pod due to whatever reason. This may cause service disruptio or loss of backend capacity. It should be noted that if a pod spec does contain probes of any type, Kubernetes defaults to success for all three types.

Users can specify pod readiness checks in the pod spec. From thare, the Kublet executes the specified check and updates the pod status based on successes or failures.

Probes effect the `.Status.Phase` field of a pod. The following is a list of the pod phases and their descriptions:

- **Pending**
  - The pod has been accepted by the cluster, but one or more of the containers has not been set up and made ready to run. This includes the time a pod spends waiting to be scheduled as well as the time spent downloading container images over the network.

- **Running**
  - The pod has been scheduled to a node, and all the containers have been created. At least one container is still running or is in the process of starting or restarting. Note that some containers may be in a failed state, such as in a CrashLoopBackoff.

- **Succeeded**
  - All containers in the pod have terminated in success and will not be restarted.

- **Failed**
  - All containers in the pod have terminated, and at least one container has terminated in failure. That is, the container either exited with nonzero status or was terminated by the system.

- **Unknown**
  - For some reason the state of the pod could not be determined. This phase typically occurs due to an error in communicating with the Kubelet where the pod should be running.

The Kubelet performs serveral types of health checks for individual containers in a pod: `livenessProbe`, `readinessProbe`, and `startupProbe`. The Kublet (and, by extension, the node it-self) must be able to connect to all containers running on that node in order to perfrom any HTTP health checks.

- **Liveness Probe**
  - Liveness probes determine **whether or not an application running in a container is in a healthy state.** If the liveness probe detects an unhealthy state, then Kubernetes kills the container and tries to redeploy it.
  - The liveness probe is configured in the spec.containers.livenessprobe attribute of the pod configuration.

- **Startup Probe**
  - A startup probe verifies **whether the application within a container is started.** Startup probes run before any other probe, and, unless it finishes successfully, disables other probes. If a container fails its startup probe, then the container is killed and follows the pod’s restartPolicy.
  - This type of probe is only executed at startup, unlike readiness probes, which are run periodically.
  - The startup probe is configured in the spec.containers.startupprobe attribute of the pod configuration.
  
- **Readiness Probe**
  - Readiness probes determine **whether or not a container is ready to serve requests.** If the readiness probe returns a failed state, then Kubernetes removes the IP address for the container from the endpoints of all Services.
  - Developers use readiness probes to instruct Kubernetes that a running container should not receive any traffic. This is useful when waiting for an application to perform time-consuming initial tasks, such as establishing network connections, loading files, and warming caches.

Each probe has one of three results:

- **Success**: The container passed the diagnostic.
- **Failure**: The container failed the diagnostic.
- **Unknown**: The diagnostic failed, so no action should be taken.

The probes can be exec probes, which attempt to execute a binary within the container, TCP probes, or HTTP probes. If the probe fails more that the `faulureThreshold` number of times, Kubernetes will consider the check to have failed. The effect of this depends on type of probe.

- **When the liveness probes fail**:
  - the Kubelet will terminate the container. 
  - Liveness probes can easily cause unexpected failures if misused or misconfigured.
  - The intended use case for liveness probes is to let the Kubelet know when to restart a container. However, as humans, we quickly learn that if “something is wrong, restart it” is a dangerous strategy.
  - For example, suppose we create a liveness probe that loads the main page of our web app. Further, suppose that some change in the system, outside our container’s code, causes the main page to return a `404` or `500` error. There are frequent causes of such a scenario, such as a backend database failure, a required service failure, or a feature flag change that exposes a bug. In any of these scenarios, the liveness probe would restart the container.
  - At best, this would be unhelpful; restarting the container will not solve a problem elsewhere in the system and could quickly worsen the problem. Kubernetes has container restart backoffs (`CrashLoopBackoff`), which add increasing delay to restarting failed containers
  - <u>With enough pods or rapid enough failures, the application may go from having an error on the home page to being hard-down</u>. Depending on the application, **pods may also lose cached data upon a restart**; it may be strenuous to fetch or impossible to fetch during the hypothetical degradation. Because of this, use liveness probes with caution. When pods use them, they only depend on the container they are testing, with no other dependencies.
  - Many engineers have specific health check endpoints, which provide minimal validation of criteria, such as “PHP is running and serving my API.”
  - If a pod's `redinessProbe` fails, the pod's IP address wil not be in the endpoint object, and the service will not route traffic to it.

- **A startup probe can provide a grace period before a liveness probe can take effect.** **Liveness probes will not terminate a container before the startup probe has succeeded**. An example use case is to allow a container to take many minutes to start, but to terminate a container quickly if it becomes unhealthy after starting.
  
- **When a container's readiness probe fails**:
  - the Kublet does not terminate it. Instead, the Kubelet writes the failure to the pod's status.

Below example, the server has a liveness probe that perform an HTTP GET on port 8080 to the path `/healthz`, while the readiness probe uses `/` on the same port.

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: go-web
spec:
  containers:
  - name: go-web
    image: go-web:v0.0.1
    ports:
    - containerPort: 8080
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
    readinessProbe:
      httpGet:
        path: /
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

This status does not affect the pod itself, but other Kubernetes mechanisms reacy to it. One key example is ReplicaSets (and, by extension, deployments). A failing readiness probe cause the ReplicaSet controller to count the pod as unready, giving ride to a galtes deployment when too many new pods are unhealthy. The `Endpoins`/`EndpointsSlice` controllers also react to failing readiness probes.

### Probe configurable options

- **initialDelaySeconds**
  - Amount of seconds after the container starts before liveness or readiness probes are initiates. Default 0; Minimum 0.
- **periodSeconds**
  - How often probes are performed. Default 10; Minimum 1.
- **timeoutSeconds**
  - Number of seconds after which the probe times out. Default 1; Minimum 1.
- **successThreshold**
  - Minimum consecutive successes for the probe to be successful after failing. Default 1; must be 1 for liveness and startup probes; Minimum 1.
- **failureThreshold**
  - When a probe fails, Kubernetes will try this many times before giving up. Giving up in the case of the liveness probe means the container will restart. For readiness probe, the pod will be marked Unready. Default 3; Minimum 1.

### Readiness gates

Application developers can also use readiness gates to help determine when the application inside the pod is ready. Available and stable since Kubernetes 1.14, to use `readiness gates`, manifest writers will add readiness gates in the pod’s spec to specify a list of additional conditions that the Kubelet evaluates for pod readiness. That is done in the `ConditionType` attribute of the readiness gates in the pod spec. The `ConditionType` is a condition in the pod’s condition list with a matching type. Readiness gates are controlled by the current state of `status.condition` fields for the pod, and if the Kubelet cannot find such a condition in the `status.conditions` field of a pod, the status of the condition is defaulted to False.

As you can see in the following example, the feature-Y readiness gate is true, while feature-X is false, so the pod’s status is ultimately false:

```yaml
kind: Pod
…
spec:
  readinessGates:
  - conditionType: www.example.com/feature-X
  - conditionType: www.example.com/feature-Y
…
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: 2021-04-25T00:00:00Z
    status: "False"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: 2021-04-25T00:00:00Z
    status: "False"
    type: www.example.com/feature-X
  - lastProbeTime: null
    lastTransitionTime: 2021-04-25T00:00:00Z
    status: "True"
    type: www.example.com/feature-Y
  containerStatuses:
  - containerID: docker://xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    ready : true
```

Load balancers like the AWS ALB can use the readiness gate as part of the pod life cycle before sending traffic to it.

---

The Kubelet must be able to connect to the Kubernetes API server, and communication between the pods and the Kubelet is made possible by the CNI.

![image](https://github.com/rlaisqls/TIL/assets/81006587/fe158dbc-addc-438d-b922-2e6ad0854b4a)

In above figure, we can see all the connections made by all the components in a cluster:

- **CNI**
  - Network plugin in Kubelet that enables networking to get IPs for pods and services.

- **gRPC**
  - API to communicate from the API server to etcd.

- **Kubelet**
  - All Kubernetes nodes have a Kubelet that ensures that any pod assigned to it are running and configured in the desired state.

- **CRI**
  - The gRPC API compiled in Kubelet, allowing Kubelet to talk to container runtimes using gRPC API. The container runtime provider must adapt it to the CRI API to allow Kubelet to talk to containers using the OCI Standard (runC). CRI consists of protocol buffers and gRPC API and libraries.

---
reference 
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- https://developers.redhat.com/blog/2020/11/10/you-probably-need-liveness-and-readiness-probes
- https://medium.com/devops-mojo/kubernetes-probes-liveness-readiness-startup-overview-introduction-to-probes-types-configure-health-checks-206ff7c24487
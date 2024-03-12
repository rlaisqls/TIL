
Kubernetes's default befavior is to allow traffic between any two pods in the cluster network. This behavior is a deliberate design choice for ease of adoption and flexibility of configuration, but it is highly undesirable in practice. Allowing any system to make (or receive) arbitrary connections creates risk.

An attacker can probe systems and can porentially exploit captured credentials to find weakened or missing authentication. Allowing arbitrary connections also makes it easier to exfiltrate data from a system through a conpromised workload.

All in all, we strongly discourage running real clusters without `NetworkPolicy`. Since all pods can communicate with all other pods, we strongly recommend that application owners use `NetworkPolicy` objects along with other application-layer security measures, such as authentication tokens or mutual Transport Layer Security (mTLS), for any network communication.

`NetworkPolicy` is a **resource type in Kubernetes that contains allow-based firewall rules**. Users can add NetworkPolicy objects to restrict connections to and from pods.

## with CNI plugins

<u>The NetworkPolicy resource acts as a configuration for CNI plugins</u>, which themselves are responsible for ensuring connectivity between pods. The Kubernetes API declares that NetworkPolicy support is optional for CNI drivers, which means that some CNI drivers do not support network policies, as shown in below Table.

If a developer creates a NetworkPolicy when using a CNI driver that does not support NetworkPolicy objects, it does not affect the pod’s network security. Some CNI drivers, such as enterprise products or company-internal CNI drivers, may introduce their equivalent of a NetworkPolicy. Some CNI drivers may also have slightly different “interpretations” of the NetworkPolicy spec.

|CNI plugin|NetworkPolicy supported|
|-|-|
|Calico|Yes, and supports additional plugin-specific policies|
|Cilium|Yes, and supports additional plugin-specific policies|
|Flannel|No|
|Kubenet|No|

## NetworkPolicy example

Below example is details a NetworkPolicy object, which contains a pod selector, ingress rules, and egress rules. The policy will <u>apply to all pods in the same namespace as the NetworkPolicy that matches the selector label</u>. This use of selector labels is consistent with other Kubernetes APIs: a spec identifies pods by their labels rather than their names or parent objects.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: demo
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: demo
  policyTypes:
  - Ingress
  - Egress
  ingress: []NetworkPolicyIngressRule # Not expanded
  egress: []NetworkPolicyEgressRule # Not expanded
```

Before getting deep into the API, let’s walk through a simple example of creating a `NetworkPolicy` to reduce the scope of access for some pods. Let’s assume we have two distinct components: `demo` and `demo-DB`. As we have no existing NetworkPolicy in below, all pods can communicate with all other pods (including hypothetically unrelated pods, not shown).

<img width="433" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/0acc3b62-041e-4b4e-9023-ce362aec34ae">

Our `demo-db` should (only) be able to receive connections from `demo` pods. To do that, we must add an ingress rule to the `NetworkPolicy`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: demo-db
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: demo-db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: demo
```

Now demo-db pods can receive connections only from demo pods. Moreover, demo-db pods cannot make connections.

<img width="433" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/af7528b4-4ade-4ce3-9207-b228caa42c97">

> If users can unwittingly or maliciously change labels, they can change how `NetworkPolicy` objects apply to all pods. In our prior example, if an attacker was able to edit the `app: demo-DB` label on a pod in that same namespace, the `NetworkPolicy` that we created would no longer apply to that pod. Similarly, an attacker could gain access from another pod in that namespace if they could add the label `app: demo` to their compromised pod.

## Rules

`NetworkPolicy` objects contain distinct ingress and egress configuration sections, which contain a list of ingress rules and egress rules, respectively. `NetworkPolicy` rules act as exceptions, or an “allow list,” to the default block caused by selecting pods in a policy. **Rules cannot block access; they can only add access**.

If multiple `NetworkPolicy` objects select a pod, all rules in each of those `NetworkPolicy` objects apply. It may make sense to use multiple `NetworkPolicy` objects for the same set of pods (for example, declaring application allowances in one policy and infrastructure allowances like telemetry exporting in another).

However, keep in mind that they do not need to be separate `NetworkPolicy` objects, and with too many `NetworkPolicy` objects it can become hard to reason.

> To support health checks and liveness checks from the Kubelet, the CNI plugin **must always allow traffic from a pod’s node.**<br>It is possible to abuse labels if an attacker has access to the node (even without admin privileges). Attackers can spoof a node’s IP and deliver packets with the node’s IP address as the source.

---

Ingress rules and egress rules are discrete types in the `NetworkPolicy` API (`NetworkPolicyIngressRule` and `NetworkPolicyEgressRule`). However, they are functionally structured the same way. Each `NetworkPolicyIngressRule`/`NetworkPolicyEgressRule` contains a list of ports and a list of `NetworkPolicyPeers`.

A `NetworkPolicyPeer` has four ways for rules to refer to networked entities: `ipBlock`, `namespaceSelector`, `podSelector`, and a combination.

`ipBlock` is useful for allowing traffic to and from external systems. It can be used only on its own in a rule, without a `namespaceSelector` or `podSelector`. `ipBlock` contains a CIDR and an optional `except` CIDR. The `except` CIDR will exclude a sub-CIDR (it must be within the CIDR range).

#### example

Allow traffic from all IP addresses in the range `10.0.0.0` to `10.0.0.255`, excluding `10.0.0.10`:

```yaml
from:
  - ipBlock:
    - cidr: "10.0.0.0/24"
    - except: "10.0.0.10"
```

Allows traffic from all pods in any namespace labeled group:`x`:

```yaml
from:
  - namespaceSelector:
    - matchLabels:
      group: x
```

allow traffic from all pods in any namespace labeled service: x.. podSelector behaves like the spec.podSelector field that we discussed earlier. If there is no namespaceSelector, it selects pods in the same namespace as the NetworkPolicy.


```yml
from:
  - podSelector:
    - matchLabels:
      service: y
```


If we specify a namespaceSelector and a podSelector, the rule selects all pods with the specified pod label in all namespaces with the specified namespace label. It is common and highly recommended by security experts to keep the scope of a namespace small; typical namespace scopes are per an app or service group or team. There is a fourth option shown in below example with a namespace and pod selector. This selector behaves like an AND condition for the namespace and pod selector: pods must have the matching label and be in a namespace with the matching label.

```yml
from:
  - namespaceSelector:
    - matchLabels:
      group: monitoring
    podSelector:
    - matchLabels:
      service: logscraper
```

Be aware this is a distinct type in the API, although the YAML syntax looks extremely similar. As `to` and `from` sections can have multiple selectors, a single character can make the difference between an `AND` and an `OR`, so be careful when writing policies.

Our earlier security warning about API access also applies here. If a user can customize the labels on their namespace, they can make a `NetworkPolicy` in another namespace apply to their namespace in a way not intended. In our previous selector example, if a user can set the label `group: monitoring `on an arbitrary namespace, they can potentially send or receive traffic that they are not supposed to. If the `NetworkPolicy` in question has only a namespace selector, then that namespace label is sufficient to match the policy. If there is also a pod label in the `NetworkPolicy` selector, the user will need to set pod labels to match the policy selection. However, in a typical setup, the service owners will grant create/update permissions on pods in that service’s namespace (directly on the pod resource or indirectly via a resource like a deployment, which can define pods).

A typical NetworkPolicy could look something like this:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: store-api
  namespace: store
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          app: frontend
      podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          app: downstream-1
      podSelector:
        matchLabels:
          app: downstream-1
    - namespaceSelector:
        matchLabels:
          app: downstream-2
      podSelector:
        matchLabels:
          app: downstream-2
    ports:
    - protocol: TCP
      port: 8080
```

In this example, all pods in our `store` namespace can receive connections only from pods labeled `app: frontend` in a namespace labeled `app: frontend`. Those pods can only create connections to pods in namespaces where the pod and namespace both have `app: downstream-1` or app: `downstream-2`. In each of these cases, only traffic to port 8080 is allowed. Finally, remember that this policy does not guarantee a matching policy for `downstream-1` or `downstream-2` (see the next example). Accepting these connections does not preclude other policies against pods in our namespace, adding additional exceptions:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: store-to-downstream-1
  namespace: downstream-1
spec:
  podSelector:
    app: downstream-1
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          app: store
    ports:
    - protocol: TCP
      port: 8080
```

Although they are a “stable” resource (i.e., part of the networking/v1 API), we believe `NetworkPolicy` objects are still an early version of network security in Kubernetes. The user experience of configuring `NetworkPolicy` objects is somewhat rough, and the default open behavior is highly undesirable. There is currently a working group to discuss the future of `NetworkPolicy` and what a v2 API would contain.

CNIs and those who deploy them use labels and selectors to determine which pods are subject to network restrictions. As we have seen in many of the previous examples, they are an essential part of the Kubernetes API, and developers and administrators alike must have a thorough knowledge of how to use them.

`NetworkPolicy` objects are an important tool in the cluster administrator’s toolbox. They are the only tool available for controlling internal cluster traffic, native to the Kubernetes API. We discuss service meshes, which will add further tools for admins to secure and control workloads, in “Service Meshes”.

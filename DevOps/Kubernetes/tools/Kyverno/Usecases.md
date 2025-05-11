Kyverno is a Kubernetes native policy engine that helps in enforcing custom policies on Kubernetes objects. It is a highly scalable and declarative tool that allows Kubernetes administrators to enforce security, compliance, and operational policies across their clusters.

Kyverno policies are written in YAML format and can be defined as cluster-wide resources (using the kind ClusterPolicy) or namespaced resources (using the kind Policy.) These policies can validate incoming objects, mutate them as required, or even reject them if they violate the defined rules.

Kyvernopolicies are highly configurable and can be applied to a wide range of usecased, including enforcing RBAC policies, preventing deployment of untrusted imgages, enforcign naming conventions, and mush more. In this tutorial, we wiil explore some usecases where you might need to create custom policies with Kyverno.

## 1. Resource Limits

One of the most common use cases for creating custom policies is enforcing resource limits. Resource limits ensure that Kubernetes pods do not consume too much CPU or memory, which can cause performance issues or even bring down the entire cluster.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: Enforce-resource-limits
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: pod-resource-limits
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Pods must have CPU limit of 1 core and memory limit of 1 GiB, and request at least 100 milli-CPUs and 256 MiB of memory"
        pattern:
          spec:
            containers:
              - name: "*"
                resources:
                  limits:
                    cpu: 1
                    memory: 1Gi
                  requests:
                    cpu: 100m
                    memory: 256Mi
```

</div>
</details>

## 2. Custom Labels

Labels can help you organize your Kubernetes resources and apply policies based on specific labels, For example, you might want to enforce a policy that requires all pods to have a specific label.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: require-backend-label
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: pod-backend-label
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Pods must have a 'team' label with value 'backend'"
        pattern:
          metadata:
            labels:
              team: backend
```

</div>
</details>

## 3. Enforcing Custom Annotations

Annotations can help you attach metadata to your Kubernetes resources. For example, you might want to enforce a policy that requires all pods to have a specific annotation.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: require-backend-description-annotation
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: pod-backend-description-annotation
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Pods must have a 'description' annotation with value 'backend'"
      pattern:
          annotations:
        metadata:
            description: backend
```

</div>
</details>

## 4. Pod Security Policies

Pod security policies help you control the security settings of your Kubernetes pods. They allow you to control aspects such as the use of privileged containers, the use of host network or host IPC, and the use of certain volume types.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: disallow-privileged-containers
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: pod-privileged
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Pods must not use privileged containers"
        pattern:
          spec:
            containers:
              - name: "*"
                securityContext:
                  privileged: false
```

</div>
</details>

Here is another example YAML file that defines a ClusterPolicy which requires all pods to use seccomp and apparmor security profiles.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: require-pod-security-policies
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: pod-security-profile
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Pods must use the 'seccomp' and 'apparmor' security profiles"
        pattern:
          spec:
            securityContext:
              seccompProfile:
                type: "RuntimeDefault"
              seLinuxOptions:
                type: "spc_t"
              supplementalGroups:
                - 100
              sysctls:
                - name: net.ipv4.ip_forward
                  value: "0"
```

</div>
</details>

## 5. Custom Naming Conventions

Naming conventions can help you maintain consistency and avoid confusion in your Kubernetes cluster. For example, you might want to enforce a naming convention that requires all pods to have a specific prefix or suffix.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: prod-naming-convention
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: pod-prod-naming
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Pods must have a 'prod-' prefix in their name"
        pattern:
          metadata:
            name: "prod-*"
```

</div>
</details>

## 6. Enforcing Service Accounts

Service accounts allow you to control access to Kubernetes resources. You might want to enforce a policy that requires all pods to use a specific service account.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: require-backend-service-account
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: pod-backend-service-account
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Pods must use the 'backend' service account"
        pattern:
          spec:
            serviceAccountName: backend
```

</div>
</details>

## 7. Enforcing Network Policies

Network policies allow you to control traffic flow to and from your Kubernetes pods. You might want to enforce a policy that restricts traffic to only certain IP ranges or ports.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: allow-specific-ip-range
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: pod-specific-ip-range
      match:
        resources:
          kinds:
            - NetworkPolicy
      validate:
        message: "Network policies must allow traffic from 192.168.0.0/16"
        pattern:
          spec:
            podSelector:
              matchLabels:
                app: myapp
            ingress:
              - from:
                  - ipBlock:
                      cidr: 192.168.0.0/16
```

</div>
</details>

## 8. Enforcing Node Affinity

Node affinity allows you to control which nodes your Kubernetes pods are scheduled on. You might want to enforce a policy that requires all pods to be scheduled on nodes with a specific label.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: require-backend-node-affinity
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: pod-backend-node-affinity
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Pods must be scheduled on nodes with the 'backend' label"
        pattern:
          spec:
            affinity:
              nodeAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                  nodeSelectorTerms:
                    - matchExpressions:
                        - key: role
                          operator: In
                          values:
                            - backend
```

</div>
</details>

## 9. Pod Restart Policies

Restart policies determine how Kubernetes handles pod restarts. You might want to enforce a policy that requires all pods to have a specific restart policy.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: require-always-restart-policy
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: pod-restart-policy
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Pods must have a restart policy of Always"
        pattern:
          spec:
            restartPolicy: Always
```

</div>
</details>

## 10. Resource Quotas on Namespaces

Resource quotas allow you to control the amount of resources that your Kubernetes namespaces can use. You might want to enforce a policy that requires all namespaces to have specific resource quotas.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: require-resource-quotas
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: namespace-resource-quotas
      match:
        resources:
          kinds:
            - ResourceQuota
      validate:
        message: "Namespaces must have a CPU limit of 2 and a memory limit of 1 GiB"
        pattern:
          spec:
            hard:
              limits.cpu: "2"
              limits.memory: "1Gi"
```

</div>
</details>

## 11. Pod Placement Constraints

Pod placement constraints allow you to control where your Kubernetes pods are scheduled. You might want to enforce a policy that requires all pods to be scheduled on nodes with specific taints or tolerations.

<details>
<summary>code</summary>
<div markdown="1">

```yaml
apiVersion: kyverno.io/v
kind: ClusterPolicy
metadata:
  name: require-tolerations
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: pod-tolerations
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Pods must tolerate the 'app=backend' taint"
        pattern:
          spec:
            tolerations:
              - key: "app"
                operator: "Equal"
                value: "backend"
                effect: "NoSchedule"
```

</div>
</details>

---

reference

- https://www.linkedin.com/pulse/kyverno-common-use-cases-afraz-ahmed/


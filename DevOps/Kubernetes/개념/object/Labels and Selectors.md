
- Labels are key/value pairs that are attached to objects such as Pods. 

- Labels are intended to be used to specify identifying attributes of objects that are **meaningful and relevant to users**, but **do not directly imply semantics to the core system.**

- Labels can be used to organize and to select subsets of objects.

- Labels can be attached to objects at creation time and subsequently added and modified at any time.

- Labels enable users to map their own organizational structures onto system objects in a loosely coupled fashion, without requiring clients to store these mappings.

- Service deployments and batch processing pipelines are often multi-dimensional entities (e.g., multiple partitions or deployments, multiple release tracks, multiple tiers, multiple micro-services per tier). Management often requires cross-cutting operations, which breaks encapsulation of strictly hierarchical representations, especially rigid hierarchies determined by the infrastructure rather than by users.

For example, here's a manifest for a Pod that has two labels `environment: production` and `app: nginx:`

```yml
apiVersion: v1
kind: Pod
metadata:
  name: label-demo
  labels:
    environment: production
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80
```

## Label selectors  

- Unlike names and UIDs, labels do not provide uniqueness. In general, we expect many objects to carry the same label(s).

- Via a label selector, the client/user can identify a set of objects. The label selector is the core grouping primitive in Kubernetes.

> For some API types, such as ReplicaSets, the label selectors of two instances must not overlap within a namespace, or the controller can see that as conflicting instructions and fail to determine how many replicas should be present.

- The API currently supports two types of selectors
  - equality-based (`=`, `==`, `!=`)
    ```yml
    environment = production # all resources with key equal to environment and value equal to production
    tier != frontend # all resources with no labels with the tier key, frontend value.
    ```
  - set-based.
    ```yml
    environment in (production, qa) # all resources with key equal to environment and value equal to production or qa.
    tier notin (frontend, backend) # all resources with key equal to tier and values other than frontend and backend, and all resources with no labels with the tier key.
    partition # including a label with key partition
    !partition # without a label with key partition
    ```

- A label selector can be made of multiple requirements which are comma-separated. In the case of multiple requirements, all must be satisfied so the comma separator acts as a logical AND (`&&`) operator.

> For both equality-based and set-based conditions there is no logical OR (||) operator. Ensure your filter statements are structured accordingly.
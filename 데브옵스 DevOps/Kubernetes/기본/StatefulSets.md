# StatefulSets

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/4ad965a1-a37c-427b-a0af-36c650186c81)

StatefulSets are a workload abstraction in Kubernetes to manage pods like you would a deployment. Unlike a deployment, StatefulSets add the following features for applications that require them:

- Stable, unique network identifiers
- Stable, persistent storage
- Ordered, graceful deployment and scaling
- Ordered, automated rolling updates

The deployment resource is better suited for applications that do not have these requirements (for example, a service that stores data in an external database).

Our database for the Golang minimal web server uses a StatefulSet. The database has a service, a ConfigMap for the Postgres username, a password, a test database name, and a StatefulSet for the containers running Postgres.

Let’s deploy it now:

```bash
kubectl apply -f database.yaml
service/postgres created
configmap/postgres-config created
statefulset.apps/postgres created
```

Let’s examine the DNS and network ramifications of using a StatefulSet.

To test DNS inside the cluster, we can use the `dnsutils` image; this image is `gcr .io/kubernetes-e2e-test-images/dnsutils:1.3` and is used for Kubernetes testing:

```bash
kubectl apply -f dnsutils.yaml

pod/dnsutils created

kubectl get pods
NAME       READY   STATUS    RESTARTS   AGE
dnsutils   1/1     Running   0          9s
```

With the replica configured with two pods, we see the StatefulSet deploy `postgres-0` and `postgres-1`, in that order, a feature of StatefulSets with IP address 10.244.1.3 and 10.244.2.3, respectively:

```bash
kubectl get pods -o wide
NAME         READY   STATUS    RESTARTS   AGE   IP           NODE
dnsutils     1/1     Running   0          15m   10.244.3.2   kind-worker3
postgres-0   1/1     Running   0          15m   10.244.1.3   kind-worker2
postgres-1   1/1     Running   0          14m   10.244.2.3   kind-worker
```

Here is the name of our headless service, Postgres, that the client can use for queries to return the endpoint IP addresses:

```bash
kubectl get svc postgres
NAME       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
postgres   ClusterIP                    <none>        5432/TCP   23m
```

Using our dnsutils image, we can see that the DNS names for the StatefulSets will return those IP addresses along with the cluster IP address of the Postgres service:

```bash
kubectl exec dnsutils -- host postgres-0.postgres.default.svc.cluster.local.
postgres-0.postgres.default.svc.cluster.local has address 10.244.1.3

kubectl exec dnsutils -- host postgres-1.postgres.default.svc.cluster.local.
postgres-1.postgres.default.svc.cluster.local has address 10.244.2.3

kubectl exec dnsutils -- host postgres
postgres.default.svc.cluster.local has address 10.105.214.153
```

StatefulSets attempt to mimic a fixed group of persistent machines. As a generic solution for stateful workloads, specific behavior may be frustrating in specific use cases.

A common problem that users encounter is an update requiring manual intervention to fix when using `.spec .updateStrategy.type: RollingUpdate, and .spec.podManagementPolicy: OrderedReady`, both of which are default settings. With these settings, a user must manually intervene if an updated pod never becomes ready.

Also, StatefulSets require a service, preferably headless, to be responsible for the network identity of the pods, and end users are responsible for creating this service.

Statefulsets have many configuration options, and many third-party alternatives exist (both generic stateful workload controllers and software-specific workload controllers).

StatefulSets offer functionality for a specific use case in Kubernetes. They should not be used for everyday application deployments. Later in this section, we will discuss more appropriate networking abstractions for run-of-the-mill deployments.

---
reference
- https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
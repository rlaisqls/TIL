
Using the same KIND cluster from the Cilium install, let's deploy the Postgres database([database.yaml](https://github.com/strongjz/Networking-and-Kubernetes/blob/master/chapter-4/database.yaml)) with the follwing `YAML` and `kubectl`

```bash
$ kubectl apply -f database.yaml
service/postgres created
configmap/postgres-config created
statefulset.apps/postgres created
```

Here we deploy our web server as a Kubernetes deployment([web.yaml](https://github.com/strongjz/Networking-and-Kubernetes/blob/master/chapter-4/web.yaml)) to our KIND cluster:

```bash
$ kubectl apply -f web.yaml
deployment.apps/app created
```

To run connectivity tests inside the cluster network, we will deploy and use a `dnsutils` pod([dnsutils.yaml](https://github.com/strongjz/Networking-and-Kubernetes/blob/master/chapter-4/dnsutils.yaml)) that has basic networking tools like `ping` and `curl`:

```bash
$ kubectl apply -f dnsutils.yaml
pod/dnsutils created
```

Since we are not deploying a service with an ingress, we can use `kubectl port-forward` to test connectivity to our web server:

```bash
kubectl port-forward app-5878d69796-j889q 8080:8080
```

Now from our local terminal, we can reach our API:

```bash
$ curl localhost:8080/
Hello
$ curl localhost:8080/healthz
Healthy
$ curl localhost:8080/data
Database Connected
```

Let’s test connectivity to our web server inside the cluster from other pods. To do that, we need to get the IP address of our web server pod:

```bash
$ kubectl get pods -l app=app -o wide
NAME                  READY  STATUS   RESTARTS  AGE  IP            NODE
app-5878d69796-j889q  1/1    Running  0         87m  10.244.2.21  kind-worker3
```

Now we can test L4 and L7 connectivity to the web server from the `dnsutils` pod:

```bash
$ kubectl exec dnsutils -- nc -z -vv 10.244.2.21 8080
10.244.2.21 (10.244.2.21:8080) open
sent 0, rcvd 0
```

From our dnsutils, we can test the layer 7 HTTP API access:

```bash
$ kubectl exec dnsutils -- wget -qO- 10.244.2.21:8080/
Hello

$ kubectl exec dnsutils -- wget -qO- 10.244.2.21:8080/data
Database Connected

$ kubectl exec dnsutils -- wget -qO- 10.244.2.21:8080/healthz
Healthy
```

We can also test this on the database pod. First, we have to retrieve the IP address of the database pod, `10.244.2.25`. We can use `kubectl` with a combination of labels and options to get this information:

```bash
$ kubectl get pods -l app=postgres -o wide
NAME         READY   STATUS    RESTARTS   AGE   IP             NODE
postgres-0   1/1     Running   0          98m   10.244.2.25   kind-worker
```

Again, let’s use `dnsutils` pod to test connectivity to the Postgres database over its default port 5432:

```bash
$ kubectl exec dnsutils -- nc -z -vv 10.244.2.25 5432
10.244.2.25 (10.244.2.25:5432) open
sent 0, rcvd 0
```

The port is open for all to use since no network policies are in place. Now let’s restrict this with a Cilium network policy. The following commands deploy the network policies so that we can test the secure network connectivity. Let’s first restrict access to the database pod to only the web server. Apply the network policy([layer_3_net_pol.yaml](https://github.com/strongjz/Networking-and-Kubernetes/blob/master/chapter-4/layer_3_net_pol.yaml)) that only allows traffic from the web server pod to the database:

```bash
$ kubectl apply -f layer_3_net_pol.yaml
ciliumnetworkpolicy.cilium.io/l3-rule-app-to-db created
```

The Cilium deploy of Cilium objects creates resources that can be retrieved just like pods with kubectl. With kubectl describe ciliumnetworkpolicies.cilium.io l3-rule-app-to-db, we can see all the information about the rule deployed via the YAML:

```bash
$ kubectl describe ciliumnetworkpolicies.cilium.io l3-rule-app-to-db
Name:         l3-rule-app-to-db
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  cilium.io/v2
Kind:         CiliumNetworkPolicy
Metadata:
  Creation Timestamp:  2023-07-25T04:48:10Z
  Generation:          1
  Resource Version:    597892
  UID:                 61b41c9d-eba0-4aa1-96da-cf534637cbcd
Spec:
  Endpoint Selector:
    Match Labels:
      App:  postgres
  Ingress:
    From Endpoints:
      Match Labels:
        App:  app
Events:       <none>
```

With the network policy applied, the `dnsutils` pod can no longer reach the database pod; we can see this in the timeout trying to reach the DB port from the `dnsutils` pods:

```bash
$ kubectl exec dnsutils -- nc -z -vv -w 5 10.244.2.25 5432
nc: 10.244.2.25 (10.244.2.25:5432): Operation timed out
sent 0, rcvd 0
command terminated with exit code 1
```

While the web server pod is still connected to the database pod, the /data route connects the web server to the database and the NetworkPolicy allows it:

```bash
$ kubectl exec dnsutils -- wget -qO- 10.244.2.21:8080/data
Database Connected

$ curl localhost:8080/data
Database Connected
```

Now let’s apply the layer 7 policy. Cilium is layer 7 aware so that we can block or allow a specific request on the HTTP URI paths. In our example policy, we allow HTTP GETs on `/` and `/data` but do not allow them on `/healthz`; let’s test that:

```bash
$ kubectl apply -f layer_7_netpol.yml
ciliumnetworkpolicy.cilium.io/l7-rule created
```

We can see the policy applied just like any other Kubernetes objects in the API:

```bash
$ kubectl get ciliumnetworkpolicies.cilium.io
NAME      AGE
l7-rule   6m54s

$ kubectl describe ciliumnetworkpolicies.cilium.io l7-rule
Name:         l7-rule
Namespace:    default
Labels:       <none>
Annotations:  API Version:  cilium.io/v2
Kind:         CiliumNetworkPolicy
Metadata:
  Creation Timestamp:  2021-01-10T00:49:34Z
  Generation:          1
  Managed Fields:
    API Version:  cilium.io/v2
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        .:
        f:egress:
        f:endpointSelector:
          .:
          f:matchLabels:
            .:
            f:app:
    Manager:         kubectl
    Operation:       Update
    Time:            2021-01-10T00:49:34Z
  Resource Version:  43869
  Self Link:/apis/cilium.io/v2/namespaces/default/ciliumnetworkpolicies/l7-rule
  UID:               0162c16e-dd55-4020-83b9-464bb625b164
Spec:
  Egress:
    To Ports:
      Ports:
        Port:      8080
        Protocol:  TCP
      Rules:
        Http:
          Method:  GET
          Path:    /
          Method:  GET
          Path:    /data
  Endpoint Selector:
    Match Labels:
      App:  app
Events:     <none>
```

As we can see, `/` and `/data` are available but not /healthz, precisely what we expect from the NetworkPolicy:

```bash
$ kubectl exec dnsutils -- wget -qO- 10.244.2.21:8080/data
Database Connected

$kubectl exec dnsutils -- wget -qO- 10.244.2.21:8080/
Hello

$ kubectl exec dnsutils -- wget -qO- -T 5 10.244.2.21:8080/healthz
wget: error getting response
command terminated with exit code 1
```

These small examples show how powerful the Cilium network policies can enforce network security inside the cluster. We highly recommend that administrators select a CNI that supports network policies and enforce developers’ use of network policies. Network policies are namespaced, and if teams have similar setups, cluster administrators can and should enforce that developers define network policies for added security.

We used two aspects of the Kubernetes API, labels and selectors; in our next section, we will provide more examples of how they are used inside a cluster.



Since not all services live in the sevice mesh, we need a way for **services inside the mesh to communicate with those outdise the mesh**. Those could be existing HTTP services or, more likely, infrastructure services like databases or caches. We can still implement sophisticated routing for services that reside outside Istio, but first we have to introduce the concept of a `ServiceEntry`.

Istio builds up an **internal service registry** of all the services that are known by the mesh and that can be accessed within the mesh. You can think of this registry as the canoncal representation of a service-discovery registry that services within the mesh can use to find other services.

Istio builds this internal registry by making assumptions about the platforkm on which the control plane is deployed. Istio uses the default Kubernetes API to build its catalog of [services](https://kubernetes.io/docs/concepts/services-networking/service). For our services within the mesh to communicate with those outside the mesh, we need to let Istio's service-discovery registry know about this external service.

We can specify `ServiceEntry` resources that augment and insert external services into the Istio service registry.

### example

The Istio ServiceEntry resource encapsulates registry metadata that we can use to insert an entry into Istio’s service registry. Here’s an example:

```bash
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: jsonplaceholder
spec:
  hosts:
  - jsonplaceholder.typicode.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
  location: MESH_EXTERNAL
```

This `ServiceEntry` resource inserts an entry into Istio’s service registry, which makes explicit that clients within the mesh are allowed to call JSON Placeholder using host `jsonplaceholder.typicode.com`. The JSON Placeholder service exposes a sample REST API that we can use to simulate talking with services that live outside our cluster. Before we create this service entry, let’s install a service that talks to the `jsonplaceholder.typicode.com` REST API and observe that Istio indeed blocks any outbound traffic.
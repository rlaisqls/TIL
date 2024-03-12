
**Contour** is an Envoy based ingress controller.

And it is an open source Kubernetes ingress controller providing the control plane for the Envoy edge and service proxy.​

Contour supports dynamic configuration updates and multi-team ingress delegation out of the box while maintaining a lightweight profile.

## Getting Started with Contour

Let's look at three ways to install Contour

- using Contour’s example YAML
- using the Helm chart for Contour
- using the Contour gateway provisioner (beta)

## Install Contour and Envoy

### 1. YAML

```bash
$ kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
```

Verify the Contour pods are ready by running the following:

```bash
$ kubectl get pods -n projectcontour -o wide
```

You should see the following:

- 2 Contour pods each with status Running and 1/1 Ready
- 1+ Envoy pod(s), each with the status Running and 2/2 Ready

### 2. Helm

This option requires Helm to be installed locally.

Add the bitnami chart repository (which contains the Contour chart) by running the following:

```bash
$ helm repo add bitnami https://charts.bitnami.com/bitnami
```

Install the Contour chart by running the following:

```bash
$ helm install my-release bitnami/contour --namespace projectcontour --create-namespace
```

Verify Contour is ready by running:

```bash
$ kubectl -n projectcontour get po,svc
```

You should see the following:

- 1 instance of pod/my-release-contour-contour with status Running and 1/1 Ready
- 1+ instance(s) of pod/my-release-contour-envoy with each status Running and 2/2 Ready
- 1 instance of service/my-release-contour
- 1 instance of service/my-release-contour-envoy

### 3. Contour Gateway Provisioner (beta)

The Gateway provisioner watches for the creation of Gateway API (`Gateway`) resources, and dynamically provisions Contour+Envoy instances based on the `Gateway's` spec.

Note that although the provisioning request itself is made via a Gateway API resource (`Gateway`), this method of installation still allows you to use any of the supported APIs for defining virtual hosts and routes: `Ingress`, `HTTPProxy`, or Gateway API’s `HTTPRoute` and `TLSRoute`.

In fact, below code will use an Ingress resource to define routing rules, even when using the Gateway provisioner for installation.

Deploy the Gateway provisioner:

```bash
$ kubectl apply -f https://projectcontour.io/quickstart/contour-gateway-provisioner.yaml
```

Verify the Gateway provisioner deployment is available:

```bash
$ kubectl -n projectcontour get deployments
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
contour-gateway-provisioner   1/1     1            1           1m
```

Create a GatewayClass:

```bash
kubectl apply -f - <<EOF
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: contour
spec:
  controllerName: projectcontour.io/gateway-controller
EOF
```

Create a Gateway:

```bash
kubectl apply -f - <<EOF
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: contour
  namespace: projectcontour
spec:
  gatewayClassName: contour
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
EOF
```

Verify the Gateway is available (it may take up to a minute to become available):

```bash
$ kubectl -n projectcontour get gateways
NAME        CLASS     ADDRESS         READY   AGE
contour     contour                   True    27s
```

Verify the Contour pods are ready by running the following:

```bash
$ kubectl -n projectcontour get pods
```

You should see the following:

- 2 Contour pods each with status Running and 1/1 Ready
- 1+ Envoy pod(s), each with the status Running and 2/2 Ready

## Test

You have installed Contour and Envoy! Let’s install a web application workload and get some traffic flowing to the backend.

To install httpbin, run the following:

```bash
$ kubectl apply -f https://projectcontour.io/examples/httpbin.yaml
```

Verify the pods and service are ready by running:


```bash
$ kubectl get po,svc,ing -l app=httpbin
```

You should see the following:

- 3 instances of pods/httpbin, each with status Running and 1/1 Ready
- 1 service/httpbin CLUSTER-IP listed on port 80
- 1 Ingress on port 80

> The Helm install configures Contour to filter Ingress and HTTPProxy objects based on the contour IngressClass name. If using Helm, ensure the Ingress has an ingress class of contour with the following:


```bash
$ kubectl patch ingress httpbin -p '{"spec":{"ingressClassName": "contour"}}'
```

Now we’re ready to send some traffic to our sample application, via Contour & Envoy.

Note, for simplicity and compatibility across all platforms we’ll use kubectl port-forward to get traffic to Envoy, but in a production environment you would typically use the Envoy service’s address.

Port-forward from your local machine to the Envoy service:

```bash
# If using YAML
$ kubectl -n projectcontour port-forward service/envoy 8888:80

# If using Helm
$ kubectl -n projectcontour port-forward service/my-release-contour-envoy 8888:80

# If using the Gateway provisioner
$ kubectl -n projectcontour port-forward service/envoy-contour 8888:80
```

In a browser or via curl, make a request to `http://local.projectcontour.io:8888 `(`local.projectcontour.io` is a public DNS record resolving to 127.0.0.1 to make use of the forwarded port). You should see the httpbin home page.

Congratulations, you have installed Contour, deployed a backend application, created an Ingress to route traffic to the application, and successfully accessed the app with Contour!

---
reference
- https://projectcontour.io/getting-started/
- https://projectcontour.io/docs/v1.10.0/
- https://github.com/projectcontour/contour
# HTTPProxy

The Ingress object was added to Kubernetes in version `1.1` to describe properties of a cluster-wide reverse HTTP proxy. Since that time, the Ingress API has remained relatively unchanged, and the need to express implementation-specific capabilities has inspired an explosion of annotations.

The goal of the HTTPProxy Custom Resource Definition (CRD) is to **expand upon the functionality of the Ingress API to allow for a richer user experience** as well addressing the limitations of the latter’s use in multi tenant environments.

## Benefits

- Safely supports multi-team Kubernetes clusters, with the ability to limit which Namespaces may configure virtual hosts and TLS credentials.
- Enables including of routing configuration for a path or domain from another HTTPProxy, possibly in another Namespace.
- Accepts multiple services within a single route and load balances traffic across them.
- Natively allows defining service weighting and load balancing strategy without annotations.
- Validation of HTTPProxy objects at creation time and status reporting for post-creation validity.

## Ingress to HTTPProxy
A minimal Ingress object might look like:

```yml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic
spec:
  rules:
  - host: foo-basic.bar.com
    http:
      paths:
      - backend:
          service:
            name: s1
            port:
              number: 80
```

This Ingress object, named `basic`, will route incoming HTTP traffic with a `Host:` header for `foo-basic.bar.com` to a Service named `s1` on port `80`. Implementing similar behavior using an HTTPProxy looks like this:

```yml
# httpproxy.yaml
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: basic
spec:
  virtualhost:
    fqdn: foo-basic.bar.com
  routes:
    - conditions:
      - prefix: /
      services:
        - name: s1
          port: 80
```

- Lines 1-5: As with all other Kubernetes objects, an HTTPProxy needs apiVersion, kind, and metadata fields.

- Lines 7-8: The presence of the virtualhost field indicates that this is a root HTTPProxy that is the top level entry point for this domain.

## Interacting with HTTPProxies

As with all Kubernetes objects, you can use kubectl to create, list, describe, edit, and delete HTTPProxy CRDs.

#### Creating an HTTPProxy:

```yml
$ kubectl create -f basic.httpproxy.yaml
httpproxy "basic" created
```

#### Listing HTTPProxies:

```yml
$ kubectl get httpproxy
NAME      AGE
basic     24s
```

#### Describing HTTPProxy:

```yml
$ kubectl describe httpproxy basic
Name:         basic
Namespace:    default
Labels:       <none>
API Version:  projectcontour.io/v1
Kind:         HTTPProxy
Metadata:
  Cluster Name:
  Creation Timestamp:  2019-07-05T19:26:54Z
  Resource Version:    19373717
  Self Link:           /apis/projectcontour.io/v1/namespaces/default/httpproxy/basic
  UID:                 6036a9d7-8089-11e8-ab00-f80f4182762e
Spec:
  Routes:
    Conditions:
      Prefix: /
    Services:
      Name:  s1
      Port:  80
  Virtualhost:
    Fqdn:  foo-basic.bar.com
Events:    <none>
```

#### Deleting HTTPProxies:

```yml
$ kubectl delete httpproxy basic
```
httpproxy "basic" deleted

## Status Reporting

There are many misconfigurations that could cause an HTTPProxy or delegation to be invalid. To aid users in resolving these issues, Contour updates a status field in all HTTPProxy objects. In the current specification, invalid HTTPProxy are ignored by Contour and will not be used in the ingress routing configuration.

If an HTTPProxy object is valid, it will have a status property that looks like this:

```yml
status:
  currentStatus: valid
  description: valid HTTPProxy
```

If the HTTPProxy is invalid, the currentStatus field will be invalid and the description field will provide a description of the issue.

As an example, if an HTTPProxy object has specified a negative value for weighting, the HTTPProxy status will be:

```yml
status:
  currentStatus: invalid
  description: "route '/foo': service 'home': weight must be greater than or equal to zero"
```

---
reference
- https://projectcontour.io/docs/v1.18.0/config/api/

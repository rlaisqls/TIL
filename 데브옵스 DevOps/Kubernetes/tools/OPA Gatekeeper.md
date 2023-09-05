# OPA Gatekeeper

The [Open Policy Agent Gatekeeper](https://github.com/open-policy-agent/gatekeeper) project can be laveraged to help enforce policies and strengthen governence in your Kubernetes environment. 

If your organization has been operating Kubernetes, you probably have been looking for ways to control what end-users can do on the cluster and ways to ensure that clusters are in compliance with company policies. These policies may be there to meet governance and legal requirements or to enforce best practices and organizational conventions. With Kubernetes, how do you ensure compliance without sacrificing development agility and operational independence?

For example, you can enforce policies like:

- All images must be from approved repositories
- All ingress hostnames must be globally unique
- All pods must have resource limits
- All namespaces must have a label that lists a point-of-contact
  
Kubernetes allows decoupling policy decisions from the API server by means of admission controller webhooks to intercept admission requests before they are persisted as objects in Kubernetes.

Gatekeeper was created to enable users to customize admission control via configuration, not code and to bring awareness of the cluster’s state, not just the single object under evaluation at admission time. Gatekeeper is a customizable admission webhook for Kubernetes that enforces policies executed by the Open Policy Agent (OPA), a policy engine for Cloud Native environments hosted by CNCF.

![image](https://github.com/rlaisqls/TIL/assets/81006587/e870ebcc-1ae3-4cb7-86e2-f0e27a81b8f4)

## Features

let’s take a closer look at the current state of Gatekeeper and how you can leverage all the latest features. Consider an organization that wants to ensure all objects in a cluster have departmental information provided as part of the object’s labels. How can you do this with Gatekeeper?

### Validating Admission Control

Once all the Gatekeeper components have been installed in your cluster, the API server will trigger the Gatekeeper admission webhook to process the admission request whenever a resource in the cluster is created, updated, or deleted.

During the validation process, Gatekeeper acts as a bridge between the API server and OPA. The API server will enforce all policies executed by OPA.

### Policies and Constraints

With the integration of the OPA Constraint Framework, a Constraint is a declaration that its author wants a system to meet a given set of requirements. Each Constraint is written with Rego, a declarative query language used by OPA to enumerate instances of data that violate the expected state of the system. All Constraints are evaluated as a logical AND. If one Constraint is not satisfied, then the whole request is rejected.

Before defining a Constraint, you need to create a Constraint Template that allows people to declare new Constraints. Each template describes both the Rego logic that enforces the Constraint and the schema for the Constraint, which includes the schema of the CRD and the parameters that can be passed into a Constraint, much like arguments to a function.

For example, here is a Constraint template CRD that requires certain labels to be present on an arbitrary object.

```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
        listKind: K8sRequiredLabelsList
        plural: k8srequiredlabels
        singular: k8srequiredlabels
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          properties:
            labels:
              type: array
              items: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        deny[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("you must provide labels: %v", [missing])
        }        
```

Once a Constraint template has been deployed in the cluster, an admin can now create individual Constraint CRDs as defined by the Constraint template. For example, here is a Constraint CRD that requires the label hr to be present on all namespaces.

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-hr
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels: ["hr"]
```

Similarly, another Constraint CRD that requires the label finance to be present on all namespaces can easily be created from the same Constraint template.

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-finance
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels: ["finance"]
```

As you can see, with the Constraint framework, we can reliably share Regos via the Constraint templates, define the scope of enforcement with the match field, and provide user-defined parameters to the Constraints to create customized behavior for each Constraint.

### Audit

The audit functionality enables periodic evaluations of replicated resources against the Constraints enforced in the cluster to detect pre-existing misconfigurations. Gatekeeper stores audit results as violations listed in the status field of the relevant Constraint.

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-hr
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels: ["hr"]
status:
  auditTimestamp: "2019-08-06T01:46:13Z"
  byPod:
  - enforced: true
    id: gatekeeper-controller-manager-0
  violations:
  - enforcementAction: deny
    kind: Namespace
    message: 'you must provide labels: {"hr"}'
    name: default
  - enforcementAction: deny
    kind: Namespace
    message: 'you must provide labels: {"hr"}'
    name: gatekeeper-system
  - enforcementAction: deny
    kind: Namespace
    message: 'you must provide labels: {"hr"}'
    name: kube-public
  - enforcementAction: deny
    kind: Namespace
    message: 'you must provide labels: {"hr"}'
    name: kube-system
```

### Data Replication

Audit requires replication of Kubernetes resources into OPA before they can be evaluated against the enforced Constraints. Data replication is also required by Constraints that need access to objects in the cluster other than the object under evaluation. For example, a Constraint that enforces uniqueness of ingress hostname must have access to all other ingresses in the cluster.

To configure Kubernetes data to be replicated, create a sync config resource with the resources to be replicated into OPA. For example, the below configuration replicates all namespace and pod resources to OPA.

```yaml
apiVersion: config.gatekeeper.sh/v1alpha1
kind: Config
metadata:
  name: config
  namespace: "gatekeeper-system"
spec:
  sync:
    syncOnly:
      - group: ""
        version: "v1"
        kind: "Namespace"
      - group: ""
        version: "v1"
        kind: "Pod"
```

---
reference
- https://kubernetes.io/blog/2019/08/06/opa-gatekeeper-policy-and-governance-for-kubernetes/
- [Intro: Open Policy Agent Gatekeeper](https://youtu.be/Yup1FUc2Qn0)
- [Deep Dive: Open Policy Agent](https://youtu.be/n94_FNhuzy4)
- https://github.com/open-policy-agent/gatekeeper-library/tree/master/library/general
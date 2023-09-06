# Kyverno

Kyverno(Greek for “govern”) is a policy engine designed for Kubernetes. It can validate, mutate, and generate configurations using admission controls and background scans, Kyverno policies are Kubernetes resources and do not require learning new language. Kyverno is designed to work nicely with tools you already use like kubectl, kustomize, and Git.

## Featchers

Kyverno is a policy engine designed specifically for Kubernetes. Some of its many features include:
- Policies as Kubernetes resources
- Validate, mutate, generate, or cleanup (remove) any resource
- Verify container images for aoftware supply chain securirty
- Inspect image metadata
- Match resources using label selectors and wildcards
- Validate and mutate using overlays (like Kustomize!)
- Syncronize configurations across Namespaces
- Block non-conformant resources using admission controls, or report policy violations
- Self-service reports (no proprietary audit log!)
- Self-service policy exceptions
- Test policies and validate resources using the Kyverno CLI, in your CI/CD pipeline, before applying to your cluster.
- Manage policies as code using familiar tools like `git` and `kustomize`

Kyverno allows cluster administrators to manage environment specific configurations independently of workload configurations and enforce configuration best practices for their clusters. Kyverno can be used to scan existing workloads for best practices, or can be used to enforce best practices by blocking or mutating API requests.

## How Kyverno works

Kyberno runs as [dynamic admission controller](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) in a Kubernetes cluster. Kyverno receives validation and mutating admission webhook HTTP callbacks from the Kubernetes API server and applies matching polcies to return results that enforce admission policies or reject requests.

Kyverno policies can match resources using the resource kind, name, label selectors, and much more.

Mutating policies can be written as overlays (similar to [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/#bases-and-overlays)) or as a [RFC 6902 JSON Patch](http://jsonpatch.com/). Validating policies also use an overlay style syntax, with support for pattern matching and conditional (if-then-else) processing.

Policy enforcement is captured using Kubernetes events. For requests that are either allowed or existed prior to introduction of a Kyverno policy, Kyverno creates Policy Reports in the cluster which contain a running list of resources matched by a policy, their status and more.

The diagram below shows the high-level logical architecture of Kyverno.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/71b5743e-e7a0-474b-a5c4-6356ad85b3be)

- The **Webhook** is the server which handles incoming AdmissionReview requests from the Kubernetes API server and send them to the **Engine** for processing.
- It is dynamically configured by the **Webhook Controller** which watches the installed policies and modifies the webhooks to request only the resources matched by those policies.
- The **Cert Renewer** is responsible for watching and renewing and renewing the certificates, stored as Kubernetes Secrets, needed by the webhook.
- The **Background Controller** handles all generate and mutate-existing policies by reconviling UpdateRequests, an intermediary resource.
- And the **Report Controllers** handle creation and reconviliation of Policy Reports from their intermediary resources Admission Reports and Background Scan Reports.

## Installation

Regardless of the method, Kyverno must always be installed in a dedicated Namespace; it must not be co-located with other applications in existing Namespaces including system Namespaces such as kube-system.

The Kyverno Namespace should also not be used for deployment of other, unrelated applications and services.

The diagram below shows a typical Kyverno installation featuring all available controllers.

<img height=300px src="https://github.com/rlaisqls/TIL/assets/81006587/81f18fbd-e507-4b85-85aa-89688c3a44b5">

A standard Kyverno installation consists of a number of different componets, some of which are optional.

- **Deployments**
  - Admission controller (required): The main component of Kyverno which handles webhook callbacks from the API server for verification, mutation, [Policy Exceptions](https://kyverno.io/docs/writing-policies/exceptions/), and the processing engine.
  - Background controller (optional): The component responsible for processing of generate and mutate-existing rules.
  - Reports controller (optional): The component responsible for handling of [Policy Reports](https://kyverno.io/docs/policy-reports/).
  - Cleanup controller (optional): The component responsible for processing of [Cleanup Policies](https://kyverno.io/docs/writing-policies/cleanup/).
- **Services**
  - Services needed to receive webhook requests.
  - Services needed for monitoring of metrics.
- **ServiceAccounts**
  - One ServiceAccount per controller to segregate and confine the permissions needed for each controller to operate on the resources for which it is responsible.
- **ConfigMaps**
  - ConfigMap for holding the main Kyverno configuration.
  - ConfigMap for holding the metrics configuration.
- **Secrets**
  - Secrets for webhook registration and authentication with the API server.
- **Roles and Bindings**
  - Roles and ClusterRoles, Bindings and ClusterRoleBindings authorizing the various ServiceAccounts to act on the resources in their scope.
- **Webhooks**
  - ValidatingWebhookConfigurations for receiving both policy and resource validation requests.
  - MutatingWebhookConfigurations for receiving both policy and resource mutating requests.
- **CustomResourceDefinitions**
  - CRDs which define the custom resources corresponding to policies, reports, and their intermediary resources.

## Policies and Rules

A Kyverno policy is a collection of rules. Each rule consists of a [match](https://kyverno.io/docs/writing-policies/match-exclude/) declaration, an optional [exclude](https://kyverno.io/docs/writing-policies/match-exclude/) declaration, and one of a [validate](https://kyverno.io/docs/writing-policies/validate/), [mutate](https://kyverno.io/docs/writing-policies/mutate/), [generate](https://kyverno.io/docs/writing-policies/generate), or [verifyImages](https://kyverno.io/docs/writing-policies/verify-images) declaration. 

<img src="https://github.com/rlaisqls/TIL/assets/81006587/210d145a-0821-490b-89b7-28bfcea3a0a0" height=300px>

Policies can be defined as cluster-wide resources (using the kind `ClusterPolicy`) or namespaced resources (using the kind `Policy`). As excepted, namespaced policies will only apply to resources within the namespace in which they are defined while cluster-wide policies are applied to matching resources acress all namespaces. Otherwise, there is no difference between the two types.

Additional policy types include Policy Exceptions and Cleanup Policies which are separate resources and described futher in the documentation.

---
reference
- https://github.com/kyverno/kyverno
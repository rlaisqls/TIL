
Let’s deploy Cilium for testing with our Golang web server in below example. We will need a Kubernetes cluster for deploying Cilium. One of the easiest ways we have found to deploy clusters for testing locally is KIND, which stands for Kubernetes in Docker. It will allow us to create a cluster with a YAML configuration file and then, using Helm, deploy Cilium to that cluster.

#### KIND configuration for Cilium local deploy

```yaml
kind: Cluster #---1
apiVersion: kind.x-k8s.io/v1alpha4 #---2
nodes: #---3
- role: control-plane #---4
- role: worker #---5
- role: worker #---6
- role: worker #---7
networking: #---8
disableDefaultCNI: true #---9
```

1. Specifies that we are configuring a KIND cluster
2. The version of KIND’s config
3. The list of nodes in the cluster
4. One control plane node
5. Worker node 1
6. Worker node 2
7. Worker node 3
8. KIND configuration options for networking
9. Disables the default networking option so that we can deploy Cilium

With the KIND cluster configuration yaml, we can use KIND to create that cluster with following command. If this is the first time you're runnging it, it will take some time to download all the Docker images for the working and control plane Docker images:

```bash
$ kind create cluster --config=kind-config.yaml
Creating cluster "kind" ...
✓ Ensuring node image (kindest/node:v1.18.
2) Preparing nodes
✓ Writing configuration Starting control-plane
Installing StorageClass Joining worker nodes Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Have a question, bug, or feature request?
Let us know! https://kind.sigs.k8s.io/#community ߙ⊭---

Always verify that the cluster is up and running with kubectl.
```

```bash
$ kubectl cluster-info --context kind-kind
Kubernetes master -> control plane is running at https://127.0.0.1:59511
KubeDNS is running at
https://127.0.0.1:59511/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
To further debug and diagnose cluster problems, use 'kubectl cluster-info dump.'
```

> The cluster nodes will remain in state NotReady until Cilium deploys the network. This is normal behavior for the cluster.

Now that our cluster is running locally, we can begin installing Cilium using Helm, a Kubernetes deployment tool.

According to its documentation, Helm is the preferred way to install Cilium. First, we need to add the Helm repo for Cilium. Optionally, you can download the Docker images for Cilium and finally instruct KIND to load the Cilium images into the cluster:

```bash
$ helm repo add cilium https://helm.cilium.io/
# Pre-pulling and loading container images is optional.
$ docker pull cilium/cilium:v1.9.1
kind load docker-image cilium/cilium:v1.9.1
```

Now that the prerequisites for Cilium are completed, we can install it in our cluster with Helm. There are many configuration options for Cilium, and Helm configures options with `--set NAME_VAR=VAR`:

```bash
$ helm install cilium cilium/cilium --version 1.10.1 --namespace kube-system

NAME: Cilium
LAST DEPLOYED: Fri Jan  1 15:39:59 2021
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
You have successfully installed Cilium with Hubble.

Your release version is 1.10.1.

For any further help, visit https://docs.cilium.io/en/v1.10/gettinghelp/
```

Cilium installs serveral pieces in the clster: the agent, the client, the operator, and the `cilium-cni` plugin:

- **Agent**
  - The Cilium agent, runs on each node in the cluster. The agent accepts configuration through Kubernetes APIs that describe networking, service load balancing, network policies, and visibility and monitoring requirements.

- **Client (CLI)**
  - The Cilium CLI client (Cilium) is a command-line tool installed along with the Cilium agent. It interacts with the REST API on the same node. The CLI allows developers to inspect the state and status of the local agent. It also provides tooling to access the eBPF maps to validate their state directly.

- **Operator**
  - The operator is responsible for managing duties in the cluster, which should be handled per cluster and not per node.

- **CNI Plugin**
  - The CNI plugin (cilium-cni) interacts with the Cilium API of the node to trigger the configuration to provide networking, load balancing, and network policies pods.

We can observe all these components being deployed in the cluster with the `kubectl -n kube-system get pods --watch` command:

```bash
$ kubectl -n kube-system get pods --watch
NAME                                         READY   STATUS
cilium-65kvp                                 0/1     Init:0/2
cilium-node-init-485lj                       0/1     ContainerCreating
cilium-node-init-79g68                       1/1     Running
cilium-node-init-gfdl8                       1/1     Running
cilium-node-init-jz8qc                       1/1     Running
cilium-operator-5b64c54cd-cgr2b              0/1     ContainerCreating
cilium-operator-5b64c54cd-tblbz              0/1     ContainerCreating
cilium-pg6v8                                 0/1     Init:0/2
cilium-rsnqk                                 0/1     Init:0/2
cilium-vfhrs                                 0/1     Init:0/2
coredns-66bff467f8-dqzql                     0/1     Pending
coredns-66bff467f8-r5nl6                     0/1     Pending
etcd-kind-control-plane                      1/1     Running
kube-apiserver-kind-control-plane            1/1     Running
kube-controller-manager-kind-control-plane   1/1     Running
kube-proxy-k5zc2                             1/1     Running
kube-proxy-qzhvq                             1/1     Running
kube-proxy-v54p4                             1/1     Running
kube-proxy-xb9tr                             1/1     Running
kube-scheduler-kind-control-plane            1/1     Running
cilium-operator-5b64c54cd-tblbz              1/1     Running
```

Now that we have deployed Cilium, we can run the Cilium connectivity check to ensure it is running correctly:

```bash
$ kubectl create ns cilium-test
namespace/cilium-test created

$ kubectl apply -n cilium-test \
-f \
https://raw.githubusercontent.com/strongjz/advanced_networking_code_examples/master/chapter-4/connectivity-check.yaml

deployment.apps/echo-a created
deployment.apps/echo-b created
deployment.apps/echo-b-host created
deployment.apps/pod-to-a created
deployment.apps/pod-to-external-1111 created
deployment.apps/pod-to-a-denied-cnp created
deployment.apps/pod-to-a-allowed-cnp created
deployment.apps/pod-to-external-fqdn-allow-google-cnp created
deployment.apps/pod-to-b-multi-node-clusterip created
deployment.apps/pod-to-b-multi-node-headless created
deployment.apps/host-to-b-multi-node-clusterip created
deployment.apps/host-to-b-multi-node-headless created
deployment.apps/pod-to-b-multi-node-nodeport created
deployment.apps/pod-to-b-intra-node-nodeport created
service/echo-a created
service/echo-b created
service/echo-b-headless created
service/echo-b-host-headless created
ciliumnetworkpolicy.cilium.io/pod-to-a-denied-cnp created
ciliumnetworkpolicy.cilium.io/pod-to-a-allowed-cnp created
ciliumnetworkpolicy.cilium.io/pod-to-external-fqdn-allow-google-cnp created
```

The connectivity test will deploy a series of Kubernetes deployments that will use various connectivity paths. Connectivity paths come with and without service load balancing and in various network policy combinations. The pod name indicates the connectivity variant, and the readiness and liveness gate indicates the success or failure of the test:

```bash
$ kubectl get pods -n cilium-test -w
NAME                                                     READY   STATUS
echo-a-57cbbd9b8b-szn94                                  1/1     Running
echo-b-6db5fc8ff8-wkcr6                                  1/1     Running
echo-b-host-76d89978c-dsjm8                              1/1     Running
host-to-b-multi-node-clusterip-fd6868749-7zkcr           1/1     Running
host-to-b-multi-node-headless-54fbc4659f-z4rtd           1/1     Running
pod-to-a-648fd74787-x27hc                                1/1     Running
pod-to-a-allowed-cnp-7776c879f-6rq7z                     1/1     Running
pod-to-a-denied-cnp-b5ff897c7-qp5kp                      1/1     Running
pod-to-b-intra-node-nodeport-6546644d59-qkmck            1/1     Running
pod-to-b-multi-node-clusterip-7d54c74c5f-4j7pm           1/1     Running
pod-to-b-multi-node-headless-76db68d547-fhlz7            1/1     Running
pod-to-b-multi-node-nodeport-7496df84d7-5z872            1/1     Running
pod-to-external-1111-6d4f9d9645-kfl4x                    1/1     Running
pod-to-external-fqdn-allow-google-cnp-5bc496897c-bnlqs   1/1     Running
```

---

reference
- https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch04.html#idm46219938952648
- https://cilium.io
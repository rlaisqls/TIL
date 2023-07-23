# Install Calico 

1. Install the Calico operator and cudtom resource definitions

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml
```

> Due to the large size of the CRD bundle, `kubectl apply` might exceed request limits. Instead, use `kubectl create` or `kubectl replace`.

2. Install Calico by creating the necessary custom resource. For more information on configuration options available in this manifest, see [the installation reference.](https://docs.tigera.io/calico/latest/reference/installation/api)

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml
```

> Before creating this manifest, read its contents and make sure its settings are correct for your environment. For example, you may need to change the default IP pool CIDR to match your pod network CIDR.

3. Confirm that all of the pods are running with the following command.

```bash
watch kubectl get pods -n calico-system
```

Wait until each pod has the `STATUS` of `Running`.

> The Tigera operator installs resources in the calico-system namespace. Other install methods may use the `kube-system` namespace instead.

4. Remove the taints on the control plane so that you can schedule pods on it.

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-
```

It should return the following.

```bash
node/<your-hostname> untainted
```

Confirm that you now have a node in your cluster with the following command.

```bash
kubectl get nodes -o wide
```

It should return something like the following.

```bash
NAME              STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
<your-hostname>   Ready    master   52m   v1.12.2   10.128.0.28   <none>        Ubuntu 18.04.1 LTS   4.15.0-1023-gcp   docker://18.6.1
```

You now have a single-host Kubernetes cluster with Calico!


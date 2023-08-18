# CSIDriber

CSIDriver **captures information about a Container Storage Interface (CSI) volume driver deployed on the cluster**. Kubernetes attach detach controller uses this object to determine whether attach is required. Kubelet uses this object to determine whether pod information needs to be passed on mount. CSIDriver objects are non-namespaced.

The CSIDriver Kubernetes API object serves two purposes:

1. Simplify driver discovery
   - If a CSI driver creates a CSIDriver object, Kubernetes users can easily discover the CSI Drivers installed on their cluster (simply by issuing kubectl get CSIDriver)
  
2. Customizing Kubernetes behavior
   - Kubernetes has a default set of behaviors when dealing with CSI Drivers (for example, it calls the Attach/Detach operations by default). This object allows CSI drivers to specify how Kubernetes should interact with it.

## What fields does the CSIDriver object have?

Here is an example of a v1 CSIDriver object:

```yaml
apiVersion: storage.k8s.io/v1
kind: CSIDriver
metadata:
  name: mycsidriver.example.com
spec:
  attachRequired: true
  podInfoOnMount: true
  fsGroupPolicy: File # added in Kubernetes 1.19, this field is GA as of Kubernetes 1.23
  volumeLifecycleModes: # added in Kubernetes 1.16, this field is beta
    - Persistent
    - Ephemeral
  tokenRequests: # added in Kubernetes 1.20. See status at https://kubernetes-csi.github.io/docs/token-requests.html#status
    - audience: "gcp"
    - audience: "" # empty string means defaulting to the `--api-audiences` of kube-apiserver
      expirationSeconds: 3600
  requiresRepublish: true # added in Kubernetes 1.20. See status at https://kubernetes-csi.github.io/docs/token-requests.html#status
  seLinuxMount: true # Added in Kubernetest 1.25.
```

These are the important fields:

- `name`
  - This should correspond to the full name of the CSI driver.

- `attachRequired`
  - Indicates this CSI volume driver requires an attach operation (because it implements the CSI `ControllerPublishVolume` method), and that Kubernetes should call attach and wait for any attach operation to complete before proceeding to mounting.
  - If a `CSIDriver` object does not exist for a given CSI Driver, the default is true -- meaning attach will be called.
  - If a `CSIDriver` object exists for a given CSI Driver, but this field is not specified, it also defaults to true -- meaning attach will be called.
  - For more information see Skip Attach.
- `podInfoOnMount`
  - Indicates this CSI volume driver requires additional pod information (like pod name, pod UID, etc.) during mount operations.
  - If value is not specified or false, pod information will not be passed on mount.
  - If value is set to true, Kubelet will pass pod information as volume_context in CSI NodePublishVolume calls:
    - `"csi.storage.k8s.io/pod.name": pod.Name`
    - `"csi.storage.k8s.io/pod.namespace": pod.Namespace`
    - `"csi.storage.k8s.io/pod.uid": string(pod.UID)`
    - `"csi.storage.k8s.io/serviceAccount.name": pod.Spec.ServiceAccountName`
  - For more information see [Pod Info on Mount](https://kubernetes-csi.github.io/docs/pod-info.html).

- `fsGroupPolicy`
  - This field was added in Kubernetes 1.19 and cannot be set when using an older Kubernetes release.
  - This field is beta in Kubernetes 1.20 and GA in Kubernetes 1.23.
  - Controls if this CSI volume driver supports volume ownership and permission changes when volumes are mounted.
  - The following modes are supported, and if not specified the default is `ReadWriteOnceWithFSType`:
    - `None`: Indicates that volumes will be mounted with no modifications, as the CSI volume driver does not support these operations.
    - `File`: Indicates that the CSI volume driver supports volume ownership and permission change via fsGroup, and Kubernetes may use fsGroup to change permissions and ownership of the volume to match user requested fsGroup in the pod's SecurityPolicy regardless of fstype or access mode.
    - `ReadWriteOnceWithFSType`: Indicates that volumes will be examined to determine if volume ownership and permissions should be modified to match the pod's security policy. **Changes will only occur if the fsType is defined** and the persistent volume's accessModes contains ReadWriteOnce. This is the default behavior if no other FSGroupPolicy is defined.
  - For more information see [CSI Driver fsGroup Support](https://kubernetes-csi.github.io/docs/support-fsgroup.html).

- `volumeLifecycleModes` (beta)
  - This field was added in Kubernetes 1.16 and cannot be set when using an older Kubernetes release.
  - It informs Kubernetes about the volume modes that are supported by the driver. This ensures that the driver is not used incorrectly by users. The default is Persistent, which is the normal PVC/PV mechanism. Ephemeral enables inline ephemeral volumes in addition (when both are listed) or instead of normal volumes (when it is the only entry in the list).

- `tokenRequests`
  - This field was added in Kubernetes 1.20 and cannot be set when using an older Kubernetes release.
  - This field is enabled by default in Kubernetes 1.21 and cannot be disabled since 1.22.
  - If this field is specified, Kubelet will plumb down the bound service account tokens of the pod as volume_context in the NodePublishVolume:
    - `"csi.storage.k8s.io/serviceAccount.tokens": {"gcp":{"token":"<token>","expirationTimestamp":"<expiration timestamp in RFC3339>"}}`
    - If CSI driver doesn't find token recorded in the volume_context, it should return error in NodePublishVolume to inform Kubelet to retry.
    - Audiences should be distinct, otherwise the validation will fail. If the audience is "", it means the issued token has the same audience as kube-apiserver.

- `requiresRepublish`
  - This field was added in Kubernetes 1.20 and cannot be set when using an older Kubernetes release.
  - This field is enabled by default in Kubernetes 1.21 and cannot be disabled since 1.22.
  - If this field is true, Kubelet will periodically call NodePublishVolume. This is useful in the following scenarios:
    - If the volume mounted by CSI driver is short-lived.
    - If CSI driver requires valid service account tokens (enabled by the field tokenRequests) repeatedly.
  - CSI drivers should only atomically update the contents of the volume. Mount point change will not be seen by a running container.

- `seLinuxMount`
  - This field is alpha in Kubernetes 1.25. It must be explicitly enabled by setting feature gates `ReadWriteOncePod` and `SELinuxMountReadWriteOncePod`.
  - The default value of this field is false.
  - When set to `true`, corresponding CSI driver announces that all its volumes are independent volumes from Linux kernel point of view and each of them can be mounted with a different SELinux label mount option (`-o context=<SELinux label>`). Examples:
    - A CSI driver that creates block devices <u>formatted with a filesystem, such as xfs or ext4</u>, can set seLinuxMount: **true**, because each volume has its own block device.
    - A CSI driver <u>whose volumes are always separate exports on a NFS server</u> can set seLinuxMount: **true**, because each volume has its own NFS export and thus Linux kernel treats them as independent volumes.
    - A CSI driver that <u>can provide two volumes as subdirectories of a common NFS export</u> **must set seLinuxMount: false**, because these two volumes are treated as a single volume by Linux kernel and must share the same `-o context=<SELinux label>` option.
  - See corresponding KEP for details.
  - Always test Pods with various SELinux contexts with various volume configurations before setting this field to `true`!

## What creates the CSIDriver object?

To install, a CSI driver's deployment manifest must contain a CSIDriver object as shown in the example above.

> NOTE: The cluster-driver-registrar side-car which was used to create CSIDriver objects in Kubernetes 1.13 has been deprecated for Kubernetes 1.16. No cluster-driver-registrar has been released for Kubernetes 1.14 and later.

CSIDriver instance should exist for whole lifetime of all pods that use volumes provided by corresponding CSI driver, so Skip Attach and Pod Info on Mount features work correctly.

### Listing registered CSI drivers

Using the CSIDriver object, it is now possible to query Kubernetes to get a list of registered drivers running in the cluster as shown below:

```bash
$> kubectl get csidrivers.storage.k8s.io
NAME                      ATTACHREQUIRED   PODINFOONMOUNT   MODES                  AGE
mycsidriver.example.com   true             true             Persistent,Ephemeral   2m46s
```

Or get a more detailed view of your registered driver with:

```bash
$> kubectl describe csidrivers.storage.k8s.io
Name:         mycsidriver.example.com
Namespace:    
Labels:       <none>
Annotations:  <none>
API Version:  storage.k8s.io/v1
Kind:         CSIDriver
Metadata:
  Creation Timestamp:  2022-04-07T05:58:06Z
  Managed Fields:
    API Version:  storage.k8s.io/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        f:attachRequired:
        f:fsGroupPolicy:
        f:podInfoOnMount:
        f:requiresRepublish:
        f:tokenRequests:
        f:volumeLifecycleModes:
          .:
          v:"Ephemeral":
          v:"Persistent":
    Manager:         kubectl-client-side-apply
    Operation:       Update
    Time:            2022-04-07T05:58:06Z
  Resource Version:  896
  UID:               6cc7d513-6d72-4203-87d3-730f83884f89
Spec:
  Attach Required:    true
  Fs Group Policy:    File
  Pod Info On Mount:  true
  Volume Lifecycle Modes:
    Persistent
    Ephemeral
Events:  <none>
```

---
reference
- https://kubernetes-csi.github.io/docs/csi-driver-object.html
- https://docs.openshift.com/container-platform/4.8/rest_api/storage_apis/csidriver-storage-k8s-io-v1.html
- https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/
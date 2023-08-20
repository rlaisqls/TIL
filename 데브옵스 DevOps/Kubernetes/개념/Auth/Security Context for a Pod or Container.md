# Security Context for a Pod or Container

A security context defines privilege and access control settings for a Pod or Container. Security context settings include, but are not limited to:

- Descretionary Access Control: Permission to access an object, like a file, is based on [user ID (UID) and group ID (GID)](https://wiki.archlinux.org/index.php/users_and_groups).
- [Security Enhanced Linux (SELinux)](https://en.wikipedia.org/wiki/Security-Enhanced_Linux): Objects are assigned security labels.
- Running as privileged or unprivileged.
- [Linux Capabilities](https://linux-audit.com/linux-capabilities-hardening-linux-binaries-by-removing-setuid/): Give a process some privileges, but not all the privileges of the root user.
- [AppArmor](https://kubernetes.io/docs/tutorials/security/apparmor/): Use program profiles to restrict the capabilities of individual programs.
- [Seccomp](https://kubernetes.io/docs/tutorials/security/seccomp/): Filter a process's system calls.
- `allowPrivilegeEscalation`: Controls whether a process can gain more privileges than its parent process. This bool directly controls whether the `[no_new_privs](https://www.kernel.org/doc/Documentation/prctl/no_new_privs.txt)` flag gets set on the container process. `allowPrivilegeEscalation` is always true when the container:
  - is run as privileged, or
  - has CAP_SYS_ADMIN
- `readOnlyRootFilesystem`: Mounts the container's root filesystem as read-only.

---

# Set the security context for a Pod

To specify security settings for a Pod, include the `securityContext` field in the Pod specification. The `securityContext` field is a [PodSecurityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.28/#podsecuritycontext-v1-core) object. The security settings that you specify for a Pod apply to all Containers in the Pod. Here is a configuration file for a Pod that has a `securityContext` and an `emptyDir` volume:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  volumes:
  - name: sec-ctx-vol
    emptyDir: {}
  containers:
  - name: sec-ctx-demo
    image: busybox:1.28
    command: [ "sh", "-c", "sleep 1h" ]
    volumeMounts:
    - name: sec-ctx-vol
      mountPath: /data/demo
    securityContext:
      allowPrivilegeEscalation: false
```

In the configuration file, the `runAsUser` field specifies that for any Containers in the Pod, all processes run with user ID 1000. The `runAsGroup` field specifies the primary group ID of 3000 for all processes within any containers of the Pod.

If this field is omitted, the primary group ID of the containers will be root(0). Any files created will also be owned by user 1000 and group 3000 when `runAsGroup` is specified. Since fsGroup field is specified, all processes of the container are also part of the supplementary group ID 2000. The owner for volume `/data/demo` and any files created in that volume will be Group ID 2000.

Create the Pod:

```bash
$ kubectl apply -f https://k8s.io/examples/pods/security/security-context.yaml
```

Verify that the Pod's Container is running:

```bash
$ kubectl get pod security-context-demo
```

In your shell, list the running processes. The output shows that the processes are running as user 1000, which is the value of runAsUser:

```bash
$ ps
PID   USER     TIME  COMMAND
    1 1000      0:00 sleep 1h
    6 1000      0:00 sh
...
```

In your shell, navigate to `/data`, and list the one directory. The output shows that the `/data/demo` directory has group ID 2000, which is the value of fsGroup.

```bash
$ cd /data
$ ls -l
drwxrwsrwx 2 root 2000 4096 Jun  6 20:08 demo
```

In your shell, navigate to `/data/demo`, and create a file:

```bash
$ cd demo
$echo hello > testfile
```

List the file in the `/data/demo` directory. The output shows that testfile has group ID 2000, which is the value of fsGroup.

```bash
$ ls -l
-rw-r--r-- 1 1000 2000 6 Jun  6 20:08 testfile
```
Run the following command, The output is similar to this:

```bash
$ id
uid=1000 gid=3000 groups=2000
```

From the output, you can see that `gid` is 3000 which is same as the `runAsGroup` field. If the `runAsGroup` was omitted, the `gid` would remain as 0(root) and the process will be able to interact with files that are owned by the root(0) group and groups that have the required group permissions for the root(0) group.

Exit your shell:

```bash
exit
```

### Configure volume permission and ownership change policy for Pods

By default, Kubernetes recursively changes ownership and permissions for the contents of each volume to match the `fsGroup` specified in a Pod's `securityContext` when that volume is mounted. For large volumes, checking and changing ownership and permissions can take a lot of time, slowing Pod startup. You can use the `fsGroupChangePolicy` field inside a `securityContext` to control the way that Kubernetes checks and manages ownership and permissions for a volume.

**fsGroupChangePolicy** - fsGroupChangePolicy defines behavior for changing ownership and permission of the volume before being exposed inside a Pod. This field only applies to volume types that support fsGroup controlled ownership and permissions. This field has two possible values:

- OnRootMismatch: Only change permissions and ownership if the permission and the ownership of root directory does not match with expected permissions of the volume. This could help shorten the time it takes to change ownership and permission of a volume.
- Always: Always change permission and ownership of the volume when volume is mounted.
For example:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 3000
  fsGroup: 2000
  fsGroupChangePolicy: "OnRootMismatch"
```

> Note: This field has no effect on ephemeral volume types such as secret, configMap, and emptydir.

### Delegating volume permission and ownership change to CSI driver

If you deploy a [Container Storage Interface (CSI)](https://github.com/container-storage-interface/spec/blob/master/spec.md) driver which supports the `VOLUME_MOUNT_GROUP` `NodeServiceCapability`, the process of setting file ownership and permissions based on the fsGroup specified in the securityContext will be performed by the CSI driver instead of Kubernetes.

In this case, since Kubernetes doesn't perform any ownership and permission change, `fsGroupChangePolicy` does not take effect, and as specified by CSI, the driver is expected to mount the volume with the provided fsGroup, resulting in a volume that is readable/writable by the fsGroup.

---

## Set the security context for a Container 

To specify security settings for a Container, include the `securityContext` field in the Container manifest. The `securityContext` field is a [SecurityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.28/#securitycontext-v1-core) object. Security settings that you specify for a Container apply only to the individual Container, and they override settings made at the Pod level when there is overlap. Container settings do not affect the Pod's Volumes.

Here is the configuration file for a Pod that has one Container. Both the Pod and the Container have a `securityContext` field:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo-2
spec:
  securityContext:
    runAsUser: 1000
  containers:
  - name: sec-ctx-demo-2
    image: gcr.io/google-samples/node-hello:1.0
    securityContext:
      runAsUser: 2000
      allowPrivilegeEscalation: false
```

Create the Pod:

kubectl apply -f https://k8s.io/examples/pods/security/security-context-2.yaml
Verify that the Pod's Container is running:

kubectl get pod security-context-demo-2
Get a shell into the running Container:

kubectl exec -it security-context-demo-2 -- sh
In your shell, list the running processes:

ps aux
The output shows that the processes are running as user 2000. This is the value of runAsUser specified for the Container. It overrides the value 1000 that is specified for the Pod.

USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
2000         1  0.0  0.0   4336   764 ?        Ss   20:36   0:00 /bin/sh -c node server.js
2000         8  0.1  0.5 772124 22604 ?        Sl   20:36   0:00 node server.js
...
Exit your shell:

exit
Set capabilities for a Container
With Linux capabilities, you can grant certain privileges to a process without granting all the privileges of the root user. To add or remove Linux capabilities for a Container, include the capabilities field in the securityContext section of the Container manifest.

First, see what happens when you don't include a capabilities field. Here is configuration file that does not add or remove any Container capabilities:

pods/security/security-context-3.yaml Copy pods/security/security-context-3.yaml to clipboard
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo-3
spec:
  containers:
  - name: sec-ctx-3
    image: gcr.io/google-samples/node-hello:1.0
Create the Pod:

kubectl apply -f https://k8s.io/examples/pods/security/security-context-3.yaml
Verify that the Pod's Container is running:

kubectl get pod security-context-demo-3
Get a shell into the running Container:

kubectl exec -it security-context-demo-3 -- sh
In your shell, list the running processes:

ps aux
The output shows the process IDs (PIDs) for the Container:

USER  PID %CPU %MEM    VSZ   RSS TTY   STAT START   TIME COMMAND
root    1  0.0  0.0   4336   796 ?     Ss   18:17   0:00 /bin/sh -c node server.js
root    5  0.1  0.5 772124 22700 ?     Sl   18:17   0:00 node server.js
In your shell, view the status for process 1:

cd /proc/1
cat status
The output shows the capabilities bitmap for the process:

...
CapPrm:	00000000a80425fb
CapEff:	00000000a80425fb
...
Make a note of the capabilities bitmap, and then exit your shell:

exit
Next, run a Container that is the same as the preceding container, except that it has additional capabilities set.

Here is the configuration file for a Pod that runs one Container. The configuration adds the CAP_NET_ADMIN and CAP_SYS_TIME capabilities:

pods/security/security-context-4.yaml Copy pods/security/security-context-4.yaml to clipboard
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo-4
spec:
  containers:
  - name: sec-ctx-4
    image: gcr.io/google-samples/node-hello:1.0
    securityContext:
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
Create the Pod:

kubectl apply -f https://k8s.io/examples/pods/security/security-context-4.yaml
Get a shell into the running Container:

kubectl exec -it security-context-demo-4 -- sh
In your shell, view the capabilities for process 1:

cd /proc/1
cat status
The output shows capabilities bitmap for the process:

...
CapPrm:	00000000aa0435fb
CapEff:	00000000aa0435fb
...
Compare the capabilities of the two Containers:

00000000a80425fb
00000000aa0435fb
In the capability bitmap of the first container, bits 12 and 25 are clear. In the second container, bits 12 and 25 are set. Bit 12 is CAP_NET_ADMIN, and bit 25 is CAP_SYS_TIME. See capability.h for definitions of the capability constants.

Note: Linux capability constants have the form CAP_XXX. But when you list capabilities in your container manifest, you must omit the CAP_ portion of the constant. For example, to add CAP_SYS_TIME, include SYS_TIME in your list of capabilities.


---
reference
- https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
- https://sysdig.com/learn-cloud-native/kubernetes-security/security-contexts/
- https://bcho.tistory.com/1275
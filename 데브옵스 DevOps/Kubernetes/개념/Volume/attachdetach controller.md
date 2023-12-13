# attach/detach-controller

## Objective

- Make volume attachment and detachment independent of any single node's availability
  - If a node or kubelet goes down, the volumes attached to that node should be detached so that they are free to be attached to other nodes.
- Secure Cloud Provider Credentials
  - Because each kubelet is responsible for triggering attach/detach logic, every node currently needs (often broad) permissions. These permissions should be limited to the master. For Google Compute Engine (GCE), for example, this means nodes should no longer need the computer-rw auth scope.
- Improve stability of volume attach/detach code

## Solution Overview

A node should not be responsible for determining whether to attach or detach a volume to itself. Instead, the responsibility should be moved (out of Kubelet) to a separate off-node “Volume Attachment/Detachment Controller” that has a life cycle independent of any individual node.

More specifically, a new controller, responsible for attaching and detaching all volumes across the cluster, will be added to the controllermanager, running on the master. This controller will watch the API server to determine when pods are scheduled or killed. When a new pod is scheduled it will trigger the appropriate attach logic for that volume type based on the node it is scheduled to. When a pod is terminated, it will similarly trigger the appropriate detach logic. Some volume types may not have a concept of attaching to a node (e.g. NFS volume), and for these volume types the attach and detach operations will be no-ops.

## Detailed Design

### Attach/Detach Controller

The controller will maintain an in-memory cache containing a list of volumes that are managed by the controller (i.e. volumes that require attach/detach). Each of these volumes will, in addition to the volume name, specify a list of nodes the volume is attached to, and similarly, each of these nodes will, in addition to the node name, specify a list of pods that are scheduled to the node and referencing the volume. This cache defines the state of the world according to the controller. This cache must be thread-safe. The cache will contain a single top level boolean used to track if state needs to be persisted or not (the value is reset every time state is persisted, and it is set anytime an attach or detach succeeds).

On initial startup, the controller will fetch a list of all persistent volume (PV) objects from the API server and pre-populate the cache with volumes and the nodes they are attached to.

The controller will have a loop that does the following:

- Fetch State
  - Fetch all pod and mirror pod objects from the API server.
- Acquire Lock
  - Acquire a lock on the in-memory cache.
- Reconcile State
  - Search for newly terminated/deleted pods:
    - Loop through all cached pods (i.e. volume->node->pods) and delete them from in-memory cache if:
      - The cached pod is not present in the list of fetched pods or the node it is scheduled to is different (indicating the pod object was was deleted from the API server or rescheduled).
      - The cached pod is present in the list of fetched pods and the PodPhase is Succeeded or Failed and the VolumeStatus (detailed in “Safe Mount/Unmount” section below) indicates the volume is safe to detach.
  - Search for newly attached volumes:
    - Iterate through the fetched pods, and for each pod with a PodPhase Pending, check the volumes it defines or references (dereference any PersistentVolumeClaim objects to fetch associated PersistentVolume objects). If the volume is already tracked in memory cache, and the node the pod is scheduled to is listed in the in-memory cache for the specified volume (indicating the volume was successfully attached to the node):
      - Add the pod to the list of pods in the in-memory cache under the node (indicating a new pod is referencing a volume that is already attached to the node it is scheduled to).
- Act
  - Trigger detaches:
    - Loop through all cached nodes (i.e. volume->node) and trigger detach logic (detailed below) for any volumes that are attached to a node (exist in-memory cache) but have no pods listed under that node (indicating no running pods using the volume) and implement the Detacher interface.
      - Detaches are triggered before attaches so that volumes referenced by pods that are rescheduled to a different node are detached first.
  - Trigger attaches:
    - Iterate through the fetched pods, and for each pod with a PodPhase Pending check the volumes it defines or references (dereference any PersistentVolumeClaim objects to fetch associated PersistentVolume objects). For each volume that implements the Attacher interface:
      - If **the volume is not already in-memory cache** (indicates a new volume has been discovered), then trigger attach logic (detailed in section below) to attach the volume to the node the pod is scheduled to.
      -If **the volume is already tracked in memory cache**, and the node the pod is scheduled to is not listed in the in-memory cache for the specified volume (indicating the volume is not attached to the node), trigger attach logic (detailed in section below) to attach the volume to the node the pod is scheduled to.
- Persist State
  - Persist the in-memory cache to API server for PersistentVolume volume types:
    - If the top level boolean in the in-memory cache used to track if state needs to be persisted or not is not set, skip this operation (to prevent unnecessary writes to the API server).
    - For each volume in the in-memory cache that is a PersistentVolume and is attached to a node (has more than one item in list of nodes), write the list of nodes to associated PersistentVolume object via the API server.
    - Reset the top level boolean in the in-memory cache to indicate that state does not need to be persisted.
- Release Lock
  - Release the lock on the in-memory cache (spawned threads have this opportunity to update state indicating volume attachment or detachment).
  
Attach and detach operations can take a long time to complete, so the primary controller loop should not block on these operations. Instead the attach and detach operations should spawn separate threads for these operations. To prevent multiple attach or detach operations on the same volume, the main thread will maintain a table mapping volumes to currently active operations. The number of threads that can be spawned will be capped (possibly using a thread pool) and once the cap is hit, subsequent requests will have to wait for a thread to become available.

For backwards compatibility, the controller binary will accept a flag (or some mechanism) to disable the new controller altogether.

### Attach Logic
To attach a volume:

- Acquire operation lock for volume so that no other attach or detach operations can be started for volume.
  - Abort if there is already a pending operation for the specified volume (main loop will retry, if needed).
- Check “policies” to determine if the persistent volume can be attached to the specified node, if not, do nothing.
  - This includes logic that prevents a ReadWriteOnce persistent volume from being attached to more than one node.
- Spawn a new thread:
  - Execute the volume-specific logic to attach the specified volume to the specified node.
  - If there is an error indicating the volume is already attached to the specified node, assume attachment was successful (this will be the responsibility of the plugin code).
  - For all other errors, log the error, and terminate the thread (the main controller will retry as needed).
  - Once attachment completes successfully:
    - Acquire a lock on the in-memory cache (block until lock is acquired).
    - Add the node the volume was attached to, to in-memory cache (i.e. volume->node), to indicate the volume was successfully attached to the node.
    - Set the top level boolean in the in-memory cache to indicate that state does need to be persisted.
    - Release the lock on the in-memory cache.
    - Make a call to the API server to update the VolumeStatus object under the PodStatus for the volume to indicate that it is now safeToMount.
- Release operation lock for volume.

### Detach Logic

To detach a volume:

- Acquire operation lock for volume so that no other attach or detach operations can be started for volume.
  - Abort if there is already a pending operation for the specified volume (main loop will retry, if needed).
- Spawn a new thread:
  - Execute the volume-specific logic to detach the specified volume from the specified node.
  - If there is an error indicating the volume is not attached to the specified node, assume detachment was successful (this will be the responsibility of the plugin code).
  - For all other errors, log the error, and terminate the thread (the main controller will retry as needed).
  - Once detachment completes successfully:
    - Acquire a lock on the in-memory cache (block until lock is acquired).
    - Remove the node that the specified volume was detached from, from the list of attached nodes under the volume in-memory cache, to indicate the volume was successfully detached from the node.
    - Set the top level boolean in the in-memory cache to indicate that state does need to be persisted.
    - Release the lock on the in-memory cache.
- Acquire operation lock for volume.

### Rationale for Storing State

The new controller will need to constantly be aware of which volumes are attached to which nodes, and which scheduled pods reference those volumes. The controller should also be robust enough that if it terminates unexpectedly, it should continue operating where it left off when restarted. Ideally, the controller should also be a closed-loop system--it should store little or no state and, instead, operate strictly with an ”observe and rectify” philosophy; meaning, it should trust no cached state (never assume the state of the world), and should instead always verify (with the source of truth) which volumes are actually attached to which nodes, then take the necessary actions to push them towards the desired state (attach or detach), and repeat (re-verify with the source of truth the state of the world and take actions to rectify).

The problem with this purist approach is that it puts an increased load on volume providers by constantly asking for the state of the world (repeated operations to list all nodes or volumes to determine attachment mapping). It makes the controller susceptible to instability/delays in the provider APIs. And, most importantly, some state simply cannot (currently) be reliably inferred through observation.

For example, the controller must be able to figure out when to to trigger volume detach operations. When a pod is terminated the pod object will be deleted (normally by kubelet, unless kubelet becomes unresponsive, in which case, the node controller will mark the node as unavailable resulting in the pod forcibly getting terminated and the pod object getting deleted). So the controller could use the deletion of the pod object (a state change) as the observation that indicates that either the volume was safely unmounted or the node became unavailable, and trigger the volume detach operation.

However, having the controller trigger such critical behavior based on observation of a state change makes the controller inherently unreliable because the controller cannot retrieve the state of the world on-demand and must instead constantly monitor for state changes; if a state change is missed, the controller will not trigger the correct behavior: imagine that the controller unexpectedly terminates, and the pod object is deleted during this period, when the controller comes back up it will have missed the pod deletion event and will have no knowledge that a volume was once attached to a node and should now be detached.

Therefore, in order to make the controller reliable, it must maintain some state (specifically which volumes are attached to which nodes). It can maintain a mapping of volumes and the nodes they are attached to in local memory, and operate based on this state.

To prevent this cached state of the world (which volumes are attached to which nodes) from becoming stale or out-of-sync with the true state of the world, the controller could, optionally, periodically poll the volume providers to find out exactly which volumes are attached to which nodes and update its cached state accordingly.

In order to make the controller more robust, the cached state should also be persisted outside the controller. This can be done by adding a field to the PersistentVolume object, exposed by the Kubernetes API server. If the controller is unexpectedly terminated, it can come back up and pick up from where it left off by reading this state from the API server (except for “Pod Defined” and “Static Pod” Volumes, see below). If a PersistentVolume object is deleted by the user before it is detached, the controller will still behave normally, as long as the controller is not restarted during this period, since the volume still exists in the controller's local memory.

### What about Pod Defined Volume Objects and Static Pods?
In the existing design, most volume types can be defined either as PersistentVolumeSource types or as plain VolumeSource types. During pod creation, Kubelet looks at any Volumes (dereferencing PersistentVolumeClaims) defined in the pod object and attaches/mounts them as needed.

The solution proposed above for persisting controller state (by extending the PersistentVolume object with additional fields that the controller can use to save and read attach/detach state), works only for volumes created as PersistentVolume objects, because the API Server stores and exposes PersistentVolume objects. However, plain Volume objects, are defined directly in the pod definition config, and are simply fields in the pod object (not first class API server objects). If any state is stored inside the pod object (like what node a volume is attached to), once the pod API object is deleted (which happens routinely when a pod is terminated), information about what node(s) the volume was attached to would be lost. Additionally, users can create Static Pods and bypass the API server altogether.

In order to support such “Pod Defined” and “Static Pod” Volumes, the controller will manage all attach/detach but persist only some state in API server objects:

- Controller handles “persistent volume” objects by parsing PersistentVolume API objects from the API server, and persists state in the PersistentVolume API object.
- Controller handles “pod defined volumes” by parsing pod objects from the API server, and stores state only in local controller memory (best effort, no persisted state).
- Controller handles “static pods” by parsing mirror pod objects from the API server, and stores state only in local controller memory (best effort, no persisted state).

Because “static pods” can be created via a kubelet running without a master (i.e. standalone mode), kubelet will support a legacy mode of operation where it continues to be responsible for attach/detach logic; same behavior as today (see below for details).

### Safe Mount/Unmount

The controller should wait for a volume to be safely unmounted before it tries to detach it. Specifically, the controller should wait for the kubelet (on the node that a volume is attached to) to safely unmount the volume before the controller detaches it. This means the controller must monitor some state (set by kubelet) indicating a volume has been unmounted, and detach once the signal is given. The controller should also be robust enough that if the kubelet is unavailable, act unilaterally to detach the disk anyway (so that no disks are left attached if kubelet becomes inaccessible).

Similarly kubelet should wait for a volume to be safely attached before it tries to mount it. Specifically, the kubelet should wait for the attach/detach controller to indicate that a volume is attached before the kubelet attempts to mount it. This means the kubelet must monitor some state (set by the controller) indicating if a volume has been attached, and mount only once the signal is given.

Both these goals can be achieved by introducing a list of VolumeStatus objects under the PodStatus API object. The VolumeStatus object, similar to ContainerStatus, will contain state information for a volume in the pod. This includes a safeToMount field indicating the volume is attached and ready to mount (set by controller, read by kubelet), and a safeToDetach field indicating the volume is unmounted and ready to detach (set by kubelet, read by controller).

---
reference
- https://github.com/kubernetes/kubernetes/issues/20262
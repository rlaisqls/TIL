# Deployment Strategy

Deployment's `.spec.strategy` specifies the strategy used to replace old Pods by new ones. `.spec.strategy.type` can be "Recreate" or "RollingUpdate". "RollingUpdate" is the default value.

## Recreate Deployment

All existing Pods are killed before new ones are created when `.spec.strategy.type==Recreate`.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/c1f2e443-ab2b-4d49-ac3d-52a1bb7992c3" height=300px>

> Note: This will only guarantee Pod termination previous to creation for upgrades. If you upgrade a Deployment, all Pods of the old revision will be terminated immediately. Successful removal is awaited before any Pod of the new revision is created. If you manually delete a Pod, the lifecycle is controlled by the ReplicaSet and the replacement will be created immediately (even if the old Pod is still in a Terminating state). If you need an "at most" guarantee for your Pods, you should consider using a StatefulSet.

## Rolling Update Deployment

The Deployment updates Pods in a rolling update fashion when `.spec.strategy.type=RollingUpdate`. You can specify maxUnavailable and maxSurge to control the rolling update process.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/d5c38099-5d03-4924-9890-a89a1690acab" height=300px>

### Max Unavailable

`.spec.strategy.rollingUpdate.maxUnavailable` is an optional field that specifies the maximum number of Pods that can be unavailable during the update process. The value can be an absolute number (for example, 5) or a percentage of desired Pods (for example, 10%). The absolute number is calculated from percentage by rounding down. The value cannot be 0 if `.spec.strategy.rollingUpdate.maxSurge` is 0. The default value is 25%.

For example, when this value is set to 30%, the old ReplicaSet can be scaled down to 70% of desired Pods immediately when the rolling update starts. Once new Pods are ready, old ReplicaSet can be scaled down further, followed by scaling up the new ReplicaSet, ensuring that the total number of Pods available at all times during the update is at least 70% of the desired Pods.

### Max Surge

`.spec.strategy.rollingUpdate.maxSurge` is an optional field that specifies the maximum number of Pods that can be created over the desired number of Pods. The value can be an absolute number (for example, 5) or a percentage of desired Pods (for example, 10%). The value cannot be 0 if MaxUnavailable is 0. The absolute number is calculated from the percentage by rounding up. The default value is 25%.

For example, when this value is set to 30%, the new ReplicaSet can be scaled up immediately when the rolling update starts, such that the total number of old and new Pods does not exceed 130% of desired Pods. Once old Pods have been killed, the new ReplicaSet can be scaled up further, ensuring that the total number of Pods running at any time during the update is at most 130% of desired Pods.

---
reference
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#recreate-deployment
- https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/

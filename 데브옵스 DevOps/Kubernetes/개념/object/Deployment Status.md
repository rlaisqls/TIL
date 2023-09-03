# Deployment Status

A Deployment enters various states during its lifecycle. It can be progressing while rolling out a new ReplicaSet, it can be complate, or it can fail to progress.

## Progressing Deployment

Kubernetes marks a Deployment as progressing when one of the follwing tasks is performed:
- The Deployment creates a new ReplicaSet.
- The Deployment is scaling up its newest ReplicaSet.
- The Deployment is scaling down its older ReplicaSet(s).
- New Pords become ready or available (ready for at least [MinReadySeconds](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#min-ready-seconds))

When the rollout becomes "progressing", the Deployment controller adds a condition with the following attributes to teh Deployment's `.status.conditions`:
- `type: Progressing`
- `status: "True"`
- `reason: NewReplicaSetCreated` | `reason: FoundNewReplicaSet` | `eeason: ReplicaSetUpdated`

You can monitor the progress for a Deployment by using `kubectl rollout status`.

## Complete Deployment

Kubernetes marks a Deployment as complete when it has the following characteristics:
- All of the replicas associated with the Deployment have been updated to the lates version you've specified, meaning any updates you've requested have been completed.
- All of replicas associated with the Deployment are available.
- No old replias for the Deployments are running.

Whe the rollout becomes "complete", the Deployment controller sets a confition with the following attributes to the Deploymwnt's `.status.conditions`:

- `type: Progressing`
- `status: "True"`
- `reason: NweReplicaSetAvailable`

This `Progressing` condition will retain a status calue of "True" until a new rollout is initiated. The condition holes even when availability of replicas changes (which does instead affect the `Available` condition).

You can check if a Deployment has completed by using `kubectl rollout status`. If the rollout completed successfully, `kubectl rollout status` returns a zero exit code.

```bash
kubectl rollout status deployment/nginx-deployment
```

The output is similar to this:

```bash
Waiting for rollout to finish: 2 of 3 updated replicas are available...
deployment "nginx-deployment" successfully rolled out
```

and the exit status from `kubectl rollout` is 0 (success):

```bash
$echo $?
0
```

## Failed Deployment 

Your Deployment may get stuck trying to deploy its newest ReplicaSet without ever completing. This can occur due to some of the following factors:

- Insufficient quota
- Readiness probe failures
- Image pull errors
- Insufficient permissions
- Limit ranges
- Application runtime misconfiguration

One way you can detect this condition is to specify a deadline parameter in your Deployment spec: ([`.spec.progressDeadlineSeconds`](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#progress-deadline-seconds)). `.spec.progressDeadlineSeconds` denotes the number of seconds the Deployment controller waits before indicating (in the Deployment status) that the Deployment progress has stalled.

The following `kubectl` command sets the spec with progressDeadlineSeconds to make the controller report lack of progress of a rollout for a Deployment after 10 minutes:

```bash
kubectl patch deployment/nginx-deployment -p '{"spec":{"progressDeadlineSeconds":600}}'
```

The output is similar to this:

```bash
deployment.apps/nginx-deployment patched
```

Once the deadline has been exceeded, the Deployment controller adds a DeploymentCondition with the following attributes to the Deployment's .status.conditions:

- `type: Progressing`
- `status: "False"`
- `reason: ProgressDeadlineExceeded`

This condition can also fail early and is then set to status value of "False" due to reasons as ReplicaSetCreateError. Also, the deadline is not taken into account anymore once the Deployment rollout completes.

See the Kubernetes API conventions for more information on status conditions.

> Note: Kubernetes takes no action on a stalled Deployment other than to report a status condition with reason: ProgressDeadlineExceeded. Higher level orchestrators can take advantage of it and act accordingly, for example, rollback the Deployment to its previous version.
 
> Note: If you pause a Deployment rollout, Kubernetes does not check progress against your specified deadline. You can safely pause a Deployment rollout in the middle of a rollout and resume without triggering the condition for exceeding the deadline.

You may experience transient errors with your Deployments, either due to a low timeout that you have set or due to any other kind of error that can be treated as transient. For example, let's suppose you have insufficient quota. If you describe the Deployment you will notice the following section:

kubectl describe deployment nginx-deployment
The output is similar to this:

```bash
<...>
Conditions:
  Type            Status  Reason
  ----            ------  ------
  Available       True    MinimumReplicasAvailable
  Progressing     True    ReplicaSetUpdated
  ReplicaFailure  True    FailedCreate
<...>
```

If you run kubectl get deployment nginx-deployment -o yaml, the Deployment status is similar to this:

```yaml
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: 2016-10-04T12:25:39Z
    lastUpdateTime: 2016-10-04T12:25:39Z
    message: Replica set "nginx-deployment-4262182780" is progressing.
    reason: ReplicaSetUpdated
    status: "True"
    type: Progressing
  - lastTransitionTime: 2016-10-04T12:25:42Z
    lastUpdateTime: 2016-10-04T12:25:42Z
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  - lastTransitionTime: 2016-10-04T12:25:39Z
    lastUpdateTime: 2016-10-04T12:25:39Z
    message: 'Error creating: pods "nginx-deployment-4262182780-" is forbidden: exceeded quota:
      object-counts, requested: pods=1, used: pods=3, limited: pods=2'
    reason: FailedCreate
    status: "True"
    type: ReplicaFailure
  observedGeneration: 3
  replicas: 2
  unavailableReplicas: 2
```

Eventually, once the Deployment progress deadline is exceeded, Kubernetes updates the status and the reason for the Progressing condition:

```bash
Conditions:
  Type            Status  Reason
  ----            ------  ------
  Available       True    MinimumReplicasAvailable
  Progressing     False   ProgressDeadlineExceeded
  ReplicaFailure  True    FailedCreate
```

You can address an issue of insufficient quota by scaling down your Deployment, by scaling down other controllers you may be running, or by increasing quota in your namespace.

If you satisfy the quota conditions and the Deployment controller then completes the Deployment rollout, you'll see the Deployment's status update with a successful condition (`status: "True"` and `reason: NewReplicaSetAvailable`).

```bash
Conditions:
  Type          Status  Reason
  ----          ------  ------
  Available     True    MinimumReplicasAvailable
  Progressing   True    NewReplicaSetAvailable
```

- `type: Available` with `status: "True"` means that your **Deployment has minimum availability**. Minimum availability is dictated by the parameters specified in the deployment strategy.

- `type: Progressing` with `status: "True"` means that your Deployment is either in the middle of a rollout and it is progressing or that it has successfully completed its progress and the minimum required new replicas are available (see the Reason of the condition for the particulars - in our case `reason: NewReplicaSetAvailable` means that the Deployment is complete).

You can check if a Deployment has failed to progress by using kubectl rollout status. kubectl rollout status returns a non-zero exit code if the Deployment has exceeded the progression deadline.

```bash
kubectl rollout status deployment/nginx-deployment
```

The output is similar to this:

```bash
Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
error: deployment "nginx" exceeded its progress deadline
```

and the exit status from kubectl rollout is 1 (indicating an error):

```bash
echo $?
1
```

### Operating on a failed deployment

All actions that apply to a complete Deployment also apply to a failed Deployment. You can scale it up/down, roll back to a previous revision, or even pause it if you need to apply multiple tweaks in the Deployment Pod template.

---
reference
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
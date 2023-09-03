# cordon, drain

쿠버네티스 클러스터를 사용하다 보면 특정 노드에 있는 포드들을 모두 다른 곳으로 옮기거나 아니면 특정 노드에는 포드들이 스케쥴링 되지 않도록 제한을 걸어야 할 때가 있다. 이러한 기능들을 제공하는 kubectl 명령어가 cordon, drain, taint 등이다.

## cordon

kubectl cordon은 지정된 노드에 더이상 포드들이 스케쥴링되서 실행되지 않도록 한다. kubectl get nodes로 노드 이름을 확인한 다음에 cordon을 해보자. cordon을 한 다음에 다시 노드를 확인해 보면 노드의 status에 SchedulingDisabled라는 STATUS가 추가된 걸 확인할 수 있다.

```bash
$ kubectl get nodes
NAME                 STATUS    ROLES     AGE       VERSION
docker-for-desktop   Ready     master    4d        v1.10.3

$ kubectl cordon docker-for-desktop
node "docker-for-desktop" cordoned

$ kubectl get nodes
NAME                 STATUS                     ROLES     AGE       VERSION
docker-for-desktop   Ready,SchedulingDisabled   master    4d        v1.10.3
```

현재 실행중인 Deployment의 포드 개수를 늘려 실제로 스케쥴링이 되지 않는지 확인해 보보자. `kubernetes-simple-app`이란 디플로이먼트의 포드가 1개 실행중인걸 확인하고 scale 명령으로 replicas를 2개로 늘렸다. 하지만 포드가 정상적으로 실행되지 않고 Pending상태로 남아 있다. 노드가 하나뿐이라 cordon을 걸어놓은 노드에 스케쥴링을 시도했는데, `SchedulingDisabled` 이기 때문에 실행이 실패하고 있는 것이다.

```bash
$ kubectl get deploy,pod
NAME                                          DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/kubernetes-simple-app   1         1         1            1           8h

NAME                                         READY     STATUS    RESTARTS   AGE
pod/kubernetes-simple-app-57585656fc-d6n7z   1/1       Running   0          33m

$ kubectl scale deploy kubernetes-simple-app --replicas=2
deployment.extensions "kubernetes-simple-app" scaled
$ kubectl get deploy,pod
NAME                                          DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/kubernetes-simple-app   2         2         2            1           8h

NAME                                         READY     STATUS    RESTARTS   AGE
pod/kubernetes-simple-app-57585656fc-82nmk   0/1       Pending   0          59s
pod/kubernetes-simple-app-57585656fc-d6n7z   1/1       Running   0          35m
```

포드가 노드에 정상적으로 스케쥴링될 수 있게 하기 위해서는 uncordon을 해주면 된다. 다음명령으로 노드를 uncordon할 수 있다.

```bash
kubectl uncordon docker-for-desktop
```

uncordon이 정상적으로 되면 노드 상태는 Ready만 남게 되고 Pending으로 남아 있던 포드가 잠시 후 정상적으로 스케쥴링되서 실행되고 있는걸 확인할 수 있다.

## drain

kubectl drain은 노드 관리를 위해서 지정된 노드에 있는 포드들을 다른곳으로 이동시키는 명령이다. 우선 새로운 포드가 노드에 스케쥴링 되어서 실행되지 않도록 설정한다. 그리고 나서 기존에 이 노드에서 실행중이던 포드들을 삭제한다.

이 때 노드에 데몬셋으로 실행된 포드들이 있으면 drain이 실패한다. 데몬셋으로 실행된 포드들은 삭제해도 데몬셋이 즉시 다시 실행하기 때문이다. 그래서 데몬셋으로 실행한 포드를 무시하고 진행하려면 `--ignore-daemonsets=true` 옵션을 주고 drain을 하면 된다.

컨트롤러를 통해서 실행되지 않은 포드만으로 실행된 포드들이 있어도 drain이 실패한다. 컨트롤러에 의해 관리되고 있는 포드들은 삭제되더라도 컨트롤러가 클러스터내의 다른 노드에 다시 동일한 역할을 하는 포드를 실행한다. 하지만 포드만으로 실행된 포드들은 한번 삭제되면 그것으로 끝이기 때문에 삭제시 위험이 있어 drain이 진행되지 않고 실패하는 것이다. 이런 경우 강제로 삭제를 진행하려면 `--force` 옵션을 주고 실행하면 된다. 또한, api server를 통해서 실행되지 않은 kubelet이 직접 실행한 static pod들도 삭제되지 않는다.

drain을 하게 되면 pod가 graceful하게 종료된다. 포드들이 종료 명령을 받았을때 바로 중단 되는게 아니라 정상적으로 잘 종료되도록 설정되어 있다면 기존 작업에 대한 정리를 하고 종료가 된다. drain은 이 과정을 모두 기다려 주도록 되어 있다.

먼저, drain을 실행해 보기 위해서 node의 이름을 확인한다.

```bash
$ kubectl get nodes
NAME                 STATUS    ROLES     AGE       VERSION
docker-for-desktop   Ready     master    4d        v1.10.3
```

도커를 이용해서 설치한 쿠버네티스라면 docker-for-desktop으로 노드이름을 확인할 수 있다.
우선 kubectl drain을 해보면 다음처럼 에러가 발생한다. 데몬셋으로 떠 있는 포드가 존재하기 때문이다.

```bash
$ kubectl drain docker-for-desktop
node "docker-for-desktop" cordoned
error: unable to drain node "docker-for-desktop", aborting command...

There are pending nodes to be drained:
docker-for-desktop
error: DaemonSet-managed pods (use --ignore-daemonsets to ignore): kube-proxy-4s52d
```

`--ignore-daemonsets=true` 옵션을 주고 다시 실행하면 정상적으로 실행되는걸 확인할 수 있다.

```bash
$ kubectl drain docker-for-desktop --ignore-daemonsets=true
node "docker-for-desktop" already cordoned
WARNING: Ignoring DaemonSet-managed pods: kube-proxy-4s52d
pod "compose-api-6fbc44c575-k6fz8" evicted
pod "compose-7447646cf5-w4mzb" evicted
pod "kubernetes-simple-app-57585656fc-nvkxm" evicted
pod "kube-dns-86f4d74b45-dt5rb" evicted
node "docker-for-desktop" drained
```

노드의 status부분을 보면 cordon을 했을 때와 똑같이 ScehdulingDisabled가 뜬 것을 볼 수 있다. 그 다음 하단의 포드들 상태를 보면 다른 node에 다시 scheduling 되기 위해 Pending, 혹은 Terminating 상태가 되어 있는걸 알 수 있다. 스태틱 포드인 것들은 Running 상태로 남아 있다. 

<img src="https://github.com/rlaisqls/TIL/assets/81006587/f97aeba1-4dc3-48a4-ba1c-73b9baf5ed76" height=200px>

클러스터의 노드가 여러개 있다면 이 노드에서 삭제된 포드들은 다른 노드들로 스케쥴링이 되었을 것이다. 하지만 지금은 노드가 1개 밖에 없기 때문에 다시 이 노드에서 포드를 실행시키려고 하지만 노드가 `SchedulingDisabled` 상태이기 때문에 스케쥴링 되지 못하고 `Pending` 상태로 남아 있게 된다. drain 되어서 스케쥴링이 되지 않고 있는 상태를 풀어주려면 uncordon 명령을 사용하면 된다. 

```bash
kubectl uncordon docker-for-desktop
```

uncordon을 하고 나서 다시 클러스터 상태를 확인해 보면 다음처럼 노드의 status는 `Ready`만 남아 있고 `SchedulingDisabled` 상태가 없어진걸 확인할 수 있다. 조금 기다리면 Pending 상태에 있던 포드들이 `ContainerCreating` 상태를 거쳐서 모두 `Running` 상태가 되는걸 확인할 수 있다.

---
reference
- https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
- https://www.howtogeek.com/devops/cordons-and-drains-how-to-prepare-a-kubernetes-node-for-maintenance/
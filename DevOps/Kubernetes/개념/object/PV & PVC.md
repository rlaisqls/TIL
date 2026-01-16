![image](https://github.com/rlaisqls/TIL/assets/81006587/2e466438-16d2-4a3d-8fa7-ca68e9e7029f)

k8s에서 Volume을 사용하는 구조는 PV라고 하는 퍼시스턴트 볼륨(PersistentVolume)과 PVC라고 하는 퍼시스턴트 볼륨 클레임(PersistentVolumeClaim) 2개로 분리되어 있다.

## PV/PVC

PV는 Persistent Volume의 약자이다. pod와는 별개로 관리되며 별도의 생명 주기가 있다. PVC는 사용자가 PV에 하는 요청이다. 사용하고 싶은 용량은 얼마인지, 읽기/쓰기는 어떤 모드로 설정하고 싶은지 등을 정해서 요청한다.

k8s 볼륨을 pod에 직접 할당하는 방식이 아니라 중간에 PVC를 두어 pod와 pod가 사용할 스토리지를 분리할 수 있다. 이런 구조는 pod 각각의 상황에 맞게 다양한 스토리지를 사용할 수 있게 한다.

클라우드 서비스를 사용할 때는 본인이 사용하는 클라우드 서비스에서 제공해주는 볼륨 서비스를 사용할 수도 있고, 직접 구축한 스토리지를 사용할 수도 있다. 이렇게 다양한 스토리지를 PV로 사용할 수 있지만 pod에 직접 연결하는 것이 아니라 PVC를 거쳐서 사용하므로 pod는 어떤 스토리지를 사용하는지 신경 쓰지 않아도 된다.

## 생명주기

PV와 PVC는 다음과 같은 생명주기가 있다.

<img width="362" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/257f124f-bbe4-42e7-a8e6-5aa3c2146008">

### 1. Provisioning(프로비저닝)

PV를 만드는 단계를 프로비저닝(Provisioning)이라고 한다. 프로비저닝 방법에는 두 가지가 있는데, PV를 미리 만들어 두고 사용하는 정적(static) 방법과 요청이 있을 때 마다 PV를 만드는 동적(dynamic) 방법이다.

- **정적(static) 프로비저닝**

  - 정적으로 PV를 프로비저닝할 때는 클러스터 관리자가 미리 적정 용량의 PV를 만들어 두고 사용자의 요청이 있으면 미리 만들어둔 PV를 할당한다. 사용할 수 있는 스토리지 용량에 제한이 있을 때 유용하다. 사용하도록 미리 만들어 둔 PV의 용량이 100GB라면 150GB를 사용하려는 요청들은 실패한다. 1TB 스토리지를 사용하더라도 미리 만들어 둔 PV 용량이 150GB 이상인 것이 없으면 요청이 실패한다.

- **동적(dynamic) 프로비저닝**
  - 동적으로 프로비저닝 할 때는 사용자가 PVC를 거쳐서 PV를 요청했을 때 생성해 제공한다. 쿠버네티스 클러스터에 사용할 1TB 스토리지가 있다면 사용자가 원하는 용량만큼을 생성해서 사용할 수 있다. 정적 프로비저닝과 달리 필요하다면 한번에 200GB PV도 만들 수 있다. PVC는 동적 프로비저닝할 때 여러가지 스토리지 중 원하는 스토리지를 정의하는 스토리지 클래스(Storage Class)로 PV를 생성한다.

### 2. Binding(바인딩)

바인딩(Binding)은 프로비저닝으로 만든 PV를 PVC와 연결하는 단계이다. PVC에서 원하는 스토리지의 용량과 접근방법을 명시해서 요청하면 거기에 맞는 PV가 할당 됩니다. 이 때 PVC에서 원하는 PV가 없다면 요청은 실패한다. 하지만 PVC는 원하는 PV가 생길 때까지 대기하다가 바인딩한다.

PV와 PVC의 매핑은 1:1 관계 이며, PVC 하나가 여러 개 PV에 할당될 수 없다.

### 3. Using(사용)

PVC는 pod에 설정되고 pod는 PVC를 볼륨으로 인식해서 사용한다.

할당된 PVC는 pod를 유지하는 동안 계속 사용되며, 시스템에서 임의로 삭제할 수 없다. 이 기능을 'Storage Object in Use Protection' (사용 중인 스토리지 오브젝트 보호)라고 한다. 사용 중인 데이터 스토리지를 임의로 삭제하는 경우 치명적인 결과가 발생할 수 있으므로 이런 보호 기능을 사용하는 것이다.

### 4. Reclaiming(반환)

사용이 끝난 PVC는 삭제되고 PVC를 사용하던 PV를 초기화(reclaim)하는 과정을 거칩니다. 이를 Reclaiming(반환)이라고 한다.

초기화 정책에는 Retain, Delete, Recycle이 있다.

- **Retain**
  - Retain은 PV를 그대로 보존한다. PVC가 삭제되면 사용 중이던 PV는 해제(released) 상태여서 다른 PVC가 재사용할 수 없다. 단순히 사용 해제 상태이므로 PV 안의 데이터는 그대로 남아있다. 이 PV를 재사용하려면 관리자가 다음 순서대로 직접 초기화해줘야한다.
    1. PV 삭제. 만약 PV가 외부 스토리지와 연결되었다면 PV는 삭제되더라도 외부 스토리지의 볼륨은 그대로 남아 있다.
    2. 스토리지에 남은 데이터를 직접 정리
    3. 남은 스토리지의 볼륨을 삭제하거나 재사용하려면 해당 볼륨을 이용하는 PV 재생성
- **Delete**
  - PV를 삭제하고 연결된 외부 스토리지 쪽의 볼륨도 삭제한다. 프로비저닝할 때 동적 볼륨 할당 정책으로 생성된 PV들은 기본 반환 정책(Reclaim Policy)이 Delete이다. 상황에 따라 처음에 Delete로 설정된 PV의 반환 정책을 수정해서 사용해야 한다.
- **Recycle**
  - Recycle은 PV의 데이터들을 삭제하고 다시 새로운 PVC에서 PV를 사용할 수 있도록 한다. 특별한 파드를 만들어 두고 데이터를 초기화하는 기능도 있지만 동적 볼륨 할당을 기본 사용할 것을 추천

## 예시

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-hostpath
spec:
  capacity:
    storage: 2Gi
  volumeMode: Filesystem # ----------------- (1)
  accessModes: # --------------------------- (2)
    - ReadWriteOnce
  storageClassName: manual # --------------- (3)
  persistentVolumeReclaimPolicy: Delete # -- (4)
  hostPath:
    path: /tmp/k8s-pv # -------------------- (5)
```

1. `.spec.volumeMode` 필드는 쿠버네티스 1.9버전 부터 추가된 필드이다. 기본 필드 값은 FileSystem 으로 볼륨을 파일 시스템 형식으로 사용한다.
   RAW 블록 디바이스 형식으로 사용하는 raw 라는 필드 값을 설정할 수 있다. 볼륨을 설정해서 사용할 수도 있다.

2. `.spec.accessModes` 필드는 볼륨의 읽기/쓰기 옵션을 설정한다. 볼륨은 한 번에 accessModes 필드를 하나만 설정할 수 있으며 필드 값은 세 가지가 있다.

   - ReadWriteOnce: 노드 하나에만 볼륨을 읽기/쓰기하도록 마운트할 수 있음
   - ReadOnlyMany: 여러 개 노드에서 읽기 전용으로 마운트할 수 있음
   - ReadWriteMany: 여러 개 노드에서 읽기/쓰기 가능하도록 마운트할 수 있음

       <details>
       <summary>볼륨 플러그인 별로 지원가능한 옵션</summary>
       <div markdown="1">
           
       |Volume Plugin|ReadWriteOnce|ReadOnlyMany|ReadWriteMany|
       |-|-|-|-|
       |AWSElasticBlockStore|✓|-|-|
       |AzureFile|✓|✓|✓|
       |AzureDisk|✓|-|-|
       |CephFS|✓|✓|✓|
       |Cinder|✓|-|-|
       |FC|✓|✓|-|
       |FlexVolume|✓|✓|-|
       |Flocker|✓|-|-|
       |GCEPersistentDisk|✓|✓|-|
       |Glusterfs|✓|✓|✓|
       |HostPath|✓|-|-|
       |iSCSI|✓|✓|-|
       |Quobyte|✓|✓|✓|
       |NFS|✓|✓|✓|
       |RBD|✓|✓|-|
       |VsphereVolume|✓|-|- (works when pods are collocated)|
       |PortworxVolume|✓|-|✓|
       |ScaleIO|✓|✓|-|
       |StorageOS|✓|-|-|
       </div>
       </details>

3. `.spec.storageClassName` 은 스토리지 클래스(StorageClass)를 설정하는 필드이다. 특정 스토리지 클래스가 있는 PV는 해당 스토리지 클래스에 맞는 PVC만 연결된다. PV에 `.spec.storageClassName` 필드 설정이 없으면 오직 `.spec.storageClassName` 필드 설정이 없는 PVC와 연결될 수 있다.

4. `.spec.persistentVolumeReclaimPolicy` 필드는 PV가 해제되었을 때 초기화 옵션을 설정한다. 앞에서 살펴본 것 처럼 Retain, Recycle, Delete 정책 중 하나이다.

5. `.spec.hostPath` 필드는 해당 PV의 볼륨 플러그인을 명시한다. 필드 값을 hostPath로 설정했기 때문에 하위의 `.spec.hostPath.path` 필드는 마운트시킬 로컬 서버의 경로를 설정한다.

---

참고

- https://kubernetes.io/docs/concepts/storage/persistent-volumes/


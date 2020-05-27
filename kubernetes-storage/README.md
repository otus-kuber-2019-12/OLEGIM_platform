# Выполнено ДЗ № 13

## Выполнем все в minikube

### Попробуем поставить CSI HostPath Driver

Задеплоим CDR для поддержки Snapshoots в кластер

```bash
# Change to the latest supported snapshotter version
SNAPSHOTTER_VERSION=v2.0.1

# Apply VolumeSnapshot CRDs
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

# Create snapshot controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
```

Проверим состояние

```bash
kubectl get volumesnapshotclasses.snapshot.storage.k8s.io
kubectl get volumesnapshots.snapshot.storage.k8s.io
kubectl get volumesnapshotcontents.snapshot.storage.k8s.io
```

Результат который получили и он нас устраивает

```bash
error: the server doesn't have a resource type "volumesnapshotclasses"
```

Клонируем репозиторий CSI HostPath Driver и сделаем деплой

```bash
git clone git@github.com:kubernetes-csi/csi-driver-host-path.git
cd csi-driver-host-path
deploy/kubernetes-latest/deploy.sh
```

Проверяем результат

```bash
kubectl get pods
AME                         READY   STATUS    RESTARTS   AGE
csi-hostpath-attacher-0      1/1     Running   0          111s
csi-hostpath-provisioner-0   1/1     Running   0          109s
csi-hostpath-resizer-0       1/1     Running   0          109s
csi-hostpath-snapshotter-0   1/1     Running   0          108s
csi-hostpath-socat-0         1/1     Running   0          108s
csi-hostpathplugin-0         3/3     Running   0          110s
snapshot-controller-0        1/1     Running   0          11m
```

Запустим примеры и проверим работу

```bash
kubectl apply -f examples/csi-storageclass.yaml && kubectl apply -f examples/csi-pvc.yaml && kubectl apply -f examples/csi-app.yaml

pod/my-csi-app created
persistentvolumeclaim/csi-pvc created
storageclass.storage.k8s.io/csi-hostpath-sc created


kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS      REASON   AGE
pvc-c218149b-84a0-4bac-931e-173961463eb8   1Gi        RWO            Delete           Bound    default/csi-pvc   csi-hostpath-sc            38s

kubectl get pvc
NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
csi-pvc   Bound    pvc-c218149b-84a0-4bac-931e-173961463eb8   1Gi        RWO            csi-hostpath-sc   78s

kubectl describe pods/my-csi-app
Name:         my-csi-app
Namespace:    default
Priority:     0
Node:         minikube/172.17.0.2
....
    Mounts:
      /data from my-csi-volume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-dg59n (ro)
....
Volumes:
  my-csi-volume:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  csi-pvc
    ReadOnly:   false
  default-token-dg59n:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-dg59n
    Optional:    false
....
Events:
  Type    Reason                  Age   From                     Message
  ----    ------                  ----  ----                     -------
  Normal  Scheduled               37s   default-scheduler        Successfully assigned default/my-csi-app to minikube
  Normal  SuccessfulAttachVolume  37s   attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-bcbc0215-74d6-4f4f-a8f0-e0d0d6359fc3"
  Normal  Pulling                 32s   kubelet, minikube        Pulling image "busybox"
  Normal  Pulled                  29s   kubelet, minikube        Successfully pulled image "busybox"
  Normal  Created                 28s   kubelet, minikube        Created container my-frontend
  Normal  Started                 28s   kubelet, minikube        Started container my-frontend
```

Проверяем как работает HostPath driver:

```bash
kubectl exec -it my-csi-app -- /bin/sh
/ # touch /data/hello-world
/ # ls -la /data
total 8
drwxr-xr-x    2 root     root          4096 May 27 12:50 .
drwxr-xr-x    1 root     root          4096 May 27 12:00 ..
-rw-r--r--    1 root     root             0 May 27 12:50 hello-world
/ # exit
```

Проверяем наличие файла в контейнере

```bash
kubectl exec -it $(kubectl get pods --selector app=csi-hostpathplugin -o jsonpath='{.items[*].metadata.name}') -c hostpath -- /bin/sh

/ # find / -name hello-world
/var/lib/kubelet/pods/525af1d9-af26-47cd-a900-d5bf2918f8dd/volumes/kubernetes.io~csi/pvc-bcbc0215-74d6-4f4f-a8f0-e0d0d6359fc3/mount/hello-world
/csi-data-dir/acfd773d-a011-11ea-98fd-0242ac120005/hello-world
/ # exit
```

## Задание

- Создать StorageClass для CSI Host Path Driver
- Создать объект PVC c именем `storage-pvc`
- Создать объект Pod c именем `storage-pod`
- Хранилище нужно смонтировать в `/data`

Применим манифесты из папки hw и посмотрим результат

```bash


kubectl apply -f hw/storageClass.yaml && kubectl apply -f hw/pvc.yaml && kubectl apply -f hw/pod.yaml
storageclass.storage.k8s.io/storage-kub created
persistentvolumeclaim/storage-pvc created
pod/storage-pod created

kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS      REASON   AGE
pvc-8a95653d-d790-44d7-8285-bc21e7d72b5b   1Gi        RWO            Delete           Bound    default/storage-pvc   storage-kub                3m39s
pvc-bcbc0215-74d6-4f4f-a8f0-e0d0d6359fc3   1Gi        RWO            Delete           Bound    default/csi-pvc       csi-hostpath-sc            68m

kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
csi-pvc       Bound    pvc-bcbc0215-74d6-4f4f-a8f0-e0d0d6359fc3   1Gi        RWO            csi-hostpath-sc   68m
storage-pvc   Bound    pvc-8a95653d-d790-44d7-8285-bc21e7d72b5b   1Gi        RWO            storage-kub       3m43s

kubectl describe pods/storage-pod
Name:         storage-pod
Namespace:    default
Priority:     0
Node:         minikube/172.17.0.2
....
    Mounts:
      /data from data-volume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-dg59n (ro)
....
Volumes:
  data-volume:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  storage-pvc
    ReadOnly:   false
  default-token-dg59n:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-dg59n
    Optional:    false
....
Events:
  Type    Reason                  Age    From                     Message
  ----    ------                  ----   ----                     -------
  Normal  Scheduled               3m53s  default-scheduler        Successfully assigned default/storage-pod to minikube
  Normal  SuccessfulAttachVolume  3m53s  attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-8a95653d-d790-44d7-8285-bc21e7d72b5b"
  Normal  Pulling                 3m44s  kubelet, minikube        Pulling image "bash"
  Normal  Pulled                  3m40s  kubelet, minikube        Successfully pulled image "bash"
  Normal  Created                 3m40s  kubelet, minikube        Created container app
  Normal  Started                 3m40s  kubelet, minikube        Started container app

```

## Snapshot

```bash

kubectl apply -f ./hw/volumeSnapshotClass.yaml
volumesnapshotclass.snapshot.storage.k8s.io/test-snapclass created
```

Добавим данные

```bash
kubectl exec -it storage-pod -- /bin/sh
/ # touch /data/test
/ # touch /data/test2
/ # touch /data/test3
/ # ls -la /data/
total 8
drwxr-xr-x    2 root     root          4096 May 27 13:16 .
drwxr-xr-x    1 root     root          4096 May 27 13:05 ..
-rw-r--r--    1 root     root             0 May 27 13:16 test
-rw-r--r--    1 root     root             0 May 27 13:16 test2
-rw-r--r--    1 root     root             0 May 27 13:16 test3
/ # exit
```

Сделаем снапшот:

```bash
kubectl apply -f ./hw/snapshotVolume.yaml
```

Посмотрим результат, снапшот готов

```bash
kubectl describe volumesnapshot
Name:         test-snapshot
Namespace:    default
Labels:       <none>
Annotations:  API Version:  snapshot.storage.k8s.io/v1beta1
Kind:         VolumeSnapshot
Metadata:
  Creation Timestamp:  2020-05-27T13:18:10Z
  Finalizers:
    snapshot.storage.kubernetes.io/volumesnapshot-as-source-protection
    snapshot.storage.kubernetes.io/volumesnapshot-bound-protection
  Generation:  1
  Managed Fields:
    API Version:  snapshot.storage.k8s.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        f:creationTime:
        f:readyToUse:
        f:restoreSize:
    Manager:         snapshot-controller
    Operation:       Update
    Time:            2020-05-27T13:18:48Z
  Resource Version:  12848
  Self Link:         /apis/snapshot.storage.k8s.io/v1beta1/namespaces/default/volumesnapshots/test-snapshot
  UID:               892941f7-efd9-49d8-aa2b-6423e1a88f98
Spec:
  Source:
    Persistent Volume Claim Name:  storage-pvc
  Volume Snapshot Class Name:      test-snapclass
Status:
  Bound Volume Snapshot Content Name:  snapcontent-892941f7-efd9-49d8-aa2b-6423e1a88f98
  Creation Time:                       2020-05-27T13:18:47Z
  Ready To Use:                        true
  Restore Size:                        1Gi
Events:                                <none>
```

Добавим данные

```bash
kubectl exec -it storage-pod -- /bin/sh
/ # touch /data/test-snapshot
/ # ls -la /data/
total 8
drwxr-xr-x    2 root     root          4096 May 27 13:22 .
drwxr-xr-x    1 root     root          4096 May 27 13:05 ..
-rw-r--r--    1 root     root             0 May 27 13:16 test
-rw-r--r--    1 root     root             0 May 27 13:22 test-snapshot
-rw-r--r--    1 root     root             0 May 27 13:16 test2
-rw-r--r--    1 root     root             0 May 27 13:16 test3
/ # exit
```

Создадим PVC из снапшота:

```bash
kubectl apply -f ./hw/pvcFromSnapshot.yaml
```

Проверяем pv и pvc

```bash

kubectl get pvc
NAME                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
csi-pvc               Bound    pvc-bcbc0215-74d6-4f4f-a8f0-e0d0d6359fc3   1Gi        RWO            csi-hostpath-sc   94m
storage-pvc           Bound    pvc-8a95653d-d790-44d7-8285-bc21e7d72b5b   1Gi        RWO            storage-kub       29m
storage-pvc-resored   Bound    pvc-8675139f-4078-4634-99ad-235dd6118741   1Gi        RWO            storage-kub       3s

kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                         STORAGECLASS      REASON   AGE
pvc-8675139f-4078-4634-99ad-235dd6118741   1Gi        RWO            Delete           Bound    default/storage-pvc-resored   storage-kub                8s
pvc-8a95653d-d790-44d7-8285-bc21e7d72b5b   1Gi        RWO            Delete           Bound    default/storage-pvc           storage-kub                29m
pvc-bcbc0215-74d6-4f4f-a8f0-e0d0d6359fc3   1Gi        RWO            Delete           Bound    default/csi-pvc               csi-hostpath-sc            94m
```

Востанновим volume из снапшота и проверим результат

```bash

kubectl apply -f ./hw/podFromSnapshot.yaml
pod/storage-pod-restored created

kubectl exec -it storage-pod-restored -- /bin/sh
/ # ls -la /data/
total 8
drwxr-xr-x    2 root     root          4096 May 27 13:34 .
drwxr-xr-x    1 root     root          4096 May 27 13:36 ..
-rw-r--r--    1 root     root             0 May 27 13:16 test
-rw-r--r--    1 root     root             0 May 27 13:16 test2
-rw-r--r--    1 root     root             0 May 27 13:16 test3
/ # exit
```

## PR checklist

- [x] Выставлен label с номером домашнего задания
- [] Задание со *
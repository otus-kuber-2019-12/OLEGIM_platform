# Выполнено ДЗ № 5

 - [x] Основное ДЗ
 - [x] Задание со *

## В процессе сделано:
  Создан кластер
 ```
  kind create cluster
  export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
 ``` 
   kubectl get statefulsets

```
NAME    READY   AGE
minio   1/1     3m7s
```
  kubectl get pods

```
NAME      READY   STATUS    RESTARTS   AGE
minio-0   1/1     Running   0          4m17s
```
  kubectl get pvc

```
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
data-minio-0   Bound    pvc-8aabab45-1b2b-4e34-9d2e-0754d19f6b2d   10Gi       RWO            standard       4m35s

```
  kubectl get pv
```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE
pvc-8aabab45-1b2b-4e34-9d2e-0754d19f6b2d   10Gi       RWO            Delete           Bound    default/data-minio-0   standard                4m52s
```
Созданы секреты
```
echo -n minio | base64
bWluaW8=
echo -n minio123 | base64
bWluaW8xMjM=
```
Добавлено в переменные valueFrom:secretKeyRef для работы с секретами

## Как запустить проект:
```
  kubectl apply -f kubernetes-volumes/ 
```
## Как проверить работоспособность:
 ```
 docker run minio/mc ls

 kubectl port-forward minio-0 9000:9000

 http://localhost:9000/minio/login
 ``` 
## PR checklist:
 - [x] Выставлен label с номером домашнего задания
 - [x] Задание со * 
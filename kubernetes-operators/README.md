# Выполнено ДЗ № 7

- [x] Основное ДЗ
- [x] Задание со *

Поднимем кластер `minikube`

```bash
minikube start  
```

Запустим Custom resource(CR) манифест

```bash
kubectl apply -f deploy/cr.yml

error: unable to recognize "deploy/cr.yml": no matches for kind "MySQL" in version "otus.homework/v1"
```

Ошибка связана с отсутсвием объектов типа MySQL в API kubernetes. Создадим Custom Resouce Definition (CRD).

Применяем CRD манифест

```bash
kubectl apply -f deploy/crd.yml
```

Повторим запуск CR.

## Взаимодействие с объектами CR CRD

Посмотрим информацию о нём:

```bash
kubectl get crd

NAME                   CREATED AT
mysqls.otus.homework   2020-03-19T16:16:58Z


kubectl get mysqls.otus.homework
NAME             AGE
mysql-instance   69s

kubectl describe mysqls.otus.homework mysql-instance
Name:         mysql-instance
Namespace:    default
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"otus.homework/v1","kind":"MySQL","metadata":{"annotations":{},"name":"mysql-instance","namespace":"default"},"spec":{"datab...
API Version:  otus.homework/v1
Kind:         MySQL
Metadata:
  Creation Timestamp:  2020-03-19T16:17:08Z
  Generation:          1
  Resource Version:    16095
  Self Link:           /apis/otus.homework/v1/namespaces/default/mysqls/mysql-instance
  UID:                 df605fae-be5d-4602-9bd6-31a334a11334
Spec:
  Database:      otus-database
  Image:         mysql:5.7
  Password:      otuspassword
  storage_size:  1Gi
```

## Validation

Добавим Validation в CDR, запустим снова:

```bash
kubectl delete mysqls.otus.homework mysql-instance
kubectl apply -f deploy/crd.yml
kubectl apply -f deploy/cr.yml
```

Добавим дерективу `spec.validation.spec.reqiored` в CRD. Удалим CR поле с размером хранилища, запустим cr и crd:

```bash
kubectl apply -f deploy/crd.yml
customresourcedefinition.apiextensions.k8s.io/mysqls.otus.homework configured

kubectl apply -f deploy/cr.yml
The MySQL "mysql-instance" is invalid: spec.storage_size: Required value
```

Ответ который нам нужен

## Операторы

Используемый фреймфорк `kopf` совместим с версией `python>=3.7`
Дополнительные модули которые нам понадобятся:

```bash
kopf == 0.25
PyYAML == 5.3
kubernetes == 10.0.1
jinja2 == 2.11.1
```

Создадим для питон-скрипта папку build

```bash
cd kubernetes-operators/build
kopf run msql-operator.py
```

Получим:

```bash
[2020-03-23 16:59:43,647] kopf.reactor.activit [INFO    ] Initial authentication has been initiated.
[2020-03-23 16:59:43,669] kopf.activities.auth [INFO    ] Handler 'login_via_pykube' succeeded.
[2020-03-23 16:59:43,693] kopf.activities.auth [INFO    ] Handler 'login_via_client' succeeded.
[2020-03-23 16:59:43,693] kopf.reactor.activit [INFO    ] Initial authentication has finished.
[2020-03-23 16:59:43,739] kopf.engines.peering [WARNING ] Default peering object not found, falling back to the standalone mode.
 mysql-operator.py:28: YAMLLoadWarning: calling yaml.load() without Loader=... is deprecated, as the default Loader is unsafe.
[2020-03-23 16:59:44,298] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'mysql_on_create' succeeded.
[2020-03-23 16:59:44,299] kopf.objects         [INFO    ] [default/mysql-instance] All handlers succeeded for creation.
[2020-03-23 17:00:39,468] kopf.reactor.running [INFO    ] Signal SIGINT is received. Operator is stopping.
```

## Вопрос: почему объект создался, хотя мы создали CR, до того, как запустили контроллер?

Запись о Custom Resource  попала в etcd и информация о ней может быть получена через kube-apiserver. Когда появляется новый ресурс, его обнаруживает контроллер mysql-operator, его задача обнаружение записей (MySql).

В нашем случае контроллер регистрирует специальный вызов для событий создания через информатор.

Этот обработчик будет вызван, когда mysql-operator впервые станет доступным.

Когда обработчик отпросит kube-apiserver по label selectors, выяснится что нет записей deployment, service, pods, pv, pvc

Процесс синхронизации ничего не знает о состоянии (является state agnostic): он проверяет новые записи точно так же, как и уже существующие, значит не важно когда ресурс был запущен, при обработке будет созданые отсутсвующие ресурсы

Т.к. мы описали логику создания ресурса, но не его удаления. Удалим ресурсы в ручную:

```bash
kubectl delete mysqls.otus.homework mysql-instance

kubectl delete deployments.apps mysql-instance

kubectl delete pvc mysql-instance-pvc

kubectl delete pv mysql-instance-pv

kubectl delete svc mysql-instance
```

## Запустим питон-скрипт для запуска контроллера, затем удалим его.

```bash
kopf run mysql-operator.py
```

```bash
kubectl apply -f deploy/cr.yml
kubectl delete -f deploy/cr.yml
kubectl get all
kubectl get pvc
kubectl get pv
```

Добавим рекомендованную строчку `kopf.append_owner_reference(restore_job, owner=body)`*

## Проверка работоспособности

```bash
kopf run mysql-operator.py
```

```bash
kubectl apply -f deploy/cr.yml
kubectl get pvc
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test ( id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database

kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data-2' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database

+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

## Удалим mysql-instance

```bash
kubectl delete mysqls.otus.homework mysql-instance
kubectl get pv
kubectl get jobs.batch
```

## Создадим новый инстанс и проверим восстановление из бэкапа:

```bash
kubectl apply -f deploy/cr.yml

export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

Контроллер работает.

## Создадим докер образ и отправим его в dockerhub

```bash
cd build
docker build -t olegim89/mysql-operator:v0.1 .
docker push  olegim89/mysql-operator:v0.1
```

Создадим роль, service account, deployment и загрузим контроллер в кластер:

```bash
kubectl apply -f /deploy
```

## Делаем проверку

```bash
kubectl apply -f deploy/cr.yml
kubectl get pvc
kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}"
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")

kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test ( id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database

kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data-2' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

## Удалим mysql-instance

```bash
kubectl delete mysqls.otus.homework mysql-instance
kubectl get pv
kubectl get jobs.batch
```

Создадим новый инстанс и проверим восстановление из бэкапа:

```bash
kubectl apply -f deploy/cr.yml

export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

## PR checklist

- [x] Выставлен label с номером домашнего задания
- [x] Задание со *

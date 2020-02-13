# Выполнено ДЗ № 3

 - [x] Основное ДЗ


## В процессе сделано:
## task01:
01-bob.yaml - добавление ServiceAccount и биндинг сервисных аккаунтов к существующим ролям\
02-dave.yaml - добавление новой роли без прав доступа\

## 02-task:
01-namespace.yaml - создание namespace prometheus :\
02-carol.yaml - добавление пользователя carol к этому namespace\
03-rules.yaml - Даем права get, list, watch\

## 03-task:
3.1. 01-namespace.yaml - namespace dev
3.2. 02-jane.yaml - SA jane
3.3. 03-jane-admin.yaml - назначем jane роль admin для dev
3.4. 04-ken.yaml создаем SA ken
3.5. 05-ken-view.yaml - даем права SA ken только на чтение в dev
## Как запустить проект:
```
    kubectl apply -f kubernetes-security/task01/
    kubectl apply -f kubernetes-security/task02/
    kubectl apply -f kubernetes-security/task03/
```
## Как проверить работоспособность:
```
kubectl get pods -n kube-system --as system:serviceaccount:default:bob
yes
kubectl get pods -n kube-system --as system:serviceaccount:default:dave
no
kubectl auth can-i get deployments --as system:serviceaccount:prometheus:carol
no
kubectl auth can-i list pods --as system:serviceaccount:prometheus:carol -n prometheus
yes
kubectl auth can-i list pods --as system:serviceaccount:prometheus:carol
yes
kubectl auth can-i get deployments --as system:serviceaccount:dev:jane
no
kubectl auth can-i create deployments --as system:serviceaccount:dev:jane -n dev
yes
kubectl auth can-i get deployments --as system:serviceaccount:dev:ken
no
kubectl auth can-i get deployments --as system:serviceaccount:dev:ken -n dev
yes
kubectl auth can-i create deployments --as system:serviceaccount:dev:ken -n dev
no
```
## PR checklist:
 - [x] Выставлен label с номером домашнего задания

 
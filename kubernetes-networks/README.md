# Выполнено ДЗ № 4

 - [x] Основное ДЗ

## В процессе сделано:
 Добавлено в файл kubernets-intro/web-pod.yaml
```
           livenessProbe:
            tcpSocket: 
              port: 8000
          readinessProbe:
            httpGet:
              path: /index.html
              port: 8000
```


 Создадим манифест web-deploy.yaml
указав количество реплик 3 для Deployment

применим и посмотрим desribe
в поле Condifitions увидим что значение Available and Progressing = true


Добавим стратегии развертывания maxUnavailable и maxSurge

Удаляем все поды создаём новые.

```
maxUnavailable: 100%
maxSurge: 0
```
Blue-Green
```
maxUnavailable: 0
maxSurge: 100%
```

Canary(ступенчатая замена)
```l
maxUnavailable: 1
maxSurge: 0
```

Рандомно
```
maxUnavailable: 100%
maxSurge: 100%
```

Приведет к ошибке
```
maxUnavailable: 0
maxSurge: 0

The Deployment "web" is invalid: spec.strategy.rollingUpdate.maxUnavailable: Invalid value: intstr.IntOrString{Type:0, IntVal:0, StrVal:""}: may not be 0 when maxSurge is 0
```

Создадим Service web-svc-cip:

    ```bash
    kubectl apply -f web-svc-cip.yaml

    service/web-svc-cip created

    kubectl get service
    NAME          TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
    kubernetes    ClusterIP   10.96.0.1      <none>        443/TCP   5h55m
    web-svc-cip   ClusterIP   10.96.253.44   <none>        80/TCP    7m41s
    ```

Найдем IP где он указан

```
minikube ssh
curl http://10.96.253.44/index.html
ping -с1 10.96.253.44
arp -an
ip addr show
sudo iptables --list -nv -t nat
```

Полностью очистим все правила iptables, поднятнутся сами новые пути

включил ipvs
проверил доступность

установка metallb, его конфигурация и создание сервиса
```
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.0/manifests/metallb.yaml
kubectl apply -f metallb-config.yaml
kubectl apply -f web-svc-lb.yaml

```
Проверим что назначен 172.17.255.1

```
kubectl --namespace metallb-system logs pod/controller
```
Name:                     web-svc-lb
Type:                     LoadBalancer
IP:                       10.96.253.44
http://10.96.253.44/index.html

{"caller":"service.go:98","event":"ipAllocated","ip":"172.17.255.1","msg":"IP address assigned by controller","service":"default/web-svc-lb","ts":"2020-02-06T16:27:45.656238705Z"}


kubectl describe svc web-svc-lb
Name:                     web-svc-lb
Namespace:                default
Labels:                   <none>
Annotations:              kubectl.kubernetes.io/last-applied-configuration:
                            {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"web-svc-lb","namespace":"default"},"spec":{"ports":[{"port":80,"p...
Selector:                 app=web
Type:                     LoadBalancer
IP:                       10.96.0.44
LoadBalancer Ingress:     172.17.255.1
Port:                     <unset>  80/TCP
TargetPort:               8000/TCP
NodePort:                 <unset>  30398/TCP
Endpoints:                172.17.0.4:8000,172.17.0.5:8000,172.17.0.6:8000
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason       Age   From                Message
  ----    ------       ----  ----                -------
  Normal  IPAllocated  12m   metallb-controller  Assigned IP "172.17.255.1"


прокинем маршрут наружу и посмотрим доступность
```
sudo ip route add 172.17.255.0/24 via 192.168.122.243

curl http://172.17.255.1/index.html
```
```
<html>
<head/>
<body>
<!-- IMAGE BEGINS HERE -->
```

## COREDNS

Нельзя сделать чтобы на прямую сделать чтобы DNS по TCP и UDP были на одном IP адресе и LoadBalancer не может работать одновременно с несколькими IP протоколами, решение проблемы добавление аннотации `metallb.universe.tf/allow-shared-ip`
Запустим и проверим что получилось
```
kubectl apply -f kubernetes-networks/coredns/
kubectl describe svc -n kube-system kube-dns 
```

## INGRESS
Установил манифесты
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
kubectl apply -f nginx-lb.yaml
kubectl apply -f web-svc-headless.yaml
```

Применил конфигурацию web-svc-headless нам не нужна балансировка
Проверил доступность ping & curl
Подключил приложение Web к Ingress c параметром ClusterIP:none
 ```
web-svc       ClusterIP   None           <none>        80/TCP    14s
 ```
Создание правил для Ingress(ingress-proxy)
```
Address:          172.17.255.1
/web   web-svc:8000 (172.17.0.4:8000,172.17.0.5:8000,172.17.0.6:8000)
```

## Как запустить проект:
```
kubectl apply -f kubernetes-intro/web-pod.yaml --force
kubectl apply -f kubernetes-network/
```
## Как проверить работоспособность:
## PR checklist:
 - [x] Выставлен label с номером домашнего задания

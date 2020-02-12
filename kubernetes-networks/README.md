# Выполнено ДЗ № 3

 - [x] Основное ДЗ


## В процессе сделано:
 Отредактирован файл kubernets-intro/web-pod.yaml


 Попробуйте разные варианты деплоя с крайними значениями
maxSurge и maxUnavailable (оба 0, оба 100%, 0 и 100%)
При maxUnavailable и maxSurge: 0 будет ошибка
```
The Deployment "web" is invalid: spec.strategy.rollingUpdate.maxUnavailable: Invalid value: intstr.IntOrString{Type:0, IntVal:0, StrVal:""}: may not be 0 when maxSurge is 0
```



Полностью очистим все правила iptables


включил ipvs
проверил доступность

ping -c1 10.96.239.166
PING 10.96.239.166 (10.96.239.166): 56 data bytes
64 bytes from 10.96.239.166: seq=0 ttl=64 time=0.168 ms



Name: KUBE-CLUSTER-IP
Type: hash:ip,port
Revision: 5
Header: family inet hashsize 1024 maxelem 65536
Size in memory: 536
References: 2
Number of entries: 7
Members:

10.96.239.166,tcp:80


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


адрес виртуалки

маршрут
sudo ip route add 172.17.255.0/24 via 192.168.122.243

curl http://172.17.255.1/index.html
<html>
<head/>
<body>
<!-- IMAGE BEGINS HERE -->



[root@minikube ~]# ipvsadm --list -n
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.96.0.1:443 rr
  -> 192.168.39.218:8443          Masq    1      0          0         
TCP  10.96.0.10:53 rr
  -> 172.17.0.2:53                Masq    1      0          0         
  -> 172.17.0.3:53                Masq    1      0          0         
TCP  10.96.0.10:9153 rr
  -> 172.17.0.2:9153              Masq    1      0          0         
  -> 172.17.0.3:9153              Masq    1      0          0         
TCP  10.96.46.215:80 rr
  -> 172.17.0.6:8000              Masq    1      0          0         
  -> 172.17.0.7:8000              Masq    1      0          0         
  -> 172.17.0.8:8000              Masq    1      0          0         
TCP  10.96.127.187:80 rr
  -> 172.17.0.5:9090              Masq    1      0          0         
TCP  10.96.147.8:8000 rr
  -> 172.17.0.4:8000              Masq    1      0          0         
UDP  10.96.0.10:53 rr
  -> 172.17.0.2:53                Masq    1      0          0         
  -> 172.17.0.3:53                Masq    1      0          0 


## INGRESS
Установил манифест
Применил конфигурацию Loadbalance
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

 
# Выполнено ДЗ № 3

 - [x] Основное ДЗ


## В процессе сделано:
 Отредактирован файл kubernets-intro/web-pod.yaml
 Вопрос: 
 1. Почему следующая конфигурация валидна, но не имеет смысла?
 2. Бывают ли ситуации, когда она все-таки имеет смысл?

 Попробуйте разные варианты деплоя с крайними значениями
maxSurge и maxUnavailable (оба 0, оба 100%, 0 и 100%)
`The Deployment "web" is invalid: spec.strategy.rollingUpdate.maxUnavailable: Invalid value: intstr.IntOrString{Type:0, IntVal:0, StrVal:""}: may not be 0 when maxSurge is 0`

Сделайте curl http://<CLUSTER-IP>/index.html - работает!
Сделайте ping <CLUSTER-IP> - пинга нет
Сделайте arp -an, ip addr show - нигде нет ClusterIP
Сделайте iptables --list -nv -t nat - вот где наш
кластерный IP!
10.96.239.166
Полностью очистим все правила iptables


включил ipvs
TCP  10.96.239.166:80 rr
  -> 172.17.0.4:8000              Masq    1      0          0         
  -> 172.17.0.5:8000              Masq    1      0          0         
  -> 172.17.0.6:8000  

ping -c1 10.96.239.166
PING 10.96.239.166 (10.96.239.166): 56 data bytes
64 bytes from 10.96.239.166: seq=0 ttl=64 time=0.168 ms

--- 10.96.239.166 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.168/0.168/0.168 ms

Name: KUBE-CLUSTER-IP
Type: hash:ip,port
Revision: 5
Header: family inet hashsize 1024 maxelem 65536
Size in memory: 536
References: 2
Number of entries: 7
Members:
10.96.0.1,tcp:443
10.96.0.10,tcp:9153
10.96.0.10,tcp:53
10.96.239.166,tcp:80
10.96.0.10,udp:53
10.96.171.50,tcp:80
10.96.196.129,tcp:8000

Name:                     web-svc-lb
Type:                     LoadBalancer
IP:                       10.96.253.44
http://10.96.253.44/index.html


адрес виртуалки
sudo route add 172.17.255.0/24 192.168.122.243
## Как запустить проект:
livenessprobe
`kubectl apply -f kubernetes-intro/web-pod.yaml --force`
  
## Как проверить работоспособность:
## PR checklist:
 - [x] Выставлен label с номером домашнего задания

 
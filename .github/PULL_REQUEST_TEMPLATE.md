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

## Как запустить проект:
livenessprobe
`kubectl apply -f kubernetes-intro/web-pod.yaml --force`
  
## Как проверить работоспособность:
## PR checklist:
 - [x] Выставлен label с номером домашнего задания

 
## Задание №1
Разберитесь почему все pod в namespace kube-system
восстановились после удаления?
## Ответ №1
Перезапуск всех модулей связан со значение с высоким приоритетом и политикой перезапуска со значением всегда.
Priority:                 2000000000
Priority Class Name:      system-cluster-critical                         
Restart Policy:           Always      

upd.
Системные компоненты (кроме core-dns) - потому что они запущены как static pods 
Coredns - перезапускается потому, что управляется контроллеров deployment


## Задание №2
Выясните причину, по которой pod frontend находится в статусе Error
## Ответ №2
kubectl logs frontend
panic: environment variable "PRODUCT_CATALOG_SERVICE_ADDR" not set

обязательные переменные для запуска не найдена.
# Выполнено ДЗ №

 - [*] Основное ДЗ
 - [*] Задание со *

## В процессе сделано:
 - Сборка образа по указанным требования образа по указанным требования https://hub.docker.com/repository/docker/olegim89/otus_intro
 - Прогон тестовой страницы
 - Создание манифеста web-pod.yaml c указанными требованиями (init, Volume)
 - Рассмотрены методы взаимодействия с управляющими компонента kubernetes

## Как запустить проект:
ввести команду:
kubectl apply -f web-pod.yaml 
ответ сервера
pod/web created
ввести команду:
kubectl port-forward --address 0.0.0.0 pod/web 8000:8000
ответ сервера
Forwarding from 0.0.0.0:8000 -> 8000

Проект будет запущен
## Как проверить работоспособность:
 Перейти по ссылке http://localhost:8080

## PR checklist:
 - [x] Выставлен label с номером домашнего задания
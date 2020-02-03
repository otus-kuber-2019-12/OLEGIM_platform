# Выполнено ДЗ № 2

 - [x] Основное ДЗ
 - [x] Задание со *

## В процессе сделано:
 - Установлен kind
 - Настроен кластер
 - Создан манифест frontend-replicaset.yaml
 - Исправлен манифест frontend-replicaset.yaml
 - Произведенно масштабирование frontend 
 - Изменен манифест frontend-replicaset.yaml на 3 реплики
 - Обновлен образ контейнера frontend(v0.0.2)
 - Вопрос: "Почему обновление ReplicaSet не повлекло обновление
запущенных pod?". Ответ: "Replica Controller не перезапускает поды после обновления шаблона"
 - Создан манифест для запуска ReplicaSet и Deployment сервиса paymentservice
 - Обновлен манифест сервиса paymentservice
 - Произведен откат deployment сервиса paymentservice
 - Подготовлен манифест для blue-green и Reverse Rolling Update deployment сервиса paymentservice
 - Создан манифест deployment сервиса frontend с настройкой readinessProbe
 - Заменено в описании пробы URL /_healthz на /_health
 - Создан манифест для DeamonSet сервиса node-exporter

## Как запустить проект:
 - Подготовка кластера (если нет развернутого):
 ```bash
 kind create cluster --config kind-config.yaml
 ```
 - Настройка и проверка ReplicaSet сервиса frontend:
 ```bash
 kubectl apply -f frontend-replicaset.yaml | kubectl get pods -l app=frontend -w
 ```
 - Настройка и проверка ReplicaSet и Deployment сервиса paymentservice:
 ```bash
 kubectl apply -f paymentservice-replicaset.yaml
 kubectl get pods -l app=paymentservice -w

 kubectl apply -f paymentservice-deployment.yaml
 kubectl get pods -l app=paymentservice -w
 ```
  - Настройка и проверка blue-green и Deployment сервиса paymentservice:
 ```bash
 kubectl apply -f paymentservice-deployment-bg.yaml | kubectl get pods -l app=paymentservice -w

 kubectl apply -f paymentservice-deployment-reverse.yaml | kubectl get pods -l app=paymentservice -w
 ```
  - Настройка и проверка DeamonSet сервиса node-exporter:
 ```bash
 kubectl apply -f node-exporter-daemonset.yaml
 kubectl get pod -o wide
 kubectl port-forward <имя pod в DaemonSet> 9100:9100
 ```

## Как проверить работоспособность:
 - Проверить корректность применения манифестов можно командой:
 ```bash
 kubectl get pods -l app=frontend
 ```
```bash
 kubectl get pods -l app=paymentservice
 ```
 - Проверить сервис node-exporter можно командой:
 ```bash
 curl localhost:9100/metrics
 ```
## PR checklist:
 - [x] Выставлен label с номером домашнего задания

 
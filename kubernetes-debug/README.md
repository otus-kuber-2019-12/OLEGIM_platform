# Выполнено ДЗ № 12

## Подготовка kuberctl-debug

```bash
wget https://github.com/aylei/kubectl-debug/releases/download/v0.1.1/kubectl-debug_0.1.1_linux_amd64.tar.gz
tar -xzf kubectl-debug_0.1.1_linux_amd64.tar.gz
sudo mv kubectl-debug /usr/local/bin/
rm -f kubectl-debug_0.1.1_linux_amd64.tar.gz
kubectl-debug --version
debug version v0.0.0-master+$Format:%h$

```

## Запустим кластер Minikube, применим манифест агента

```bash
kubectl apply -f strace/agent_daemonset.yml 
error: unable to recognize "strace/agent_daemonset.yml": no matches for kind "DaemonSet" in version "extensions/v1beta1"
Заменим ApiVersion на apps/v1
```

Задеплоим наш под:

```bash
kubectl apply -f strace/pod.yml
```

Запустим debug:

```bash
kubectl-debug pod
```

Запускаем strace

```bash
strace: attach: ptrace(PTRACE_SEIZE, 1): Operation not permitted
```

Получили ошибку, это связано с образом в agent_daemonset, заменим образ на релиз aylei/debug-agent:v0.1.1 и повторим попытку. В итоге получаем

```bash
strace -c -p1
strace: Process 1 attached
```

## iptables-tailer

Создадим кластер GKE

```bash
gcloud container --project "debug-278415" clusters create "cluster" --enable-network-policy --zone "europe-west2-a" --image-type "ubuntu"

gcloud container clusters get-credentials cluster --zone europe-west2-a --project debug-278415
```

### Установим netperf-operator

```bash

kubectl apply -f ./deploy/crd.yaml
customresourcedefinition.apiextensions.k8s.io/netperfs.app.example.com created

kubectl apply -f ./deploy/rbac.yaml
role.rbac.authorization.k8s.io/netperf-operator created
rolebinding.rbac.authorization.k8s.io/default-account-netperf-operator created

kubectl apply -f ./deploy/operator.yaml
deployment.apps/netperf-operator created

kubectl apply -f ./deploy/cr.yaml
netperf.app.example.com/example created
```

Посмотрим отчет о поде, обратим внимание на статус пода. Status: Done

```bash
kubectl describe netperf.app.example.com/example
Name:         example
Namespace:    default
....
Status:
  Client Pod:          netperf-client-42010a9a00bf
  Server Pod:          netperf-server-42010a9a00bf
  Speed Bits Per Sec:  1841.65
  Status:              Done
Events:                <none>
```

Применим сетевые политики

```bash
kubectl apply -f ./netperf-calico-policy.yaml
networkpolicy.crd.projectcalico.org/netperf-calico-policy created
```

Удалим ресурсы и заново добавим

```bash
kubectl delete -f ./deploy/cr.yaml && kubectl apply -f ./deploy/cr.yaml
kubectl describe netperf.app.example.com/example
Name:         example
Namespace:    default
....
Status:
  Client Pod:          netperf-client-42010a9a00bf
  Server Pod:          netperf-server-42010a9a00bf
  Speed Bits Per Sec:  0
  Status:              Started test
Events:                <none>

```

Посмотрим отчет о поде, обратим внимание на статус пода. Status: Started test


- Подключитесь к ноде по SSH 
- iptables --list -nv | grep DROP - счетчики дропов ненулевые 
- iptables --list -nv | grep LOG - счетчики с действием логирования ненулевые

## Деплой `iptaibles-tailer`

kubectl apply -f kit/

В манифесте DaemonSet префикс calico-drop заменим его на calico-packet и заново применим манифест

Удалим манифест и снова применим

```bash
kubectl delete -f kit/deploy/cr.yaml && kubectl apply -f kit/deploy/cr.yaml
```

Проверяем

```bash
kubectl describe netperf.app.example.com/example
Name:         example
Namespace:    default
....
Status:
  Client Pod:          netperf-client-42010a9a00bf
  Server Pod:          netperf-server-42010a9a00bf
  Speed Bits Per Sec:  1917.98
  Status:              Done
Events:                <none>
```

Добавим ещё одну переменню среды в контейнер `iptables-tailer` в `daemonSet.yml`:

```bash
- name: "POD_IDENTIFIER"
  value: "name"
```

## PR checklist

- [x] Выставлен label с номером домашнего задания
- [x] Задание со *
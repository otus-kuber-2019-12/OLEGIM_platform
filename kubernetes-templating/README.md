# Выполнено ДЗ № 6

 - [x] Основное ДЗ
 - [x] Задание со *

## В процессе сделано:
 
# Проверяем установку helm

```bash
helm version
version.BuildInfo{Version:"v3.1.2", GitCommit:"d878d4d45863e42fd5cff6743294a11d28a9abce", GitTreeState:"clean", GoVersion:"go1.13.8"}

```

## Создание кластера

```bash
gcloud beta container --project "cloud-otus" clusters create "kuber" --zone "europe-west2-a"

```

## config local

```bash

gcloud container clusters get-credentials kuber --zone=europe-west2-a

```

Добавим репозиторий

```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add jetstack https://charts.jetstack.io
```

## повышаем права

```bash
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$(gcloud config get-value core/account)
```

## Создадим namespace и release nginx-ingress

```bash

kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress stable/nginx-ingress --wait \
--namespace=nginx-ingress \
--version=1.11.1

```

## Создадим namespace и release cert-manager

```bash
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
kubectl create namespace cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"
helm upgrade --install cert-manager jetstack/cert-manager --wait --namespace=cert-manager --version=0.9.0
kubectl apply -f kubernetes-templating/cert-manager/ -n cert-manager
helm repo update
```

## Узнаем IP nginx-ingress

```bash
kubectl get svc -n nginx-ingress
```

## Создадим наймспейс chartmuseum и установим chart

```bash

kubectl create ns chartmuseum
namespace/chartmuseum created

helm upgrade --install chartmuseum stable/chartmuseum --wait \
 --namespace=chartmuseum \
 --version=2.3.2 \
 -f kubernetes-templating/chartmuseum/values.yaml

```

helm ls -n chartmuseum

```bash

NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
chartmuseum     chartmuseum     1               2020-03-09 23:43:53.339270236 +0300 MSK deployed        chartmuseum-2.3.2       0.8.2  

```

kubectl get secrets -n chartmuseum

```bash
NAME                                TYPE                                  DATA   AGE
chartmuseum.35.189.112.153.nio.io      kubernetes.io/tls                     3      35m
```

## Проверка

``` bash

curl --insecure -v https://chartmuseum.35.189.112.153.nip.io  2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/ { if (cert) print }'

```

## Добавление репозитория harbor

``` bash
helm repo add harbor https://helm.goharbor.io
```

Создадим неимспейс harbor и применим chart (в этом чарте выключим сервис notary)

``` bash

kubectl create ns harbor
helm upgrade --install harbor harbor/harbor --wait \
--namespace=harbor \
--version=1.1.2 \
-f kubernetes-templating/harbor/values.yaml

```

## Проверка harbor

```bash

curl --insecure -v https://chartmuseum.35.189.112.153.xip.io  2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/ { if (cert) print }'

```

## Добавим репозитой в helm Задание со ⭐

```bash

helm repo add chartmuseum https://chartmuseum.35.189.112.153.nip.io/
"chartmuseum" has been added to your repositories

```

Скачаем репозиторий mysql, проверим его, упакуем его, получим версию с 1.0.3, загрузим его в chartmuseum

``` bash

git clone git@github.com:stakater/chart-mysql.git
cd chart-mysql/mysql

helm lint
==> Linting .
[INFO] Chart.yaml: icon is recommended
1 chart(s) linted, 0 chart(s) failed


helm package .

Successfully packaged chart and saved it to: chart-mysql/mysql/mysql-1.0.3.tgz
curl  --data-binary "@mysql-1.0.3.tgz" https://chartmuseum.35.189.112.153.nip.io/api/charts
{"saved":true}
```

## Используем helmfile | Задание со⭐

helmfile описан список файлов для выполнения.
все файлы хранятся в папке helmfile/template

## Создаем свой helmchart

Инициализируем структуру и установим hipster-shop, создадим правило для файрвола и узнаем по какому внешнему ip доступно

``` bash
helm create kubernetes-templating/hipster-shop
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
gcloud compute firewall-rules create frontend-svc-nodeport-rule --allow=tcp:$(kubectl -n hipster-shop get services frontend -o jsonpath="{.spec.ports[*].nodePort}")
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'
```

Создадим заготовку frontend hipster-shop

``` bash
helm create kubernetes-templating/frontend
```

Разносим по yaml файлам deployment, ingress и service которые будух хранится в папке templates

в файле values храним наши переменные

в папке hipster-shop добавляем зависимости (ссылку на frontend)

обновляем зависимости

```bash
helm dep update kubernetes-templating/hipster-shop
```

изменяет Nodeport в ручную командой:
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop --set frontend.service.NodePort=31234


## Работа с helm-secrets

```bash
/.gnupg/pubring.kbx
-----------------------------
pub   rsa3072 2020-03-15 [SC] [expires: 2020-03-16]
      21ED6B3FA42F2E1758F1D76D3253B9D37F862C7C
uid           [ultimate] olegim <olegim.89@gmail.com>
sub   rsa3072 2020-03-15 [E] [expires: 2020-03-16]
```

Зашифруем файл secrets.yaml и попробуем его расшифровать для просмотра

```bash
sops -e -i --pgp 21ED6B3FA42F2E1758F1D76D3253B9D37F862C7C secrets.yaml
sops -d secrets.yaml
```

Передадим файл секрета в hipster-shop

```bash
helm secrets upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop \
-f kubernetes-templating/frontend/values.yaml \
-f kubernetes-templating/frontend/secrets.yaml
```

## Kubecfg

```bash
kubecfg show kubernetes-templating/kubecfg/services.jsonnet
kubecfg update kubernetes-templating/kubecfg/services.jsonnet --namespace hipster-shop
```

## Kustomization

Для реализации возьмем emailservice, переместим блок из all-hipster-shop.yaml в kustomize/email

Проверим Yaml на работоспособность

```bash
kustomize build kubernetes-templating/kustomize/email/
```

Для применения манифестов используем

```bash
kubectl apply -k kubernetes-templating/kustomize/overrides/hispter-shop/
kubectl apply -k kubernetes-templating/kustomize/overrides/hispter-shop-prod/
```

## PR checklist:
 - [x] Выставлен label с номером домашнего задания
 - [x] Задание со * 
# Выполнено ДЗ № 11

## Подготовка GitLab репозитория

```bash

git clone https://github.com/GoogleCloudPlatform/microservices-demo
cd microservices-demo
git remote add gitlab git@gitlab.com:olegim/microservices-demo.git
git remote remove origin
git push gitlab master

```

## Подготовка чартов

Воспользуемся готовыми чартами из демонстрационного репозитория, и изменим их

```bash
sed -i 's/avtandilko/olegim/g' deploy/charts/*/values.yaml

tree -L 1 deploy/charts
deploy/charts
├── adservice
├── cartservice
├── checkoutservice
├── currencyservice
├── emailservice
├── frontend
├── grafana-load-dashboards
├── loadgenerator
├── paymentservice
├── productcatalogservice
├── recommendationservice
└── shippingservice
```

## Cоздадим кластер

```bash
gcloud beta container --project "otus-gitops" clusters create "cluster" --zone "europe-west2-b" --no-enable-basic-auth --cluster-version "1.14.10-gke.27" --machine-type "n1-standard-2" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "4" --enable-stackdriver-kubernetes --enable-ip-alias --network "projects/otus-gitops/global/networks/default" --subnetwork "projects/otus-gitops/regions/europe-west2/subnetworks/default" --default-max-pods-per-node "110" --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair

```

## Continuous Integration

Соберем образы и запушим в docker hub с тегом v0.0.1

```bash
export TAG=v0.0.1 && export REPO_PREFIX=olegim89$svcname
microservices-demo/hack/make-docker-images.sh
```

## Установим CRD, добавляющую в кластер новый ресурс - HelmRelease

```bash
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml
```

## Добавим официальный репозиторий Flux

```bash
helm repo add fluxcd https://charts.fluxcd.io
```

## Произведем установку Flux в кластер, в namespace flux

```bash
kubectl create namespace flux
helm upgrade --install flux fluxcd/flux -f flux.values.yaml --namespace flux
```

## Установка Helm operator и flux

```bash
helm upgrade --install helm-operator fluxcd/helm-operator -f helm-operator.values.yaml --namespace flux

sudo snap install fluxctl --classic

export FLUX_FORWARD_NAMESPACE=flux

kubectl create clusterrolebinding "cluster-admin-$(whoami)" \
--clusterrole=cluster-admin \
--user="$(gcloud config get-value core/account)"

```

Сгенерируем ключ

```bash
fluxctl identity --k8s-fwd-ns flux
```

Проверим корректность работы Flux. Flux должен автоматически синхронизировать состояние кластера и репозитория. Это касается не только сущностей HelmRelease, которыми мы будем оперировать для развертывания приложения, но и обыкновенных манифестов.

```bash

git remote remove origin
git push gitlab master
```

## PR checklist

- [x] Выставлен label с номером домашнего задания
- [x] Задание со *

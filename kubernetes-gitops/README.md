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

kubectl -n flux logs deployment/flux -f | grep "namespace/microservices-demo created"

ts=2020-04-18T16:44:11.602395883Z caller=sync.go:605 method=Sync cmd="kubectl apply -f -" took=470.115849ms err=null output="namespace/microservices-demo created\nhelmrelease.helm.fluxcd.io/frontend created"
```

```bash
kubectl get hr/frontend  -o wide
NAME       RELEASE    PHASE       STATUS     MESSAGE                                                                       AGE
frontend   frontend   Succeeded   deployed   Release was successful for Helm release 'frontend' in 'microservices-demo'.   87s

kubectl get helmrelease -n microservices-demo
NAME       RELEASE    PHASE       STATUS     MESSAGE                                                                       AGE
frontend   frontend   Succeeded   deployed   Release was successful for Helm release 'frontend' in 'microservices-demo'.   3m13s

helm list -n microservices-demo
NAME            NAMESPACE               REVISION        UPDATED                                 STATUS          CHART           APP VERSION
frontend        microservices-demo      1               2020-04-18 22:04:43.126212453 +0000 UTC deployed        frontend-0.21.0 1.16.0
```

Обновим образ до тега v0.0.2

```bash
docker build -t olegim89/frontend:v0.0.2 .

docker push olegim89/frontend:v0.0.2
```

## Автоматическое обновление

```bash
helm history frontend -n microservices-demo
REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
1               Sat Apr 18 22:04:43 2020        superseded      frontend-0.21.0 1.16.0          Install complete
2               Sat Apr 18 22:10:46 2020        deployed        frontend-0.21.0 1.16.0          Upgrade complete
```

## Попробуем внести изменения в Helm chart frontend и поменять имя deployment на frontend-hipster

```bash
sed -i 's/name: frontend/name: frontend-hipster/g' deploy/charts/frontend/Chart.yaml
```

## Найдите в логах helm-operator строки, указывающие на механизм проверки изменений в Helm chart и определения необходимости обновить релиз

```bash
kubectl logs helm-operator-7ddb568cfb-tqldq | grep 'hipster'
ts=2020-04-18T22:33:16.857473527Z caller=release.go:261 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="difference detected during release comparison" diff="  &helm.Chart{\n- \tName:       \"frontend\",\n+ \tName:       \"frontend-hipster-hipster\",\n  \tVersion:    \"0.21.0\",\n  \tAppVersion: \"1.16.0\",\n  \t... // 2 identical fields\n  }\n" phase=dry-run-compare
```

## Самостоятельное задание

* Добавьте манифесты HelmRelease для всех микросервисов входящих в состав HipsterShop
* Проверьте, что все микросервисы успешно развернулись в Kubernetes кластере

```bash

helm list -n microservices-demo | nl
     1  NAME                    NAMESPACE               REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
     2  adservice               microservices-demo      1               2020-04-18 23:16:57.375620166 +0000 UTC deployed        adservice-0.5.0                 1.16.0
     3  cartservice             microservices-demo      1               2020-04-18 23:17:12.767162944 +0000 UTC deployed        cartservice-0.4.1               1.16.0
     4  checkoutservice         microservices-demo      1               2020-04-18 23:16:57.927622572 +0000 UTC deployed        checkoutservice-0.4.0           1.16.0
     5  currencyservice         microservices-demo      1               2020-04-18 23:16:57.710162408 +0000 UTC deployed        currencyservice-0.4.0           1.16.0
     6  emailservice            microservices-demo      1               2020-04-18 23:17:00.048332656 +0000 UTC deployed        emailservice-0.4.0              1.16.0
     7  frontend                microservices-demo      3               2020-04-18 22:33:17.148608575 +0000 UTC deployed        frontend-hipster-hipster-0.21.0 1.16.0
     8  loadgenerator           microservices-demo      1               2020-04-18 23:17:01.308814661 +0000 UTC deployed        loadgenerator-0.4.0             1.16.0
     9  paymentservice          microservices-demo      1               2020-04-18 23:17:04.185375986 +0000 UTC deployed        paymentservice-0.3.0            1.16.0
    10  productcatalogservice   microservices-demo      1               2020-04-18 23:17:05.434050166 +0000 UTC deployed        productcatalogservice-0.3.0     1.16.0
    11  recommendationservice   microservices-demo      1               2020-04-18 23:17:08.628851209 +0000 UTC deployed        recommendationservice-0.3.0     1.16.0
    12  shippingservice         microservices-demo      1               2020-04-18 23:17:09.697221409 +0000 UTC deployed        shippingservice-0.3.0           1.16.0

```

## Установка Istio

```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.5.1/bin
cp istioctl /usr/local/bin/
istioctl manifest apply --set profile=demo
```

## Установка Flagger

```bash
helm repo add flagger https://flagger.app
kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml
helm upgrade --install flagger flagger/flagger \
--namespace=istio-system \
--set crd.create=false \
--set meshProvider=istio \
--set metricsServer=http://prometheus:9090

```

## Istio | Sidecar Injection

* добавим в каждый pod sidecar контейнер с envoy proxy

```bash
  labels:
    istio-injection: enabled
```

* удалим поды для появления sidecar`ов

```bash
kubectl delete pods --all -n microservices-demo
```

* Проверим istio-proxy

```bash
Init Containers:
  istio-init:
    Container ID:  docker://b64a8d7ddf96ef91a3888fc897c2f564aec08edb2a44ccb5c5e14fd0e74bb187
    Image:         docker.io/istio/proxyv2:1.5.1
    Image ID:      docker-pullable://istio/proxyv2@sha256:3ad9ee2b43b299e5e6d97aaea5ed47dbf3da9293733607d9b52f358313e852ae
    Port:          <none>
    Host Port:     <none>
```

## Доступ к frontend

* На текущий момент у нас отсутствует ingress и мы не можем получить доступ к frontend снаружи кластера. Чтобы настроить маршрутизацию трафика к приложению с использованием Istio, нам необходимо добавить ресурсы VirtualService и Gateway

* Создайте директорию следующие манифесты: deploy/istio и поместите в нее следующие манифесты: frontend-vs.yaml и frontend-gw.yaml

* Посмотрим Gateway и External_IP

```bash
kubectl get gateway -n microservices-demo
kubectl get svc istio-ingressgateway -n istio-system
```

* Интегрируем в окружиние frontend gateway и virtualservice

## Flagger | Canary

Добавим в template canary.yaml и запушим в репозиторий

```bash
kubectl get canary -n microservices-demo
NAME       STATUS        WEIGHT   LASTTRANSITIONTIME
frontend   Initialized   0        2020-04-19T01:07:51Z


kubectl get pods -n microservices-demo -l app=frontend-primary
NAME                               READY   STATUS    RESTARTS   AGE
frontend-primary-5d4dd5f68-946ct   2/2     Running   0          9m36s
```

## Сделаем релиз v0.0.3 и посмотрим изменения

* ошибочная установка

```bash
kubectl describe canary frontend -n microservices-demo
Type     Reason  Age   From     Message
  ----     ------  ----  ----     -------
  Warning  Synced  13m   flagger  frontend-primary.microservices-demo not ready: waiting for rollout to finish: observed deployment generation less then desired generation
  Normal   Synced  13m   flagger  Initialization done! frontend.microservices-demo
```

## PR checklist

- [x] Выставлен label с номером домашнего задания
- [] Задание со *

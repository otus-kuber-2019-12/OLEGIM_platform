# Выполнено ДЗ № 10

Создадим кластер при помощи cluster.yaml

Клонируем репозитории, устанавливаем компоненты

```bash
git clone https://github.com/hashicorp/consul-helm.git
git clone https://github.com/hashicorp/vault-helm.git
helm install consul ./consul-helm
helm install vault ./vault-helm
```

## helm status vault

```bash
NAME: vault
LAST DEPLOYED: Mon Apr 13 23:16:34 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get vault


kubectl logs vault-0

WARNING! Unable to read storage migration status.
2020-04-13T20:16:45.680Z [INFO]  proxy environment: http_proxy= https_proxy= no_proxy=
2020-04-13T20:16:45.680Z [WARN]  storage.consul: appending trailing forward slash to path
2020-04-13T20:16:45.685Z [WARN]  storage migration check error: error="Unexpected response code: 500"
==> Vault server configuration:

             Api Address: http://10.32.0.7:8200
                     Cgo: disabled
         Cluster Address: https://vault-0.vault-internal:8201
              Listener 1: tcp (addr: "[::]:8200", cluster address: "[::]:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
               Log Level: info
                   Mlock: supported: true, enabled: false
           Recovery Mode: false
                 Storage: consul (HA available)
                 Version: Vault v1.4.0

==> Vault server started! Log data will stream in below:

2020-04-13T20:16:51.351Z [INFO]  core: seal configuration missing, not initialized
2020-04-13T20:16:54.347Z [INFO]  core: seal configuration missing, not initialized
```

## Инициализация Vault

```bash
kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
Unseal Key 1: xQx/5ZfrRrtTQ87krDc1UGtgqda887UD/Yp+dm/ZNyA=

Initial Root Token: s.9iLWEQnLuBLs3lrdc019rSo4

Vault initialized with 1 key shares and a key threshold of 1. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 1 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 1 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

## vault status

```bash
kubectl exec -it vault-0 -- vault status
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       1
Threshold          1
Unseal Progress    0/1
Unseal Nonce       n/a
Version            1.4.0
HA Enabled         true
```

## Распечатаем vault

```bash

kubectl exec -it vault-0 -- vault operator unseal 'xQx/5ZfrRrtTQ87krDc1UGtgqda887UD/Yp+dm/ZNyA='
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.4.0
Cluster Name    vault-cluster-6f3c014f
Cluster ID      36f0e642-044c-02eb-39a7-9a4b6262399d
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active

kubectl exec -it vault-1 -- vault operator unseal 'xQx/5ZfrRrtTQ87krDc1UGtgqda887UD/Yp+dm/ZNyA='
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.4.0
Cluster Name           vault-cluster-6f3c014f
Cluster ID             36f0e642-044c-02eb-39a7-9a4b6262399d
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.32.0.7:8200

kubectl exec -it vault-2 -- vault operator unseal 'xQx/5ZfrRrtTQ87krDc1UGtgqda887UD/Yp+dm/ZNyA='
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.4.0
Cluster Name           vault-cluster-6f3c014f
Cluster ID             36f0e642-044c-02eb-39a7-9a4b6262399d
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.32.0.7:8200
```

## Вход в vault

```bash
kubectl exec -ti vault-0 vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.fk0QTB9v7qEldxewr3xALQBt
token_accessor       OIlj3cGO471EiuYFbd3kaaSv
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

## Посмотрим список доступных авторизаций

```bash
kubectl exec -it vault-0 -- vault auth list
Error listing enabled authentications: Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/auth
Code: 400. Errors:

* missing client token
```

## Залогинимся в vault

```bash
kubectl exec -it vault-0 -- vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.9iLWEQnLuBLs3lrdc019rSo4
token_accessor       ujooGyhofQPiMeXNDRHM5O2u
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

## Запросим список авторизаций повторно

```bash
kubectl exec -it vault-0 -- vault auth list
Path      Type     Accessor               Description
----      ----     --------               -----------
token/    token    auth_token_edd77563    token based credentials
```

## Добавим секреты

```bash

kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
Success! Enabled the kv secrets engine at: otus/

kubectl exec -it vault-0 -- vault secrets list --detailed
Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----
cubbyhole/    cubbyhole    cubbyhole_ac3e6184    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           a449ef55-281d-b507-a856-242287079a4e
identity/     identity     identity_bfc6948b     system         system     false             replicated     false        false                      map[]      identity store                                             ebebb9ac-d2bf-ce4b-de53-1a46375a6f1a
otus/         kv           kv_9865a4b6           system         system     false             replicated     false        false                      map[]      n/a                                                        d9cd9248-121d-b71e-25c6-adb4447730ff
sys/          system       system_13a85a46       n/a            n/a        false             replicated     false        false                      map[]      system endpoints used for control, policy and debugging    baea45b8-f977-bd22-e86f-b4873d2bdf60

kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-ro/config

kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-rw/config
```

## Прочитаем ключи

```bash
kubectl exec -it vault-0 -- vault read otus/otus-ro/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus

kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus
```

## Включение авторизации и проверим это

```bash

kubectl exec -it vault-0 -- vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/

kubectl exec -it vault-0 -- vault auth list
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_3114b06e    n/a
token/         token         auth_token_edd77563         token based credentials
```

## Создадим Service Account vault-auth и применим ClusterRoleBinding

```bash

kubectl create serviceaccount vault-auth
serviceaccount/vault-auth created

kubectl apply -f vault-auth-service-account.yaml
clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
```

## Подготовим переменные для записи в конфиг кубер авторизации

```bash
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')
```

### alternative way

```bash
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes master' | awk '/https/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g' )
```

* Обратите внимание на конструкцию sed ’s/\x1b\[[0-9;]*m//g, что по вашему она делает?
заменяет цвет адреса Kubernetes master

## Запишем конфиг в vault

```bash
kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
 token_reviewer_jwt="$SA_JWT_TOKEN" \
 kubernetes_host="$K8S_HOST" \
 kubernetes_ca_cert="$SA_CA_CRT"
Success! Data written to: auth/kubernetes/config
```

## Создадим файл политики

```bash
tee otus-policy.hcl <<EOF
path "otus/otus-ro/*" {
capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
capabilities = ["read", "create", "list"]
}
EOF
```

## создадим политку и роль в vault

```bash
kubectl cp otus-policy.hcl vault-0:./vault

kubectl exec -it vault-0 -- vault policy write otus-policy /vault/otus-policy.hcl
Success! Uploaded policy: otus-policy

kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy ttl=24h
Success! Data written to: auth/kubernetes/role/otus
```

## Проверим как работает авторизация

```bash

```

## PR checklist

-[x] Выставлен label с номером домашнего задания
-[x] Задание со *

VAULT_ADDR=http://vault:8200

KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq

curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq

TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "test"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')




export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export CLUSTER_NAME=$(kubectl config current-context)
export K8S_HOST=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")

# Удалить все escape codes, управляющие цветом вывода, например "\x1b[31m" - красный
sed 's/\x1b\[[0-9;]*m//g'

# Примечание: у меня эта команда работает некорректно, т.к. в config файле перечислено несколько контекстов
# и лучше не парсить структурированные файлы (json, xml, yaml и т. д.) с помощью sed/grep/awk
export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')

# Это более корректный способ определения адреса k8s
export CLUSTER_NAME=$(kubectl config current-context)
export K8S_HOST=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")

# но он тоже не будет работать, т.к. если используется minikube/kind, то адрес может быть localhost'ом и pod с vault не сможет подключиться к k8s (будет долбиться в свой localhost),
# поэтому правильно будет использовать внутренний адрес https://kubernetes.default.svc если vault находится в том же k8s кластере, что и SA

export K8S_HOST='https://kubernetes.default.svc'

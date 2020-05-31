# Выполнено ДЗ № 10

Создадим кластер при помощи cluster.yaml

```bash
kind create cluster --config cluster.yaml
```

Клонируем репозитории, устанавливаем компоненты

```bash
git clone https://github.com/hashicorp/consul-helm.git
git clone https://github.com/hashicorp/vault-helm.git
helm install consul ./consul-helm && helm install vault ./vault-helm
```

## helm status vault

```bash
NAME: vault
LAST DEPLOYED: Sun May 31 00:30:02 2020
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
```

## kubectl logs vault-0

```bash
==> Vault server configuration:

             Api Address: http://10.244.3.4:8200
                     Cgo: disabled
         Cluster Address: https://vault-0.vault-internal:8201
              Listener 1: tcp (addr: "[::]:8200", cluster address: "[::]:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
               Log Level: info
                   Mlock: supported: true, enabled: false
           Recovery Mode: false
                 Storage: consul (HA available)
                 Version: Vault v1.4.0

==> Vault server started! Log data will stream in below:

2020-05-30T21:31:22.569Z [INFO]  proxy environment: http_proxy= https_proxy= no_proxy=
2020-05-30T21:31:22.569Z [WARN]  storage.consul: appending trailing forward slash to path
```

## Инициализация Vault

```bash
kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
Unseal Key 1: Sk2vjbR/ly2IVp+1TvtOuXQv3PmxzHwOW2gDiYRSlu8=

Initial Root Token: s.mO7GJ07lsUIhDhLiOuLBTUJU

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
for POD in 0 1 2; do kubectl exec -it vault-"${POD}" -- vault operator unseal 'Sk2vjbR/ly2IVp+1TvtOuXQv3PmxzHwOW2gDiYRSlu8=' ;done

Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.4.0
Cluster Name    vault-cluster-fe9d277a
Cluster ID      4fff8755-cfae-499a-142e-37d585cfb6d4
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active

Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.4.0
Cluster Name           vault-cluster-fe9d277a
Cluster ID             4fff8755-cfae-499a-142e-37d585cfb6d4
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.244.3.4:8200

Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.4.0
Cluster Name           vault-cluster-fe9d277a
Cluster ID             4fff8755-cfae-499a-142e-37d585cfb6d4
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.244.3.4:8200
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
token                s.9cm14ju971q9lPj84UNyOVWs
token_accessor       FwPPWsOb39Rio5TaYaEaLgeG
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
token/    token    auth_token_6f17a78a    token based credentials
```

## Добавим секреты

```bash

kubectl exec -it vault-0 -- vault secrets enable --path=otus kv

Success! Enabled the kv secrets engine at: otus/

kubectl exec -it vault-0 -- vault secrets list --detailed

Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----
cubbyhole/    cubbyhole    cubbyhole_77bf1316    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           d01da536-7175-6b4f-09d1-93939d2d4c8c
identity/     identity     identity_9ae49b47     system         system     false             replicated     false        false                      map[]      identity store                                             6a54e1ab-f2b5-e3d9-64fb-1e3c6ee1acf5
otus/         kv           kv_26691b17           system         system     false             replicated     false        false                      map[]      n/a                                                        53c777fa-e7f1-451b-7578-0fc4d8301a78
sys/          system       system_c64923d5       n/a            n/a        false             replicated     false        false                      map[]      system endpoints used for control, policy and debugging    0e24a58d-654b-5dee-7ceb-98d1168c5c72

kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs' && kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'

Success! Data written to: otus/otus-ro/config
Success! Data written to: otus/otus-rw/config
```

## Прочитаем ключи

```bash
kubectl exec -it vault-0 -- vault read otus/otus-ro/config && kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config

Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus
```

## Включение авторизации и проверим это

```bash

kubectl exec -it vault-0 -- vault auth enable kubernetes && kubectl exec -it vault-0 -- vault auth list

Success! Enabled kubernetes auth method at: kubernetes/
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_b8c6bf79    n/a
token/         token         auth_token_6f17a78a         token based credentials
```

## Создадим Service Account vault-auth и применим ClusterRoleBinding

```bash

kubectl create serviceaccount vault-auth && kubectl apply --filename vault-auth-service-account.yaml

serviceaccount/vault-auth created
clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
```

## Подготовим переменные для записи в конфиг кубер авторизации

```bash
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}") &&
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo) &&
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo) &&
export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')
```

### alternative way

```bash
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes master' | awk '/https/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g' )
или
export K8S_HOST='https://kubernetes.default.svc'
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

## Создадим файл политики (Добавим в capabilities update)

```bash
tee otus-policy.hcl <<EOF
path "otus/otus-ro/*" {
      capabilities = ["read", "list"]
  }
path "otus/otus-rw/*" {
      capabilities = ["read", "create", "list", "update"]
  }
EOF
```

## создадим политку и роль в vault

```bash

kubectl cp otus-policy.hcl vault-0:/tmp && kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl
Success! Uploaded policy: otus-policy

kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
  bound_service_account_names=vault-auth \
  bound_service_account_namespaces=default policies=otus-policy  ttl=24h

Success! Data written to: auth/kubernetes/role/otus
```

## Проверим как работает авторизация

```bash
kubectl run --generator=run-pod/v1 tmp  -i  --tty --serviceaccount=vault-auth --image alpine:3.7
apk add curl jq
```

## Получение клиенского токена

```bash
VAULT_ADDR=http://vault:8200

KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
 % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
1{0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  "request_id": "055433ce-69eb-04d4-ca82-5d5e6d0af53e",
0  "lease_id": "",
0  "renewable": false,
   "lease_duration": 0,
   "data": null,
16  "wrap_info": null,
05  "warnings": null ,
  "auth": {
     "client_token": "s.2WGAVrGPz0NljnztPqiyHujl",
1    "accessor": "q9YTNasWwwbmuFjRlT41E5dw",
    "policies": [
0      "default",
      "otus-policy"
    ],
    "token_policies": [
      "default",
0   666  100   939  12807  18057 --:--:-- --:--:-- --:--:-- 30865
      "otus-policy"
    ],
    "metadata": {
      "role": "otus",
      "service_account_name": "vault-auth",
      "service_account_namespace": "default",
      "service_account_secret_name": "vault-auth-token-zkzzl",
      "service_account_uid": "46fd4557-f09c-4080-bd88-33e1f153c7a5"
    },
    "lease_duration": 86400,
    "renewable": true,
    "entity_id": "eacae8f3-9202-bfe0-6ba9-88c3b31c24e9",
    "token_type": "service",
    "orphan": true
  }
}

TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')

echo $TOKEN
s.uA7kFxvEL6P0fqzP3v8o3JrG
```

## Проверим чтение и запись

```bash
Добавили Update в capabilies для возможности записи  
curl --header "X-Vault-Token:s.uA7kFxvEL6P0fqzP3v8o3JrG" $VAULT_ADDR/v1/otus/otus-ro/config && \
curl --header "X-Vault-Token:s.uA7kFxvEL6P0fqzP3v8o3JrG" $VAULT_ADDR/v1/otus/otus-rw/config && \
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.uA7kFxvEL6P0fqzP3v8o3JrG" $VAULT_ADDR/v1/otus/otus-ro/config && \
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.uA7kFxvEL6P0fqzP3v8o3JrG" $VAULT_ADDR/v1/otus/otus-rw/config && \
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.uA7kFxvEL6P0fqzP3v8o3JrG" $VAULT_ADDR/v1/otus/otus-rw/config1

{"request_id":"1c88dee9-21eb-0ac1-7117-d063807a7a8f","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"password":"asajkjkahs","username":"otus"},"wrap_info":null,"warnings":null,"auth":null}
{"request_id":"e6b47474-62dc-656c-2785-dea6cdcb2110","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"password":"asajkjkahs","username":"otus"},"wrap_info":null,"warnings":null,"auth":null}
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}
```

## Use case использования авторизации через кубер

Клонируем репозиторий

```bash
git clone https://github.com/hashicorp/vault-guides.git
cd vault-guides/identity/vault-agent-k8s-demo
```

Редактируем файлы и запускаем

```bash

kubectl create configmap example-vault-agent-config --from-file=./configmap.yaml
configmap/example-vault-agent-config created

kubectl get configmap example-vault-agent-config -o yaml
apiVersion: v1
data:
  consul-template-config.hcl: |2-

    template {
      destination = "/etc/secrets/index.html"
      contents = <<EOF
      <html>
      <body>
      <p>Some secrets:</p>
      {{- with secret "otus/otus-rw/config" }}
      <ul>
      <li><pre>username: {{ .Data.username }}</pre></li>
      <li><pre>password: {{ .Data.password }}</pre></li>
      </ul>
      {{ end }}
      </body>
      </html>
      EOF
    }
  index.html: |-
    <html>
    <body>
    <p>Some secrets:</p>
    <ul>
    <li><pre>username: otus</pre></li>
    <li><pre>password: asajkjkahs</pre></li>
    </ul>
    </body>
    </html>
  vault-agent-config.hcl: |-
    # Uncomment this to have Agent run once (e.g. when running as an initContainer)
    exit_after_auth = true
    pid_file = "/home/vault/pidfile"

    auto_auth {
        method "kubernetes" {
            mount_path = "auth/kubernetes"
            config = {
                role = "otus"
            }
        }

        sink "file" {
            config = {
                path = "/home/vault/.vault-token"
            }
        }
    }
  vault-auth-service-account.yaml: |-
    ---
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRoleBinding
    metadata:
      name: role-tokenreview-binding
      namespace: default
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: system:auth-delegator
    subjects:
    - kind: ServiceAccount
      name: vault-auth
      namespace: default
kind: ConfigMap
metadata:
  creationTimestamp: "2020-05-31T02:59:59Z"
  name: example-vault-agent-config
  namespace: default
  resourceVersion: "26499"
  selfLink: /api/v1/namespaces/default/configmaps/example-vault-agent-config
  uid: c23566ce-5c49-46de-bbd6-ea84d24ef408

kubectl apply -f example-k8s-spec.yaml --record
pod/vault-agent-example created
```

## Создадим CA на базе vault

```bash
kubectl exec -it vault-0 -- vault secrets enable pki
Success! Enabled the pki secrets engine at: pki/

kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
Success! Tuned the secrets engine at: pki/

kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="exmaple.ru" ttl=87600h > CA_cert.crt
```

## Пропишем урлы для ca и отозванных сертификатов

```bash
kubectl exec -it vault-0 -- vault write pki/config/urls issuing_certificates="http://vault:8200/v1/pki/ca" crl_distribution_points="http://vault:8200/v1/pki/crl"
Success! Data written to: pki/config/urls
```

## Создадим промежуточный сертификат

```bash
kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
Success! Enabled the pki secrets engine at: pki_int/

kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
Success! Tuned the secrets engine at: pki_int/

kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
```

## Пропишем промежуточный сертификат в Vault

```bash
kubectl cp pki_intermediate.csr vault-0:./tmp

kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem

kubectl cp intermediate.cert.pem vault-0:./tmp

kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem
Success! Data written to: pki_int/intermediate/set-signed
```

## Создадим и отзовем новые сертификаты

### Создадим роль для выдачи сертификатов

```bash
kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru allowed_domains=example.ru allow_subdomains=true max_ttl=720h

Success! Data written to: pki_int/roles/example-dot-ru
```

### Создадим сертификат

```bash
kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name=gitlab.example.ru ttl=24h
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUc2ybCk4hoVxZGR9jNwGx61ZAdTgwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDA1MzAyMzQyNDhaFw0yMTA1
MzAyMzQzMThaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALQ3a1Y28duk
5wRDEAycyczth3e8OkfeyAijGrS6TtL+RFl95ISwNICPE6ka4UwJfQ6v4Pkx615C
6sI235N/qxwTSJ+I6kBgjMP/LeuPk4BNtvwTEFEh+/HuPOIzyQzHQyhBG/pYLt/n
4fwwpxV29OuGNsAnChGT/HfM66c4U7MFBJRcroRsYovo+n65dVp6OQHvSbdSN5sH
3lX9clHqY+WsoHtmSGDagg+mt8EhzJajnzKVeeQiZWkCZxSU5wfhLIEae10Fe9IB
X2elC6RbAl1vtwZkj5GdBLydF/fBuhA2RepSIf9FZmK8CboPLpHDyojd5EMJx9ip
3JRDPRt8HmMCAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQU/VGVX4qYzyMbqHrXRYPFQ2zT28gwHwYDVR0jBBgwFoAU
LPNMXbSlqStMzpSPN1gA/n7bB2kwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
KgZYKrXsPJxbfV/5LWeOHeba22lLRcMKYZ6IAU2O3fHqUhR2v4+FTIGHIjpIccPv
hOnDuSRkBK+b/GvFe3kHfe9BaGRhz5e6Wg86V5W8HENEvw0P6jfZkrWvMbawLCgt
maA5cd6Kn3nKot+yyn53qE9OkD27U5XtRV3jWUbTyqccgJfI3a2+LThrcCQ9mEk5
YUkphYJ8p8IPNmAZ4vjVfwoVWzHs3KvXMIrvvg9smOsd1cBWLWKrke3Cy+ehdTC7
O4wI3x/99bxzkD7JfZ03Y1fokgmKbBsT9jR6xgut7AKgTIPxaSUC6lFuPqpk3pc+
SPSpFjpxFP9mYsopMDndYw==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDZzCCAk+gAwIBAgIUbKhvKEYJ8lguGtXnVVooEp877oMwDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTIwMDUzMDIzNTMzOVoXDTIwMDUzMTIzNTQwOVowHDEaMBgGA1UEAxMRZ2l0
bGFiLmV4YW1wbGUucnUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx
hzJyh5rjq3E9G9KK6ZRxxURb6mv3Zdx6H0fxL9ADbHKgO8MFC2Nbd4q+u/BYPiiU
WEBCGkDZpRdLF7dv89HBm7aRmR93vADfGdDMj34UTemaagR9HXcA25BsjgndnUOs
gys+KYiysJyPqeJ4YGt+bJ540FFpmG3H86b8YMIVaqEXSkmd0Pt5dSJYbxgc2saK
oGT1yUjy6oOZhIFGb0vnlU9JREgS+FsVnJ5ky2Ygk7wW7jTix13hKwZ72r/sX5WD
w506oi/J3AdnkGhjpoiS5w/re7FcRbfwlViXjQoGdHQexzD27oe5IjcnSOqUAHFE
VSz8db7wSQ39fOGkSKC9AgMBAAGjgZAwgY0wDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQUN9DybJBCswQ1fmLR
UvNr1hmE1J4wHwYDVR0jBBgwFoAU/VGVX4qYzyMbqHrXRYPFQ2zT28gwHAYDVR0R
BBUwE4IRZ2l0bGFiLmV4YW1wbGUucnUwDQYJKoZIhvcNAQELBQADggEBAFn4astC
mVs3PGw34jhhcFeNBI9Pvrd2F8tqFKC7vxBn8lP81F4D0DpcXnSIa/9NNTznGUi1
xUaERjW4db2v21RHtwu0pEN+BYuIwLpbA2pFhsQs1iu5cHCyFcgJzdbLOpwFktgr
e0sk/gj3jzSun1q1Eq4tJt4eC9bYaWFq4H4I5yP8AxHM8dx+OgN3OxpnDKvN2kcq
TbvwdyNfRUD7N5I0SO+5B/kM2ezIDMOfilYW1BTXk+2P5D4r1FLF6ZAQTI1ZB6SD
HZipSVK2rAzZu1t7R3Znyr0ATjkcSks8lyMoQGC1oVI7NPfSpW2ssRVJr+lVdruo
yt2B79px4tBv/Qo=
-----END CERTIFICATE-----
expiration          1590969249
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUc2ybCk4hoVxZGR9jNwGx61ZAdTgwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDA1MzAyMzQyNDhaFw0yMTA1
MzAyMzQzMThaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALQ3a1Y28duk
5wRDEAycyczth3e8OkfeyAijGrS6TtL+RFl95ISwNICPE6ka4UwJfQ6v4Pkx615C
6sI235N/qxwTSJ+I6kBgjMP/LeuPk4BNtvwTEFEh+/HuPOIzyQzHQyhBG/pYLt/n
4fwwpxV29OuGNsAnChGT/HfM66c4U7MFBJRcroRsYovo+n65dVp6OQHvSbdSN5sH
3lX9clHqY+WsoHtmSGDagg+mt8EhzJajnzKVeeQiZWkCZxSU5wfhLIEae10Fe9IB
X2elC6RbAl1vtwZkj5GdBLydF/fBuhA2RepSIf9FZmK8CboPLpHDyojd5EMJx9ip
3JRDPRt8HmMCAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQU/VGVX4qYzyMbqHrXRYPFQ2zT28gwHwYDVR0jBBgwFoAU
LPNMXbSlqStMzpSPN1gA/n7bB2kwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
KgZYKrXsPJxbfV/5LWeOHeba22lLRcMKYZ6IAU2O3fHqUhR2v4+FTIGHIjpIccPv
hOnDuSRkBK+b/GvFe3kHfe9BaGRhz5e6Wg86V5W8HENEvw0P6jfZkrWvMbawLCgt
maA5cd6Kn3nKot+yyn53qE9OkD27U5XtRV3jWUbTyqccgJfI3a2+LThrcCQ9mEk5
YUkphYJ8p8IPNmAZ4vjVfwoVWzHs3KvXMIrvvg9smOsd1cBWLWKrke3Cy+ehdTC7
O4wI3x/99bxzkD7JfZ03Y1fokgmKbBsT9jR6xgut7AKgTIPxaSUC6lFuPqpk3pc+
SPSpFjpxFP9mYsopMDndYw==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAsYcycoea46txPRvSiumUccVEW+pr92Xceh9H8S/QA2xyoDvD
BQtjW3eKvrvwWD4olFhAQhpA2aUXSxe3b/PRwZu2kZkfd7wA3xnQzI9+FE3pmmoE
fR13ANuQbI4J3Z1DrIMrPimIsrCcj6nieGBrfmyeeNBRaZhtx/Om/GDCFWqhF0pJ
ndD7eXUiWG8YHNrGiqBk9clI8uqDmYSBRm9L55VPSURIEvhbFZyeZMtmIJO8Fu40
4sdd4SsGe9q/7F+Vg8OdOqIvydwHZ5BoY6aIkucP63uxXEW38JVYl40KBnR0Hscw
9u6HuSI3J0jqlABxRFUs/HW+8EkN/XzhpEigvQIDAQABAoIBADMaGMJxGHvq0Ojn
Rl7oR+vL/hZ7T2LitmmM8ZeSzMz/fat0KHoeQhaFPbITxWaRVfsFwFGG3x4HcMIT
7KDUTY/us8oLisxbmOCfvMP1ljRgDRt+4xXk0mmzykoFRP+/EkjpZRw6tnfBcP/F
xkQidS7qM1/Rj23XC9rf3zSM4bFqCnMbKXxCoDL5T1fxy1NcQ/DaTCQ4xq/j8PK7
ZBoNPzZQXPNmRXWxiPL7O9tXRqtfqZWO0Cp8RKZ43iZBz871L9KfNl8xrNjmN6Zl
lApORE+i/3RUVniXceCNsEZPGqGnfZsGNIIDRpoVkQsirhj9BIwKoy/FLKXzuew/
xuFtPCECgYEA3CkHkCgURG0W2GORG2i5yhZszZkWtnH+JhpIvk8IBS9HYfUU4yOj
xh99Wc3ximf7s6fF40MRvRZAuCuwJmb4vOFulxJvE/TMTMMKlmu20B7NZBXqkIKt
7OeyqnuBkhox/U0sO09xaD/Rq+NbOo/CLZ/1RwwOp6iYz0018p3UD3UCgYEAzm2D
RPfp5bG2juAoRCXrcrBJZgOf37jWUOUSjSskOQieN8Ah3eY2G7gXORnlTDjTrJM/
otLElJw2qAzwzcFsIMMFo5eDumeapv+WrpDQIm/1C1YQpjfIv2e4IGkaseXMcQD3
sMGBbg2wFuDsvAfWdZDRTOrEJiaxx63aI/IjqykCgYBG5guid9W3B25w9vd23S3f
j4MwXpl63ZDb0mEUsDzD9qrFN/inAQYvulpSvkiHqt7axy+p9SJUQ0NKS/9pDoYR
xYMosW4F/jKAkdrp//waX6EDFy+3o+3AugjGcAmU9Eye5uhUnUvHJ64s7YWmgT8m
FDoXzCE4CspTD+lMnVj6NQKBgQCaY93iH2mYmanogk6baaEHTkIXQm64bQ4dwrZ1
TubwoTl0iQbLZ/rgEHeOBYgx0e6/DAJ0TR8p5wwZ9FPGD/xHJJV7HT8wk3xfmpmg
Rj7lAsdLizs4llBWl8RmuTV2CGE3w3l9gbzECwjAk8l7eIE1vPJNjOjXf+lHZwfY
CqoSwQKBgHzZk/DpGM/9z8FVHA+bft03agvv/Vz4EttKxT4gqCglUolJLwVeSVHL
sv/4m9ZKpdZoy2JnkF5nUbib97vNs0HTglUsY8j4tkvBn/YPqd3BhYGgNlk8+C/K
rrieRj4wiRi26VPzTRe2ByoCLNWsDOGwJ/3kPyaxn07DXvmmIioU
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       6c:a8:6f:28:46:09:f2:58:2e:1a:d5:e7:55:5a:28:12:9f:3b:ee:83

```

### Отзовем сертификат

```bash
kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="6c:a8:6f:28:46:09:f2:58:2e:1a:d5:e7:55:5a:28:12:9f:3b:ee:83"

Key                        Value
---                        -----
revocation_time            1590882952
revocation_time_rfc3339    2020-05-30T23:55:52.876749986Z
```

## Включить TLS

```bash
cd tls
openssl req -new -config tls.cnf -keyout tls.key -out tls.csr

kubectl apply -f csr.yaml
certificatesigningrequest.certificates.k8s.io/vault-req created

kubectl certificate approve vault-req
certificatesigningrequest.certificates.k8s.io/vault-req approved

kubectl get csr vault-req -o jsonpath='{.status.certificate}' | base64 --decode > tls.crt

kubectl create secret generic vault-certs --from-file=.
secret/vault-certs created

```

## Обновим vault

```bash
helm upgrade --install vault ./vault-helm -f vault/vault-tls.yaml
```

## Создадим политику для чтения pki_int и применим к уже существующему сервис-аккаунту:

```bash
kubectl cp nginx/cert-issuer.hcl vault-0:./tmp

kubectl exec -it vault-0 -- vault policy write cert-issuer /tmp/cert-issuer.hcl
Success! Uploaded policy: cert-issuer

kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy,cert-issuer default_ttl=1m
Success! Data written to: auth/kubernetes/role/otus

kubectl apply -f nginx/nginx-deployment.yml
deployment.apps/nginx-tls created
```

## Пробросим порты

```bash
kubectl port-forward nginx-tls-66d8fff855-krgml 8443:8443

localhost:8443 или test.example.com указав в /etc/hosts
```

## PR checklist

-[x] Выставлен label с номером домашнего задания
-[] Задание со *

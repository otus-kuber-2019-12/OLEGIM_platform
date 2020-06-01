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
LAST DEPLOYED: Sun May 31 16:59:26 2020
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

             Api Address: http://10.244.4.4:8200
                     Cgo: disabled
         Cluster Address: https://vault-0.vault-internal:8201
              Listener 1: tcp (addr: "[::]:8200", cluster address: "[::]:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
               Log Level: info
                   Mlock: supported: true, enabled: false
           Recovery Mode: false
                 Storage: consul (HA available)
                 Version: Vault v1.4.2

==> Vault server started! Log data will stream in below:

2020-05-31T14:00:57.107Z [INFO]  core: seal configuration missing, not initialized
```

## Инициализация Vault

```bash
kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
Unseal Key 1: lynKqpw4yQS85Jx9pa2S/stdm3GkhxEeldJq4v6z37A=

Initial Root Token: s.g0j3D3W8zAWTCBrsZMdO0eQR

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
Version            1.4.2
HA Enabled         true
```

## Распечатаем vault

```bash
for POD in 0 1 2; do kubectl exec -it vault-"${POD}" -- vault operator unseal 'lynKqpw4yQS85Jx9pa2S/stdm3GkhxEeldJq4v6z37A=' ;done

Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.4.2
Cluster Name    vault-cluster-e2c410ec
Cluster ID      0301c02f-11f1-5d5b-27da-07f93a0c76cd
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
Version                1.4.2
Cluster Name           vault-cluster-e2c410ec
Cluster ID             0301c02f-11f1-5d5b-27da-07f93a0c76cd
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.244.4.4:8200

Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.4.2
Cluster Name           vault-cluster-e2c410ec
Cluster ID             0301c02f-11f1-5d5b-27da-07f93a0c76cd
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.244.4.4:8200
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
token                s.g0j3D3W8zAWTCBrsZMdO0eQR
token_accessor       W2XKNvclhs3Gjv3uX8esBr1C
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
token/    token    auth_token_4edbfa72    token based credentials
```

## Добавим секреты

```bash

kubectl exec -it vault-0 -- vault secrets enable --path=otus kv

Success! Enabled the kv secrets engine at: otus/

kubectl exec -it vault-0 -- vault secrets list --detailed

Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----
cubbyhole/    cubbyhole    cubbyhole_d8e27783    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           e0db9f8e-856a-a5bc-277f-3954b5ef0ae7
identity/     identity     identity_7bbd08b7     system         system     false             replicated     false        false                      map[]      identity store                                             c51a1cf5-a019-5f60-3f9a-3fbe9f5c3c09
otus/         kv           kv_4565240c           system         system     false             replicated     false        false                      map[]      n/a                                                        98881664-d3f2-00e1-9943-3a4b58dc3912
sys/          system       system_bbc4781e       n/a            n/a        false             replicated     false        false                      map[]      system endpoints used for control, policy and debugging    9eab472e-2235-457f-15c0-86ccbf39cc04

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
kubernetes/    kubernetes    auth_kubernetes_84958cb9    n/a
token/         token         auth_token_4edbfa72         token based credentials
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
apk add curl jq && VAULT_ADDR=http://vault:8200 && KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1605  100{    0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
    "request_id": "a8abac0d-65b9-c430-e567-818a5c9b8821"6,
66  "lease_id": "",
    "renewable": false1,
00  "lease_duration": 0 ,
   "data": null,
   "wrap_info": null,
93  "warnings": null9,
    "auth": {
12    "client_token": "s.9CaML106weg5D96uJSfnsLrK"8,
07    "accessor": "DlhFytewDpShTd7awwQH3W9V",
      "policies": [1
8      "default",
05      "otus-policy"
7    ] ,
-    "token_policies": [-
:      "default"-,
-      "otus-policy"
:    ]-,
-     "metadata": {
-      "role": "otus"-,
:-      "service_account_name": "vault-auth",
-      "service_account_namespace": "default":,
--      "service_account_secret_name": "vault-auth-token-qjw9b",
 -      "service_account_uid": "fc2123ad-793c-48c3-b76b-1826bfadb3ce"-
:    }-,
-:-    "lease_duration": 86400,
-     "renewable": true,
30    "entity_id": "e96a0442-f516-954e-befa-5fb1615e97f9",
8    "token_type": "service"6,
5    "orphan": true

  }
}

TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')

echo $TOKEN
s.JGXR9kng4DdRVN18QBaxHmZY

s.o6OitumfL6AR3L0gyXHbxHo7
```

## Проверим чтение и запись

```bash
Добавили Update в capabilies для возможности записи  
curl --header "X-Vault-Token:s.JGXR9kng4DdRVN18QBaxHmZY" $VAULT_ADDR/v1/otus/otus-ro/config && \
curl --header "X-Vault-Token:s.JGXR9kng4DdRVN18QBaxHmZY" $VAULT_ADDR/v1/otus/otus-rw/config && \
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.JGXR9kng4DdRVN18QBaxHmZY" $VAULT_ADDR/v1/otus/otus-ro/config && \
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.JGXR9kng4DdRVN18QBaxHmZY" $VAULT_ADDR/v1/otus/otus-rw/config && \
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.JGXR9kng4DdRVN18QBaxHmZY" $VAULT_ADDR/v1/otus/otus-rw/config1

{"request_id":"a12478aa-3b3c-dcf1-c5a9-3bed0bf57f7b","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"password":"asajkjkahs","username":"otus"},"wrap_info":null,"warnings":null,"auth":null}
{"request_id":"ff149d1c-cd9a-deb5-71d2-dfd9ef4878ac","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"password":"asajkjkahs","username":"otus"},"wrap_info":null,"warnings":null,"auth":null}
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

kubectl create configmap example-vault-agent-config --from-file=./configs-k8s/
configmap/example-vault-agent-config created

kubectl get configmap example-vault-agent-config -o yaml

apiVersion: v1
data:
  consul-template-config.hcl: |
    vault {
      renew_token = false
      vault_agent_token_file = "/home/vault/.vault-token"
      retry {
        backoff = "1s"
      }
    }

    template {
      destination = "/etc/secrets/index.html"
      contents = <<EOH
      <html>
      <body>
      <p>Some secrets:</p>
      {{- with secret "otus/otus-rw/config" }}
      <ul>
      <li><pre>username: otus</pre></li>
      <li><pre>password: asajkjkahs</pre></li>
      </ul>
      {{ end }}
      </body>
      </html>
      EOH
    }
  vault-agent-config.hcl: |
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
kind: ConfigMap
metadata:
  creationTimestamp: "2020-05-31T17:43:21Z"
  name: example-vault-agent-config
  namespace: default
  resourceVersion: "28065"
  selfLink: /api/v1/namespaces/default/configmaps/example-vault-agent-config
  uid: 92960439-a867-4186-9d49-000a10f3f894
```

```bash
kubectl apply -f example-k8s-spec.yaml --record
pod/vault-agent-example created
```

Создадим папку для сертификатов и перейдем в неё

```bash
mkdir ../../../crt/
cd ../../../crt/
```

## Создадим CA на базе vault

```bash
kubectl exec -it vault-0 -- vault secrets enable pki
Success! Enabled the pki secrets engine at: pki/

kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
Success! Tuned the secrets engine at: pki/

kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="example.ru" ttl=87600h > CA_cert.crt
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
MIIDnTCCAoWgAwIBAgIUalZNNQYmBR6Qw58CiWm9Vw4TwxswDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhhbXBsZS5ydTAeFw0yMDA1MzExNzQ1MjdaFw0yNTA1
MzAxNzQ1NTdaMC0xKzApBgNVBAMMImV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIApB
dXRob3JpdHkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDPFeoSp81t
qQWudpLxZOp8Kf81GZObQ8YHd15m1J0JZrExvJNgPhXVbP8pbBZGDnE6oU8NqlpG
aOdn1fHG3A6RLeFzcKmKPpw2G5BVVcVCuPIcmx4kg2T1pliY7HYUUyhtFXWplut6
T9/VMjNArffEfVNQSmmqshT0LxN/XHTLqycOY5HpYtYb3DFVv4QnKyoz3l+eU8rz
wMSSgLsXCBXEFQ2SiOa+pe71cITfAWMvuZlM6bcZHtIi+w26W4zZyGttlkQY9HpV
L6QithpRTsNBxJH9vjrQ3qRBWnRJRcFCJyl9Fx8s/r/R68oE+lMh1Uc+KMgszCZi
Lvf6V9NG4IMRAgMBAAGjgcwwgckwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF
MAMBAf8wHQYDVR0OBBYEFI9z6XC28NXg+yUxPeH1DQNbKp7nMB8GA1UdIwQYMBaA
FGxMBF5feqni/hr8fnlFsziEAdoFMDcGCCsGAQUFBwEBBCswKTAnBggrBgEFBQcw
AoYbaHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NhMC0GA1UdHwQmMCQwIqAgoB6G
HGh0dHA6Ly92YXVsdDo4MjAwL3YxL3BraS9jcmwwDQYJKoZIhvcNAQELBQADggEB
AEZvkLPwaqEfRs3HPTbsSIIPc9IbKVC13o5pp+e6jnuz73mbgEoNeHu/n5DSW/xc
ezTBTe3sABhjJP+lM9hRKlz73uE+1KZlgpI5r6XgQhdxG/bmg3AKg4M7KJkJjHOG
a/SvHMrmGiuHxBaIMzSl2eKbX9c5dzyVrJtHW8aAR9zDOjuMgm+UU40f1nN6aN2k
Df99B5g/zpq5O1xJk9Tl5O042DbwVOtAuR3IxWytltP21ouyMq0Oxmg+VEo8ijwW
oAc5hwKRo3ed+rIn02Pv4lPexig5ckxgmfQWWlB2xwPlIXQbTqKODDWdeQiUxm7L
I9Us60U7WICgP3zB+TKfLnM=
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDaDCCAlCgAwIBAgIUMYtxZjYPaZIojBbtAbhutTdiD98wDQYJKoZIhvcNAQEL
BQAwLTErMCkGA1UEAwwiZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgCkF1dGhvcml0
eTAeFw0yMDA1MzExNzQ1NTFaFw0yMDA2MDExNzQ2MjFaMBwxGjAYBgNVBAMTEWdp
dGxhYi5leGFtcGxlLnJ1MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
tPoe9p8YBVHJz1X+Ktf2eTNzlW3bfOZJM3UBT5XaSnPOcbgslwC/Aqad6fca/EQe
soS0/D2MB7J7uqIvzzwiB8dZP3kBnhwFEtfwvvELfwFAxAP2ZvEFcRKyYQF+2NyV
jEQ0MJJ1rLB9LHGHG4VOUl6g/h5+wF4VEn6ytBmANRXFs3yIKK2g9Iv9TcUmjTRc
/Uo38U3zXZ8jQdbK3qYUMV+S70QYor059Yqsx3ffyjh89R+9cOKJDXzcX/5u0k01
I1Nip8vyDzBzAW/BPoPP5wAV0FFgSSWN9lmPybxf06n7D+WOwKA6sKx79un+M7xw
ZiKeMeRUr13KSl7vny8kMwIDAQABo4GQMIGNMA4GA1UdDwEB/wQEAwIDqDAdBgNV
HSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwHQYDVR0OBBYEFAmXRLHtunk9Z/ef
1MsnKRjaH210MB8GA1UdIwQYMBaAFI9z6XC28NXg+yUxPeH1DQNbKp7nMBwGA1Ud
EQQVMBOCEWdpdGxhYi5leGFtcGxlLnJ1MA0GCSqGSIb3DQEBCwUAA4IBAQABTW9g
QSK4IomdMdXASnrR05zhxXdjUQjR9XiVPZAW/hn8gPc8mpZiy4UYY/AOQemZWcRb
d7wnfM/m6OGk/jaHLyjihXwd7dwJH0EM6rkHqBw8Vtuf5RpephkNATTJG8YyHKEB
E+ixX+eGMgMpQi7o5hurEB4im+FNgBg4vVcw714qavuspWsKvkfFIXlj2ZcCWW7T
5PLyz4N/P2P/59Cofr1XLqivCvAvSaXDnXBOVNmsxycZYg8pfVPrEv7UtQj8ZNME
Ju6BW9ZBcEkAavtWhGUMXLp5b1lXq9kxIQ2Ccn2bnCs3Q6DHGj/5lE6ECpWH7J5s
qkQ448CvDGwwAPJo
-----END CERTIFICATE-----
expiration          1591033581
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDnTCCAoWgAwIBAgIUalZNNQYmBR6Qw58CiWm9Vw4TwxswDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhhbXBsZS5ydTAeFw0yMDA1MzExNzQ1MjdaFw0yNTA1
MzAxNzQ1NTdaMC0xKzApBgNVBAMMImV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIApB
dXRob3JpdHkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDPFeoSp81t
qQWudpLxZOp8Kf81GZObQ8YHd15m1J0JZrExvJNgPhXVbP8pbBZGDnE6oU8NqlpG
aOdn1fHG3A6RLeFzcKmKPpw2G5BVVcVCuPIcmx4kg2T1pliY7HYUUyhtFXWplut6
T9/VMjNArffEfVNQSmmqshT0LxN/XHTLqycOY5HpYtYb3DFVv4QnKyoz3l+eU8rz
wMSSgLsXCBXEFQ2SiOa+pe71cITfAWMvuZlM6bcZHtIi+w26W4zZyGttlkQY9HpV
L6QithpRTsNBxJH9vjrQ3qRBWnRJRcFCJyl9Fx8s/r/R68oE+lMh1Uc+KMgszCZi
Lvf6V9NG4IMRAgMBAAGjgcwwgckwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF
MAMBAf8wHQYDVR0OBBYEFI9z6XC28NXg+yUxPeH1DQNbKp7nMB8GA1UdIwQYMBaA
FGxMBF5feqni/hr8fnlFsziEAdoFMDcGCCsGAQUFBwEBBCswKTAnBggrBgEFBQcw
AoYbaHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NhMC0GA1UdHwQmMCQwIqAgoB6G
HGh0dHA6Ly92YXVsdDo4MjAwL3YxL3BraS9jcmwwDQYJKoZIhvcNAQELBQADggEB
AEZvkLPwaqEfRs3HPTbsSIIPc9IbKVC13o5pp+e6jnuz73mbgEoNeHu/n5DSW/xc
ezTBTe3sABhjJP+lM9hRKlz73uE+1KZlgpI5r6XgQhdxG/bmg3AKg4M7KJkJjHOG
a/SvHMrmGiuHxBaIMzSl2eKbX9c5dzyVrJtHW8aAR9zDOjuMgm+UU40f1nN6aN2k
Df99B5g/zpq5O1xJk9Tl5O042DbwVOtAuR3IxWytltP21ouyMq0Oxmg+VEo8ijwW
oAc5hwKRo3ed+rIn02Pv4lPexig5ckxgmfQWWlB2xwPlIXQbTqKODDWdeQiUxm7L
I9Us60U7WICgP3zB+TKfLnM=
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAtPoe9p8YBVHJz1X+Ktf2eTNzlW3bfOZJM3UBT5XaSnPOcbgs
lwC/Aqad6fca/EQesoS0/D2MB7J7uqIvzzwiB8dZP3kBnhwFEtfwvvELfwFAxAP2
ZvEFcRKyYQF+2NyVjEQ0MJJ1rLB9LHGHG4VOUl6g/h5+wF4VEn6ytBmANRXFs3yI
KK2g9Iv9TcUmjTRc/Uo38U3zXZ8jQdbK3qYUMV+S70QYor059Yqsx3ffyjh89R+9
cOKJDXzcX/5u0k01I1Nip8vyDzBzAW/BPoPP5wAV0FFgSSWN9lmPybxf06n7D+WO
wKA6sKx79un+M7xwZiKeMeRUr13KSl7vny8kMwIDAQABAoIBACjviqFuSxio72Ue
pmc6gl3X7YUXXFZcIKKrDKjb1IyStVezuSJO4OXQmleZtVjqb6chrW6A3XPAQ4xr
szTE/U2VIfLhhCQnYl5oyePm0hrgRa4Q12NhkUGKYR7gH7kd7BXWN5flCQkOwsGS
zGTFOnoXPYM9kp4gqdONJQ7n1cAr0tKct00VRK3f5Lqyqyt40rgjqChYznXPl5fh
nnsQDfQW1/SraypQKfhS3rrtYrMbSwd5nA/Fw3m2f8vH0wzBBBi0NOs5jU3IPTCy
iJx3Y8oBD/REg5ScoD8yuGFUOpcch1cJ7vuuzSuUETDhkKebVOx57U9HdvWQaDo1
1J/GkIECgYEA6yoh3ZWGC1D7wNRz/u+SQyTcTj5ltT6VF1eq+JsC75HH3/qknM6R
6Z+yRLO6GDVN/ydYQQvRkMsNwCJ0rzmpfUCB8YGGw9inEMMrU1UMZcbQqPlRWJI3
89GZygJR2/0+Z6TxefcZ0PCUCRcFp3pR1majvHsIK29fFxMzCidtOEkCgYEAxQLw
HcO0v3IGc41/eSiviH2NRM/Dyl8tLr0cpxRGj+XUjiVVTDRnwF695bKMOSLVzOsg
QhHdqI2xrLXgh5CObYd+LQyZlW0DC+FurpXiELc+CSN14N+uGvm7W+IAEYa4apnE
CaNLaA0qDNTKwPHaSklKNsvqSIYwMoxyPK89kJsCgYBswrGi75JtDWlBx4BWOaql
jxisv0L+zhDaGNuj2t1Cu2N7fUpAk3D8YbVq/MxmgdCu3x18B+FGXALiB417tOlk
Wj8+2K7hSQQLRph1E/KF56t9WsF6ezWReDDuMqB1Y+xGtwxPYi74aSuuAI3G5VWQ
GSxE8YnXvMx3uZNzcMScsQKBgCg+7WZnMGlblc3NPhk2IoWzgERqXQjeYJCHuW64
SaHjxYQ0RDSJEBjQQeLGkrapUxvFfJWCqNFiAMXTcca/1Riy8Seqx0UrO9AVgVLQ
85mOlXGweMgzaZHBKnEevfzWlJ3SQ6XkYecjqU9tuO2penpqdmqzRW0DXJ02669R
7TW5AoGAMXwmztjbV63Pv/z2j5mawclTU9G6gN8WsvXhxC0rIcuFDGcj1CD7zNWD
GfUrU/BcFymgUmR42l9iSqELwomQdnBdcdgWWzFmIzFQ+RKlt35aukHYSuNYpUZD
yoix2MDdss7JaOTl4VCLYaY+ooBiS2zVG5toNGgTQl6PE7MiYnk=
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       31:8b:71:66:36:0f:69:92:28:8c:16:ed:01:b8:6e:b5:37:62:0f:df

```

### Отзовем сертификат

```bash
kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="31:8b:71:66:36:0f:69:92:28:8c:16:ed:01:b8:6e:b5:37:62:0f:df"

Key                        Value
---                        -----
revocation_time            1590947212
revocation_time_rfc3339    2020-05-31T17:46:52.992075244Z
```

## Включить TLS

cd ../tls

Генерируем ключ rsa

```bash
openssl genrsa -out tls.key 4096
```

Создадим файл конфигурации

```bash
cat <<EOF >./tls.cnf
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_ext
[ dn ]
commonName = localhost
stateOrProvinceName = SPB
countryName = RU
emailAddress = info@nks.com
organizationName = NoORG
organizationalUnitName = IT
[ v3_ext ]
basicConstraints = CA:FALSE
keyUsage = keyEncipherment,dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = vault
DNS.2 = localhost
DNS.3 = vault-server-tls
DNS.4 = vault-server-tls.default
DNS.5 = vault-server-tls.default.svc
DNS.6 = vault-server-tls.default.svc.cluster.local
IP.1 = 127.0.0.1
EOF
```

Создадим csr

```bash
openssl req -new -config tls.cnf -keyout tls.key -out tls.csr
```

Закодируем сертификат

```bash
export TMPDIR=~/express42/OLEGIM_platform/kubernetes-vault/tls
export CSR_NAME=vault-certs

cat <<EOF >${TMPDIR}/csr.yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  groups:
  - system:authenticated
  request: $(cat ${TMPDIR}/tls.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF
```

Применяем манифест

```bash
kubectl apply -f csr.yaml
certificatesigningrequest.certificates.k8s.io/vault-req created
```

Подтверждаем использование

```bash
kubectl certificate approve ${CSR_NAME}
certificatesigningrequest.certificates.k8s.io/vault-req approved
```

Извлекаем сертификат

```bash
kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}' | base64 --decode > tls.crt
```

Создаем секрет

```bash
kubectl create secret generic ${CSR_NAME} \
        --from-file=tls.key=${TMPDIR}/tls.key \
        --from-file=tls.crt=${TMPDIR}/tls.crt \
        --from-file=tls.csr=${TMPDIR}/tls.csr
secret/vault-secrets created
```

## Обновим vault

cd ..

Удаляем волт и ставим с нужными параметрами

```bash
helm delete vault
release "vault" uninstalled


helm upgrade --install vault vault-helm -f vault/values-tls.yaml
Release "vault" does not exist. Installing it now.
NAME: vault
LAST DEPLOYED: Sun May 31 21:34:02 2020
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

## Распечатаем vault

```bash
for POD in 0 1 2; do kubectl exec -it vault-"${POD}" -- vault operator unseal 'lynKqpw4yQS85Jx9pa2S/stdm3GkhxEeldJq4v6z37A=' ;done

Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.4.2
Cluster Name    vault-cluster-e2c410ec
Cluster ID      0301c02f-11f1-5d5b-27da-07f93a0c76cd
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
Version                1.4.2
Cluster Name           vault-cluster-e2c410ec
Cluster ID             0301c02f-11f1-5d5b-27da-07f93a0c76cd
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.244.5.9:8200

Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.4.2
Cluster Name           vault-cluster-e2c410ec
Cluster ID             0301c02f-11f1-5d5b-27da-07f93a0c76cd
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.244.5.9:8200
```

## Залогинимся

```bash
kubectl exec -it vault-0 -- vault login
Token (will be hidden):  s.g0j3D3W8zAWTCBrsZMdO0eQR

Key                  Value
---                  -----
token                s.g0j3D3W8zAWTCBrsZMdO0eQR
token_accessor       W2XKNvclhs3Gjv3uX8esBr1C
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]

```

## Подготовим переменные для записи в конфиг кубер авторизации

```bash
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}") &&
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo) &&
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo) &&
export K8S_HOST='https://kubernetes.default.svc'
```

echo $VAULT_SA_NAME &&
echo $SA_JWT_TOKEN &&
echo $SA_CA_CRT &&
echo $K8S_HOST


## Запишем конфиг в vault

```bash
kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
 token_reviewer_jwt="$SA_JWT_TOKEN" \
 kubernetes_host="$K8S_HOST" \
 kubernetes_ca_cert="$SA_CA_CRT"
Success! Data written to: auth/kubernetes/config
```

## Проверим как работает авторизация

```bash
kubectl run --generator=run-pod/v1 tmp  -i  --tty --serviceaccount=vault-auth --image alpine:3.7
```

## Получение клиенского токена

```bash
apk add curl jq && VAULT_ADDR=http://vault:8200 && KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login

{"request_id":"bed663b2-dee4-b065-e1b3-8767d6365778","lease_id":"","renewable":false,"lease_duration":0,"data":null,"wrap_info":null,"warnings":null,"auth":{"client_token":"s.QcbakOo1yFixKjx5JTlfAeB7","accessor":"6jiQ5daJltKckuUWXDmHRgy4","policies":["default","otus-policy"],"token_policies":["default","otus-policy"],"metadata":{"role":"otus","service_account_name":"vault-auth","service_account_namespace":"default","service_account_secret_name":"vault-auth-token-qjw9b","service_account_uid":"fc2123ad-793c-48c3-b76b-1826bfadb3ce"},"lease_duration":86400,"renewable":true,"entity_id":"e96a0442-f516-954e-befa-5fb1615e97f9","token_type":"service","orphan":true}}
```

```bash
kubectl cp nginx/cert-issuer.hcl vault-0:./tmp

kubectl exec -it vault-0 -- vault policy write cert-issuer /tmp/cert-issuer.hcl
Success! Uploaded policy: cert-issuer

kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy,cert-issuer default_ttl=5m
Success! Data written to: auth/kubernetes/role/otus

kubectl apply -f nginx/nginx-configmap.yaml
configmap/nginx-conf created
configmap/index-html created

kubectl apply -f nginx/nginx-deployment.yaml
deployment.apps/nginx-tls created
```

## Пробросим порты

```bash
kubectl port-forward nginx-tls-7bf5f66ccc-v8r6z 8443:8443

localhost:8443 или test.example.ru добавим в /etc/hosts
```

![alt_text](2020-06-01-04-51-24.png "Первый сертификат")

    Через некоторое время заметим что сертификат другой:

![alt_text](2020-06-01-05-05-22.png "Второй сертификат")


## PR checklist

-[x] Выставлен label с номером домашнего задания
-[] Задание со *

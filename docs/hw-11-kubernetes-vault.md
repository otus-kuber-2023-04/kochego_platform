## ДЗ №11. Хранилище секретов для приложений. Vault
### Подготовка к работе
Запущен кластер Managed k8s в Yandex Cloud  

### Установка и инициализация
```bash
git clone https://github.com/hashicorp/consul-helm.git
helm upgrade -i consul consul-helm -f consul.values.yaml
```
```txt
NAME: consul
LAST DEPLOYED: Fri Oct 20 11:47:46 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Consul!

Now that you have deployed Consul, you should look over the docs on using
Consul with Kubernetes available here:

https://www.consul.io/docs/platform/k8s/index.html


Your release is named consul.

To learn more about the release, run:

  $ helm status consul
  $ helm get all consul
```
### Установка Vault
```bash
git clone https://github.com/hashicorp/vault-helm.git
```
После редактирования values запустим установку
```bash
helm upgrade -i vault vault-helm -f vault.values.yaml
helm status vault
kubectl logs vault-0
```
Проверим:
```txt
helm status vault

NAME: vault
LAST DEPLOYED: Sat Oct 21 00:02:34 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://developer.hashicorp.com/vault/docs


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault
```
Проведем инициализацию и распечатаем каждый хост
```bash
kubectl exec -it vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
VAULT_UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[]")
kubectl exec -it vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
```
Вывод команды выше:
```txt
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.14.0
Build Date      2023-06-19T11:40:23Z
Storage Type    consul
Cluster Name    vault-cluster-a7a2151b
Cluster ID      34c9123c-ff50-ce5a-84a4-9b7e3b5f003a
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
Active Since    2023-10-29T04:54:16.536165189Z
```
Повторим с двумя оставшимися хостами:
```bash
kubectl exec vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.14.0
Build Date             2023-06-19T11:40:23Z
Storage Type           consul
Cluster Name           vault-cluster-a7a2151b
Cluster ID             34c9123c-ff50-ce5a-84a4-9b7e3b5f003a
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.112.131.8:8200

kubectl exec vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.14.0
Build Date             2023-06-19T11:40:23Z
Storage Type           consul
Cluster Name           vault-cluster-a7a2151b
Cluster ID             34c9123c-ff50-ce5a-84a4-9b7e3b5f003a
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.112.131.8:8200
```
Проверим статус сервера:
```bash
kubectl exec -it vault-0 -- vault status
```
```txt
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.14.0
Build Date      2023-06-19T11:40:23Z
Storage Type    consul
Cluster Name    vault-cluster-a7a2151b
Cluster ID      34c9123c-ff50-ce5a-84a4-9b7e3b5f003a
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
Active Since    2023-10-29T04:54:16.536165189Z
```
Узнаем адрес vault:
```bash
k exec -it vault-0 -- env | grep VAULT_ADDR
VAULT_ADDR=http://127.0.0.1:8200
```
### Аутентификация
До настройки:
```bash
kubectl exec -it vault-0 -- vault auth list
```
Логинимся (root token берем из cluster-keys.json ранее сохраненного):
```bash
kubectl exec -it vault-0 -- vault login
```
```txt
kubectl exec -it vault-0 -- vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.Oboeo4wEgzdnPNaskqxnVffb
token_accessor       OFG6eQmh3O2B0BSQ1RJ38b96
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```
Список способов аутентификации:
```bash
kubectl exec -it vault-0 -- vault auth list
Path      Type     Accessor               Description                Version
----      ----     --------               -----------                -------
token/    token    auth_token_1f3c449a    token based credentials    n/a
```
### Работа с секретами
```bash
kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
Success! Enabled the kv secrets engine at: otus/

kubectl exec -it vault-0 -- vault secrets list --detailed
Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID                                    Version    Running Version          Running SHA256    Deprecation Status
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----                                    -------    ---------------          --------------    ------------------
cubbyhole/    cubbyhole    cubbyhole_6852ee7a    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           fba098da-19bd-e272-bac0-0cd706985da2    n/a        v1.14.0+builtin.vault    n/a               n/a
identity/     identity     identity_fbc6f677     system         system     false             replicated     false        false                      map[]      identity store                                             2b600906-0d98-fe68-5974-b5bb07e82847    n/a        v1.14.0+builtin.vault    n/a               n/a
otus/         kv           kv_fb40537e           system         system     false             replicated     false        false                      map[]      n/a                                                        962b7437-bfaf-bc61-126d-fa839333462b    n/a        v0.15.0+builtin          n/a               supported
sys/          system       system_7f774027       n/a            n/a        false             replicated     true         false                      map[]      system endpoints used for control, policy and debugging    4b685af4-a5b3-1883-4ace-2db14f0f32fa    n/a        v1.14.0+builtin.vault    n/a               n/a


kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-ro/config

kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-rw/config

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
### Авторизация через k8s
```bash
kubectl exec -it vault-0 -- vault auth enable kubernetes
kubectl exec -it vault-0 -- vault auth list

Path           Type          Accessor                    Description                Version
----           ----          --------                    -----------                -------
kubernetes/    kubernetes    auth_kubernetes_0c194924    n/a                        n/a
token/         token         auth_token_1f3c449a         token based credentials    n/a
```
Создаем сервисный аккаунт, роль и секрет:
```bash
kubectl apply --filename vault-auth-service-account.yaml

clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
serviceaccount/vault-auth created
secret/vault-auth-secret created
```

Настроим переменные среды (по инструкции с оф. сайта):
```bash
export SA_SECRET_NAME=$(kubectl get secrets --output=json    | jq -r '.items[].metadata | select(.name|startswith("vault-auth-")).name')
export SA_JWT_TOKEN=$(kubectl get secret $SA_SECRET_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl config view --raw --minify --flatten   --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
export K8S_HOST=$(kubectl config view --raw --minify --flatten   --output 'jsonpath={.clusters[].cluster.server}')

kubectl exec -it vault-0 -- vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="$K8S_HOST" kubernetes_ca_cert="$SA_CA_CRT" issuer="https://kubernetes.default.svc.cluster.local"
Success! Data written to: auth/kubernetes/config
```
Создаем политику и роль в vault:
```bash
kubectl cp --no-preserve=false otus-policy.hcl vault-0:/tmp

kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl
Success! Uploaded policy: otus-policy

kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus bound_service_account_names=vault-auth bound_service_account_namespaces=default token_policies=otus-policy ttl=24h
Success! Data written to: auth/kubernetes/role/otus
```

Для проверки создадим под
```bash
kubectl apply -f vault-test-pod.yaml
```
Заходим в под устанавливаем jq и получаем токен:
```bash
kubectl exec -it vault-test -- sh
curl http://vault:8200/v1/sys/seal-status
export VAULT_ADDR=http://vault:8200
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')
```
Проверяем чтение и запись секретов:
```bash
curl -s  --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-ro/config | jq
{
  "request_id": "43a534a1-4806-7124-b408-069fd78998cb",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}

curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-ro/config
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}
curl --request POST --data '{"bar": "baz"}' --header "X-VaultToken:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config
{"errors":["permission denied"]}
curl --request POST --data '{"bar": "baz"}' --header "X-VaultToken:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config1
{"errors":["permission denied"]}
```
Чтение работает, в отличии от обновления.
**Вопрос**: Почему мы смогли записать otus-rw/config1 но не смогли otus-rw/config?
**Ответ**: Потому что в политиках определены правила
```txt
path "otus/otus-ro/*" {
      capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
      capabilities = ["read", "create", "list"]
}
```

Правила определяют, что можно создавать ключи, а не менять. Чтобы это исправить надо изменить правило:
```txt
path "otus/otus-ro/*" {
capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
capabilities = ["read", "create", "list", "update"]
}
```

Изменяем политику, проверяем, теперь ключ обновляется:
```bash
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config1
curl -s --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config 1| jq
{
"request_id": "3d938675-8bee-ad5c-7f83-15ae07a2bda1",
"lease_id": "",
"renewable": false,
"lease_duration": 2764800,
"data": {
"bar": "baz"
},
"wrap_info": null,
"warnings": null,
"auth": null
}
```

### 
Use case использования аутентификации через Kubernetes
Исправляем configmap vault-agent, деплоим vault-agent и тестовый под

```bash
kubectl create configmap example-vault-agent-config --from-file=./configs-k8s/
configmap/example-vault-agent-config created
kubectl get configmap example-vault-agent-config -o yaml
kubectl apply -f example-k8s-spec.yaml --record
```

Проверяем. Init-контейнер с Vault-agent сходил в Vault, достал секреты и записал их на стартовой странице Nginx
```bash
kubectl exec -it vault-agent-example -- sh
Defaulted container "nginx-container" out of: nginx-container, vault-agent (init)
# cat /usr/share/nginx/html/index.html
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>

</body>
</html>
```
### CA на базе vault

Включим PKI:
```bash
kubectl exec -it vault-0 -- vault secrets enable pki 
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="kochego.online" ttl=87600h > CA_cert.crt
```
Пропишем URL-ы и СА для отозванных сертификатов:
```bash
kubectl exec -it vault-0 -- vault write pki/config/urls \
issuing_certificates="http://vault:8200/v1/pki/ca" \
crl_distribution_points="http://vault:8200/v1/pki/crl"
```
Создадим промежуточный сертификат и сохраним все сертификаты CA в Vault:
```bash
kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal \
common_name="kochego.online Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
````
Пропишем промежуточный сертификат в vault
```bash
kubectl cp pki_intermediate.csr vault-0:/tmp
kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate \
csr=@/tmp/pki_intermediate.csr \
format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem

kubectl cp intermediate.cert.pem vault-0:/tmp
kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem
```
Создадим роль для выдачи сертификатов:
```bash
kubectl exec -it vault-0 -- vault write pki_int/roles/vault-kochego-online    allowed_domains="kochego.online" allow_subdomains=true max_ttl="720h"
```
Выпустим сертификат:
```bash
kubectl exec -it vault-0 -- vault write pki_int/issue/vault-kochego-online common_name="*.kochego.online" ttl="24h"

Key                 Value
---                 -----
-----BEGIN CERTIFICATE-----
MIIDqDCCApCgAwIBAgIUf2nyxTFn6eMM4BVu7IGaQ8BjZPowDQYJKoZIhvcNAQEL
...
8Re8RfSQaIw+DKo8RQVXGInUHtPgYhOENNMSSg==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDTDCCAjSgAwIBAgIUVTkctwk4vaFcpqdUYSFI/T0eQ3IwDQYJKoZIhvcNAQEL
...
SHT7iKyAGGf2MqeoSEKzxIv/XaylbIrFi6GFBzS2IPs=
-----END CERTIFICATE-----
 -----BEGIN CERTIFICATE-----
MIIDaTCCAlGgAwIBAgIUB0J0RusfaupSt6a52AbboJ7WY5AwDQYJKoZIhvcNAQEL
...
olCD6U9JPp/49LaMaC0BN3HwBfV/axU7IqQ78rzErmxZLiRJHEl/XAUKE32klGOe
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDqDCCApCgAwIBAgIUf2nyxTFn6eMM4BVu7IGaQ8BjZPowDQYJKoZIhvcNAQEL
...
8Re8RfSQaIw+DKo8RQVXGInUHtPgYhOENNMSSg==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAq+sYCQFhFsDskgvvrRIKU5l3rA0a24QDudc68E48HHdptouk
...
ab0bPOYp57S9D5YwoG6ggQac6c/RK6lu19HQZIFvCbMJNHbpkxT00A==
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       07:42:74:46:eb:1f:6a:ea:52:b7:a6:b9:d8:06:db:a0:9e:d6:63:90
```

Отзовем сертификат:
```bash
kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="07:42:74:46:eb:1f:6a:ea:52:b7:a6:b9:d8:06:db:a0:9e:d6:63:90"

Key                        Value
---                        -----
revocation_time            1698559984
revocation_time_rfc3339    2023-10-29T06:13:04.302419606Z
state                      revoked
```

### * Реализовать доступ к Vault через https
Выполняем все действия согласно инструкции https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls
Получаем кластер Vault с включенным TLS

### * Настроить autounseal
Настраиваем провайдера autounseal в Yandex Cloud, действуем по инструкции https://cloud.yandex.ru/docs/kms/tutorials/vault-secret#setup

### * Настроить lease временных секретов для доступа к БД)
Для примера настроим динамически изменяемые секреты для MySQL. Действуем по инструкции https://developer.hashicorp.com/vault/docs/secrets/databases/mysql-maria
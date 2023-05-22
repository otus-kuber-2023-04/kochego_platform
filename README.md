# kochego_platform
kochego Platform repository

# ДЗ №4. Хранение данных в Kubernetes: Volumes, Storages, Statefull-приложения

- В кластере kind создан StatefulSet для хранилища MinIO и сделан доступным изнутри кластера при помощи механизма Headless Service
- Проверена работоспособность MinIO изнутри кластера при помощи клиента mc - коннект к хранилищу и создание/удаление бакета
- Креденшалы для подключение к MinIO переданы в виде секретов. StatefulSet перенастроен и проверена работоспособность

# ДЗ №5. Безопасность и управление доступом

- **task01** Создана ClusterRole для управления доступом к ресурсам всего кластера с полными правами, сервисные аккаунты и один из аккаунтов связан с ClusterRole вследствие чего он может работать ресурсами всего кластера с админскими правами
- **task02** Созданы namespace, ClusterRole с правами на чтение подов во всем кластере, сервисный аккаунт в рамках одного неймспейса и при помощи ClusterRoleBinding добавлена возможность всем сервисным аккаунтам в рамках созданного неймспейеса работать с правами на чтение со всеми подами кластера
- **task03** Создан неймспейс, две роли в рамках этого неймспейса с правами админа и правами на чтение, два сервисных аккаунта, настроена связь между аккаунтами и ролями
#### Для проверок удобно использовать команду 'auth can-i'
Например, для задания из **task01**
```bash
kubectl auth can-i get deployments --as system:serviceaccount:default:bob --all-namespaces=true
```
Ожидаемый результат:
```bash
yes
```
# ДЗ №6. Мониторинг компонентов кластера и приложений, работающих в нем

- **./kubernetes-monitoring/web/** Создан кастомный образ Nginx, который умеет отдавать свои метрики по пути /basic_status и запушен в докерхаб
- **./kubernetes-monitoring/nginx-deploy.yaml** Создан деплоймент и сервис для Nginx на основе этого образа в кластере minikube
```bash
kubectl apply -f ./kubernetes-monitoring/nginx-deploy.yaml
```
- **./kubernetes-monitoring/nginx-exporter-deploy.yaml** Создан деплоймент и сервис для prometheus Nginx exporter, который собирает метрики с Nginx и преобразовывает их в prometheus формат, после преобразования они доступны по пути /metrics
```bash
kubectl apply -f ./kubernetes-monitoring/nginx-exporter-deploy.yaml
```
- Установлен prometheus-operator при помощи манифеста из официального репозитория
- **./kubernetes-monitoring/service-monitor.yaml** Создан service monitor для Nginx
- **./kubernetes-monitoring/grafana.yaml** Поднята Grafana при помощи инструкции с официального сайта. Дэшборд не нарисовала, поскольку работала в терминале

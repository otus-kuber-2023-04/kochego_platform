# kochego_platform
kochego Platform repository

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

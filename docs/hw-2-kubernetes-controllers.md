# ДЗ №2. Механика запуска и взаимодействия контейнеров в Kubernetes

- Развернут кластер kind, проверена его работоспособность
- **frontend-replicaset.yaml** Поднят под для frontend модуля приложения hipster shop при помощи контроллера ReplicaSet, количество реплик доведено до 3
- Обновлен и применен манифест для frontend типа ReplicaSet с использованием новой версии образа. После применения запущенные поды не обновились (не изменилась версия образа), поскольку ReplicaSet контролирует только количество запущенных экземпляров подов. Если удалить все поды, то они пересоздадутся уже с новой версией образа.
- **paymentservice-replicaset.yaml** Написан и применен манифест для paymentService модуля приложения hipster shop при помощи контроллера ReplicaSet.
- **paymentservice-deployment.yaml** Затем этот манифест переписан под создание при помощи контроллера Deployment. Данный контроллер помимо сущности Deployment создал нам ReplicaSet и поднял необходимое количество подов.
- Проверен сценарий отката деплоймента
- **paymentservice-deployment-bg.yaml && paymentservice-deployment-reverse.yaml** Для paymentService реализованы стратегии blue-green deployment и Reverse Rolling Update путем настройки параметров maxSurge и maxUnavailable
- **frontend-deployment.yaml** Для frontend написан Deployment манифест, дописана readinessProbe и проверена ее работа
- Создан манифест для развертывания Prometheus Node Exporter при помощи контроллера DaemonSet. В результате применения было поднято по одному поду на каждой worker ноде кластера. Проброшен порт и проверена работоспособность
- **node-exporter-daemonset.yaml** Модифицирован манифест, чтобы Node Exporter был развернут не только на worker, но и на control-plane нодах.
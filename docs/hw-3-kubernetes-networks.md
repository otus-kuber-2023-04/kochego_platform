# ДЗ №3. Сетевая подсистема Kubernetes

- **web-pod.yaml** Модифицирован манифест по созданию пода для веб сервера - добавлены проверки readinessProbe и livenessProbe, проверена их работоспособность
- **web-deploy.yaml** Создан манифест деплоймента для веб сервера с корректными пробами, проведен деплой с использованием различных стратегий (меняла версию образа busybox, чтобы помониторить разные стратегии деплоя)
- **web-svc-cip.yaml** Создан сервис типа ClusterIP для подключения к подам созданным ранее при помощи деплоймент манифеста, проверен доступ к странице веб сервера по CLUSTER-IP изнутри кластера
- В minikube для kube-proxy включен режим IPVS
- В minikube установлен MetalLB (использовалась инструкция с оф.сайта с последней версией манифеста и metallb-config.yaml для назначения пула адресов)
- **web-svc-lb.yaml** Создан сервис типа LoadBalancer, проверено что назначился EXTERNAL-IP, добавлен маршрут и проверен доступ к странице веб сервера по EXTERNAL-IP извне кластера
- **coredns/coredns-svc-lb.yaml** Создан сервис типа LoadBalancer для доступа к CoreDNS извне кластера, проверно что запросы к CoreDNS проходят
- **nginx-lb.yaml** Создан и запущен ingress-controller
- **web-ingress.yaml** Создано правило ingress, проверен доступ к странице веб сервера по Ingress EXTERNAL-IP и нужному префиксу извне кластера
- **dashboard/dashboard-ingress.yaml** Создано правило ingress для kubernetes-dashboard, проверен доступ к дэшборду через ingress
- **canary/*.yaml** Реализован canary deployment с помощью ingress - при передаче заголовка test: canary запрос идет на под с "канареечным" сайтом
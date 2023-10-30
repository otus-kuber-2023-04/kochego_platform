### Подготовка к работе
В YC созданы 4 ноды с образом Ubuntu 20.04 LTS
master      (intel ice lake, 2vCPU, 8 GB RAM)
worker-1    (intel ice lake, 2vCPU, 8 GB RAM)
worker-2    (intel ice lake, 2vCPU, 8 GB RAM)
worker-3    (intel ice lake, 2vCPU, 8 GB RAM)

### Развертывание кластера kubeadm
Подключаемся по ssh к ВМ
```bash
ssh admin@158.160.122.83 -i ~/.ssh/id_rsa_1
```

Отключаем swap на каждой ВМ
```bash
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
```

Включаем маршрутизацию
```bash
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<eof net.bridge.bridge-nf-calliptables="1" net.ipv4.ip_forward="1" net.bridge.bridge-nf-call-ip6tables="1" eof=""
sysctl="" --system="" <="" code=""></eof>
```

Загрузим br_netfilter и позволим iptables видеть трафик
```bash
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
```
Установим Containerd
```bash
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
# Apply sysctl params without reboot
sudo sysctl --system
#Install and configure containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update -y
sudo apt install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
#Start containerd
sudo systemctl restart containerd
sudo systemctl enable containerd
```
Установим kubectl, kubeadm, kubelet - на всех нодах
```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update -y
sudo apt -y install vim git curl wget kubelet=1.23.0-00 kubeadm=1.23.0-00 kubectl=1.23.0-00
sudo apt-mark hold kubelet kubeadm kubectl
sudo kubeadm config images pull --cri-socket /run/containerd/containerd.sock --kubernetes-version v1.23.0
```

Создадим настроим мастер ноду при помощи kubeadm, для этого на ней выполним:
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --upload-certs --kubernetes-version=v1.23.0 --ignore-preflight-errors=Mem --cri-socket /run/containerd/containerd.sock
```
В выводе будут:
команда для копирования конфига kubectl
сообщение о том, что необходимо установить сетевой плагин
команда для присоединения worker ноды
```txt
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.128.0.32:6443 --token 48pxb8.5gjfyfaxj2lzd4o5 \
        --discovery-token-ca-cert-hash sha256:153928b53a9dba6ef0c6049fa4c97a649f001ddcc8b33d2ece2ad74cb9c47b63
```

Копируем конфиг kubectl
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Установим сетевой плагин (Flannel)
```bash
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml

namespace/kube-flannel created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds created
```

Подключаем worker-ноды  
В предыдущих шагах уже было сделано:
- Установите на worker ноды containers
- включите маргрутизацию
- выключите swap
- установите kubeadm, kubelet, kubectl

Теперь делаем join на worker нодах
```bash
sudo kubeadm join 10.128.0.32:6443 --token 48pxb8.5gjfyfaxj2lzd4o5 \
        --discovery-token-ca-cert-hash sha256:153928b53a9dba6ef0c6049fa4c97a649f001ddcc8b33d2ece2ad74cb9c47b63
        
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
W1029 09:58:13.946422    6505 utils.go:69] The recommended value for "resolvConf" in "KubeletConfiguration" is: /run/systemd/resolve/resolv.conf; the provided value is: /run/systemd/resolve/resolv.conf
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.        
```

Если вывод команды потерялся, токены можно посмотреть командой
```bash
kubeadm token list
```
Получить хеш
```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform
der 2>/dev/null | \
 openssl dgst -sha256 -hex | sed 's/^.* //'
```

Проверим, что все ноды подключились
```bash
kubectl get nodes

master     Ready    control-plane,master   10m     v1.23.0
worker-1   Ready    <none>                 3m13s   v1.23.0
worker-2   Ready    <none>                 46s     v1.23.0
worker-3   Ready    <none>                 40s     v1.23.0
```

Для проверки развернем nginx в кластере
```bash
kubectl apply -f deployment.yaml
deployment.apps/nginx-deployment created

kubectl get all
NAME                                 READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-8c9c5f4-5d4kv   1/1     Running   0          12s
pod/nginx-deployment-8c9c5f4-7qtmf   1/1     Running   0          12s
pod/nginx-deployment-8c9c5f4-84pzb   1/1     Running   0          12s
pod/nginx-deployment-8c9c5f4-kgrbp   1/1     Running   0          12s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   14m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   4/4     4            4           12s

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-8c9c5f4   4         4         4       12s
```

### Обновление кластера
Так как кластер мы разворачивали с помощью kubeadm, то и производить обновление будем с помощью него    
Обновлять ноды будем по очереди  
Допускается, отставание версий worker-нод от master, но не наоборот  
Поэтому обновление будем начинать с нее master-нода у нас версии 1.23.0

Обновление пакетов
```bash
sudo apt update
sudo apt-cache madison kubeadm
sudo apt-mark unhold kubeadm && \
sudo apt-get update && sudo apt-get install -y kubeadm=1.24.17-00 && \
sudo apt-mark hold kubeadm
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.24.17

...
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.24.17". Enjoy!
```

Проверка
```bash
kubectl get nodes
NAME       STATUS   ROLES           AGE   VERSION
master     Ready    control-plane   24m   v1.24.0
worker-1   Ready    <none>          17m   v1.23.0
worker-2   Ready    <none>          15m   v1.23.0
worker-3   Ready    <none>          15m   v1.23.0
```
Обновление компонентов кластера (API-server, kube-proxy, controller-manager)
```bash
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.24.17
```
Проверка
```bash
kubeadm version
kubelet --version
kubectl version
kubectl describe pod pod/kube-apiserver-master -n kube-system
```

Обновим worker ноды
```bash
kubectl drain worker-1 --ignore-daemonsets
```
На worker-1 выполняем
```bash
sudo apt-mark unhold kubeadm && \
sudo apt-get update && sudo apt-get install -y kubeadm=1.24.17-00 && \
sudo apt-mark hold kubeadm
sudo kubeadm upgrade node
sudo apt-mark unhold kubelet kubectl && \
sudo apt-get update && sudo apt-get install -y kubelet=1.24.17-00 kubectl=1.24.17-00 && \
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```
Проверим и вернем в строй:
```bash
kubectl get nodes
NAME       STATUS                     ROLES           AGE   VERSION
worker-1   Ready,SchedulingDisabled   <none>          43m   v1.24.17

kubectl uncordon worker-1
```
Обновим остальные ноды и проверим
```bash
kubectl get nodes
NAME       STATUS   ROLES           AGE   VERSION
master     Ready    control-plane   55m   v1.24.17
worker-1   Ready    <none>          48m   v1.24.17
worker-2   Ready    <none>          45m   v1.24.17
worker-3   Ready    <none>          45m   v1.24.17
```

### Развертывание кластера Kubespray
Установка kubespray
Пре-реквизиты:
Python и pip на локальной машине
SSH доступ на все ноды кластера
```bash
# получение kubespray
git clone https://github.com/kubernetes-sigs/kubespray.git
# установка зависимостей
sudo pip3 install -r kubespray/requirements.txt
# копирование примера конфига в отдельную директорию
cp -rfp inventory/sample inventory/mycluster
```
Поправим адреса машин кластера в конфиге kubespray
inventory/mycluster/inventory.ini

Установим кластер
```bash
ansible-playbook -i inventory/mycluster/inventory.ini --become --become-user=root --user=${SSH_USERNAME} --key-file=${SSH_PRIVATE_KEY} cluster.yml
```

По завершении кластер установлен
```bash
kubectl get nodes
NAME       STATUS   ROLES           AGE   VERSION
master-1   Ready    control-plane   55m   v1.27.5
master-2   Ready    control-plane   55m   v1.27.5
master-3   Ready    control-plane   55m   v1.27.5
worker-1   Ready    <none>          48m   v1.27.5
worker-2   Ready    <none>          45m   v1.27.5
```
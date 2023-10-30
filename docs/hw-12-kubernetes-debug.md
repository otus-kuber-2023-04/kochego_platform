## ДЗ №12. Диагностика и отладка кластера и приложений в нем
### Подготовка к работе
Запущен кластер Managed k8s в Yandex Cloud

### kubectl-debug
Оригинальный репо: https://github.com/aylei/kubectl-debug  
Форк: https://github.com/JamesTGrant/kubectl-debug  
Более не поддерживается и не развивается и не работает с последними версиями k8s  
Предлагается использовать [ephemeral containers](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/)

### ephemeral containers

Стартуем пустой pause container:
```bash
kubectl run ephemeral-demo --image=registry.k8s.io/pause:3.1 --restart=Never
```
Запускаем отладку:
```bash
kubectl debug -it ephemeral-demo --image=busybox:1.28 --target=ephemeral-demo
```
Отладим контейнер с Nginx:
```bash
kubectl run ephemeral-nginx --image=nginx --restart=Never
kubectl debug -it ephemeral-nginx --image=alpine:latest --target=ephemeral-nginx

Targeting container "ephemeral-nginx". If you don't see processes from this container it may be because the container runtime doesn't support this feature.
Defaulting debug container name to debugger-d7jgq.
If you don't see a command prompt, try pressing enter.
/ #
```
Поставим в Ephemeral Container утилиту strace:
```bash
apk --update add strace

fetch https://dl-cdn.alpinelinux.org/alpine/v3.18/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.18/community/x86_64/APKINDEX.tar.gz
(1/6) Installing libbz2 (1.0.8-r5)
(2/6) Installing musl-fts (1.2.7-r5)
(3/6) Installing xz-libs (5.4.3-r0)
(4/6) Installing zstd-libs (1.5.5-r4)
(5/6) Installing libelf (0.189-r2)
(6/6) Installing strace (6.3-r1)
Executing busybox-1.36.1-r2.trigger
OK: 10 MiB in 21 packages
/ # strace ls
execve("/bin/ls", ["ls"], 0x7fff39d664c0 /* 90 vars */) = 0
arch_prctl(ARCH_SET_FS, 0x7ff51a66eb48) = 0
set_tid_address(0x7ff51a66efb8)         = 42
brk(NULL)                               = 0x5636fde9d000
brk(0x5636fde9f000)                     = 0x5636fde9f000
mmap(0x5636fde9d000, 4096, PROT_NONE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x5636fde9d000
mprotect(0x7ff51a66b000, 4096, PROT_READ) = 0
mprotect(0x5636fcd44000, 16384, PROT_READ) = 0
getuid()                                = 0
ioctl(0, TIOCGWINSZ, {ws_row=41, ws_col=172, ws_xpixel=0, ws_ypixel=0}) = 0
ioctl(1, TIOCGWINSZ, {ws_row=41, ws_col=172, ws_xpixel=0, ws_ypixel=0}) = 0
ioctl(1, TIOCGWINSZ, {ws_row=41, ws_col=172, ws_xpixel=0, ws_ypixel=0}) = 0
stat(".", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
open(".", O_RDONLY|O_LARGEFILE|O_CLOEXEC|O_DIRECTORY) = 3
fcntl(3, F_SETFD, FD_CLOEXEC)           = 0
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7ff51a5d3000
getdents64(3, 0x7ff51a5d3038 /* 19 entries */, 2048) = 464
lstat("./home", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./bin", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./mnt", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./run", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./proc", {st_mode=S_IFDIR|0555, st_size=0, ...}) = 0
lstat("./dev", {st_mode=S_IFDIR|0755, st_size=380, ...}) = 0
lstat("./usr", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./root", {st_mode=S_IFDIR|0700, st_size=4096, ...}) = 0
lstat("./sys", {st_mode=S_IFDIR|0555, st_size=0, ...}) = 0
lstat("./sbin", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./tmp", {st_mode=S_IFDIR|S_ISVTX|0777, st_size=4096, ...}) = 0
lstat("./srv", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./etc", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./media", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./lib", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./var", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./opt", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
getdents64(3, 0x7ff51a5d3038 /* 0 entries */, 2048) = 0
close(3)                                = 0
munmap(0x7ff51a5d3000, 8192)            = 0
ioctl(1, TIOCGWINSZ, {ws_row=41, ws_col=172, ws_xpixel=0, ws_ypixel=0}) = 0
writev(1, [{iov_base="\33[1;34mbin\33[m    \33[1;34mdev\33[m  "..., iov_len=285}, {iov_base="\n", iov_len=1}], 2bin    dev    etc    home   lib    media  mnt    opt    proc   root   run    sbin   srv    sys    tmp    usr    var
) = 286
exit_group(0)                           = ?
+++ exited with 0 +++
```

### iptables-tailer
Применила ресурсы для деплоя netperf-operator из https://github.com/piontec/netperf-operator/tree/master/deploy согласно методичке
```bash
k apply -f kubernetes-debug/kit/crd.yaml
customresourcedefinition.apiextensions.k8s.io/netperfs.app.example.com created
k apply -f kubernetes-debug/kit/operator.yaml
deployment.apps/netperf-operator created
k apply -f kubernetes-debug/kit/rbac.yaml
role.rbac.authorization.k8s.io/netperf-operator created
rolebinding.rbac.authorization.k8s.io/default-account-netperf-operator created
```
Создала Netperf ресурс
```bash
k apply -f kubernetes-debug/kit/cr.yaml
netperf.app.example.com/example created

kubectl describe netperf.app.example.com/example
Name:         example
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  app.example.com/v1alpha1
Kind:         Netperf
Metadata:
  Creation Timestamp:  2023-10-29T08:48:43Z
  Generation:          1
  Resource Version:    1201990
  UID:                 e2732a47-7fd7-4e92-9958-50f47265e1ca
Events:                <none>
```



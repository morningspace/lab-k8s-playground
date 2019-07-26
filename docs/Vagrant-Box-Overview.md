# Use the Vagrant Box


## What it includes?

* Kubernetes cluster with multiple nodes and configurable versions, supporting `v1.12`, `v1.13`, `v1.14`, `v1.15`
* Kubernetes tooling, e.g. 
  * [kubectl](https://kubernetes.io/docs/reference/kubectl)
  * [helm](https://helm.sh)
  * [kubectl autocompletion](https://kubernetes.io/docs/tasks/tools/install-kubectl/#optional-kubectl-configurations)
  * [kubectl aliases](https://github.com/ahmetb/kubectl-aliases)
  * [kubens](https://github.com/ahmetb/kubectx)
  * [kubebox](https://github.com/astefanutti/kubebox)
  * [kubetail](https://github.com/johanhaleby/kubetail)
  * [kube-shell](https://github.com/cloudnativelabs/kube-shell)
* [Kubernetes dashboard](https://github.com/kubernetes/dashboard)
* [Istio](https://istio.io) with demo app [bookinfo](https://istio.io/docs/examples/bookinfo)
* [Grafana](https://grafana.com)
* [Kiali](https://www.kiali.io)
* [Jaeger](https://www.jaegertracing.io)
* [Prometheus](https://prometheus.io)
* Private Docker image registries that help boost cluster launch

## What it supports?

* Configurable Kubernetes versions, supporting `v1.12`, `v1.13`, `v1.14`, `v1.15`.
* Configurable number of cluster nodes, one master node and two worker nodes by default.
* Many Kubernetes tools integrated for you to learn, use, and evaluate.
* [Web terminal](https://github.com/shellinabox/shellinabox) that allows to log in to the box from browser, so you can use all Kubernetes tools in the box wilthin browser without having them installed on your host machine.
* Private Docker image registries and disk file cache to store both pulled images and downloaded installation packages that make cluster launch faster, even can be run in offline mode after the first privisioning to the box is done.
* Special optimization for users in China through environment variables `IS_IN_CHINA` and `https_proxy` when pull images and download installation packages.
* Repeatable quick system bootstrap at any time after the first provisioning for any reason, e.g. to destroy the current Kubernetes cluster and re-launch a new one with different versions, or to update the private Docker image registries to cache newly added images.
* Customizable system bootstrap to meet your very specific requirements, e.g. only re-launch Kubernetes to bring up a clean cluster without touching other installed components. You can even hook your own installation scripts into the bootstrap process.

## Demo

> Customize repeatable bootstrap in offline mode.

In this demo, I turned Wi-Fi off on my laptop, then logged into the provisioned box, and run `launch kubernetes helm` specifically to re-install Kubernetes and Helm.

![](demo-1.gif)

> Run Kubernetes tools from both OS terminal and web terminal.

In this demo, I ran tools e.g. kube-shell, autocompletion, kubetail, kubebox, aliases, kubens in OS terminal first, then web terminal.

![](demo-2.gif)

> Use Dashboard, Grafana, Kiali, Jaeger when run Istio Bookinfo demo app.

In this demo I had Istio and its demo app installed with Kubernetes, then tried different deployed applications in browser.

![](demo-3.gif)

## How to use it?

To provision the box, go to the repository root folder and run:
```shell
$ vagrant up
```

To log in to the box via ssh after provisioned:
```shell
$ vagrant ssh
```

To customize bootstrap after the first provisioning, run `launch` command in the box and specify the target(s) that you want to launch. For example, the below command will re-launch a clean Kubernetes cluster:
```shell
vagrant@vagrant:~$ launch kubernetes
```

The below command will update Docker image registries to cache any newly added images to local, then re-launch a clean Kubernetes cluster:
```shell
$ launch registry kubernetes
```

To destroy the box for re-provisioning:
```shell
$ vagrant destroy
```

Available targets:

| Target					| Description
| ---- 						|:----
| docker          | Install docker
| docker-compose  | Install docker-compose required by target registry
| kubectl         | Install kubectl
| registry        | Setup Docker image registries
| kubernetes      | Launch Kubernetes
| tools           | Install recommended Kubernetes tools
| helm            | Install Helm
| istio           | Install Istio
| istio-bookinfo  | Install Istio demo app: bookinfo
| endpoints       | Display all application endpoints with their states

You can even define your own target for specific installation requirement, save as a shell script file, e.g. my-app.sh, to `/install/targets` folder, then run `launch my-app` to invoke it.

## Application Endpoinds

After system bootstrapped, you can use below endpoints to access variant applications:

| Application			| Endpoints
| ---- 						|:----
| Web terminal		| https://192.168.56.100:4200/
| Dashboard				| http://192.168.56.100:32768/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
| Istio Bookinfo	| http://192.168.56.100:31380/productpage
| Grafana					| http://192.168.56.100:3000/
| Kiali						| http://192.168.56.100:20001/
| Jaeger					| http://192.168.56.100:15032/
| Prometheus			| http://192.168.56.100:9090/

Also, you can run `launch endpoints` to list all supported applications with their endpoints and current status.

```shell
vagrant@vagrant:~$ launch endpoints 
* targets to be launched: [endpoints]
####################################
# Launch target endpoints...
####################################
✔   Web terminal: https://192.168.56.100:4200
✔      Dashboard: http://192.168.56.100:32792/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy
✔ Istio Bookinfo: http://192.168.56.100:31380/productpage
✔        Grafana: http://192.168.56.100:3000
✔          Kiali: http://192.168.56.100:20001
✔         Jaeger: http://192.168.56.100:15032
✔     Prometheus: http://192.168.56.100:9090
```

### How to configure it

```ruby
# set number of vcpus
cpus = '6'
# set amount of memory allocated by vm
memory = '8192'

# set Kubernetes version, supported versions: v1.12, v1.13, v1.14, v1.15
k8s_version = "v1.14"
# set number of worker nodes
nodes = 2
# set host ip of the box
host_ip = '192.168.56.100'

# special optimization for users in China, 1 or 0
is_in_china = 1
# set https_proxy
https_proxy = ""

# optional targets to be run, can be customized as your need
targets = "helm tools istio"
```

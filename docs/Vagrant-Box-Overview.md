# Vagrant Box Overview

This is the very high level overview of what the Vagrant box provides. For more details, please check ["Vagrant Box Getting Started"](Vagrant-Box-Getting-Started.md) on how to use the box, and ["Target Launch Reference"](Target-Launch-Reference.md) on how to customize the box.

## Highly configurable

The Vagrant box includes a Kubernetes cluster with multiple nodes and configurable version support ranging from `v1.12` to `v1.15`.

The number of cluster nodes is also configurable. By default it's one master node and two worker nodes.

For more details, please check ["Customize the launch"](Vagrant-Box-Getting-Started.md#customize-the-launch).

## Rich tooling

There are many Kubernetes tools integrated within the box for you to learn, use, and evaluate, e.g.:
* [kubectl](https://kubernetes.io/docs/reference/kubectl)
* [helm](https://helm.sh)
* [kubectl autocompletion](https://kubernetes.io/docs/tasks/tools/install-kubectl/#optional-kubectl-configurations)
* [kubectl aliases](https://github.com/ahmetb/kubectl-aliases)
* [kubens](https://github.com/ahmetb/kubectx)
* [kubebox](https://github.com/astefanutti/kubebox)
* [kubetail](https://github.com/johanhaleby/kubetail)
* [kube-shell](https://github.com/cloudnativelabs/kube-shell)

It also has below applications deployed:
* [Kubernetes dashboard](https://github.com/kubernetes/dashboard)
* [Istio](https://istio.io) with demo app [bookinfo](https://istio.io/docs/examples/bookinfo)
* [Grafana](https://grafana.com)
* [Kiali](https://www.kiali.io)
* [Jaeger](https://www.jaegertracing.io)
* [Prometheus](https://prometheus.io)

## Web terminal

To use the box, you can login from OS terminal via ssh, or use the [Web terminal](https://github.com/shellinabox/shellinabox) that allows you to log in to the box from browser.

So, you can use all Kubernetes tools in the box without having them installed on your local machine.

## Cache everything

To boost your cluster launch, the box uses private container registries to mimic some public registries such as [Google Container Registry](https://gcr.io), [Quay](https://quay.io), and [Docker Hub](https://hub.docker.com) to store required images when launch cluster or deploy applications.

It also has disk file cache to store downloaded installation packages that makes the box provisioning much faster.

After the first privisioning to the box is done, you can even run the cluster in offline mode without network connectivity!

For more details, please check ["Run in offline mode"](Vagrant-Box-Getting-Started.md#run-in-offline-mode).

## Flexible customization

By using `launch` utility, you can customize the box to meet your very specific requirement at any time after the box is provisioned repeatedly without any side effect, e.g. to destroy the current cluster and re-launch a new one with different Kubernetes version, or to update the private container registries to cache newly added images. For more details, please check ["Launch targets"](Vagrant-Box-Getting-Started.md#launch-targets), ["Re-launch targets"](Vagrant-Box-Getting-Started.md#re-launch-targets) and ["Use private registries"](Vagrant-Box-Getting-Started.md#use-private-registries)

You can even hook your own installation scripts into the provisioning process. For more details, please check ["Target Launch Reference"](Target-Launch-Reference.md).

## Special care for China users

There is some particular optimization for users in China to overcome the network connectivity issue of some sites required when launch cluster and deploy applications. It has been integrated into the box without any additional complicated configuration. Please check ["Customize the launch"](Vagrant-Box-Getting-Started.md#customize-the-launch) if you want to enable this feature.

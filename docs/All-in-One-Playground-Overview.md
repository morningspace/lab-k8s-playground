# The All-in-One Kubernetes Playground Overview

> This is the very high level overview of the All-in-One Kubernetes Playground. For more details on how to use the playground, please refer to ["The All-in-One Kubernetes Playground Usage Guide"](All-in-One-Playground-Usage-Guide.md) or ["All-in-One K8S Playground中文使用指南"](https://morningspace.github.io/tech/all-in-one-k8s-playground/).

This playground includes a set of shell scripts that can help you launch a multi-node Kubernetes cluster on a single machine in minutes in a repeatable manner.

## Applications

The below applications are deployed along with the playground for you to evaluate and use:
* [Kubernetes dashboard](https://github.com/kubernetes/dashboard)
* [Istio](https://istio.io) with demo app [bookinfo](https://istio.io/docs/examples/bookinfo)
* [Grafana](https://grafana.com)
* [Kiali](https://www.kiali.io)
* [Jaeger](https://www.jaegertracing.io)
* [Prometheus](https://prometheus.io)
* [IBM API Connect](https://www.ibm.com/cloud/api-connect), for more details, please refer to [Quick Guide to Launch APIC Playground](APIC-Quick-Guide.md)

## Tools

The below Kubernetes-related command line tools are integrated with the playground for you to evaluate and use:
* [kubectl](https://kubernetes.io/docs/reference/kubectl)
* [helm](https://helm.sh)
* [kubectl autocompletion](https://kubernetes.io/docs/tasks/tools/install-kubectl/#optional-kubectl-configurations)
* [kubectl aliases](https://github.com/ahmetb/kubectl-aliases)
* [kubens](https://github.com/ahmetb/kubectx)
* [kubebox](https://github.com/astefanutti/kubebox)
* [kubetail](https://github.com/johanhaleby/kubetail)
* [kube-shell](https://github.com/cloudnativelabs/kube-shell)

## Private Registry

The playground runs a set of private registries that can be used to mimic below public container regiestries:
* [Google Container Registry](https://gcr.io)
* [Quay](https://quay.io)
* [Docker Hub](https://hub.docker.com)

By storing all images into private registries, it can boost your playground launch dramatically fast. You can even launch the playground without network connectivity! Furthermore, if you share the registries with your teammates, they all can benefit from that.

For more details, please refer to ["Can I launch the playground without network?"](All-in-One-Playground-Usage-Guide.md#can-i-launch-the-playground-without-network), ["Can I share private registries with others?"](All-in-One-Playground-Usage-Guide.md#can-i-share-private-registries-with-others).

## Launch

The playground provides a Vagrant Box out of the box that can be launched by a single line of command. Meanwhile, it can also be launched on your host machine directly.

For more details, please refer to ["How to launch the playground?"](All-in-One-Playground-Usage-Guide.md#how-to-launch-the-playground).

## Access

To use the playground in command line, you can login from normal terminal, or use [web terminal](https://github.com/shellinabox/shellinabox) that allows you to log in to the playground in web browser.

For more details, please refer to ["How to access the playground?"](All-in-One-Playground-Usage-Guide.md#how-to-access-the-playground)

## Use

You can do a lot of things by using the built-in "Launch Utility". You can even use the "Launch Utility" to create snapshot for the current running cluster, then restore from it later very quickly.

For more details, please refer to ["What else can I do with the playground?"](All-in-One-Playground-Usage-Guide.md#what-else-can-i-do-with-the-playground), ["Restore cluster from snapshot"](All-in-One-Playground-Usage-Guide.md#restore-cluster-from-snapshot), and the ["Launch Utility Usage Guide"](Launch-Utility-Usage-Guide.md).

## Customize

You can customize the playground before or after its launch in many aspects to meet your very specific requirement, e.g. to change the kubernetes version, the number of cluster nodes, the applications to be installed, and the Docker images to be pulled.

For more details, please refer to ["Can I customize the playground?"](All-in-One-Playground-Usage-Guide.md#can-i-customize-the-playground), ["What if images are changed?"](All-in-One-Playground-Usage-Guide.md#what-if-images-are-changed).

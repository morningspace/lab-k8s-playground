## MorningSpace Lab 

晴耕实验室

[![](https://morningspace.github.io/assets/images/banner.jpg)](https://morningspace.github.io)

# Kubernetes Playground

Keywords: Kubernetes, Container, Vagrant

## Overview

This lab project is a playground for you to play with Kubernetes.

It can launch a multi-node cluster on your local machine in less than one minute even without network connection! 

It also supports to maintain multi-version Kubernetes clusters in parallel on your machine even the latest snapshot built from Kubernetes source.

For more details on how to run this project, please check [Launch multi-node Kubernetes cluster locally in one minute, and more...](https://morningspace.github.io/tech/k8s-run/), or the video tutorial on [YouTube](https://www.youtube.com/watch?v=0uVdF3Inv48&list=PLVQM6jLkNkfqHgd0aX7TnjioOiQrqsXIa), or [YouKu](https://v.youku.com/v_show/id_XNDI2Mzk1NDcyMA==.html?f=52221532).

More tools and samples will be coming soon...

## The Vagrant Box

The project also has a [vagrant box](/Vagrantfile) that integrates a lot of popular Kubernetes related applications and tools with best practices to make your daily work with Kubernetes more efficiently.

It includes Kubernetes tools, e.g. [kubectl](https://kubernetes.io/docs/reference/kubectl), [helm](https://helm.sh), [kubectl autocompletion](https://kubernetes.io/docs/tasks/tools/install-kubectl/#optional-kubectl-configurations), [kubectl aliases](https://github.com/ahmetb/kubectl-aliases), [kubens](https://github.com/ahmetb/kubectx), [kubebox](https://github.com/astefanutti/kubebox), [kubetail](https://github.com/johanhaleby/kubetail), [kube-shell](https://github.com/cloudnativelabs/kube-shell).

And applications, e.g. [Kubernetes dashboard](https://github.com/kubernetes/dashboard), [Istio](https://istio.io) with demo app [bookinfo](https://istio.io/docs/examples/bookinfo), [Grafana](https://grafana.com), [Kiali](https://www.kiali.io), [Jaeger](https://www.jaegertracing.io), [Prometheus](https://prometheus.io) and Private Docker image registries that help boost cluster launch.

Below are some demos. For more details on how to use the vagrant box, please check [Use the Vagrant Box](/docs/UseVagrantBox.md).

> Launch Kubernetes and Helm in offline mode.

![](/docs/demo-1.gif)

> Run Kubernetes tools from both OS terminal and web terminal.

![](/docs/demo-2.gif)

> Use Dashboard, Grafana, Kiali, Jaeger, Prometheus when run Istio Bookinfo demo app.

![](/docs/demo-3.gif)

Have Fun!

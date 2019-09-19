## MorningSpace Lab 

晴耕实验室

[![](https://morningspace.github.io/assets/images/banner.jpg)](https://morningspace.github.io)

# Kubernetes Playground

Keywords: Kubernetes, Container, DIND, Vagrant

## Overview

This lab project is a playground for you to play with Kubernetes easily and efficiently.

It includes an `All-in-One Playground` that can launch a multi-node cluster with configurable Kubernetes version on your local machine in minutes in a repeatable manner even without network connectivity!

* If you want to try the `All-in-One Playground`, please refer to ["The All-in-One Kubernetes Playground Overview"](/docs/All-in-One-Playground-Overview.md), ["The All-in-One Kubernetes Playground Usage Guide"](/docs/All-in-One-Playground-Usage-Guide.md) or ["All-in-One K8S Playground中文使用指南"](https://morningspace.github.io/tech/all-in-one-k8s-playground/).
* If you want to know what is the magic behind, please refer to ["Launch multi-node Kubernetes cluster locally in one minute, and more..."](https://morningspace.github.io/tech/k8s-run/), and the video series on [YouTube](https://www.youtube.com/watch?v=0uVdF3Inv48&list=PLVQM6jLkNkfqHgd0aX7TnjioOiQrqsXIa) or [YouKu](https://v.youku.com/v_show/id_XNDI2Mzk1NDcyMA==.html?f=52221532).
* If you want to start in a funny way, please take look at this [`special function`](https://morningspace.github.io/lab-k8s-playground/docs/slides/#/11/1) written in shell script and taken from the online ["Introduction Slides"](https://morningspace.github.io/lab-k8s-playground/docs/slides).

More cool features will be coming soon... Have Fun!

## Demos

Below are demos created based on the `All-in-One Playground`.

> Use [Dashboard](https://github.com/kubernetes/dashboard), [Grafana](https://grafana.com), [Kiali](https://www.kiali.io), [Jaeger](https://www.jaegertracing.io) when run [Istio](https://istio.io) [Bookinfo](https://istio.io/docs/examples/bookinfo) demo app.

![](/docs/demo-apps.gif)

> Run Kubernetes-related command line tools from both normal terminal and web terminal.

![](/docs/demo-tools.gif)

> Re-launch Kubernetes cluster and deploy [Helm](https://helm.sh) where there is no network connectivity.

![](/docs/demo-offline.gif)

> Launch [API Connect](https://developer.ibm.com/apiconnect) on top of Kubernetes cluster in the All-in-One Playground.

![](/docs/demo-apic.gif)

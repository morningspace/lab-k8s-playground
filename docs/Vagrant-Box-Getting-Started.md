# Vagrant Box Getting Started

## Start the box

When you have [Vagrant](https://www.vagrantup.com/) and its provider, e.g. typically [VirtualBox](https://www.virtualbox.org/) installed, to start the box is quite easy, just run below command:
```shell
$ vagrant up
```

By default, it will provision the box and launch a three-node Kubernetes cluster with a group of tools to help you manage your Kubernetes cluster. This can be customized. See ["Customize the launch"](#customize-the-launch) for details. 

## Use the box

To log in to the box from terminal via ssh, run below command:
```shell
$ vagrant ssh
```

You can also login using web terminal via https://192.168.56.100:4200. By default it uses `192.168.56.100` as the IP address of the box, but you can change it, see ["Customize the launch"](#customize-the-launch) for details.

After login, you can use [kubectl](https://kubernetes.io/docs/reference/kubectl) to access the cluster, and use [helm](https://helm.sh) to deploy your own applications.

Besides that, there are a whole bunch of pre-installed tools, e.g. [kubens](https://github.com/ahmetb/kubectx), [kubectl aliases](https://github.com/ahmetb/kubectl-aliases) to make your access to the cluster much easier, e.g. this is going to switch the namespace to `kube-system` using `kubens`, then list pods using `kubectl aliases`:
```shell
$ kubens kube-system
Context "dind" modified.
Active namespace is "kube-system".

$ kgpo
coredns-584795fc57-6bt45                1/1     Running   0          9m15s
etcd-kube-master                        1/1     Running   0          8m13s
kube-apiserver-kube-master              1/1     Running   0          8m9s
kube-controller-manager-kube-master     1/1     Running   0          8m8s
kube-proxy-5ght7                        1/1     Running   0          8m45s
kube-proxy-k7kzz                        1/1     Running   0          8m45s
kube-proxy-ttrkh                        1/1     Running   0          9m14s
kube-scheduler-kube-master              1/1     Running   0          8m25s
kubernetes-dashboard-54fb766c84-h5fh8   1/1     Running   0          8m40s
tiller-deploy-5c5b6f6567-8thvr          1/1     Running   0          8m23s
```

More use on variant tools, please check below demo: Run Kubernetes tools from both OS and web terminals. In this demo, I ran tools e.g. [kube-shell](https://github.com/cloudnativelabs/kube-shell), [kubectl autocompletion](https://kubernetes.io/docs/tasks/tools/install-kubectl/#optional-kubectl-configurations), [kubetail](https://github.com/johanhaleby/kubetail), [kubebox](https://github.com/astefanutti/kubebox), [kubectl aliases](https://github.com/ahmetb/kubectl-aliases), [kubens](https://github.com/ahmetb/kubectx) in OS terminal first, then web terminal.

![](demo-tools.gif)

## Launch targets

You can adjust the box after it is up, e.g. to install [Istio](https://istio.io) in the box. This can be done by running the built-in command utility `launch` which can help you adjust the box in many different ways. Simply run `launch` will give you brief help info:
```shell
$ launch

Usage: launch [targets]

  Targets are separated by space and launch in order of appearance one by one.

  Special pre-defined targets:
  * base      will launch target docker, docker-compose, and kubectl
  * default   will launch target base, registry, and kubernetes

  e.g.
  launch default tools istio
  launch kubernetes
```

Usually, the command is followed by a few targets separated by space. It then launches the targets in order of appearance one by one, e.g. this is going to install `kubectl` first, then `helm`:
```shell
$ launch kubectl helm
```

Actually, the [Vagrantfile](/Vagrantfile) also consistently uses `launch` to provision the box. There are a whole bunch of pre-defined targets available. You can even add your own. See ["Target Launch Reference"](Target-Launch-Reference.md) for details.

Now, let's install `Istio`:
```
$ launch istio
```

Wait for a while till it's finished. Then, run a target called `endpoints` to list all available endpoints with their healthiness states:
```
$ launch endpoints
* targets to be launched: [endpoints]
####################################
# Launch target endpoints...
####################################
✔   Web terminal: https://192.168.56.100:4200
✔      Dashboard: http://192.168.56.100:32770/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy
✗ Istio Bookinfo: http://192.168.56.100:31380/productpage
✔        Grafana: http://192.168.56.100:3000
✔          Kiali: http://192.168.56.100:20001
✔         Jaeger: http://192.168.56.100:15032
✔     Prometheus: http://192.168.56.100:9090
Total elapsed time: 1 seconds
```

This target outputs the endpoinds of [Web terminal](https://github.com/shellinabox/shellinabox), [Kubernetes dashboard](https://github.com/kubernetes/dashboard), as well as [Grafana](https://grafana.com), [Kiali](https://www.kiali.io), [Jaeger](https://www.jaegertracing.io) and so on that are installed along with `Istio`. Again, the IP address is configurable.

You may notice that all endpoinds are healthy except [Istio Bookinfo](https://istio.io/docs/examples/bookinfo). That's because we haven't installed the Istio demo app, Bookinfo, yet. To install it, use the corresponding target `istio-bookinfo` as below:
```shell
$ launch istio-bookinfo
```

After it's installed, go back to check the endpoints, you will see all endpoints become healthy now. Choose one of them and open it in browser, or you can check below demo: Use Dashboard, Grafana, Kiali, Jaeger when run Istio Bookinfo demo app. In this demo I had Istio and its demo app installed with Kubernetes, then tried different deployed applications in browser.

![](demo-apps.gif)

## Re-launch targets

Most targets can be re-launched in the box multiple times without any side effect. Because of local caches and auto-detecting logic, launches after the first one will be much faster, e.g. it will check if an installation package is in cache before download it; or detect if a command line tool exists before install it.

To re-launch some targets in a later phase after the box is up is useful in some cases, e.g. you can drop all deployments and run below command to bring the cluster back to clean state:
```shell
$ launch kubernetes
```

## Use private registries

Another example to re-launch target is to add new images to the private container registries.

Private container registries are used to store images that will be pulled during cluster launch or application deployment. This is quite useful when we run the cluster in a poor network environment. As you can store all images to the private registries and have them co-located with the cluster, you can even run the cluster without network connectivity. See ["Run in offline mode"](#run-in-offline-mode) for details.

There is a target called `registry` used to setup the private registries. It reads images configured in file [images.list](/install/targets/images.list), pull them from their original registries to the local, then push to the target private registries. So, if you have new images, just add them to `images.list` as below:
```
images+=(
  # istio
  istio/citadel:1.2.2
  istio/galley:1.2.2
  istio/kubectl:1.2.2
  ...

  # istio demo: bookinfo
  istio/examples-bookinfo-details-v1:1.12.0
  istio/examples-bookinfo-productpage-v1:1.12.0
  istio/examples-bookinfo-ratings-v1:1.12.0
  ...

  # add your own images here
  morningspace/docker-registry-cli
  busybox
)
```

Then, re-launch the target `registry` to update registries, so that newly added images can be pulled and consumed by your cluster.

## Run in offline mode

As I mentioned earlier, if we setup private registries to store all images required to launch the cluster, you can even run the cluster in offline mode! By default, most of the pre-defined private registries have been launched to mimic their public peers such as `k8s.gcr.io`, `gcr.io`, `quay.io`. You can also run below command to launch a specific private registry to mimic [Docker Hub](https://hub.docker.com).
```shell
$ launch registry::docker.io
```

After it's finished, you can turn off your network completely, then re-launch some targets such as `kubernetes` to bring the cluster back in offline mode, e.g. let's re-launch kubernetes with helm installed as below:
```
$ launch kubernetes helm
```

Also check below demo: Re-launch cluster in offline mode. In this demo, I turned Wi-Fi off on my laptop, then logged into the provisioned box, and run `launch kubernetes helm` specifically to re-install Kubernetes and Helm.

![](demo-offline.gif)

## Use proxy registries

To have all private registries co-located with your cluster in the same box makes it simple to maintain and easy to port, but in some cases, you may want your registries to be accessed externally, e.g. can be shared among multiple boxes on the same machine with different clusters, or shared among multiple developers' machines as team-level registries. This can be done by launching a target called `registry-proxy` to replace the target `registry`.

For example, let's go to the project root and run below command to provision the private registries first:
```shell
$ LAB_HOME=`pwd` K8S_VERSION=v1.15 ./install/launch.sh registry
```

You may notice that we are actually launching target outside the box. That's true, targets can be launched outside the box! Please check ["Run outside the box"](#run-outside-the-box) for details. Here, we use `LAB_HOME` to specify the current working folder as project root, and use `K8S_VERSION` to specify which Kubernetes version we are referring to. 

After it's finished, you should be able to query images stored on these registries by `curl` as below:
```shell
$ curl 127.0.0.1:5000/v2/_catalog
```

Now, we are going to share these registries to our cluster run within the box. Go into the box and run below command to stop the existing registries first:
```shell
$ launch registry::down
```

You may notice that here we append `::` then `down` when launch `registry`. This is going to call the command `down` of target `registry`. Some targets may support commands, please check ["Target Launch Reference"](Target-Launch-Reference.md) for details.

After it's finished, we then launch the same set of registries as proxies using target `registry-proxy`. This will delegate all image pull requests to the remote peers outside the box:
```shell
$ launch registry-proxy
```

After images are pulled and stored at local, next time when we pull these images, it will load them from local storage without making any remote call.

## Run outside the box

If you prefer to launching the cluster on your local machine rather than in the box, it's easy, because most of the targets can be launched on your local machine directly!

For example, to setup private registries first, then launch cluster on your local machine, you can go to the project root, and run below command:
```shell
LAB_HOME=`pwd` K8S_VERSION=v1.14 ./install/launch.sh registry kubernetes
```

Other than `LAB_HOME` and `K8S_VERSION` that we have already explained, there are also some other useful environment variables that can be configured to customize the launch. Please check ["Customize the launch"](#customize-the-launch) for details.

## Customize the launch

By going through the previous sections, we've known how to use command `launch` to customize the box after it is provisioned.

There are also quite a few settings defined in [Vagrantfile](/Vagrantfile) for you to tune the box when it is being provisioned, e.g. you can specify the Kubernetes version, number of cluster nodes, the IP address of the box, etc. They are all self-explained as below:

```ruby
# set number of vcpus
cpus = '6'
# set amount of memory allocated by vm
memory = '8192'

# targets to be run, can be customized as your need
targets = "default helm tools"

# set Kubernetes version, supported versions: v1.12, v1.13, v1.14, v1.15
k8s_version = "v1.14"
# set number of worker nodes
num_nodes = 2
# set host ip of the box
host_ip = '192.168.56.100'

# special optimization for users in China, 1 or 0
is_in_china = 0
# set https proxy
https_proxy = ""
```

Notes:

* The setting `targets` is used to customize the launch process during the box being provisioned. See ["Target Launch Reference"](Target-Launch-Reference.md) for details.
* Settings started from `k8s_version` are not only applicable when the box is being provisioned, but also can be used as environment variables when run `launch` command after the box is provisioned. Just convert the setting name to uppercase. That becomes the environment variable name, e.g. for setting `num_nodes`, its environment variable is `NUM_NODES`.
* The setting `is_in_china` or the environment variable `IS_IN_CHINA` is specific to users in China who may not have network access to some sites required by Kubernetes when launch the cluster, e.g. by default, images from `k8s.gcr.io` and `gcr.io` are not accessible; the default google charts repository for helm installation is also not accessible. There are some special optimizations to handle these cases if we set `is_in_china` to 1.

## Stop the box

Finally, when you finish your work in the box or want to swith to other work, you can run below command to suspend the box:
```shell
$ vagrant suspend
```

Next time when you go back to the box, run below command to resume it:
```shell
$ vagrant resume
```

You can also destroy the box if it's not needed anymore:
```shell
$ vagrant destroy
```

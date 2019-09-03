# Quick Guide to Launch APIC Playground

This guide will work you through the steps to launch [IBM API Connect(APIC)](https://www.ibm.com/support/knowledgecenter/en/SSMNED_2018/mapfiles/getting_started.html) on top of the all-in-one Kubernetes playground for a cluster with 3 worker nodes on a single machine!

## Step 1. Prepare the playground

Clone the playground repository, go into the repository root directory, run command to init the environment, reload `.bashrc` to enable bash completion and other features in current login session, then switch to git branch `apic`:
```shell
$ git clone https://github.com/morningspace/lab-k8s-playground.git
$ cd lab-k8s-playground
$ ./install/launch.sh init
$ . ~/.bashrc
$ git checkout apic
```

## Step 2. Prepare apic installation packages

Download apic installation packages into `$LAB_HOME/install/.launch-cache/apic` including all Docker images and the `apicup` executable required when install apic, e.g.:
```shell
$ ls -1 $LAB_HOME/install/.launch-cache/apic/
analytics-images-kubernetes_lts_v2018.4.1.4.tgz
apicup-linux_lts_v2018.4.1.4
idg_dk2018414.lts.nonprod.tar.gz
management-images-kubernetes_lts_v2018.4.1.4.tgz
portal-images-kubernetes_lts_v2018.4.1.4.tgz
```

Here, `$LAB_HOME` refers to the repository root directory.

## Step 3. Review and change apic settings

Specify k8s version, number of worker nodes, host IP, apic hostnames and other settings as needed, e.g.:
```shell
$ export K8S_VERSION=v1.15
$ export NUM_NODES=3 # Number of worker nodes, must be 3
$ export HOST_IP=<your_host_ip> # The IP of the host running apic
$ vi $LAB_HOME/install/targets/apic/settings.sh # Change hostnames, etc.
```

You can set `apic_skip_load_images` to `1` in `settings.sh` after the first launch, to skip the step of loading apic images into local private registry because you don't have to repeat that if the registry has already been provisioned. To skip this can make the launch faster.

If you are interested in apic settings customization, please check [Appendix: Customize apic settings](#appendix-customize-apic-settings)

## Step 4. Launch kubernetes, helm, and apic

```shell
$ launch default helm apic
```

It takes time to finish the launch which depends on your system configuration, e.g., on my virtual machine, it usually takes less than 15 minutes to finish all the work before I can use.

If you want to destroy the current cluster for whatever reason and re-launch a new one, please run below command:
```shell
$ launch registry::up kubernetes helm apic
```

## Step 5. Expose apic endpoints

You can expose apic endpoints outside the cluster:
```shell
$ launch apic::portforward
```

You can also add the host IP and hostname mapping into `/etc/hosts` on your local machine so that you can access apic UI from web browser. e.g.:
```shell
$ cat /etc/hosts
...
<your_host_ip>   cm.morningspace.com gwd.morningspace.com gw.morningspace.com padmin.morningspace.com portal.morningspace.com ac.morningspace.com apim.morningspace.com api.morningspace.com
```

## Appendix: Customize apic settings

All apic settings files can be found at `$LAB_HOME/install/targets/apic`. It includes a few `pv-*.yml` files used to create the persistence volumes before you launch apic, and `settings.sh` to configure apic hostnames and required memory or volume size.

When finish the customization, you can run below command to review the changes:
```shell
$ launch apic::validate
```

In the output, you may notice some subsystems report validation failures, e.g.:
```shell
data-storage-size-gb  10    ✘  data-storage-size-gb must be 200 or greater 
```

It indicates the `data-storage-size-gb` used by `analytics` subsystem must be 200 or greater. You can ignore these failures if you are sure the specified value is sufficient for you to launch apic in your particular environment.

# Quick Guide to Launch APIC Playground

This guide will work you through the steps to launch an [IBM API Connect(APIC)](https://www.ibm.com/support/knowledgecenter/en/SSMNED_2018/mapfiles/getting_started.html) playground in a Kubernetes cluster with 3 worker nodes on a single machine.

## Step 1. Prepare the playground

```shell
$ git clone https://github.com/morningspace/lab-k8s-playground.git
$ cd lab-k8s-playground
$ export LAB_HOME=`pwd`
$ git checkout apic
```

## Step 2. Prepare apic installation packages

Download apic installation packages into `$LAB_HOME/install/.lab-k8s-cache/apic` including all apic Docker images and the `apicup` executable, e.g.:
```shell
$ ls -1 $LAB_HOME/install/.lab-k8s-cache/apic/
analytics-images-kubernetes_lts_v2018.4.1.4.tgz
apicup-linux_lts_v2018.4.1.4
idg_dk2018414.lts.nonprod.tar.gz
management-images-kubernetes_lts_v2018.4.1.4.tgz
portal-images-kubernetes_lts_v2018.4.1.4.tgz
```

## Step 3. Review and change apic settings

Specify k8s version, number of worker nodes, host IP, apic hostnames, e.g.:
```shell
$ export K8S_VERSION=v1.14
$ export NUM_NODES=3 # must be 3
$ export HOST_IP=<your_host_ip>
$ vi $LAB_HOME/install/targets/apic/settings.sh # modify hostnames
```

You can set `apic_skip_load_images` to `1` in `settings.sh` after the first launch to skip the step of loading apic images into private registry because you don't have to repeat it after the registry has been provisioned. Skipping this can make the launch faster.

For more customization on apic configuration, please check [Appendix: Customize apic configuration](#appendix-customize-apic-configuration)

## Step 4. Launch kubernetes, helm, and apic

```shell
$ ./install/launch.sh default helm apic
```

It takes time to finish the launch which depends on your system configuration, e.g., on my virtual machine, it usually takes less than 20 minutes to finish all the work before I can use.

If you want to destroy the current cluster for whatever reason and re-launch a new one, just re-run the above command.

## Step 5. Expose apic endpoints

```shell
$ ./install/launch.sh apic::portforward
```

You can also add your host IP and hostname mapping into `/etc/hosts` on your local machine so that you can access apic UI in web browser. e.g.:
```shell
$ cat /etc/hosts
...
<your_host_ip>   cm.morningspace.com gwd.morningspace.com gw.morningspace.com padmin.morningspace.com portal.morningspace.com ac.morningspace.com apim.morningspace.com api.morningspace.com
```

## Appendix: Customize apic configuration

All apic configuration files can be found at `$LAB_HOME/install/targets/apic`. It includes a few `pv-*.yml` files used to create the persistence volumes before you launch apic, and `settings.sh` to configure apic hostnames and required memory or volume size.

When finish the customization, you can run below command to review the change:
```shell
$ ./install/launch.sh apic::validate
```

In the output, you may notice some subsystems report validation failures, e.g.:
```shell
data-storage-size-gb  10    ✘  data-storage-size-gb must be 200 or greater 
```

It indicates that the `data-storage-size-gb` used by `analytics` subsystem must be 200 or greater. You can ignore these failures if you are sure the specified value is sufficient for you to launch apic in your particular environment.

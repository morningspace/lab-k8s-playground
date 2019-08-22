# IBM API Connect Getting Started

In this guide, you will know how to install [IBM API Connect(APIC)](https://www.ibm.com/support/knowledgecenter/en/SSMNED_2018/mapfiles/getting_started.html) to a Kubernetes cluster with 3 worker nodes typically on a single machine using Docker-in-Docker technology.

## Prepare environment

First, manually download the installation packages into `$HOME/.lab-k8s-cache/apic`. It includes packaged images for all APIC subsystems and the `apicup` executable. The launch utility will use them to install APIC, e.g.:
```shell
$ ls -1 ~/.lab-k8s-cache/apic/
analytics-images-kubernetes_lts_v2018.4.1.4.tgz
apicup-linux_lts_v2018.4.1.4
idg_dk2018414.lts.nonprod.tar.gz
management-images-kubernetes_lts_v2018.4.1.4.tgz
portal-images-kubernetes_lts_v2018.4.1.4.tgz
```

Next, check the number of worker nodes:
```shell
$ printenv NUM_NODES
2
```

This playground requires 3 worker nodes. You need to update it if it's not the right value:
```shell
$ export NUM_NODES=3
```

As long as you update `NUM_NODES`, run below command to re-launch the Kubernetes cluster then install Helm since you have changed the cluster topology:
```shell
$ launch kubernetes helm
```

## Launch APIC

After the cluster is started, it's quite simple to launch APIC. You just need to run below command:
```shell
$ launch apic
```

Then, the launch utility will handle all the underlying dirty work for you. It will probably take a bit long time to finish the installation process which depends on your virtual or bare machine configuration, e.g., on my virtual machine, it usually takes less than 15 minutes to finish all the work before I can use it.

After APIC is launched, run below command to forward the APIC port, so that you can access it via web browser.
```shell
$ launch apic::portforward
```

Before you access, add the IP hostname mapping in your `etc/hosts`. e.g.:
```shell
192.168.56.100   cm.morningspace.com gwd.morningspace.com gw.morningspace.com padmin.morningspace.com portal.morningspace.com ac.morningspace.com apim.morningspace.com api.morningspace.com
```

Here, `192.168.56.100` is the IP address of the machine that runs the Kubernetes cluster. Then, the hostname and its aliases which are all configurable. Please check [Customize Configuration](#customize-configuration) to learn how to configure hostnames for each subsystem.

## Customize Configuration

All APIC configuration files can be found at `$LAB_HOME/install/targets/apic`. It includes the pv-*.yml files used to create the pre-defined persistence volumes before you launch APIC. But the only configuration file that you may care about is `settings.sh`. It includes the hostname settings for all APIC subsystems and the required memory or volume size. e.g.
```shell
platform_api=api.morningspace.com
api_manager_ui=apim.morningspace.com
cloud_admin_ui=cm.morningspace.com
consumer_api=consumer.morningspace.com
```

This is the pre-defined hostnames for `management` subsystem. You can change the default values as needed. You can also change the memory or volume size as well:
```shell
cassandra_max_memory_gb=4
cassandra_volume_size_gb=5
```

After you finish the change, you can run below command to revisit and validate all configuration:
```shell
$ launch apic::validate
```

In the output, you may notice some subsystems report validation failures, e.g.:
```shell
data-storage-size-gb  10    ✘  data-storage-size-gb must be 200 or greater 
```

It indicates that the `data-storage-size-gb` used by `analytics` subsystem must be 200 or greater. You can ignore such failures if you are sure the specified value is sufficient for you to launch and use APIC in your particular environment.

Another useful configuration is `apic_skip_load_images`. This is used to control whether or not to load images into your private registry. During the APIC installation, there is a private registry used to store images that are loaded from the downloaded APIC packages. After the registry is provisioned, APIC will pull images from there, then deploy them into the cluster.

You don't have to run the step to load images into private registry every time when you launch APIC after its first privisioning. In such case, you can enable `apic_skip_load_images` as below:
```shell
apic_skip_load_images=1
```

This can make the APIC launch much faster.

## Clean up

To clean up the APIC that is launched, run below command:
```shell
$ launch apic::clean
```

This will delete all APIC deployments.

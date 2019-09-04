# Launch Utility Usage Guide

The `Launch Utility` is a set of shell scripts distributed along with the All-in-One Kubernetes Playground. It can help you launch many different targets within the playground, e.g. to start Kubernetes cluster, install kubectl, deploy Istio, etc.

## Usage

To type `launch` from command line without additional argument will display the simple usage information. Usually, it will be followed by one or more targets that are separated by space as below:
```shell
$ launch [target1] [target2] [target3] ...
```

These targets will be launched in order of appearance one by one, e.g.:
```shell
$ launch default tools istio
$ launch kubernetes
```

## Launch pre-defined targets

The `Launch Utility` supports many pre-defined targets. They are listed as below:

| Target				| Description
| ---- 					|:----
|base						| As a special target, will launch target docker, docker-compose, kubectl
|default				| As a special target, will launch target base, registry, kubernetes
|docker					| Install docker
|docker-compose	| Install docker-compose
|endpoints			| List all application endpoints available in the playground with healthiness status
|helm						| Install helm
|init						| Initialize the playground environment
|istio					| Deploy istio
|istio-bookinfo	| Deploy istio demo app: bookinfo
|kubectl				| Install kubectl
|kubernetes			| Manipulate kubernetes cluster
|registry				| Manipulate private container registries
|registry-proxy	| Manipulate private container registries that work as proxies to connect to their remote peers
|sample					| A sample target for you to take as reference on how to write your own target
|tools					| Install kubernetes-related tools

### Target commands

Some targets may have multiple commands available for you to call, e.g. target `kubernetes` has below commands that support regular cluster manipulation:

| Command				| Description
| ---- 					|:----
|clean					| Stop the cluster and clean up the storage
|down						| Stop the cluster but do not clean up the storage
|init						| Initialize and bring up the cluster
|snapshot				| Create snapshot for current running cluster
|up							| Launch the cluster from snapshot

To call a particular command when launch a target, use the below format:
```shell
$ launch <target_name>::<command_name>
```

For example, this is to launch a cluster from snapshot:
```shell
$ launch kubernetes::up
```

For the supported commands of other targets, you can explore by yourself using the `Launch Utility` auto-completion feature, e.g.:
```shell
$ launch registry::<tab><tab>
down  init  up
```

Typing two `<tab>`s after `::` will list all available commands of target `registry`.

## Define your own target

You can even define your own target for your specific installation requirement. Each target is essentially an executable script written in shell. You can do whatever in your shell script. Just one rule for such script that runs as a target. That is to put your script in directory `$LAB_HOME/install/targets` so that can be detected by `Launch Utility`. Here, `$LAB_HOME` is the repository root directory.

Write you own target then save it. Next time when you run `launch` command, you should be able to see your target in the auto-completion list. That means it has been detected by `Launch Utility` and you can launch it now.

Optionally, you can also define commands for your target. There is a [sample target](/install/targets/sample.sh) for you to take as reference. Just follow the naming convention `<target>::<command>` to name your function which can be recognized as target command by `Launch Utility`. Function that does not follow this naming convention will be treated as normal function.

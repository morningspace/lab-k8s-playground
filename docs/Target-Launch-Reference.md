# Target Launch Reference

## Launch targets

The `launch` utility supports many pre-defined targets. The below list includes all available targets and their descriptions:

| Target				| Description
| ---- 					|:----
|base						| As an alias to a group of targets, it will launch target docker, docker-compose, and kubectl
|default				| As an alias to a group of targets, it will launch target base, registry, and kubernetes
|docker					| Handle docker installation
|docker-compose	| Handle docker-compose installation
|docker.io			| Launch a secured private registry to mimic Docker Hub
|docker.io.proxy| Launch a secured private registry to mimic Docker Hub and work as a proxy that connects to its remote peer
|endpoints			| Print all endpoints that can be accessed in web browser with their healthiness states
|helm						| Handle helm installation
|istio					| Handle istio installation
|istio-bookinfo	| Handle istio demo app, bookinfo, installation
|kubectl				| Handle kubectl installation
|kubernetes			| Manipulate kubernetes cluster launch
|registry				| Launch a group of private registries provisioned with images used by the cluster
|registry-proxy	| Launch a group of private registries to work as proxies that connect to their remote peers
|tools					| Handle kubernetes related tools installation

## Run target commands

Some targets may have multiple commands available for you to call, e.g. target `kubernetes` has below commands that support regular cluster manipulation:

| Command				| Description
| ---- 					|:----
|clean					| Stop the cluster and clean up the storage
|down						| Stop the cluster but do not clean up the storage
|init						| Initialize and bring up the cluster
|snapshot				| Create a snapshot for current cluster and save to the storage
|up							| Bring up a stopped cluster

Other targets may have their own commands as well. The `launch` utility has enabled auto-completion by default in the box, so you can explore target commands by yourself using auto-completion, e.g.:
```shell
$ launch registry::<tab><tab>
down  init  up
```

Append `::` after the target name, it will list all available commands of that target. To run the command, complete the command name either by auto-completion or manually.

## Define your own target

You can even define your own target for your specific installation requirement. Each target is actually an executable script written in shell. They are all saved in `$LAB_HOME/install/targets`. Here, `$LAB_HOME` is the root folder of this project.

Write you own target, save as a shell script into `/install/targets` folder, then you should be able to launch it immediately. To see it in `launch` auto-completion, you may need to re-login to the box.

You can also add commands to the target. There is a [sample target](/install/targets/sample.sh) for you to take as reference. Just follow the sample target, use the naming convention `<target>::<command>` to name your functions. These functions will be recognized as target commands by `launch` utility and be appeared in `launch` auto-completion.

#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install

# base targets
base=(
  "docker"
  "docker-compose"
  "kubectl"
)

# default targets
default=(
  "docker"
  "docker-compose"
  "kubectl"
  "registry"
  "kubernetes"
)

if [[ $# == 0 ]]; then
  cat << EOF

Usage: launch [targets]

  Targets are separated by space and launch in order of appearance one by one.

  Special pre-defined targets:
  * base      will launch target docker, docker-compose, and kubectl
  * default   will launch target base, registry, and kubernetes

  e.g.
  launch default tools istio
  launch kubernetes

EOF
  exit
fi

# resolve targets
for target in $@ ; do
  if [ $target == "base" ]; then
    targets+=(${base[@]})
  elif [ $target == "default" ]; then
    targets+=(${default[@]})
  else
    targets+=($target)
  fi
done

# launch targets
echo "Targets to be launched: [${targets[@]}]"
start_time=$SECONDS
for target in ${targets[@]} ; do
  command=${target/#*::}
  target=${target/%::*}
  [[ $target == $command ]] && command=""
  echo "####################################"
  echo "# Launch target $target..."
  echo "####################################"
  target_shell="$INSTALL_HOME/targets/$target.sh"
  if [[ -f $target_shell ]]; then
    LAB_HOME=$LAB_HOME $target_shell $command
  else
    echo "$target_shell not found"
  fi
done
elapsed_time=$(($SECONDS - $start_time))
echo "Total elapsed time: $elapsed_time seconds"

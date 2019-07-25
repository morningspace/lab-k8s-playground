#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install

# configure lab cache
mkdir -p $INSTALL_HOME/.lab-k8s-cache
ln -sf $INSTALL_HOME/.lab-k8s-cache $HOME/.lab-k8s-cache

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

  Pre-defined targets:
  * base      will launch docker docker-compose kubectl
  * default   will launch base registry kubernetes

  e.g.
  launch default tools istio
  launch kubernetes

EOF
  exit
fi

# resolve targets
if [[ $1 == base ]]; then
  targets=${base[@]}
  targets+=(${@:2})
elif [[ $1 == default ]]; then
  targets=${default[@]}
  targets+=(${@:2})
else
  targets=$@
fi

# launch targets
echo "* targets to be launched: [${targets[@]}]"
for target in ${targets[@]} ; do
  echo "####################################"
  echo "# Launch target $target..."
  echo "####################################"
  target_shell="$INSTALL_HOME/targets/$target.sh"
  if [[ -f $target_shell ]]; then
    $target_shell
  else
    echo "* $target_shell not found"
  fi
done

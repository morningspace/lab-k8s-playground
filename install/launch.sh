#!/bin/bash

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

  Targets are separated by space, e.g. helm tools istio, and launch in order of appearance one by one.
  The pre-defined target default will launch targets: docker docker-compose kubectl registry kubernetes.

  e.g.
  launch default tools istio
  launch kubernetes

EOF
  exit
fi

if [[ $1 == default ]]; then
  targets=${default[@]}
  targets+=(${@:2})
else
  targets=$@
fi

# Launch targets
echo "* targets to be launched: [${targets[@]}]"
for target in ${targets[@]} ; do
  echo "####################################"
  echo "# Launch target $target..."
  echo "####################################"
  target_shell="/vagrant/install/targets/$target.sh"
  if [[ -f $target_shell ]]; then
    $target_shell
  else
    echo "* $target_shell not found"
  fi
done

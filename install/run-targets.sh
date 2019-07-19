#!/bin/bash

# targets to be run
targets=(
  "docker"
  "docker-compose"
  "kubectl"
  "registry"
  "kubernetes"
)

case $1 in
"-a")
  targets+=(${2//,/ });;
"-t")
  targets=(${2//,/ });;
*)
  cat << EOF

Usage: run-targets <options> [targets]
    -a    Run all default and additional targets if specified one by one,
          targets are separated by commas, e.g. helm,tools,istio.
    -t    Run specific targets.
    -h    Print this help.

EOF
  exit
esac

# Run targets
echo "* targets to be run: [${targets[@]}]"
for target in ${targets[@]} ; do
  echo "####################################"
  echo "# Run target $target..."
  echo "####################################"
  target_shell="/vagrant/install/targets/$target.sh"
  if [[ -f $target_shell ]]; then
    $target_shell
  else
    echo "* $target_shell not found"
  fi
done

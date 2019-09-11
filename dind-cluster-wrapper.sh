#!/bin/bash

env_vars=()

function env() {
  local env_var=$1
  env_vars+=($env_var)
  eval "if [[ -z \${$env_var+set} ]]; then $env_var=$2; fi"
}

function envs() {
  for env_var in "${env_vars[@]}" ; do
    eval "echo $env_var=\$$env_var"
  done
}

script_home=$(cd -P "$(dirname "$0")" && pwd)
script_name="dind-cluster.sh"
script_dir="$script_home/install/$script_name"
script_baseurl="https://raw.githubusercontent.com/kubernetes-sigs/kubeadm-dind-cluster"

function install_script() {
  local script force=$1
  for script in "$script_name" "config.sh" ; do
    local script_dir="$script_home/install/$script"
    local script_url="$script_baseurl/master/$script"
    if [[ ! -f $script_dir || -n $force ]] ; then
      echo "Download $script ..."
      curl -sSL $script_url -o $script_dir
      [ $? != 0 ] && exit 1
      chmod +x $script_dir
    fi
  done
}

function run_script() {
  start_time=$SECONDS
  . $script_dir
  elapsed_time=$(($SECONDS - $start_time))
  echo "Total elapsed time: $elapsed_time seconds"
}

#################################################

# Kubernetes version
env DIND_K8S_VERSION ${K8S_VERSION:-v1.14}
env DIND_COMMIT 62f5a9277678777b63ae55d144bd2f99feb7c824

# Build Kubernetes from source
env BUILD_KUBEADM
env BUILD_HYPERKUBE

# Customize Kubernetes Dashboard
DASHBOARD_BASEURL="https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy"
env DASHBOARD_URL ${DASHBOARD_BASEURL}/recommended/kubernetes-dashboard.yaml
# env DASHBOARD_URL ${DASHBOARD_BASEURL}/alternative/kubernetes-dashboard.yaml
env SKIP_DASHBOARD

# To have kubeadm-dind-cluster join custom networks, separated by comma
env DIND_CUSTOM_NETWORKS net-registries
# To use insecure private Docker registries for kubeadm to pull images from there
env DIND_INSECURE_REGISTRIES '"[\"k8s.gcr.io\", \"gcr.io\", \"quay.io\", \"mr.io:5000\"]"'

# To skip pull of image kubeadm-dind-cluster
env DIND_SKIP_PULL
# To skip snapshot
env SKIP_SNAPSHOT
#
env NUM_NODES
#
env HOST_IP

#################################################

if [[ $1 == 'env' ]] ; then
  envs
elif [[ $1 == 'install' ]] ; then
  install_script 1
else
  install_script

  if [[ -z $1 ]] ; then
    echo "prepare:" >&2
    echo "  $0 env" >&2
    echo "  $0 install" >&2
  fi

  run_script $@
fi

#!/bin/bash

env_vars=()

function env() {
  env_vars+=($1)
  eval "$1=\${$1:-$2}"
}

function envs() {
  for env_var in "${env_vars[@]}" ; do
    eval "echo $env_var=\$$env_var"
  done
}

script_home=$(cd -P "$(dirname "$0")" && pwd)
script_name="dind-cluster.sh"
script_dir="$script_home/$script_name"
script_baseurl="https://raw.githubusercontent.com/morningspace/kubeadm-dind-cluster"

function install_script() {
  local script force=$1
  for script in "$script_name" "config.sh" ; do
    local script_dir="$script_home/$script"
    local script_url="$script_baseurl/master/$script"
    if [[ ! -f $script_dir || -n $force ]] ; then
      echo "Download $script ..."
      curl -sSLO $script_url
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
env DIND_K8S_VERSION v1.13
env DIND_COMMIT 76f7b8a5f3966aa80700a8c9f92d23f6936f949b

# Build Kubernetes from source
env BUILD_KUBEADM
env BUILD_HYPERKUBE

# Customize Kubernetes Dashboard
DASHBOARD_BASEURL="https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy"
env DASHBOARD_URL ${DASHBOARD_BASEURL}/recommended/kubernetes-dashboard.yaml
# env DASHBOARD_URL ${DASHBOARD_BASEURL}/alternative/kubernetes-dashboard.yaml
env SKIP_DASHBOARD 1

# To have kubeadm-dind-cluster join custom networks, separated by comma
env DIND_CUSTOM_NETWORKS net-registry
# To use insecure private Docker registries for kubeadm to pull images from there
env DIND_INSECURE_REGISTRIES '"[\"k8s.gcr.io\", \"gcr.io\", \"mirantis\", \"mr.io\"]"'

# To skip pull of image kubeadm-dind-cluster
env DIND_SKIP_PULL 1
# To skip snapshot
env SKIP_SNAPSHOT

#################################################

if [[ $1 == 'env' ]] ; then
  envs
elif [[ $1 == 'install' ]] ; then
  install_script 1
else
  install_script
  run_script $@
fi

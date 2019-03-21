#!/bin/bash

# Kubernetes version
DIND_K8S_VERSION=${DIND_K8S_VERSION:-v1.13}
DIND_COMMIT=${DIND_COMMIT:-76f7b8a5f3966aa80700a8c9f92d23f6936f949b}

# Build Kubernetes from source
BUILD_KUBEADM=${BUILD_KUBEADM:-}
BUILD_HYPERKUBE=${BUILD_HYPERKUBE:-}

# Customize Kubernetes Dashboard URL
DASHBOARD_BASE_URL="https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy"
DASHBOARD_URL="${DASHBOARD_BASE_URL}/recommended/kubernetes-dashboard.yaml"
# DASHBOARD_URL="${DASHBOARD_BASE_URL}/alternative/kubernetes-dashboard.yaml"
# To skip Kubernetes Dashboard deployment
SKIP_DASHBOARD=${SKIP_DASHBOARD:-1}

# To have kubeadm-dind-cluster join custom networks, separated by comma
DIND_CUSTOM_NETWORKS=${DIND_CUSTOM_NETWORKS:-net-registry}
# To use insecure private Docker registries for kubeadm to pull images from there
DIND_INSECURE_REGISTRIES=${DIND_INSECURE_REGISTRIES:-'["k8s.gcr.io", "gcr.io", "mirantis", "mr.io"]'}

# To skip pull of image kubeadm-dind-cluster
DIND_SKIP_PULL=1

# To skip snapshot
# SKIP_SNAPSHOT=1

#################################################

function log_env() {
  echo "DIND_K8S_VERSION=$DIND_K8S_VERSION"
  echo "BUILD_KUBEADM=$BUILD_KUBEADM"
  echo "BUILD_HYPERKUBE=$BUILD_HYPERKUBE"
  echo "DASHBOARD_URL=$DASHBOARD_URL"
  echo "SKIP_DASHBOARD=$SKIP_DASHBOARD"
  echo "DIND_CUSTOM_NETWORKS=$DIND_CUSTOM_NETWORKS"
  echo "DIND_INSECURE_REGISTRIES=$DIND_INSECURE_REGISTRIES"
  echo "DIND_SKIP_PULL=$DIND_SKIP_PULL"
  echo "SKIP_SNAPSHOT=$SKIP_SNAPSHOT"
}

SCRIPT_HOME=$(cd -P "$(dirname "$0")" && pwd)
SCRIPT_BASEURL="https://raw.githubusercontent.com/morningspace/kubeadm-dind-cluster"

function load_script() {
  local script_name
  for script_name in "$@" ; do
    local script_dir="$SCRIPT_HOME/$script_name"
    local script_url="$SCRIPT_BASEURL/master/$script_name"

    if [ ! -f $script_dir ] ; then
      echo "Download $script_name ..."
      curl -sSL $script_url > $script_dir
      chmod +x $script_dir
    fi
  done
}

function run_script() {
  local script_name="dind-cluster.sh"
  load_script $script_name "config.sh"

  local script_dir="$SCRIPT_HOME/$script_name"

  echo "Run $script_name ..."
  start_time=$SECONDS
  . $script_dir
  elapsed_time=$(($SECONDS - $start_time))
  echo "Total elapsed time: $elapsed_time seconds"
}

if [[ $1 == 'env' ]] ; then
  log_env
else
  run_script $@
fi

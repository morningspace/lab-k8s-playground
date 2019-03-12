#!/bin/bash

DIND_K8S_VERSION="${DIND_K8S_VERSION:-1.13}"
DIND_SCRIPT="dind-cluster-v$DIND_K8S_VERSION.sh"
DIND_SCRIPT_URL="https://raw.githubusercontent.com/morningspace/kubeadm-dind-cluster/master/fixed/$DIND_SCRIPT"

#################################################
# Customize Kubernetes Dashboard URL
DASHBOARD_BASE_URL="https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy"
DASHBOARD_URL="${DASHBOARD_BASE_URL}/recommended/kubernetes-dashboard.yaml"
# DASHBOARD_URL="${DASHBOARD_BASE_URL}/alternative/kubernetes-dashboard.yaml"

# To skip Kubernetes Dashboard deployment
DIND_SKIP_DASHBOARD=1

# To have kubeadm-dind-cluster join custom networks, separated by comma
DIND_CUSTOM_NETWORK=net-registry

# To use insecure private Docker registries for kubeadm to pull images from there
DIND_INSECURE_REGISTRIES='["k8s.gcr.io", "gcr.io", "mirantis", "mr.io"]'

# To skip pull of image kubeadm-dind-cluster
# DIND_SKIP_PULL=1

# To skip download of kubectl
# DOWNLOAD_KUBECTL=0

#################################################
# Run the shell script
if [ ! -f ./$DIND_SCRIPT ] ; then
  curl -sSL "$DIND_SCRIPT_URL" > ./$DIND_SCRIPT
  chmod +x ./$DIND_SCRIPT
fi

if [ -f ./$DIND_SCRIPT ] ; then
  echo "$0: (info) run $DIND_SCRIPT ..."
  echo "  DASHBOARD_URL=$DASHBOARD_URL"
  echo "  DIND_SKIP_DASHBOARD=$DIND_SKIP_DASHBOARD"
  echo "  DIND_CUSTOM_NETWORK=$DIND_CUSTOM_NETWORK"
  echo "  DIND_INSECURE_REGISTRIES=$DIND_INSECURE_REGISTRIES"
  echo "  DIND_SKIP_PULL=$DIND_SKIP_PULL"
  echo "  DOWNLOAD_KUBECTL=$DOWNLOAD_KUBECTL"
  . ./$DIND_SCRIPT
else
  echo "$0: (error) $DIND_SCRIPT not found"
fi

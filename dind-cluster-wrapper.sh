#!/bin/bash

K8S_VERSION="1.13"
DIND_SCRIPT="dind-cluster-v$K8S_VERSION.sh"
DIND_SCRIPT_URL="https://raw.githubusercontent.com/morningspace/kubeadm-dind-cluster/master/fixed/$DIND_SCRIPT"

[[ ! -f ./$DIND_SCRIPT ]] && curl -sSL "$DIND_SCRIPT_URL" > ./$DIND_SCRIPT && chmod +x ./$DIND_SCRIPT

DASHBOARD_BASE_URL="https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy"
export DASHBOARD_URL="${DASHBOARD_BASE_URL}/recommended/kubernetes-dashboard.yaml"
# export DASHBOARD_URL="${DASHBOARD_BASE_URL}/alternative/kubernetes-dashboard.yaml"
export DIND_SKIP_DASHBOARD=1

# export DIND_INSECURE_REGISTRIES="[\"k8s.gcr.io\", \"gcr.io\", \"mirantis\", \"mr.io\"]"
# export DIND_CUSTOM_NETWORK=net-registry

# export DIND_SKIP_PULL=1

./$DIND_SCRIPT $@

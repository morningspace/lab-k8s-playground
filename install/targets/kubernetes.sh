#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

function init {
  ensure_k8s_version || exit

  if [[ ! -f ~/.lab-k8s-cache/kubernetes-dashboard.yaml ]]; then
    download_url=https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/alternative/kubernetes-dashboard.yaml
    curl -sL $download_url -o ~/.lab-k8s-cache/kubernetes-dashboard.yaml
  fi

  DIND_REGISTRY_MIRROR=http://docker.io.local
  DASHBOARD_URL=$HOME/.lab-k8s-cache/kubernetes-dashboard.yaml
  SKIP_SNAPSHOT=1

  if ensure_box; then
    cat /etc/environment | grep -q "^# for kubeadm-dind-clusters$" || \
    cat << EOF | sudo tee -a /etc/environment
# for kubeadm-dind-clusters
export DIND_REGISTRY_MIRROR=$DIND_REGISTRY_MIRROR
export DASHBOARD_URL=$DASHBOARD_URL
export SKIP_SNAPSHOT=$SKIP_SNAPSHOT
EOF
  fi

  pushd $LAB_HOME

  sudo \
    DIND_K8S_VERSION=$DIND_K8S_VERSION \
    NUM_NODES=$NUM_NODES \
    DIND_HOST_IP=$DIND_HOST_IP \
    DIND_REGISTRY_MIRROR=$DIND_REGISTRY_MIRROR \
    DASHBOARD_URL=$DASHBOARD_URL \
    SKIP_SNAPSHOT=$SKIP_SNAPSHOT \
  ./dind-cluster-wrapper.sh up

  if [[ $? == 0 ]]; then
    sudo chown -R $USER ~/.kube

    cat <<EOF | kubectl replace -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
EOF
  fi

  popd
}

function run {
  pushd $LAB_HOME
  SKIP_SNAPSHOT= ./dind-cluster-wrapper.sh $1
  popd
}

command=${1:-init}

case $command in
  "init") init;;
  "up") run up;;
  "down") run down;;
  "clean") run clean;;
  "snapshot") run snapshot;;
  *) echo "* unkown command";;
esac

#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

function kubernetes::init {
  if [[ ! -f ~/.launch-cache/kubernetes-dashboard.yaml ]]; then
    target::step "Download kubernetes dashboard yaml"
    download_url=https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/alternative/kubernetes-dashboard.yaml
    curl -sSL $download_url -o ~/.launch-cache/kubernetes-dashboard.yaml
  fi

  DIND_CUSTOM_VOLUMES=$INSTALL_HOME/certs:/certs
  DIND_CA_CERT_URL=file:////certs/lab-ca.pem.crt
  DASHBOARD_URL=$HOME/.launch-cache/kubernetes-dashboard.yaml
  SKIP_SNAPSHOT=1

  if ! cat ~/.bashrc | grep -q "^# For kubeadm-dind-clusters$" ; then
    target::step "Update .bashrc"
    cat << EOF >> ~/.bashrc

# For kubeadm-dind-clusters
export DIND_CUSTOM_VOLUMES=$DIND_CUSTOM_VOLUMES
export DIND_CA_CERT_URL=$DIND_CA_CERT_URL
export DASHBOARD_URL=$DASHBOARD_URL
export SKIP_SNAPSHOT=$SKIP_SNAPSHOT
EOF
  fi

  pushd $LAB_HOME

  target::step "Start to init kubernetes cluster"
  [ $(uname -s) == "Linux" ] && run_cmd="sg docker -c" || run_cmd="eval"
  $run_cmd \
   "K8S_VERSION=$K8S_VERSION \
    NUM_NODES=$NUM_NODES \
    HOST_IP=$HOST_IP \
    DIND_CUSTOM_VOLUMES=$DIND_CUSTOM_VOLUMES \
    DIND_CA_CERT_URL=$DIND_CA_CERT_URL \
    DASHBOARD_URL=$DASHBOARD_URL \
    SKIP_SNAPSHOT=$SKIP_SNAPSHOT \
  ./dind-cluster-wrapper.sh up"

  if [[ $? == 0 ]]; then
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

function kubernetes::up {
  target::step "Take kubernetes cluster up"
  pushd $LAB_HOME; SKIP_SNAPSHOT= ./dind-cluster-wrapper.sh up; popd
}

function kubernetes::down {
  target::step "Take kubernetes cluster down"
  pushd $LAB_HOME; SKIP_SNAPSHOT= ./dind-cluster-wrapper.sh down; popd
}

function kubernetes::clean {
  target::step "Clean kubernetes cluster"
  pushd $LAB_HOME; SKIP_SNAPSHOT= ./dind-cluster-wrapper.sh clean; popd
}

function kubernetes::snapshot {
  target::step "Create snapshot for kubernetes cluster"
  pushd $LAB_HOME; SKIP_SNAPSHOT= ./dind-cluster-wrapper.sh snapshot; popd
}

target::command $@

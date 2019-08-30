#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

function kubernetes::init {
  if [[ ! -f ~/.lab-k8s-cache/kubernetes-dashboard.yaml ]]; then
    download_url=https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/alternative/kubernetes-dashboard.yaml
    curl -sL $download_url -o ~/.lab-k8s-cache/kubernetes-dashboard.yaml
  fi

  DIND_CUSTOM_VOLUMES=$INSTALL_HOME/certs:/certs
  DIND_CA_CERT_URL=file:////certs/lab-ca.pem.crt
  DASHBOARD_URL=$HOME/.lab-k8s-cache/kubernetes-dashboard.yaml
  SKIP_SNAPSHOT=1

  if ensure_os Linux; then
    cat /etc/environment | grep -q "^# for kubeadm-dind-clusters$" || \
    cat << EOF | sudo tee -a /etc/environment
# for kubeadm-dind-clusters
export DIND_CUSTOM_VOLUMES=$DIND_CUSTOM_VOLUMES
export DIND_CA_CERT_URL=$DIND_CA_CERT_URL
export DASHBOARD_URL=$DASHBOARD_URL
export SKIP_SNAPSHOT=$SKIP_SNAPSHOT
EOF
  fi

  pushd $LAB_HOME

  sudo -E \
    K8S_VERSION=$K8S_VERSION \
    NUM_NODES=$NUM_NODES \
    HOST_IP=$HOST_IP \
    DIND_CUSTOM_VOLUMES=$DIND_CUSTOM_VOLUMES \
    DIND_CA_CERT_URL=$DIND_CA_CERT_URL \
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

function kubernetes::up {
  pushd $LAB_HOME; SKIP_SNAPSHOT= ./dind-cluster-wrapper.sh up; popd
}

function kubernetes::down {
  pushd $LAB_HOME; SKIP_SNAPSHOT= ./dind-cluster-wrapper.sh down; popd
}

function kubernetes::clean {
  pushd $LAB_HOME; SKIP_SNAPSHOT= ./dind-cluster-wrapper.sh clean; popd
}

function kubernetes::snapshot {
  pushd $LAB_HOME; SKIP_SNAPSHOT= ./dind-cluster-wrapper.sh snapshot; popd
}

target::command $@

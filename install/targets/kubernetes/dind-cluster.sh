#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

ensure_k8s_provider "dind-cluster" || exit

function add_endpoints {
  local apiserver_port=$($INSTALL_HOME/dind-cluster.sh apiserver-port 2>/dev/null)
  local dashboard_endpoint="http://$HOST_IP:$apiserver_port/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy"
  add_endpoint "common" "Dashboard" $dashboard_endpoint
}

function dind-cluster::init {
  if [[ ! -f ~/.launch-cache/kubernetes-dashboard.yaml ]]; then
    target::step "Download kubernetes dashboard yaml"
    download_url=https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/alternative/kubernetes-dashboard.yaml
    curl -sSL $download_url -o ~/.launch-cache/kubernetes-dashboard.yaml
  fi

  DIND_CUSTOM_VOLUMES=$INSTALL_HOME/certs:/certs
  DIND_CA_CERT_URL=file:////certs/lab-ca.pem.crt
  DASHBOARD_URL=$HOME/.launch-cache/kubernetes-dashboard.yaml

  if ! cat ~/.bashrc | grep -q "^# For kubeadm-dind-clusters$" ; then
    target::step "Update .bashrc"
    cat << EOF >> ~/.bashrc

# For kubeadm-dind-clusters
export DIND_CUSTOM_VOLUMES=$DIND_CUSTOM_VOLUMES
export DIND_CA_CERT_URL=$DIND_CA_CERT_URL
export DASHBOARD_URL=$DASHBOARD_URL
EOF
  fi

  target::step "Start to init kubernetes cluster"
  if ensure_os_linux && grep -q "^docker:" /etc/group; then
    run_cmd="sg docker -c"
  else
    run_cmd="eval"
  fi  
  $run_cmd \
   "K8S_VERSION=$K8S_VERSION \
    NUM_NODES=$NUM_NODES \
    HOST_IP=$HOST_IP \
    DIND_CUSTOM_VOLUMES=$DIND_CUSTOM_VOLUMES \
    DIND_CA_CERT_URL=$DIND_CA_CERT_URL \
    DASHBOARD_URL=$DASHBOARD_URL \
    SKIP_SNAPSHOT= \
  $LAB_HOME/dind-cluster-wrapper.sh up"

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

  add_endpoints
}

function dind-cluster::up {
  target::step "Take kubernetes cluster up"
  SKIP_SNAPSHOT= $LAB_HOME/dind-cluster-wrapper.sh up; clean_endpoints "common"; add_endpoints
}

function dind-cluster::down {
  target::step "Take kubernetes cluster down"
  SKIP_SNAPSHOT= $LAB_HOME/dind-cluster-wrapper.sh down
}

function dind-cluster::clean {
  target::step "Clean kubernetes cluster"
  SKIP_SNAPSHOT= $LAB_HOME/dind-cluster-wrapper.sh clean; clean_endpoints "common"
}

function dind-cluster::snapshot {
  target::step "Create snapshot for kubernetes cluster"
  SKIP_SNAPSHOT= $LAB_HOME/dind-cluster-wrapper.sh snapshot
}

target::command $@

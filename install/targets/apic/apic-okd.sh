#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
APIC_DEPLOY_HOME=$INSTALL_HOME/targets/apic
HOST_IP=${HOST_IP:-127.0.0.1}

apic_domain="$HOST_IP.xip.io"
ingress_type="route"
my_registry="127.0.0.1:5000"
pv_type="host"
apic_pv_home="$INSTALL_HOME/.launch-cache/apic/pv/"

. $INSTALL_HOME/funcs.sh
. $APIC_DEPLOY_HOME/settings.sh
. $APIC_DEPLOY_HOME/apic-dind-cluster.sh

function ensure_nodes {
  :
}

function prepare_env {
  target::step "Prepare environment"
  oc login -u system:admin

  target::step "Create namespace $apic_ns"
  oc create namespace $apic_ns
  
  target::step "Install helm client"
  export HELM_VERSION="v2.10.0"
  export TILLER_NAMESPACE="kube-system"
  $INSTALL_HOME/targets/helm.sh --client-only
  
  target::step "Install tiller"
  oc process -f https://github.com/openshift/origin/raw/master/examples/helm/tiller-template.yaml \
    -p TILLER_NAMESPACE=$TILLER_NAMESPACE -p HELM_VERSION=$HELM_VERSION | \
  oc create -n $TILLER_NAMESPACE -f -
  oc create clusterrolebinding tiller-binding --clusterrole=cluster-admin --user=system:serviceaccount:$TILLER_NAMESPACE:tiller

  target::step "Assign SCC permissions"
  oc adm policy add-scc-to-group anyuid system:serviceaccounts:$apic_ns
}

function prepare_pv {
  target::step "Prepare apic persistent volumes"

  # mgmt
  mkdir -p $apic_pv_home/var/db
  chown 105 $apic_pv_home/var/db

  # analyt
  mkdir -p $apic_pv_home/var/lib/elasticsearch-data/
  chown 1000 $apic_pv_home/var/lib/elasticsearch-data/

  mkdir -p $apic_pv_home/var/lib/elasticsearch-master/
  chown 1000 $apic_pv_home/var/lib/elasticsearch-master/

  # ptl
  mkdir -p $apic_pv_home/var/lib/mysqldata
  chown 201 $apic_pv_home/var/lib/mysqldata

  mkdir -p $apic_pv_home/var/log/mysqllog
  chown 201 $apic_pv_home/var/log/mysqllog

  mkdir -p $apic_pv_home/web
  chown 200 $apic_pv_home/web

  mkdir -p $apic_pv_home/var/aegir/backups
  chown 200 $apic_pv_home/var/aegir/backups

  mkdir -p $apic_pv_home/var/devportal
  chown 200 $apic_pv_home/var/devportal
}

function install_ingress {
  :
}

function apic-okd::init {
  prepare_env
  apic-k8s::init
}

function apic-okd::validate {
  apic-k8s::validate
}

function apic-okd::clean {
  target::step "Delete tiller role binding"
  oc delete clusterrolebinding tiller-binding

  apic-k8s::clean

  target::step "Clean apic persistent volumes"
  rm -rf $apic_pv_home
}

target::command $@

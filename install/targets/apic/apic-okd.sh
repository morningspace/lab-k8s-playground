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
  oc login -u system:admin

  # Create namespace
  oc create namespace $apic_ns
  
  # Install Helm client
  export HELM_VERSION="v2.10.0"
  export TILLER_NAMESPACE="$apic_ns"
  $INSTALL_HOME/targets/helm.sh --client-only
  
  # Install Tiller
  oc process -f https://github.com/openshift/origin/raw/master/examples/helm/tiller-template.yaml \
    -p TILLER_NAMESPACE=$TILLER_NAMESPACE -p HELM_VERSION=$HELM_VERSION | \
  oc create -n "$apic_ns" -f -
  oc create clusterrolebinding tiller-binding --clusterrole=cluster-admin --user=system:serviceaccount:$TILLER_NAMESPACE:tiller

  # Assign SCC permissions
  oc adm policy add-scc-to-group anyuid system:serviceaccounts:$apic_ns
}

function prepare_pv {
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
  rm -rf $apic_pv_home
  oc delete clusterrolebinding tiller-binding
  apic-k8s::clean
}

target::command $@

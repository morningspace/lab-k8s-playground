#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install

apic_domain=${HOST_IP:-127.0.0.1}.xip.io
apic_pv_type=host
apic_pv_home=$INSTALL_HOME/.launch-cache/apic/pv/
apic_ingress_type=route
apic_registry=127.0.0.1:5000

. $LAB_HOME/install/targets/apic/apic-base.sh

function on_before_init {
  oc login -u system:admin >/dev/null

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

  target::step "Ensure namespace $apic_ns"

  if oc get namespace | grep -q $apic_ns ; then
    target::log "namespace $apic_ns detected"
  else
    oc create namespace $apic_ns
  fi

  target::step "Install helm client"

  export HELM_VERSION="v2.10.0"
  export TILLER_NAMESPACE="$apic_ns"
  $INSTALL_HOME/targets/helm.sh --client-only
  
  target::step "Install tiller"

  if kubectl get deploy/tiller -o name -n $TILLER_NAMESPACE 2>/dev/null | grep -q tiller; then
    target::log "Deployment tiller detected"
  else
    oc process -f https://github.com/openshift/origin/raw/master/examples/helm/tiller-template.yaml \
      -p TILLER_NAMESPACE=$TILLER_NAMESPACE -p HELM_VERSION=$HELM_VERSION | \
    oc create -n $TILLER_NAMESPACE -f -
    oc create clusterrolebinding tiller-binding --clusterrole=cluster-admin --user=system:serviceaccount:$TILLER_NAMESPACE:tiller
  fi

  target::step "Assign SCC permissions"

  oc adm policy add-scc-to-group anyuid system:serviceaccounts:$apic_ns
}

function on_after_init {
  # Management
  add_endpoint "apic" "Cloud Manager UI" "https://$cloud_admin_ui/admin" "(default usr/pwd: admin/7iron-hide)"
}

function on_before_clean {
  oc login -u system:admin >/dev/null

  target::step "Delete tiller role binding"
  local rolebinding=$(oc get clusterrolebinding tiller-binding -o name 2>/dev/null)
  [ -n "$rolebinding" ] && oc delete clusterrolebinding tiller-binding
}

function on_after_clean {
  target::step "Clean apic persistent volumes"
  rm -rf $apic_pv_home
}

function apic-okd::init {
  init
}

function apic-okd::validate {
  validate
}

function apic-okd::clean {
  clean
}

target::command $@

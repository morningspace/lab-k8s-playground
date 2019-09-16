#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}

. $LAB_HOME/install/targets/apic/apic-base.sh

function on_before_init {
  target::step "Ensure cluster nodes"

  if [[ $NUM_NODES != 3 ]]; then
    target::log "NUM_NODES must be 3, current value $NUM_NODES"
    exit 255
  fi

  target::step "Prepare apic persistent volumes"

  # gwy
  docker exec kube-node-1 mkdir -p /drouter/ramdisk2/mnt/raid-volume/raid0/local
  # mgmt
  docker exec kube-node-1 mkdir -p /var/db
  # analyt
  docker exec kube-node-2 mkdir -p /var/lib/elasticsearch
  docker exec kube-node-3 mkdir -p /var/lib/elasticsearch
  # ptl
  docker exec kube-node-2 mkdir -p /var/lib/mysqldata
  docker exec kube-node-2 mkdir -p /var/log/mysqllog
  docker exec kube-node-2 mkdir -p /web
  docker exec kube-node-2 mkdir -p /var/aegir/backups
  docker exec kube-node-2 mkdir -p /var/devportal

  target::step "Ensure namespace $apic_ns"

  if kubectl get namespace | grep -q $apic_ns ; then
    target::log "namespace $apic_ns detected"
  else
    kubectl create namespace $apic_ns
  fi

  target::step "Ensure kubectl"

  kubectl version --short 2>/dev/null | grep Client
  $INSTALL_HOME/targets/kubectl.sh --force
  kubectl version --short 2>/dev/null | grep Client
}

function on_after_init {
  target::step "Install ingress controller"

  helm upgrade -i ingress stable/nginx-ingress \
    --namespace $apic_ns \
    --values $APIC_DEPLOY_HOME/ingress-config.yml

  local ingress_svc_ip=$(kubectl get svc -n $apic_ns | grep ingress-nginx-ingress-controller | awk '{print $3}')
  local apic_hosts="\
    $apic_gw_service $api_gateway \
    $analytics_client $analytics_ingestion \
    $platform_api $api_manager_ui $cloud_admin_ui $consumer_api \
    $portal_admin $portal_www"

  cat $APIC_DEPLOY_HOME/coredns.yml | \
    sed -e "s/@@ingress_svc_ip/$ingress_svc_ip/g" | \
    sed -e "s/@@apic_hosts/$apic_hosts/g" | \
    kubectl apply -f -

  # Management
  add_endpoint "apic" "Cloud Manager UI" "https://$cloud_admin_ui" "(default usr/pwd: admin/7iron-hide)"
}

function on_before_clean {
  # Management
  clean_endpoints "apic" "Cloud Manager UI"
}

function apic-dind-cluster::init {
  init
}

function apic-dind-cluster::validate {
  validate
}

function apic-dind-cluster::clean {
  clean
}

function apic-dind-cluster::portforward {
  kill_portfwds "443:443"
  create_portfwd $apic_ns service/ingress-nginx-ingress-controller 443:443
}

target::command $@

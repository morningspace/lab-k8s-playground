#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
APIC_INSTALL_HOME=$INSTALL_HOME/.lab-k8s-cache/apic
APIC_PROJECT_HOME=$APIC_INSTALL_HOME/lab-project
APIC_DEPLOY_HOME=$INSTALL_HOME/targets/apic
HOST_IP=${HOST_IP:-127.0.0.1}

source $INSTALL_HOME/funcs.sh
source $APIC_DEPLOY_HOME/settings.sh

function ensure_nodes {
  target::step "Ensure cluster nodes"

  if [[ $NUM_NODES != 3 ]]; then
    target::log "NUM_NODES must be 3, current value $NUM_NODES"
    exit 255
  fi
}

function ensure_downloads {
  target::step "Ensure apic installation packages"

  if [[ ! -d $APIC_INSTALL_HOME ]]; then
    target::log "$APIC_INSTALL_HOME not found"
    exit 255
  else
    ptl_images_tgz=$(ls $APIC_INSTALL_HOME/portal*gz)
    mgmt_images_tgz=$(ls $APIC_INSTALL_HOME/management*gz)
    analyt_images_tgz=$(ls $APIC_INSTALL_HOME/analytics*gz)
    gwy_images_tgz=$(ls $APIC_INSTALL_HOME/idg*gz)
    apicup=$(ls $APIC_INSTALL_HOME/apicup*)
    chmod +x $apicup
    target::log "portal images tgz: $ptl_images_tgz"
    target::log "management images tgz: $mgmt_images_tgz"
    target::log "analytics images tgz: $analyt_images_tgz"
    target::log "gateway images tgz: $gwy_images_tgz"
    target::log "apicup: $apicup"
  fi
}

function ensure_namespace {
  target::step "Ensure namespace $apic_ns"

  if kubectl get namespace | grep -q $apic_ns ; then
    target::log "namespace $apic_ns detected"
  else
    kubectl create namespace $apic_ns
  fi
}

function init_project {
  target::step "Init apic project"

  if [[ -d $APIC_PROJECT_HOME ]]; then
    target::log "$APIC_PROJECT_HOME detected"
  else
    mkdir -p $APIC_PROJECT_HOME
    $apicup init $APIC_PROJECT_HOME
  fi

  # create crd
  kubectl apply -f $APIC_DEPLOY_HOME/CustomResourceDefinition.yml
}

function load_images {
  target::step "Load apic images into private registry"

  $INSTALL_HOME/targets/docker.io.sh up

  target::step "Load portal images"
  $apicup registry-upload portal $ptl_images_tgz registry-1.docker.io

  target::step "Load management images"
  $apicup registry-upload management $mgmt_images_tgz registry-1.docker.io

  target::step "Load analytics images"
  $apicup registry-upload analytics $analyt_images_tgz registry-1.docker.io

  $INSTALL_HOME/targets/docker.io.sh down

  target::step "Load gateway image"
  local gwy_image=$(docker load -i $gwy_images_tgz | grep -o ibmcom/datapower.*)
  docker tag $gwy_image 127.0.0.1:5000/$image_repository:$image_tag
  docker push 127.0.0.1:5000/$image_repository:$image_tag
  docker rmi 127.0.0.1:5000/$image_repository:$image_tag

  target::step "Load busybox image"
  docker pull busybox:1.29-glibc
  docker tag busybox:1.29-glibc 127.0.0.1:5000/busybox:1.29-glibc
  docker push 127.0.0.1:5000/busybox:1.29-glibc
  docker rmi 127.0.0.1:5000/busybox:1.29-glibc
}

function install_mgmt {
  target::step "Install management subsystem"

  # create pv
  docker exec kube-node-1 mkdir -p /var/db
  kubectl apply -f $APIC_DEPLOY_HOME/pv-mgmt.yml

  # config settings
  if $apicup subsys list|grep -q mgmt; then
    target::log "management subsystem detected"
  else
    $apicup subsys create mgmt management --k8s
  fi

  $apicup subsys set mgmt \
    ingress-type=ingress \
    mode=dev \
    namespace=$apic_ns \
    registry=mr.io \
    storage-class=apic-local-storage \
    create-crd=false \
    platform-api=$platform_api \
    api-manager-ui=$api_manager_ui \
    cloud-admin-ui=$cloud_admin_ui \
    consumer-api=$consumer_api \
    cassandra-cluster-size=1 \
    cassandra-max-memory-gb=$cassandra_max_memory_gb \
    cassandra-volume-size-gb=$cassandra_volume_size_gb

  # install
  if [[ -d mgmt-install-plan ]]; then
    target::log "management install plan detected"
  else
    $apicup subsys install mgmt --out=mgmt-install-plan --no-verify
  fi

  $apicup subsys install mgmt --plan-dir=mgmt-install-plan
}

function install_gwy {
  target::step "Install gateway subsystem"

  # create pv
  docker exec kube-node-1 mkdir -p /drouter/ramdisk2/mnt/raid-volume/raid0/local
  kubectl apply -f $APIC_DEPLOY_HOME/pv-gwy.yml

  # config settings
  if $apicup subsys list|grep -q mgmt; then
    target::log "gateway subsystem detected"
  else
    $apicup subsys create gwy gateway --k8s
  fi

  $apicup subsys set gwy \
    ingress-type=ingress \
    mode=dev \
    namespace=$apic_ns \
    registry=mr.io \
    storage-class=apic-local-storage \
    api-gateway=$api_gateway \
    apic-gw-service=$apic_gw_service \
    image-repository=$image_repository \
    image-tag=$image_tag \
    image-pull-policy=Always \
    replica-count=1 \
    max-cpu=4 \
    max-memory-gb=$max_memory_gb \
    v5-compatibility-mode=false \
    enable-tms=true \
    tms-peering-storage-size-gb=$tms_peering_storage_size_gb

  # install
  if [[ -d mgmt-install-plan ]]; then
    target::log "gateway install plan detected"
  else
    $apicup subsys install gwy --out=gwy-install-plan --no-verify
  fi

  $apicup subsys install gwy --plan-dir=gwy-install-plan
}

function install_analyt {
  target::step "Install analytics subsystem"

  # adjust vm.max_map_count
  if ! $(sysctl vm.max_map_count|grep -q $max_map_count) ; then
    target::log "set vm.max_map_count to $max_map_count"
    sysctl -w vm.max_map_count=$max_map_count
  fi

  # create pv
  docker exec kube-node-2 mkdir -p /var/lib/elasticsearch
  docker exec kube-node-3 mkdir -p /var/lib/elasticsearch
  kubectl apply -f $APIC_DEPLOY_HOME/pv-analyt.yml

  # config settings
  if $apicup subsys list|grep -q mgmt; then
    target::log "analytics subsystem detected"
  else
    $apicup subsys create analyt analytics --k8s
  fi

  $apicup subsys set analyt \
    ingress-type=ingress \
    mode=dev \
    namespace=$apic_ns \
    registry=mr.io \
    storage-class=apic-local-storage \
    analytics-ingestion=$analytics_ingestion \
    analytics-client=$analytics_client \
    coordinating-max-memory-gb=$coordinating_max_memory_gb \
    data-max-memory-gb=$data_max_memory_gb \
    data-storage-size-gb=$data_storage_size_gb \
    master-max-memory-gb=$master_max_memory_gb \
    master-storage-size-gb=$master_storage_size_gb \
    enable-message-queue=false

  # install
  if [[ -d mgmt-install-plan ]]; then
    target::log "analytics install plan detected"
  else
    $apicup subsys install analyt --out=analyt-install-plan --no-verify
  fi

  $apicup subsys install analyt --plan-dir=analyt-install-plan
}

function install_ptl {
  target::step "Install portal subsystem"

  # create pv
  docker exec kube-node-2 mkdir -p /var/lib/mysqldata
  docker exec kube-node-2 mkdir -p /var/log/mysqllog
  docker exec kube-node-2 mkdir -p /web
  docker exec kube-node-2 mkdir -p /var/aegir/backups
  docker exec kube-node-2 mkdir -p /var/devportal
  kubectl apply -f $APIC_DEPLOY_HOME/pv-ptl.yml

  # config settings
  if $apicup subsys list|grep -q mgmt; then
    target::log "portal subsystem detected"
  else
    $apicup subsys create ptl portal --k8s
  fi

  $apicup subsys set ptl \
    ingress-type=ingress \
    mode=dev \
    namespace=$apic_ns \
    registry=mr.io \
    storage-class=apic-local-storage \
    portal-admin=$portal_admin \
    portal-www=$portal_www \
    www-storage-size-gb=$www_storage_size_gb \
    backup-storage-size-gb=$backup_storage_size_gb \
    db-storage-size-gb=$db_storage_size_gb \
    db-logs-storage-size-gb=$db_logs_storage_size_gb \
    admin-storage-size-gb=$admin_storage_size_gb

  # install
  if [[ -d mgmt-install-plan ]]; then
    target::log "portal install plan detected"
  else
    $apicup subsys install ptl --out=ptl-install-plan --no-verify
  fi

  $apicup subsys install ptl --plan-dir=ptl-install-plan
}

function install_ingress {
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
}

ensure_nodes
ensure_downloads
ensure_namespace

function apic::init {
  init_project

  pushd $APIC_PROJECT_HOME >/dev/null

  load_images
  install_gwy
  install_ptl
  install_analyt
  install_mgmt
  install_ingress

  popd >/dev/null
}

function apic::validate {
  pushd $APIC_PROJECT_HOME >/dev/null

  target::step "Validate gateway subsystem"
  $apicup subsys get gwy --validate

  target::step "Validate portal subsystem"
  $apicup subsys get ptl --validate

  target::step "Validate analytics subsystem"
  $apicup subsys get analyt --validate

  target::step "Validate management subsystem"
  $apicup subsys get mgmt --validate

  popd >/dev/null
}

function apic::clean {
  target::step "Delete namespace $apic_ns"
  kubectl delete namespace $apic_ns
  
  target::step "Delete CRDs"
  kubectl delete -f $APIC_DEPLOY_HOME/CustomResourceDefinition.yml

  target::step "Delete PVs"
  kubectl delete -f $APIC_DEPLOY_HOME/pv-mgmt.yml
  kubectl delete -f $APIC_DEPLOY_HOME/pv-gwy.yml
  kubectl delete -f $APIC_DEPLOY_HOME/pv-analyt.yml
  kubectl delete -f $APIC_DEPLOY_HOME/pv-ptl.yml

  target::step "Clean apic project"
  rm -rf $APIC_PROJECT_HOME
}

function apic::endpoint {
  kubectl -n $apic_ns port-forward --address $HOST_IP service/ingress-nginx-ingress-controller 443:443
}

target::command $@

#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
APIC_INSTALL_HOME=$INSTALL_HOME/.launch-cache/apic
APIC_PROJECT_HOME=$APIC_INSTALL_HOME/lab-project
APIC_DEPLOY_HOME=$INSTALL_HOME/targets/apic
HOST_IP=${HOST_IP:-127.0.0.1}

source $INSTALL_HOME/funcs.sh
source $APIC_DEPLOY_HOME/settings.sh

function ensure_nodes {
  target::step "ensure cluster nodes"

  if [[ $NUM_NODES != 3 ]]; then
    target::log "NUM_NODES must be 3, current value $NUM_NODES"
    exit 255
  fi
}

function ensure_images {
  target::step "ensure apic packaged images"

  if [[ ! -d $APIC_INSTALL_HOME ]]; then
    target::log "$APIC_INSTALL_HOME not found"
    exit 255
  else
    ensure_tgz portal
    ptl_images_tgz=$images_tgz
    
    ensure_tgz management
    mgmt_images_tgz=$images_tgz

    ensure_tgz analytics
    analyt_images_tgz=$images_tgz

    ensure_tgz idg
    gwy_images_tgz=$images_tgz
  fi
}

function ensure_apicup {
  target::step "ensure apicup"

  if [[ ! -d $APIC_INSTALL_HOME ]]; then
    target::log "$APIC_INSTALL_HOME not found"
    exit 255
  else
    apicup=$(ls $APIC_INSTALL_HOME/apicup*)
    chmod +x $apicup
    target::log "$apicup"
  fi
}

function ensure_namespace {
  target::step "ensure namespace $apic_ns"

  if kubectl get namespace | grep -q $apic_ns ; then
    target::log "namespace $apic_ns detected"
  else
    kubectl create namespace $apic_ns
  fi
}

function ensure_tgz {
  images_tgz=$(ls $APIC_INSTALL_HOME/$1*gz)
  [ $? != 0 ] && exit 255

  target::log "validate $images_tgz"

  tar -tzf $images_tgz >/dev/null
  [ $? != 0 ] && target::log "$images_tgz is invalid" && exit 255
}

function init_project {
  target::step "init apic project"

  if [[ -d $APIC_PROJECT_HOME ]]; then
    target::log "$APIC_PROJECT_HOME detected"
  else
    mkdir -p $APIC_PROJECT_HOME
    $apicup init $APIC_PROJECT_HOME
  fi

  # create crd
  kubectl apply -f $APIC_DEPLOY_HOME/CustomResourceDefinition.yml
  # create sc
  kubectl apply -f $APIC_DEPLOY_HOME/sc.yml
}

function load_image {
  docker tag $1 127.0.0.1:5000/$2
  docker push 127.0.0.1:5000/$2
  docker rmi 127.0.0.1:5000/$2
}

function load_images {
  target::step "load apic images into private registry"

  $INSTALL_HOME/launch.sh registry::docker.io

  target::step "load portal images"
  $apicup registry-upload portal $ptl_images_tgz registry-1.docker.io

  target::step "load management images"
  $apicup registry-upload management $mgmt_images_tgz registry-1.docker.io

  target::step "load analytics images"
  $apicup registry-upload analytics $analyt_images_tgz registry-1.docker.io

  $INSTALL_HOME/launch.sh registry::docker.io

  target::step "load gateway image"
  local gwy_image=$(docker load -i $gwy_images_tgz | grep -o ibmcom/datapower.*)
  load_image $gwy_image $image_repository:$image_tag

  target::step "load busybox image"
  docker pull busybox:1.29-glibc
  load_image busybox:1.29-glibc busybox:1.29-glibc
}

function install_mgmt {
  target::step "install management subsystem"

  # create pv
  docker exec kube-node-1 mkdir -p /var/db
  cat $APIC_DEPLOY_HOME/pv-mgmt.yml | \
    sed -e "s/@@cassandra_volume_size_gb/$cassandra_volume_size_gb/g" | \
    kubectl apply -f -

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
  target::log
}

function install_gwy {
  target::step "install gateway subsystem"

  # create pv
  docker exec kube-node-1 mkdir -p /drouter/ramdisk2/mnt/raid-volume/raid0/local
  cat $APIC_DEPLOY_HOME/pv-gwy.yml | \
    sed -e "s/@@tms_peering_storage_size_gb/$tms_peering_storage_size_gb/g" | \
    kubectl apply -f -

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
  target::log
}

function install_analyt {
  target::step "install analytics subsystem"

  # adjust vm.max_map_count
  if ! $(sysctl vm.max_map_count|grep -q $max_map_count) ; then
    target::log "set vm.max_map_count to $max_map_count"
    sysctl -w vm.max_map_count=$max_map_count
  fi

  # create pv
  docker exec kube-node-2 mkdir -p /var/lib/elasticsearch
  docker exec kube-node-3 mkdir -p /var/lib/elasticsearch
  cat $APIC_DEPLOY_HOME/pv-analyt.yml | \
    sed -e "s/@@data_storage_size_gb/$data_storage_size_gb/g; \
      s/@@master_storage_size_gb/$master_storage_size_gb/g" | \
    kubectl apply -f -

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
  target::log
}

function install_ptl {
  target::step "install portal subsystem"

  # create pv
  docker exec kube-node-2 mkdir -p /var/lib/mysqldata
  docker exec kube-node-2 mkdir -p /var/log/mysqllog
  docker exec kube-node-2 mkdir -p /web
  docker exec kube-node-2 mkdir -p /var/aegir/backups
  docker exec kube-node-2 mkdir -p /var/devportal
  cat $APIC_DEPLOY_HOME/pv-ptl.yml | \
    sed -e "s/@@db_storage_size_gb/$db_storage_size_gb/g; \
      s/@@db_logs_storage_size_gb/$db_logs_storage_size_gb/g; \
      s/@@www_storage_size_gb/$www_storage_size_gb/g; \
      s/@@backup_storage_size_gb/$backup_storage_size_gb/g; \
      s/@@admin_storage_size_gb/$admin_storage_size_gb/g" | \
    kubectl apply -f -

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
  target::log
}

function install_ingress {
  target::step "install ingress controller"

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

function apic::init {
  ensure_nodes
  ensure_apicup
  ensure_namespace

  init_project

  pushd $APIC_PROJECT_HOME >/dev/null

  if [[ -z $apic_skip_load_images || $apic_skip_load_images == 0 ]]; then
    ensure_images
    load_images
  fi

  install_gwy
  install_ptl
  install_analyt
  install_mgmt
  install_ingress

  # Gateway
  add_endpoint "apic" "Gateway Management Endpoint" "https://$apic_gw_service"
  add_endpoint "apic" "Gateway API Endpoint Base" "https://$api_gateway"
  # Portoal
  add_endpoint "apic" "Portal Management Endpoint" "https://$portal_admin"
  add_endpoint "apic" "Portal Website URL" "https://$portal_www"
  # Analytics
  add_endpoint "apic" "Analytics Management Endpoint" "https://$analytics_client"
  # Management
  add_endpoint "apic" "Cloud Manager UI" "https://$cloud_admin_ui" "(default usr/pwd: admin/7iron-hide)"

  popd >/dev/null
}

function apic::validate {
  [ ! -d $APIC_PROJECT_HOME ] && target::log "$APIC_PROJECT_HOME not found" && exit

  ensure_apicup

  pushd $APIC_PROJECT_HOME >/dev/null

  target::step "validate gateway subsystem"
  $apicup subsys get gwy --validate

  target::step "validate portal subsystem"
  $apicup subsys get ptl --validate

  target::step "validate analytics subsystem"
  $apicup subsys get analyt --validate

  target::step "validate management subsystem"
  $apicup subsys get mgmt --validate

  popd >/dev/null
}

function apic::clean {
  clean_endpoints "apic"

  target::step "delete namespace $apic_ns"
  (kubectl get namespace | grep -q $apic_ns) && \
  kubectl delete namespace $apic_ns
  
  target::step "delete CRDs"
  local crds=($(kubectl get crd -o name | grep .apic.ibm.com))
  [ -n "$crds" ] && kubectl delete crd "${crds[@]##*/}"

  target::step "delete PVs"
  local pvs=($(kubectl get pv -o name | grep persistentvolume/apic-))
  [ -n "$pvs" ] && kubectl delete pv "${pvs[@]##*/}"

  target::step "clean apic project"
  rm -rf $APIC_PROJECT_HOME
}

docker_io_host="registry-1.docker.io"
function apic::portforward {
  pushd $LAB_HOME >/dev/null
  sudo docker-compose stop $docker_io_host
  popd >/dev/null

  kill_portfwds "443:443"
  create_portfwd $apic_ns service/ingress-nginx-ingress-controller 443:443
}

target::command $@

#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
APIC_INSTALL_HOME=$INSTALL_HOME/.launch-cache/apic
APIC_PROJECT_HOME=$APIC_INSTALL_HOME/lab-project
APIC_DEPLOY_HOME=$INSTALL_HOME/targets/apic

. $INSTALL_HOME/funcs.sh
. $APIC_DEPLOY_HOME/settings.sh

apic_pv_home_text="${apic_pv_home////\\/}"

function ensure_apicup {
  target::step "Ensure apicup"

  if [[ ! -d $APIC_INSTALL_HOME ]]; then
    target::log "$APIC_INSTALL_HOME not found"
    exit 255
  else
    apicup=$(ls $APIC_INSTALL_HOME/apicup*)
    chmod +x $apicup
    target::log "$apicup"
  fi
}

function ensure_tgz {
  images_tgz=$(ls $APIC_INSTALL_HOME/$1*gz)
  [ $? != 0 ] && exit 255

  target::log "validate $images_tgz"

  tar -tzf $images_tgz >/dev/null
  [ $? != 0 ] && target::log "$images_tgz is invalid" && exit 255
}

function ensure_images {
  target::step "Ensure apic packaged images"

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

function load_image {
  docker tag $1 127.0.0.1:5000/$2
  docker push 127.0.0.1:5000/$2
  docker rmi 127.0.0.1:5000/$2
}

function load_images {
  target::step "Load apic images into private registry"

  local docker_io_host="registry-1.docker.io"
  $INSTALL_HOME/launch.sh registry::docker.io

  target::step "Load portal images"
  $apicup registry-upload portal $ptl_images_tgz $docker_io_host

  target::step "Load management images"
  $apicup registry-upload management $mgmt_images_tgz $docker_io_host

  target::step "Load analytics images"
  $apicup registry-upload analytics $analyt_images_tgz $docker_io_host

  $INSTALL_HOME/launch.sh registry::docker.io

  target::step "Load gateway image"
  local gwy_image=$(docker load -i $gwy_images_tgz | grep -o ibmcom/datapower.*)
  load_image $gwy_image $gwy_image_repository:$gwy_image_tag

  target::step "Load busybox image"
  docker pull busybox:1.29-glibc
  load_image busybox:1.29-glibc busybox:1.29-glibc
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
  # create sc
  kubectl apply -f $APIC_DEPLOY_HOME/pv/sc.yml
}

function install_mgmt {
  target::step "Install management subsystem"

  # create pv
  cat $APIC_DEPLOY_HOME/pv/$apic_pv_type/mgmt.yml | \
    sed -e "s/@@cassandra_volume_size_gb/$cassandra_volume_size_gb/g; \
      s/@@apic_pv_home/$apic_pv_home_text/g" | \
    kubectl apply -f -

  # config settings
  if $apicup subsys list|grep -q mgmt; then
    target::log "management subsystem detected"
  else
    $apicup subsys create mgmt management --k8s
  fi

  $apicup subsys set mgmt \
    ingress-type=$apic_ingress_type \
    mode=dev \
    namespace=$apic_ns \
    registry=$apic_registry \
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

  target::log "[done]"
}

function install_gwy {
  target::step "Install gateway subsystem"

  # create pv
  cat $APIC_DEPLOY_HOME/pv/$apic_pv_type/gwy.yml | \
    sed -e "s/@@tms_peering_storage_size_gb/$tms_peering_storage_size_gb/g; \
      s/@@apic_pv_home/$apic_pv_home_text/g" | \
    kubectl apply -f -

  # config settings
  if $apicup subsys list|grep -q mgmt; then
    target::log "gateway subsystem detected"
  else
    $apicup subsys create gwy gateway --k8s
  fi

  $apicup subsys set gwy \
    ingress-type=$apic_ingress_type \
    mode=dev \
    namespace=$apic_ns \
    registry=$apic_registry \
    storage-class=apic-local-storage \
    api-gateway=$api_gateway \
    apic-gw-service=$apic_gw_service \
    image-repository=$gwy_image_repository \
    image-tag=$gwy_image_tag \
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

  target::log "[done]"
}

function install_analyt {
  target::step "Install analytics subsystem"

  # adjust vm.max_map_count
  if ! $(sysctl vm.max_map_count|grep -q $max_map_count) ; then
    target::log "set vm.max_map_count to $max_map_count"
    sysctl -w vm.max_map_count=$max_map_count
  fi

  # create pv
  cat $APIC_DEPLOY_HOME/pv/$apic_pv_type/analyt.yml | \
    sed -e "s/@@data_storage_size_gb/$data_storage_size_gb/g; \
      s/@@master_storage_size_gb/$master_storage_size_gb/g; \
      s/@@apic_pv_home/$apic_pv_home_text/g" | \
    kubectl apply -f -

  # config settings
  if $apicup subsys list|grep -q mgmt; then
    target::log "analytics subsystem detected"
  else
    $apicup subsys create analyt analytics --k8s
  fi

  $apicup subsys set analyt \
    ingress-type=$apic_ingress_type \
    mode=dev \
    namespace=$apic_ns \
    registry=$apic_registry \
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

  target::log "[done]"
}

function install_ptl {
  target::step "Install portal subsystem"

  # create pv
  cat $APIC_DEPLOY_HOME/pv/$apic_pv_type/ptl.yml | \
    sed -e "s/@@db_storage_size_gb/$db_storage_size_gb/g; \
      s/@@db_logs_storage_size_gb/$db_logs_storage_size_gb/g; \
      s/@@www_storage_size_gb/$www_storage_size_gb/g; \
      s/@@backup_storage_size_gb/$backup_storage_size_gb/g; \
      s/@@admin_storage_size_gb/$admin_storage_size_gb/g; \
      s/@@apic_pv_home/$apic_pv_home_text/g" | \
    kubectl apply -f -

  # config settings
  if $apicup subsys list|grep -q mgmt; then
    target::log "portal subsystem detected"
  else
    $apicup subsys create ptl portal --k8s
  fi

  $apicup subsys set ptl \
    ingress-type=$apic_ingress_type \
    mode=dev \
    namespace=$apic_ns \
    registry=$apic_registry \
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

  target::log "[done]"
}

function add_endpoints {
  # Gateway
  add_endpoint "apic" "Gateway Management Endpoint" "https://$apic_gw_service"
  add_endpoint "apic" "Gateway API Endpoint Base" "https://$api_gateway"
  # Portoal
  add_endpoint "apic" "Portal Management Endpoint" "https://$portal_admin"
  add_endpoint "apic" "Portal Website URL" "https://$portal_www"
  # Analytics
  add_endpoint "apic" "Analytics Management Endpoint" "https://$analytics_client"
}

function on_before_init {
  :
}

function init {
  on_before_init

  ensure_apicup

  if [[ -z $apic_skip_load_images || $apic_skip_load_images == 0 ]]; then
    ensure_images
    load_images
  fi

  init_project

  pushd $APIC_PROJECT_HOME >/dev/null

  install_gwy
  install_ptl
  install_analyt
  install_mgmt
  add_endpoints

  popd >/dev/null

  on_after_init
}

function on_after_init {
  :
}

function validate {
  [ ! -d $APIC_PROJECT_HOME ] && target::log "$APIC_PROJECT_HOME not found" && exit

  ensure_apicup

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

function on_before_clean {
  :
}

function clean {
  on_before_clean

  clean_endpoints "apic"

  target::step "Delete namespace $apic_ns"
  (kubectl get namespace | grep -q $apic_ns) && \
  kubectl delete namespace $apic_ns
  
  target::step "Delete CRDs"
  local crds=($(kubectl get crd -o name | grep .apic.ibm.com))
  [ -n "$crds" ] && kubectl delete crd "${crds[@]##*/}"

  target::step "Delete PVs"
  local pvs=($(kubectl get pv -o name | grep persistentvolume/apic-))
  [ -n "$pvs" ] && kubectl delete pv "${pvs[@]##*/}"

  target::step "Clean apic project"
  rm -rf $APIC_PROJECT_HOME

  on_after_clean
}

function on_after_clean {
  :
}

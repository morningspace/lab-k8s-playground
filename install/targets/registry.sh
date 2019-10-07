#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
. $LAB_HOME/install/funcs.sh

[[ -n $RUN_DOCKER_AS_SUDO ]] && sudo_prefix="sudo"

function registry::init {
  ensure_k8s_version || exit

  if [[ $K8S_PROVIDER == oc ]]; then
    images=(
      openshift/origin-node:v3.11
      openshift/origin-control-plane:v3.11
      openshift/origin-haproxy-router:v3.11
      openshift/origin-deployer:v3.11
      openshift/origin-cli:v3.11
      openshift/origin-hyperkube:v3.11
      openshift/origin-pod:v3.11
      openshift/origin-hypershift:v3.11
      openshift/origin-docker-registry:v3.11
      openshift/origin-web-console:v3.11
      openshift/origin-service-serving-cert-signer:v3.11
    )
  else
    # images to be cached per kubernetes version
    case $K8S_VERSION in
    "v1.12")
      images=(
      # k8s
      k8s.gcr.io/hyperkube:v1.12.8
      k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
      k8s.gcr.io/pause:3.1
      k8s.gcr.io/coredns:1.2.2
      k8s.gcr.io/etcd:3.2.24
      # kubeadm-dind-cluster
      mirantis/kubeadm-dind-cluster:62f5a9277678777b63ae55d144bd2f99feb7c824-v1.12
      # helm
      gcr.io/kubernetes-helm/tiller:v2.12.3
      );;
    "v1.13")
      images=(
      # k8s
      k8s.gcr.io/hyperkube:v1.13.5
      k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
      k8s.gcr.io/pause:3.1
      k8s.gcr.io/coredns:1.2.6
      k8s.gcr.io/etcd:3.2.24
      # kubeadm-dind-cluster
      mirantis/kubeadm-dind-cluster:62f5a9277678777b63ae55d144bd2f99feb7c824-v1.13
      # helm
      gcr.io/kubernetes-helm/tiller:v2.13.1
      );;
    "v1.14")
      images=(
      # k8s
      k8s.gcr.io/hyperkube:v1.14.1
      k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
      k8s.gcr.io/pause:3.1
      k8s.gcr.io/coredns:1.3.1
      k8s.gcr.io/etcd:3.3.10
      # kubeadm-dind-cluster
      mirantis/kubeadm-dind-cluster:62f5a9277678777b63ae55d144bd2f99feb7c824-v1.14
      # helm
      gcr.io/kubernetes-helm/tiller:v2.14.2
      );;
    "v1.15")
      images=(
      # k8s
      k8s.gcr.io/hyperkube:v1.15.0
      k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
      k8s.gcr.io/pause:3.1
      k8s.gcr.io/coredns:1.3.1
      k8s.gcr.io/etcd:3.3.10
      # kubeadm-dind-cluster
      mirantis/kubeadm-dind-cluster:62f5a9277678777b63ae55d144bd2f99feb7c824-v1.15
      # helm
      gcr.io/kubernetes-helm/tiller:v2.14.2
      );;
    *)
      images=(
      # nothing
      );;
    esac
  fi

  # registries having mirrors on docker hub
  registries_mirrored=(
    k8s.gcr.io
    gcr.io
  )
  # registries not docker hub
  registries_not_dockerhub=(
    k8s.gcr.io
    gcr.io
    quay.io
  )

  insecure_registries=($(get_insecure_registries))
  my_registry=${insecure_registries[0]}
  if ensure_os_linux && [ ! -f /etc/docker/daemon.json ]; then
    target::step "Set up insecure registries"

    cat << EOF | sudo tee /etc/docker/daemon.json
{
  "insecure-registries" : [$(get_insecure_registries_text)]
}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo systemctl show --property=Environment docker
  fi

  target::step "Set up registries network and volume"
  $sudo_prefix docker network inspect net-registries &>/dev/null || \
  $sudo_prefix docker network create net-registries
  $sudo_prefix docker volume create vol-registries

  pushd $LAB_HOME

  target::step "Take registry mr.io up"
  $sudo_prefix docker-compose up -d mr.io

  sleep 5

  [ -f install/targets/images.list ] && . install/targets/images.list

  for image in ${images[@]} ; do
    local registry=${image%%/*}
    local repository=${image#*/}
    local mirrored=0
    if [[ $IS_IN_CHINA == 1 && ${registries_mirrored[@]} =~ $registry ]]; then
      registry=morningspace
      image=$registry/${repository/\//-}
      mirrored=1
    fi

    if [[ $image != *"/"* ]]; then
      image=library/$repository
    fi

    local target_image=$my_registry/$image
    if [[ ${registries_not_dockerhub[@]} =~ $registry || $mirrored == 1 ]]; then
      target_image=$my_registry/$repository
    fi

    target::step "$image ➞ $target_image"
    $sudo_prefix docker pull $image
    $sudo_prefix docker tag $image $target_image
    $sudo_prefix docker push $target_image
    $sudo_prefix docker rmi $target_image
  done  

  target::step "Take other registries up"
  $sudo_prefix docker-compose up -d --scale socat=0

  popd
}

function registry::up {
  pushd $LAB_HOME
  target::step "Take all registries up"
  $sudo_prefix docker-compose up -d --scale socat=0
  popd
}

function registry::down {
  pushd $LAB_HOME
  target::step "Take all registries down"
  $sudo_prefix docker-compose down
  popd
}

docker_io_host="registry-1.docker.io"
function registry::docker.io {
  pushd $LAB_HOME

  if cat /etc/hosts | grep -q "# $docker_io_host"; then
    target::step "Disable local docker.io"
    $sudo_prefix docker-compose stop socat

    target::step "Remove $docker_io_host mapping from /etc/hosts"
    sudo sed -i.bak "/$docker_io_host/d" /etc/hosts
  else
    target::step "Enable local docker.io"
    $sudo_prefix COMPOSE_IGNORE_ORPHANS=True docker-compose up -d socat

    target::step "Add $docker_io_host mapping into /etc/hosts"
    cat << EOF | sudo tee -a /etc/hosts
# $docker_io_host
127.0.0.1	$docker_io_host
EOF
  fi

  popd
}

function registry::mr.io {
  pushd $LAB_HOME

  if cat /etc/hosts | grep -q "# mr.io"; then
    target::step "Remove mr.io mapping from /etc/hosts"
    sudo sed -i.bak "/mr.io/d" /etc/hosts
  else
    target::step "Add mr.io mapping into /etc/hosts"
    cat << EOF | sudo tee -a /etc/hosts
# mr.io
127.0.0.1	mr.io
EOF
  fi

  popd
}

target::command $@

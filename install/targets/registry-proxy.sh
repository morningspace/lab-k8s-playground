#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
source $LAB_HOME/install/funcs.sh

docker_compose="sudo docker-compose -f docker-compose-registry-proxy.yml"

function registry-proxy::init {
  # set up private registries
  my_registry=127.0.0.1:5000
  if ensure_os Linux && [ ! -f /etc/docker/daemon.json ]; then
    cat << EOF | sudo tee /etc/docker/daemon.json
{
  "insecure-registries" : ["$my_registry"]
}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo systemctl show --property=Environment docker
  fi

  sudo docker network inspect net-registries &>/dev/null || \
  sudo docker network create net-registries
  sudo docker volume create vol-registries

  pushd $LAB_HOME

  REGISTRY_REMOTE=${REGISTRY_REMOTE:-$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)}
  [ -z $REGISTRY_REMOTE ] && target::log '$REGISTRY_REMOTE must not be empty' && exit 1
  echo "REGISTRY_PROXY_REMOTEURL=http://$REGISTRY_REMOTE:5000" >.env

  target::step "take registry proxies up"
  $docker_compose up -d --scale docker.io.proxy=0

  popd
}

function registry-proxy::up {
  pushd $LAB_HOME
  target::step "take registry proxies up"
  $docker_compose up -d --scale docker.io.proxy=0
  popd
}

function registry-proxy::down {
  pushd $LAB_HOME
  target::step "take registry proxies down"
  $docker_compose down
  popd
}

target::command $@

#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
source $LAB_HOME/install/funcs.sh

docker_compose="sudo docker-compose -f docker-compose-registry-proxy.yml"

function registry-proxy::init {
  my_registry=127.0.0.1:5000
  if ensure_os_linux && [ ! -f /etc/docker/daemon.json ]; then
    target::step "Set up insecure registries"

    cat << EOF | sudo tee /etc/docker/daemon.json
{
  "insecure-registries" : ["$my_registry"]
}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo systemctl show --property=Environment docker
  fi

  target::step "Set up registries network and volume"
  sudo docker network inspect net-registries &>/dev/null || \
  sudo docker network create net-registries
  sudo docker volume create vol-registries

  pushd $LAB_HOME

  REGISTRY_REMOTE=${REGISTRY_REMOTE:-$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)}
  [ -z $REGISTRY_REMOTE ] && target::log '$REGISTRY_REMOTE must not be empty' && exit 1
  echo "REGISTRY_PROXY_REMOTEURL=http://$REGISTRY_REMOTE:5000" >.env

  target::step "Take all registry proxies up"
  $docker_compose up -d

  popd
}

function registry-proxy::up {
  pushd $LAB_HOME
  target::step "Take all registry proxies up"
  $docker_compose up -d
  popd
}

function registry-proxy::down {
  pushd $LAB_HOME
  target::step "Take all registry proxies down"
  $docker_compose down
  popd
}

target::command $@

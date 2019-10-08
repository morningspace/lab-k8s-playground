#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
. $LAB_HOME/install/funcs.sh

function registry-proxy::init {
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
  $(run_docker_as_sudo) "docker network inspect net-registries &>/dev/null" || \
  $(run_docker_as_sudo) "docker network create net-registries"
  $(run_docker_as_sudo) "docker volume create vol-registries"

  pushd $LAB_HOME

  REGISTRY_REMOTE=${REGISTRY_REMOTE:-$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)}
  [ -z $REGISTRY_REMOTE ] && target::log '$REGISTRY_REMOTE must not be empty' && exit 1
  echo "REGISTRY_PROXY_REMOTEURL=http://$REGISTRY_REMOTE:5000" >.env

  target::step "Take all registry proxies up"
  $(run_docker_as_sudo) "docker-compose -f docker-compose-registry-proxy.yml up -d"

  popd
}

function registry-proxy::up {
  pushd $LAB_HOME
  target::step "Take all registry proxies up"
  $(run_docker_as_sudo) "docker-compose -f docker-compose-registry-proxy.yml up -d"
  popd
}

function registry-proxy::down {
  pushd $LAB_HOME
  target::step "Take all registry proxies down"
  $(run_docker_as_sudo) "docker-compose -f docker-compose-registry-proxy.yml down"
  popd
}

target::command $@

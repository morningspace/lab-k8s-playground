#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

docker_compose="docker-compose -f docker-compose-registry-proxy.yml"

function registry-proxy::init {
  # set up private registries
  ensure_box
  if [[ $? == 0 && ! -f /etc/docker/daemon.json ]]; then
    cat << EOF | sudo tee /etc/docker/daemon.json
{
  "insecure-registries" : ["127.0.0.1:5000"]
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
  echo "REGISTRY_PROXY_REMOTEURL=http://$REGISTRY_REMOTE:5000" >.env
  sudo $docker_compose up -d --scale docker.io.proxy=0

  popd
}

function registry-proxy::up {
  pushd $LAB_HOME
  $docker_compose up -d --scale docker.io.proxy=0
  popd
}

function registry-proxy::down {
  pushd $LAB_HOME
  $docker_compose down
  popd
}

run_target_command $@

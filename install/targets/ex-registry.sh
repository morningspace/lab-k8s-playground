#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

function init {
  # set up private registries
  ensure_box
  if [[ $? == 0 && ! -f /etc/docker/daemon.json ]]; then
    cat << EOF | sudo tee /etc/docker/daemon.json
{
  "insecure-registries" : ["127.0.0.1:5000"],
  "registry-mirrors": ["http://127.0.0.1:5555"]
}
EOF

    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo systemctl show --property=Environment docker
  fi

  sudo docker network inspect net-registries &>/dev/null || \
  sudo docker network create net-registries
  sudo docker volume create vol-registries

  # start external registries
  pushd $LAB_HOME

  X_REGISTRY=$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)
  echo "REGISTRY_PROXY_REMOTEURL=http://$X_REGISTRY:5000" >.env
  sudo docker-compose -f docker-compose-ex-reg.yml up -d

  popd
}

function up {
  pushd $LAB_HOME
  docker-compose -f docker-compose-ex-reg.yml up -d
  popd
}

function down {
  pushd $LAB_HOME
  docker-compose -f docker-compose-ex-reg.yml down
  popd
}

command=${1:-init}

case $command in
  "init") init;;
  "up") up;;
  "down") down;;
  *) echo "* unkown command";;
esac

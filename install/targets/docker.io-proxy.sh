#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

host="registry-1.docker.io"
docker_compose="docker-compose -f docker-compose-registry-proxy.yml"

function docker.io-proxy::init {
  if cat /etc/hosts | grep -q "# $host"; then
    echo "* $host mapping detected"
  else
    cat << EOF | sudo tee -a /etc/hosts
# $host
127.0.0.1	$host
EOF
  fi

  docker.io-proxy::up
}

function docker.io-proxy::up {
  pushd $LAB_HOME
  $docker_compose up -d docker.io.proxy
  popd
}

function docker.io-proxy::down {
  pushd $LAB_HOME
  $docker_compose stop docker.io.proxy
  $docker_compose rm -f docker.io.proxy
  popd
}

function docker.io-proxy::clean {
  if cat /etc/hosts | grep -q "# $host"; then
    sudo sed -i.bak "/$host/d" /etc/hosts
  fi

  docker.io-proxy::down
}

run_target_command $@

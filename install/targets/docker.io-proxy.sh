#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
source $LAB_HOME/install/funcs.sh

host="registry-1.docker.io"
docker_compose="docker-compose -f docker-compose-registry-proxy.yml"

function docker.io-proxy::up {
  if cat /etc/hosts | grep -q "# $host"; then
    target::log "$host mapping detected"
  else
    cat << EOF | sudo tee -a /etc/hosts
# $host
127.0.0.1	$host
EOF
  fi

  pushd $LAB_HOME
  $docker_compose up -d docker.io.proxy
  popd
}

function docker.io-proxy::down {
  if cat /etc/hosts | grep -q "# $host"; then
    sudo sed -i.bak "/$host/d" /etc/hosts
  fi

  pushd $LAB_HOME
  $docker_compose stop docker.io.proxy
  $docker_compose rm -f docker.io.proxy
  popd
}

target::command $@

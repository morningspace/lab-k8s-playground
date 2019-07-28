#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

host="registry-1.docker.io"

function init {
  if cat /etc/hosts | grep -q "# $host"; then
    echo "* $host mapping detected"
  else
    cat << EOF | sudo tee -a /etc/hosts
# $host
127.0.0.1	$host
EOF
  fi

  up
}

function up {
  pushd $LAB_HOME
  docker-compose -f docker-compose-registry-proxy.yml up -d docker.io.proxy
  popd
}

function down {
  pushd $LAB_HOME
  docker-compose -f docker-compose-registry-proxy.yml stop docker.io.proxy
  docker-compose -f docker-compose-registry-proxy.yml rm -f docker.io.proxy
  popd
}

function clean {
  if cat /etc/hosts | grep -q "# $host"; then
    sudo sed -i.bak "/$host/d" /etc/hosts
  fi

  down
}

command=${1:-init}

case $command in
  "init") init;;
  "up") up;;
  "down") down;;
  "clean") clean;;
  *) echo "* unkown command";;
esac

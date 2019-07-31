#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
source $LAB_HOME/install/funcs.sh

host="registry-1.docker.io"

function docker.io::init {
  if cat /etc/hosts | grep -q "# $host"; then
    echo "* $host mapping detected"
  else
    cat << EOF | sudo tee -a /etc/hosts
# $host
127.0.0.1	$host
EOF
  fi

  docker.io::up
}

function docker.io::up {
  pushd $LAB_HOME
  docker-compose up -d docker.io
  popd
}

function docker.io::down {
  pushd $LAB_HOME
  docker-compose stop docker.io
  docker-compose rm -f docker.io
  popd
}

function docker.io::clean {
  if cat /etc/hosts | grep -q "# $host"; then
    sudo sed -i.bak "/$host/d" /etc/hosts
  fi

  docker.io::down
}

target::command $@

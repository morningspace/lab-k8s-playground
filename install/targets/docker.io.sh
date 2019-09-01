#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
source $LAB_HOME/install/funcs.sh

host="registry-1.docker.io"
docker_compose="sudo docker-compose"

function docker.io::up {
  target::step "update /etc/hosts"
  if cat /etc/hosts | grep -q "# $host"; then
    target::log "$host mapping detected"
  else
    cat << EOF | sudo tee -a /etc/hosts
# $host
127.0.0.1	$host
EOF
  fi

  target::step "take registry docker.io up"
  pushd $LAB_HOME
  $docker_compose up -d docker.io
  popd
}

function docker.io::down {
  target::step "update /etc/hosts"
  if cat /etc/hosts | grep -q "# $host"; then
    sudo sed -i.bak "/$host/d" /etc/hosts
  fi

  target::step "take registry docker.io down"
  pushd $LAB_HOME
  $docker_compose stop docker.io
  $docker_compose rm -f docker.io
  popd
}

target::command $@

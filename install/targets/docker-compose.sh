#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
. $LAB_HOME/install/funcs.sh

target::step "Start to install docker-compose"
ensure_command "docker-compose" && exit

executable="docker-compose-$(uname -s)-$(uname -m)"

if [[ ! -f ~/.launch-cache/$executable ]]; then
  target::step "Download docker-compose"
  download_url=https://github.com/docker/compose/releases/download/1.24.0/$executable
  curl -sSL $download_url -o ~/.launch-cache/$executable
  chmod +x ~/.launch-cache/$executable
fi

create_links ~/.launch-cache/$executable "docker-compose"

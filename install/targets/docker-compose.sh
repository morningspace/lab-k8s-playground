#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

ensure_command "docker-compose" && exit

if [[ ! -f ~/.lab-k8s-cache/docker-compose ]]; then
  download_url=https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)
  curl -sL $download_url -o ~/.lab-k8s-cache/docker-compose
fi

sudo ln -sf ~/.lab-k8s-cache/docker-compose /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
. $LAB_HOME/install/funcs.sh

target::step "Start to install kubectl"

if ensure_command "kubectl"; then
  [[ $@ =~ --force ]] && target::log "force to install" || exit
fi
  
ensure_k8s_version || exit

# set version per kubernetes version
case $K8S_VERSION in
  "v1.12")
    KUBECTL_VERSION="v1.12.10";;
  "v1.13")
    KUBECTL_VERSION="v1.13.8";;
  "v1.14")
    KUBECTL_VERSION="v1.14.4";;
  "v1.15")
    KUBECTL_VERSION="v1.15.1";;
  *)
    target::log "Nothing happened"
    exit
esac

os=$(uname -s | tr '[:upper:]' '[:lower:]')
executable="kubectl-$KUBECTL_VERSION-$os"

if [[ ! -f ~/.launch-cache/$executable ]]; then
  target::step "Download kubectl"
  [[ -n $https_proxy ]] && target::log "https_proxy detected: $https_proxy"
  download_url=https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/$os/amd64/kubectl
  curl -sSL $download_url -o ~/.launch-cache/$executable
  chmod +x ~/.launch-cache/$executable
fi

create_links ~/.launch-cache/$executable kubectl
if [[ $os != darwin ]]; then
  sudo setcap CAP_NET_BIND_SERVICE=+ep ~/.launch-cache/$executable
fi

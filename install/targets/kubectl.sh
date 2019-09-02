#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
source $LAB_HOME/install/funcs.sh

target::step "Start to install kubectl"
ensure_command "kubectl" && exit
ensure_k8s_version || exit

# set version per kubernetes version
case $K8S_VERSION in
  "v1.12")
    kubectl_version="v1.12.10";;
  "v1.13")
    kubectl_version="v1.13.8";;
  "v1.14")
    kubectl_version="v1.14.4";;
  "v1.15")
    kubectl_version="v1.15.1";;
esac

os=$(uname -s | tr '[:upper:]' '[:lower:]')
executable="kubectl-$kubectl_version-$os"

if [[ ! -f ~/.launch-cache/$executable ]]; then
  target::step "Download kubectl"
  [[ -n $https_proxy ]] && target::log "https_proxy detected: $https_proxy"
  download_url=https://storage.googleapis.com/kubernetes-release/release/$kubectl_version/bin/$os/amd64/kubectl
  curl -sSL $download_url -o ~/.launch-cache/$executable
  sudo chmod +x ~/.launch-cache/$executable
fi

target::step "Create link to kubectl"
sudo ln -sf ~/.launch-cache/$executable /usr/bin/kubectl
sudo ln -sf ~/.launch-cache/$executable /usr/sbin/kubectl

#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

ensure_command "kubectl" && exit
ensure_k8s_version

# set version per kubernetes version
case $DIND_K8S_VERSION in
  "v1.12")
    kubectl_version="v1.12.10";;
  "v1.13")
    kubectl_version="v1.13.8";;
  "v1.14")
    kubectl_version="v1.14.4";;
  "v1.15")
    kubectl_version="v1.15.1";;
esac

if [[ ! -f ~/.lab-k8s-cache/kubectl-$kubectl_version ]]; then
  [[ -n $https_proxy ]] && echo "* https_proxy detected: $https_proxy"
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  download_url=https://storage.googleapis.com/kubernetes-release/release/$kubectl_version/bin/$os/amd64/kubectl
  curl -sL $download_url -o ~/.lab-k8s-cache/kubectl-$kubectl_version
fi

sudo ln -sf ~/.lab-k8s-cache/kubectl-$kubectl_version /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl

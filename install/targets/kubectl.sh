#!/bin/bash

. /vagrant/install/funcs.sh

check_command "kubectl" && exit

# set version per kubernetes version
case $DIND_K8S_VERSION in
  "v1.12")
    kubectl_version="v1.12.10";;
  "v1.13")
    kubectl_version="v1.13.8";;
  "v1.14")
    kubectl_version="v1.14.4";;
  "*")
    echo "Unsupported Kubernetes version... exiting."
    exit 1
    ;;
esac

if [[ ! -f ~/.lab-k8s-cache/kubectl-$kubectl_version ]]; then
  [[ -n $https_proxy ]] && echo "* https_proxy detected: $https_proxy"
  download_url=https://storage.googleapis.com/kubernetes-release/release/$kubectl_version/bin/linux/amd64/kubectl
  curl -sL $download_url -o ~/.lab-k8s-cache/kubectl-$kubectl_version
fi

sudo ln -sf ~/.lab-k8s-cache/kubectl-$kubectl_version /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl

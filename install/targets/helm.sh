#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

ensure_k8s_version || exit

# set version per kubernetes version
case $K8S_VERSION in
  "v1.12")
    HELM_VERSION="v2.12.3";;
  "v1.13")
    HELM_VERSION="v2.13.1";;
  "v1.14")
    HELM_VERSION="v2.14.2";;
  "v1.15")
    HELM_VERSION="v2.14.2";;
esac

os=$(uname -s | tr '[:upper:]' '[:lower:]')
helm_tgz="helm-$HELM_VERSION-$os-amd64.tar.gz"
if [[ ! -f ~/.lab-k8s-cache/$helm_tgz ]]; then
  curl -sL https://get.helm.sh/$helm_tgz -o ~/.lab-k8s-cache/$helm_tgz
fi
tar -zxf ~/.lab-k8s-cache/$helm_tgz

sudo mv ./$os-amd64/helm /usr/local/bin/helm
rm -rf ./$os-amd64

if [[ $IS_IN_CHINA == 1 ]]; then
  tiller_image="mr.io/kubernetes-helm-tiller:$HELM_VERSION"
  stable_repo="https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts"
  helm init -i $tiller_image --stable-repo-url $stable_repo

  cat ~/.bashrc | grep -q "^# helm hacks$" || \
  cat << EOF >>~/.bashrc

# helm hacks
function helm() {
  if [[ \$1 == "init" ]]; then
    set -- "\$@" -i $tiller_image --stable-repo-url $stable_repo
    echo "helm init using $tiller_image, $stable_repo..."
  fi
  command helm \$@
}
EOF
else
  helm init
fi

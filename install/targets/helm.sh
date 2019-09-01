#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
source $LAB_HOME/install/funcs.sh

target::step "start to install helm"
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
package="helm-$HELM_VERSION-$os-amd64"

if [ ! -f ~/.launch-cache/$package.tar.gz ]; then
  target::step "download helm"
  curl -sSL https://get.helm.sh/$package.tar.gz -o ~/.launch-cache/$package.tar.gz
fi

if [ ! -d ~/.launch-cache/$package ]; then
  target::step "extract helm package"
  mkdir ~/.launch-cache/$package
  tar -zxf ~/.launch-cache/$package.tar.gz -C ~/.launch-cache/$package
fi

target::step "create link to helm"
sudo ln -sf ~/.launch-cache/$package/$os-amd64/helm /usr/bin/helm
sudo ln -sf ~/.launch-cache/$package/$os-amd64/helm /usr/sbin/helm

target::step "run helm init"
if [[ $IS_IN_CHINA == 1 ]]; then
  stable_repo="https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts"
  helm init --stable-repo-url $stable_repo

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

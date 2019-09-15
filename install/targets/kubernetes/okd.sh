#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
. $INSTALL_HOME/funcs.sh

ensure_k8s_provider "okd" || exit

OKD_INSTALL_HOME=$INSTALL_HOME/.launch-cache/okd
OKD_VERSION=${OKD_VERSION:-v3.11.0}
OKD_COMMIT=${OKD_COMMIT:-0cbc58b}

ensure_os || exit

function okd::init {
  case "$(detect_os)" in
  ubuntu|centos|rhel)
    local package="openshift-origin-client-tools-$OKD_VERSION-$OKD_COMMIT-linux-64bit"
    local package_file=$package.tar.gz
    ;;
  darwin)
    local package="openshift-origin-client-tools-$OKD_VERSION-$OKD_COMMIT-mac"
    local package_file=$package.zip
    ;;
  esac

  if [[ ! -f ~/.launch-cache/$package_file ]]; then
    target::step "Download openshift"
    download_url=https://github.com/openshift/origin/releases/download/$OKD_VERSION/$package_file
    curl -sSL $download_url -o ~/.launch-cache/$package_file
  fi

  if [ ! -d ~/.launch-cache/$package ]; then
    target::step "Extract openshift package"
    mkdir ~/.launch-cache/$package
    tar -zxf ~/.launch-cache/$package_file -C ~/.launch-cache/$package
  fi

  target::step "Create link to oc"
  sudo ln -sf ~/.launch-cache/$package/oc /usr/bin/oc
  sudo ln -sf ~/.launch-cache/$package/oc /usr/sbin/oc

  target::step "Create link to kubectl"
  if [[ -f ~/.launch-cache/$package/kubectl ]]; then
    sudo ln -sf ~/.launch-cache/$package/kubectl /usr/bin/kubectl
    sudo ln -sf ~/.launch-cache/$package/kubectl /usr/sbin/kubectl
  fi

  okd::up
}

function okd::up {
  target::step "Take kubernetes cluster up"
  mkdir -p $OKD_INSTALL_HOME
  oc cluster up --public-hostname=$HOST_IP --base-dir=$OKD_INSTALL_HOME --write-config=false

  add_endpoint "common" "OKD Console" "https://$HOST_IP:8443/console"
}

function okd::down {
  target::step "Take kubernetes cluster down"
  oc cluster down
}

function okd::clean {
  target::step "Clean kubernetes cluster"

  clean_endpoints "common"

  okd::down

  rm -rf $OKD_INSTALL_HOME
}

target::command $@

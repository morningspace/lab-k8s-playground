#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
. $INSTALL_HOME/funcs.sh

OC_INSTALL_HOME=${OC_INSTALL_HOME:-~/openshift.local.clusterup}
OC_VERSION=${OC_VERSION:-v3.11.0}
OC_COMMIT=${OC_COMMIT:-0cbc58b}

ensure_os || exit

function kubernetes::init {
  case "$(detect_os)" in
  ubuntu|centos|rhel)
    local package="openshift-origin-client-tools-$OC_VERSION-$OC_COMMIT-linux-64bit"
    local package_file=$package.tar.gz
    ;;
  darwin)
    local package="openshift-origin-client-tools-$OC_VERSION-$OC_COMMIT-mac"
    local package_file=$package.zip
    ;;
  esac

  if [[ ! -f ~/.launch-cache/$package_file ]]; then
    target::step "Download OpenShift client tools"
    download_url=https://github.com/openshift/origin/releases/download/$OC_VERSION/$package_file
    curl -sSL $download_url -o ~/.launch-cache/$package_file
  fi

  if [ ! -d ~/.launch-cache/$package ]; then
    target::step "Extract OpenShift package"
    mkdir ~/.launch-cache/$package
    tar -zxf ~/.launch-cache/$package_file -C ~/.launch-cache/
  fi

  create_links ~/.launch-cache/$package/oc oc

  if [[ -f ~/.launch-cache/$package/kubectl ]]; then
    create_links ~/.launch-cache/$package/kubectl kubectl
  fi

  kubernetes::up
}

function kubernetes::up {
  target::step "Take kubernetes cluster up"

  mkdir -p $OC_INSTALL_HOME

  if ensure_os_linux && grep -q "^docker:" /etc/group; then
    run_cmd="sg docker -c"
  else
    run_cmd="eval"
  fi  

  local http_proxy=$($run_cmd "docker info -f {{.HTTPProxy}}")
  local https_proxy=$($run_cmd "docker info -f {{.HTTPSProxy}}")
  [[ -n $http_proxy ]] && opts+=" --http-proxy=$http_proxy"
  [[ -n $https_proxy ]] && opts+=" --https-proxy=$https_proxy"

  $run_cmd "oc cluster up --public-hostname=$HOST_IP --base-dir=$OC_INSTALL_HOME $opts"

  add_endpoint "common" "OpenShift Console" "https://$HOST_IP:8443/console"
}

function kubernetes::down {
  target::step "Take kubernetes cluster down"
  oc cluster down
}

function kubernetes::clean {
  target::step "Clean kubernetes cluster"

  clean_endpoints "common" "OpenShift Console"

  kubernetes::down

  local os=$(detect_os)
  if [[ $os == rhel || $os == centos ]]; then
    # https://github.com/openshift/origin/pull/2629
    findmnt -lo TARGET | grep openshift.local.volumes | xargs -r sudo umount
    sudo rm -rf $OC_INSTALL_HOME
  elif [[ $os == ubuntu ]]; then
    findmnt -lo TARGET -t tmpfs | grep openshift.local.volumes | sort -u | xargs -r sudo umount
    sudo rm -rf $OC_INSTALL_HOME
  else
    rm -rf $OC_INSTALL_HOME
  fi
}

function kubernetes::env {
  printenv_common
  printenv_provider OC_INSTALL_HOME
}

target::command $@

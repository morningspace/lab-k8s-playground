#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
. $INSTALL_HOME/funcs.sh

CACHE_HOME=$INSTALL_HOME/.launch-cache

CRC_INSTALL_HOME=$HOME/.crc
CRC_VERSION=${CRC_VERSION:-1.0.0-rc.0}
CRC_OPENSHIFT_VERSION=${CRC_OPENSHIFT_VERSION:-4.2.0-0.nightly-2019-09-26-192831}
CRC_MEMORY=${CRC_MEMORY:-8192}
CRC_CPUS=${CRC_CPUS:-4}
CRC_USE_VIRTUALBOX=${CRC_USE_VIRTUALBOX:-}

virtualbox_bundle="crc_virtualbox_$CRC_OPENSHIFT_VERSION.crcbundle"

os=$(detect_os)
case $os in
ubuntu|centos|rhel)
  package="crc-linux-amd64"
  pkg_pattern="crc-linux.\+-amd64"
  ;;
darwin)
  package="crc-macos-amd64"
  pkg_pattern="crc-macos.\+-amd64"
  ;;
esac

function kubernetes::init {
  target::step "Install Dependencies"

  case $os in
  centos|rhel)
    # su -c 'yum install NetworkManager'
    sudo yum install -y NetworkManager xz
    unzip_cmd="unxz -f"
    untar_cmd="tar -xf"
    ;;
  ubuntu)
    sudo apt-get install -y qemu-kvm libvirt-daemon libvirt-daemon-system network-manager xz-utils
    unzip_cmd="unxz -f"
    untar_cmd="tar -xf"
    ;;
  darwin)
    unzip_cmd="gunzip -f"
    untar_cmd="tar -zxf"
    ;;
  esac
  
  local target=$CACHE_HOME/$package
  if [[ ! -f $target-$CRC_VERSION.tar ]]; then
    if [[ ! -f $target-$CRC_VERSION.tar.xz ]]; then
      target::step "Download OpenShift CRC"
      local download_url=https://mirror.openshift.com/pub/openshift-v4/clients/crc/$CRC_VERSION/$package.tar.xz
      curl -sSL $download_url -o $target-$CRC_VERSION.tar.xz
    fi
    $unzip_cmd $target-$CRC_VERSION.tar.xz
    rm -rf $target
  fi

  if [[ -n $CRC_USE_VIRTUALBOX && ! -f $CACHE_HOME/$virtualbox_bundle ]]; then
    target::step "Download OpenShift CRC VirtualBox Bundle"
    download_url=https://mirror.openshift.com/pub/openshift-v4/clients/crc/latest/$virtualbox_bundle
    curl -sSL $download_url -o $CACHE_HOME/$virtualbox_bundle
  fi

  if [[ ! -d $target ]] ; then
    target::step "Extract OpenShift CRC package"
    $untar_cmd $target-$CRC_VERSION.tar -C $CACHE_HOME/
    local extracted=$(ls -d $CACHE_HOME/*/ | grep $pkg_pattern)
    mv $extracted $target
  fi

  create_links $target/crc crc

  target::step "Update OpenShift CRC configuration"

  crc config set memory $CRC_MEMORY
  crc config set cpus $CRC_CPUS

  crc setup

  # https://github.com/code-ready/crc/issues/618
  if [[ $os == darwin ]]; then
    [[ $(stat -f '%A' /etc/hosts) == 644 ]] || sudo chmod 0644 /etc/hosts
    [[ $(stat -f '%A' /etc/resolver/testing) == 600 ]] || sudo chmod 0600 /etc/resolver/testing
  fi

  kubernetes::up

  # eval $(crc oc-env)
  create_links $HOME/.crc/bin/oc oc
}

function kubernetes::up {
  target::step "Take kubernetes cluster up"

  local opt
  if [[ -n $CRC_USE_VIRTUALBOX ]]; then
    opt+=" --vm-driver virtualbox --bundle $CACHE_HOME/$virtualbox_bundle"
  fi
  if [[ -f $CRC_INSTALL_HOME/pull-secret.txt ]]; then
    opt+=" --pull-secret-file $CRC_INSTALL_HOME/pull-secret.txt"
  fi

  crc start $opt

  add_endpoint "common" "OpenShift Console" $(crc console --url)
}

function kubernetes::down {
  target::step "Take kubernetes cluster down"

  # crc status >/dev/null 2>&1 && \
  # crc status | grep "^CRC VM:" | grep -q Running && \
  crc stop # --force
}

function kubernetes::clean {
  clean_endpoints "common" "OpenShift Console"

  kubernetes::down

  target::step "Clean kubernetes cluster"

  # crc status >/dev/null 2>&1 && \
  crc delete --force # --clear-cache

  if [[ $os == darwin ]];  then
    [[ $(stat -f '%u' /etc/hosts) == 0 ]] || sudo chown root /etc/hosts
  fi
}

function kubernetes::env {
  printenv_common
  printenv_provider CRC_VERSION CRC_OPENSHIFT_VERSION CRC_MEMORY CRC_CPUS CRC_USE_VIRTUALBOX
}

target::command $@

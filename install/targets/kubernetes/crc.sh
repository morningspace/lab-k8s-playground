#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
. $INSTALL_HOME/funcs.sh

CACHE_HOME=$INSTALL_HOME/.launch-cache

CRC_INSTALL_HOME=$HOME/.crc
CRC_USE_VIRTUALBOX=${CRC_USE_VIRTUALBOX:-}

virtualbox_bundle="crc_virtualbox_4.1.14.crcbundle"

function kubernetes::init {
  case "$(detect_os)" in
  ubuntu|centos|rhel)
    local os="linux"
    local package="crc-$os-amd64"
    # stat -c "%a" filename
    # stat -c "%U" filename
    ;;
  darwin)
    local os="macos"
    local package="crc-$os-amd64"
    ;;
  esac

  local target=$CACHE_HOME/$package
  if [[ ! -f $target.tar ]]; then
    target::step "Download OpenShift CRC"
    local download_url=https://mirror.openshift.com/pub/openshift-v4/clients/crc/latest/$package.tar.xz
    curl -sSL $download_url -o $target.tar.xz
    gunzip -f $target.tar.xz # macos?
    rm -rf $target
  fi

  if [[ -n $CRC_USE_VIRTUALBOX && ! -f $CACHE_HOME/$virtualbox_bundle ]]; then
    target::step "Download OpenShift CRC VirtualBox Bundle"
    download_url=https://mirror.openshift.com/pub/openshift-v4/clients/crc/latest/$virtualbox_bundle
    curl -sSL $download_url -o $CACHE_HOME/$virtualbox_bundle
  fi

  if [[ ! -d $target ]] ; then
    target::step "Extract OpenShift CRC package"
    tar -zxf $target.tar -C $CACHE_HOME/
    local extracted=$(ls -d $CACHE_HOME/*/ | grep "crc-$os.\+-amd64")
    mv $extracted $target
  fi

  target::step "Create link to crc"
  if [[ $os == macos ]]; then
    ln -sf $target/crc /usr/local/bin/crc
  else
    sudo ln -sf $target/crc /usr/bin/crc
    sudo ln -sf $target/crc /usr/sbin/crc
  fi

  crc setup

  # https://github.com/code-ready/crc/issues/618
  [[ $(stat -f '%A' /etc/hosts) == 644 ]] || sudo chmod 0644 /etc/hosts
  [[ $(stat -f '%A' /etc/resolver/testing) == 600 ]] || sudo chmod 0600 /etc/resolver/testing

  kubernetes::up

  # eval $(crc oc-env)
  target::step "Create link to oc"
  if [[ $os == macos ]]; then
    ln -sf $HOME/.crc/bin/oc /usr/local/bin/oc
  else
    sudo ln -sf $HOME/.crc/bin/oc /usr/bin/oc
    sudo ln -sf $HOME/.crc/bin/oc /usr/sbin/oc
  fi
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

  crc status >/dev/null 2>&1 && \
  crc status | grep "^CRC VM:" | grep -q Running && \
  crc stop --force
}

function kubernetes::clean {
  kubernetes::down

  target::step "Clean kubernetes cluster"

  crc status >/dev/null 2>&1 && \
  crc delete --force # --clear-cache

  [[ $(stat -f '%u' /etc/hosts) == 0 ]] || sudo chown root /etc/hosts
}

function kubernetes::env {
  printenv_common
  printenv_provider CRC_USE_VIRTUALBOX
}

target::command $@

#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
. $INSTALL_HOME/funcs.sh

ensure_k8s_provider || exit
target_shell="$INSTALL_HOME/targets/istio/istio-$K8S_PROVIDER.sh"

function istio::init {
  LAB_HOME=$LAB_HOME $target_shell init
}

function istio::clean {
  LAB_HOME=$LAB_HOME $target_shell clean
}

function istio::portforward {
  LAB_HOME=$LAB_HOME $target_shell portforward
}

target::command $@

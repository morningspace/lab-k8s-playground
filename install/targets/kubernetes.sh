#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

ensure_k8s_provider || exit
target_shell="$INSTALL_HOME/targets/kubernetes/$K8S_PROVIDER.sh"

function kubernetes::init {
  LAB_HOME=$LAB_HOME $target_shell init
}

function kubernetes::up {
  LAB_HOME=$LAB_HOME $target_shell up
}

function kubernetes::down {
  LAB_HOME=$LAB_HOME $target_shell down
}

function kubernetes::clean {
  LAB_HOME=$LAB_HOME $target_shell clean
}

function kubernetes::snapshot {
  LAB_HOME=$LAB_HOME $target_shell snapshot
}

target::command $@

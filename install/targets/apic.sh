#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

ensure_k8s_provider || exit
target_shell="$INSTALL_HOME/targets/apic/apic-$K8S_PROVIDER.sh"

function apic::init {
  LAB_HOME=$LAB_HOME $target_shell init
}

function apic::validate {
  LAB_HOME=$LAB_HOME $target_shell validate
}

function apic::clean {
  LAB_HOME=$LAB_HOME $target_shell clean
}

function apic::portforward {
  LAB_HOME=$LAB_HOME $target_shell portforward
}

target::command $@

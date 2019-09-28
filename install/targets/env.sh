#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
. $INSTALL_HOME/funcs.sh

target::log LAB_HOME=$LAB_HOME
target::log HOST_IP=$HOST_IP
target::log K8S_PROVIDER=$K8S_PROVIDER
target::log K8S_VERSION=$K8S_VERSION
target::log NUM_NODES=$NUM_NODES

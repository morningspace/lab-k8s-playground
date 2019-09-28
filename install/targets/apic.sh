#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
. $LAB_HOME/install/funcs.sh
target::delegate apic/apic-$K8S_PROVIDER.sh $@

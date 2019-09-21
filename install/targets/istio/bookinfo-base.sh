#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}

. $LAB_HOME/install/funcs.sh

function on_before_init {
  :
}

function init {
  on_before_init

  target::step "Start to install istio-bookinfo"

  pushd ~/.launch-cache/istio

  kubectl label namespace default istio-injection=enabled --overwrite
  kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml -n default
  kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml -n default

  wait_for_app "default" "bookinfo"\
    "app=details,version=v1" "app=productpage,version=v1" "app=ratings,version=v1" \
    "app=reviews,version=v1" "app=reviews,version=v2" "app=reviews,version=v3"

  popd

  on_after_init
}

function on_after_init {
  :
}

function on_before_clean {
  :
}

function clean {
  on_before_clean

  pushd ~/.launch-cache/istio
  samples/bookinfo/platform/kube/cleanup.sh
  popd

  on_after_clean
}

function on_after_clean {
  :
}

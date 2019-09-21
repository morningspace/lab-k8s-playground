#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}

. $LAB_HOME/install/targets/istio/bookinfo-base.sh

function on_after_init {
  add_endpoint "istio" "Istio Bookinfo" "http://@@HOST_IP:31380/productpage"
}

function on_before_clean {
  clean_endpoints "istio" "Istio Bookinfo"
}

function bookinfo-dind::init {
  init
}

function bookinfo-dind::clean {
  clean
}

function istio-bookinfo::portforward {
  kill_portfwds "31380:80"
  create_portfwd istio-system service/istio-ingressgateway 31380:80
}

target::command $@

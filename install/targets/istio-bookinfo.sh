#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
source $LAB_HOME/install/funcs.sh

HOST_IP=${HOST_IP:-127.0.0.1}

function istio-bookinfo::init {
  target::step "Start to install istio-bookinfo"

  pushd ~/.launch-cache/istio

  kubectl config set-context --current --namespace=default
  kubectl label namespace default istio-injection=enabled --overwrite
  kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
  kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

  wait_for_app "default" "bookinfo"\
    "app=details,version=v1" "app=productpage,version=v1" "app=ratings,version=v1" \
    "app=reviews,version=v1" "app=reviews,version=v2" "app=reviews,version=v3"

  add_endpoint "istio" "Istio Bookinfo" "http://@@HOST_IP:31380/productpage"

  popd
}

function istio-bookinfo::clean {
  pushd ~/.launch-cache/istio
  clean_endpoints "istio" "Istio Bookinfo"
  samples/bookinfo/platform/kube/cleanup.sh
  popd
}

function istio-bookinfo::portforward {
  kill_portfwds "31380:80"
  create_portfwd istio-system service/istio-ingressgateway 31380:80
}

target::command $@

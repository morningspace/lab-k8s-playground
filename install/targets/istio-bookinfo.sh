#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

HOST_IP=${HOST_IP:-127.0.0.1}

function init {
  pushd ~/.lab-k8s-cache/istio

  kubectl config set-context --current --namespace=default
  kubectl label namespace default istio-injection=enabled --overwrite
  kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
  kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

  wait_for_app "default" "bookinfo"\
    "app=details,version=v1" "app=productpage,version=v1" "app=ratings,version=v1" \
    "app=reviews,version=v1" "app=reviews,version=v2" "app=reviews,version=v3"

  kill_portfwds "31380:80"
  kubectl -n istio-system port-forward --address $HOST_IP service/istio-ingressgateway 31380:80 >/dev/null &

  popd
}

function clean {
  pushd ~/.lab-k8s-cache/istio
  samples/bookinfo/platform/kube/cleanup.sh
  popd
}

command=${1:-init}

case $command in
  "init") init;;
  "clean") clean;;
  *) echo "* unkown command";;
esac

#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
source $LAB_HOME/install/funcs.sh

ISTIO_VERSION="1.2.2"
HOST_IP=${HOST_IP:-127.0.0.1}
case $(uname -s) in
  "Linux") package="istio-$ISTIO_VERSION-linux";;
  "Darwin") package="istio-$ISTIO_VERSION-osx";;
esac

function istio::init {
  if [ ! -f ~/.launch-cache/$package.tar.gz ]; then
    target::step "download istio"
    download_url=https://github.com/istio/istio/releases/download/$ISTIO_VERSION/$package.tar.gz
    curl -sSL $download_url -o ~/.launch-cache/$package.tar.gz
  fi
  if [ ! -d ~/.launch-cache/istio ]; then
    target::step "extract istio package"
    tar -zxf ~/.launch-cache/$package.tar.gz -C ~/.launch-cache/
    mv ~/.launch-cache/istio{-$ISTIO_VERSION,}
  fi

  target::step "start to install istio"
  pushd ~/.launch-cache/istio

  for yaml in install/kubernetes/helm/istio-init/files/crd*yaml; do
    kubectl apply -f $yaml
  done

  sleep 3

  kubectl apply -f install/kubernetes/istio-demo.yaml

  wait_for_app "istio-system" "istio" "app=istio-ingressgateway"

  add_endpoint "istio" "Grafana" "http://@@HOST_IP:3000"
  add_endpoint "istio" "Kiali" "http://@@HOST_IP:20001"
  add_endpoint "istio" "Jaeger" "http://@@HOST_IP:15032"
  add_endpoint "istio" "Prometheus" "http://@@HOST_IP:9090"

  popd
}

function istio::clean {
  pushd ~/.launch-cache/istio
  clean_endpoints "istio"
  kubectl delete -f install/kubernetes/istio-demo.yaml
  popd
}

function istio::portforward {
  kill_portfwds "3000:3000" "20001:20001" "15032:16686" "9090:9090"

  create_portfwd istio-system service/grafana 3000:3000
  create_portfwd istio-system service/kiali 20001:20001
  create_portfwd istio-system pod/jaeger 15032:16686
  create_portfwd istio-system pod/prometheus 9090:9090
}

target::command $@

#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
source $LAB_HOME/install/funcs.sh

ISTIO_VERSION="1.2.2"
HOST_IP=${HOST_IP:-127.0.0.1}

function istio::init {
  istio_tgz="istio-$ISTIO_VERSION-linux.tar.gz"
  if [[ ! -f ~/.lab-k8s-cache/$istio_tgz ]]; then
    download_url=https://github.com/istio/istio/releases/download/$ISTIO_VERSION/$istio_tgz
    curl -sL $download_url -o ~/.lab-k8s-cache/$istio_tgz
  fi
  if [[ ! -d ~/.lab-k8s-cache/istio ]]; then
    tar -zxf ~/.lab-k8s-cache/$istio_tgz -C ~/.lab-k8s-cache
    mv ~/.lab-k8s-cache/istio{-$ISTIO_VERSION,}
  fi

  target::step "start to install istio"

  pushd ~/.lab-k8s-cache/istio

  for yaml in install/kubernetes/helm/istio-init/files/crd*yaml; do
    kubectl apply -f $yaml
  done

  sleep 3

  kubectl apply -f install/kubernetes/istio-demo.yaml

  wait_for_app "istio-system" "istio" "app=istio-ingressgateway"

  add_endpoint "istio" "Grafana" "http://$HOST_IP:3000"
  add_endpoint "istio" "Kiali" "http://$HOST_IP:20001"
  add_endpoint "istio" "Jaeger" "http://$HOST_IP:15032"
  add_endpoint "istio" "Prometheus" "http://$HOST_IP:9090"

  popd
}

function istio::clean {
  pushd ~/.lab-k8s-cache/istio
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

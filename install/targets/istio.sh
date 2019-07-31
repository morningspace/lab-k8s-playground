#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

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

  pushd ~/.lab-k8s-cache/istio

  for yaml in install/kubernetes/helm/istio-init/files/crd*yaml; do
    kubectl apply -f $yaml
  done

  sleep 3

  kubectl apply -f install/kubernetes/istio-demo.yaml

  wait_for_app "istio-system" "istio" "app=istio-ingressgateway"

  kill_portfwds "3000:3000" "20001:20001" "15032:16686" "9090:9090"
  kubectl -n istio-system port-forward --address $HOST_IP service/grafana 3000:3000 >/dev/null &
  kubectl -n istio-system port-forward --address $HOST_IP service/kiali 20001:20001 >/dev/null &
  kubectl -n istio-system port-forward --address $HOST_IP $(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 15032:16686 >/dev/null &
  kubectl -n istio-system port-forward --address $HOST_IP $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 >/dev/null &

  popd
}

function istio::clean {
  pushd ~/.lab-k8s-cache/istio
  kubectl delete -f install/kubernetes/istio-demo.yaml
  popd
}

run_target_command $@

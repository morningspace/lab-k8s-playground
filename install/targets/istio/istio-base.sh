#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}

. $LAB_HOME/install/funcs.sh

ISTIO_VERSION="1.2.2"

function on_before_init {
  :
}

function init {
  on_before_init

  case $(uname -s) in
    "Linux") package="istio-$ISTIO_VERSION-linux";;
    "Darwin") package="istio-$ISTIO_VERSION-osx";;
  esac

  if [ ! -f ~/.launch-cache/$package.tar.gz ]; then
    target::step "Download istio"
    download_url=https://github.com/istio/istio/releases/download/$ISTIO_VERSION/$package.tar.gz
    curl -sSL $download_url -o ~/.launch-cache/$package.tar.gz
  fi

  if [ ! -d ~/.launch-cache/istio ]; then
    target::step "Extract istio package"
    tar -zxf ~/.launch-cache/$package.tar.gz -C ~/.launch-cache/
    mv ~/.launch-cache/istio{-$ISTIO_VERSION,}
  fi

  target::step "Start to install istio"
  pushd ~/.launch-cache/istio

  for yaml in install/kubernetes/helm/istio-init/files/crd*yaml; do
    kubectl apply -f $yaml
  done

  sleep 3

  kubectl apply -f install/kubernetes/istio-demo.yaml

  wait_for_app "istio-system" "istio" "app=istio-ingressgateway"

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
  kubectl delete -f install/kubernetes/istio-demo.yaml
  popd

  on_after_clean
}

function on_after_clean {
  :
}

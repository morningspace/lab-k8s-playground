#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}

. $LAB_HOME/install/funcs.sh

ISTIO_VERSION="1.2.2"

function on_before_init {
  :
}

function istio::init {
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

function istio::clean {
  on_before_clean

  pushd ~/.launch-cache/istio

  for yaml in install/kubernetes/helm/istio-init/files/crd*yaml; do
    kubectl delete -f $yaml
  done

  kubectl delete -f install/kubernetes/istio-demo.yaml 2>/dev/null

  popd

  on_after_clean
}

function on_after_clean {
  :
}

function on_before_init_bookinfo {
  :
}

function istio-bookinfo::init {
  on_before_init_bookinfo

  target::step "Start to install istio-bookinfo"

  pushd ~/.launch-cache/istio

  kubectl label namespace default istio-injection=enabled --overwrite
  kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml -n default
  kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml -n default

  wait_for_app "default" "bookinfo"\
    "app=details,version=v1" "app=productpage,version=v1" "app=ratings,version=v1" \
    "app=reviews,version=v1" "app=reviews,version=v2" "app=reviews,version=v3"

  popd

  on_after_init_bookinfo
}

function on_after_init_bookinfo {
  :
}

function on_before_clean_bookinfo {
  :
}

function istio-bookinfo::clean {
  on_before_clean_bookinfo

  pushd ~/.launch-cache/istio
  samples/bookinfo/platform/kube/cleanup.sh
  popd

  on_after_clean_bookinfo
}

function on_after_clean_bookinfo {
  :
}

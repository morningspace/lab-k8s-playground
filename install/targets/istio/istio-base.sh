#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
. $LAB_HOME/install/funcs.sh

ISTIO_VERSION="1.2.2"
ISTIO_INSTALL_MODE=
ISTIO_CNI_ENABLED=

function on_before_init {
  :
}

function download_pkg {
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
}

function install_crds {
  if [[ $ISTIO_INSTALL_MODE == helm ]]; then
    (kubectl get namespace | grep -q istio-system) || \
    kubectl create namespace istio-system

    target::step "Install CRDs"

    helm template install/kubernetes/helm/istio-init \
      --name istio-init --namespace istio-system | kubectl apply -f -

    while (( $(kubectl get crds 2>/dev/null | grep 'istio.io' | wc -l) != 23 )); do
      echo -n "." >&2
      sleep 1
    done
    echo "[done]" >&2
  fi
}

function install_istio {
  target::step "Start to install istio"

  if [[ $ISTIO_INSTALL_MODE == helm ]]; then
    if [[ $ISTIO_CNI_ENABLED == true ]]; then
      local exclude_ns="istio-system,kube-system"
      helm template install/kubernetes/helm/istio-cni \
        --name=istio-cni --namespace=kube-system \
        --set logLevel=info --set excludeNamespaces={$exclude_ns} | kubectl apply -f -
    fi

    helm template install/kubernetes/helm/istio \
      --name istio --namespace istio-system \
      --set istio_cni.enabled=$ISTIO_CNI_ENABLED \
      --set gateways.istio-ingressgateway.type=NodePort \
      --values install/kubernetes/helm/istio/values-istio-demo.yaml | kubectl apply -f -
  else
    kubectl apply -f install/kubernetes/istio-demo.yaml
  fi

  wait_for_app "istio-system" "istio" "app=istio-ingressgateway"
}

function install_all {
  pushd ~/.launch-cache/istio
  install_crds
  install_istio
  popd
}

function add_endpoints {
  :
}

function istio::init {
  download_pkg
  on_before_init
  install_all
  on_after_init
  add_endpoints
}

function on_after_init {
  :
}

function on_before_clean {
  :
}

function delete_crds {
  if [[ $ISTIO_INSTALL_MODE == helm ]]; then
    target::step "Delete CRDs"
    for yaml in install/kubernetes/helm/istio-init/files/crd*yaml; do
      kubectl delete -f $yaml 2>/dev/null
    done
  fi
}

function delete_istio {
  target::step "Start to uninstall istio"
  if [[ $ISTIO_INSTALL_MODE == helm ]]; then
    helm template install/kubernetes/helm/istio \
      --name istio --namespace istio-system \
      --set istio_cni.enabled=$ISTIO_CNI_ENABLED \
      --values install/kubernetes/helm/istio/values-istio-demo.yaml | kubectl delete -f -

    if [[ $ISTIO_CNI_ENABLED == true ]]; then
      helm template install/kubernetes/helm/istio-cni \
        --name=istio-cni --namespace=kube-system | kubectl delete -f -
    fi

    (kubectl get namespace | grep -q istio-system) && \
    kubectl delete namespace istio-system
  else
    kubectl delete -f install/kubernetes/istio-demo.yaml 2>/dev/null
  fi
}

function delete_all {
  pushd ~/.launch-cache/istio
  delete_istio
  delete_crds
  popd
}

function istio::clean {
  clean_endpoints "istio"
  on_before_clean
  delete_all
  on_after_clean
}

function on_after_clean {
  :
}

function on_before_init_bookinfo {
  :
}

function install_bookinfo {
  pushd ~/.launch-cache/istio

  target::step "Start to install istio-bookinfo"
  kubectl label namespace default istio-injection=enabled --overwrite
  kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml -n default
  kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml -n default
  wait_for_app "default" "bookinfo"\
    "app=details,version=v1" "app=productpage,version=v1" "app=ratings,version=v1" \
    "app=reviews,version=v1" "app=reviews,version=v2" "app=reviews,version=v3"

  popd
}

function add_endpoints_bookinfo {
  :
}

function istio-bookinfo::init {
  on_before_init_bookinfo
  install_bookinfo
  on_after_init_bookinfo
  add_endpoints_bookinfo
}

function on_after_init_bookinfo {
  :
}

function on_before_clean_bookinfo {
  :
}

function istio-bookinfo::clean {
  clean_endpoints "istio" "Istio Bookinfo"
  on_before_clean_bookinfo
  target::step "Start to uninstall istio-bookinfo"
  NAMESPACE=default ~/.launch-cache/istio/samples/bookinfo/platform/kube/cleanup.sh
  on_after_clean_bookinfo
}

function on_after_clean_bookinfo {
  :
}

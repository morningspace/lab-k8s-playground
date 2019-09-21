#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}

. $LAB_HOME/install/targets/istio/bookinfo-base.sh

function on_before_init {
  # Add scc to group for bookinfo
  oc adm policy add-scc-to-group privileged system:serviceaccounts -n default
  oc adm policy add-scc-to-group anyuid system:serviceaccounts -n default
}

function on_after_init {
  oc expose svc/istio-ingressgateway --port=http2 -n istio-system
  add_endpoint "istio" "Istio Bookinfo" "http://istio-ingressgateway-istio-system.@@HOST_IP.nip.io/productpage"
}

function on_before_clean {
  clean_endpoints "istio" "Istio Bookinfo"

  oc get route istio-ingressgateway -n istio-system 1>/dev/null 2>&1 && \
  oc delete route istio-ingressgateway -n istio-system

  oc adm policy remove-scc-from-group privileged system:serviceaccounts -n default
  oc adm policy remove-scc-from-group anyuid system:serviceaccounts -n default
}

function bookinfo-oc::init {
  init
}

function bookinfo-oc::clean {
  clean
}

target::command $@

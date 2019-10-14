#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
. $LAB_HOME/install/targets/istio/istio-base.sh
. $LAB_HOME/install/targets/istio/istio-openshift.sh

ISTIO_INSTALL_MODE=helm
ISTIO_CNI_ENABLED=true

function login_as_admin {
  local adm_p=$(crc console --credentials | grep kubeadmin | sed "s/.*password is '\(.*\)'./\1/")
  oc login -u kubeadmin -p $adm_p https://api.crc.testing:6443
}

function add_endpoints {
  target::step "Add endpoints for istio"
  add_endpoint "istio" "Grafana" "http://grafana-istio-system.apps-crc.testing"
  add_endpoint "istio" "Kiali" "http://kiali-istio-system.apps-crc.testing"
  add_endpoint "istio" "Prometheus" "http://prometheus-istio-system.apps-crc.testing"
  add_endpoint "istio" "Jaeger" "http://jaeger-query-istio-system.apps-crc.testing"
}

function add_endpoints_bookinfo {
  target::step "Add endpoints for istio-bookinfo"
  add_endpoint "istio" "Istio Bookinfo" "http://istio-ingressgateway-istio-system.apps-crc.testing/productpage"
}

target::command $@

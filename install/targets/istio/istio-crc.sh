#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
. $LAB_HOME/install/targets/istio/istio-base.sh
. $LAB_HOME/install/targets/istio/istio-openshift.sh

ISTIO_INSTALL_MODE=helm
ISTIO_CNI_ENABLED=true

function login_as_admin {
  oc login -u kubeadmin -p BMLkR-NjA28-v7exC-8bwAk https://api.crc.testing:6443
  # oc login -u kubeadmin -p F44En-Xau6V-jQuyb-yuMXB https://api.crc.testing:6443
}

function add_endpoints {
  add_endpoint "istio" "Grafana" "http://grafana-istio-system.apps-crc.testing"
  add_endpoint "istio" "Kiali" "http://kiali-istio-system.apps-crc.testing"
  add_endpoint "istio" "Prometheus" "http://prometheus-istio-system.apps-crc.testing"
  add_endpoint "istio" "Jaeger" "http://jaeger-query-istio-system.apps-crc.testing"
}

function add_endpoints_bookinfo {
  add_endpoint "istio" "Istio Bookinfo" "http://istio-ingressgateway-istio-system.apps-crc.testing/productpage"
}

target::command $@

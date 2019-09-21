#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}

. $LAB_HOME/install/targets/istio/istio-base.sh

function on_after_init {
  add_endpoint "istio" "Grafana" "http://@@HOST_IP:3000"
  add_endpoint "istio" "Kiali" "http://@@HOST_IP:20001"
  add_endpoint "istio" "Jaeger" "http://@@HOST_IP:15032"
  add_endpoint "istio" "Prometheus" "http://@@HOST_IP:9090"
}

function on_before_clean {
  clean_endpoints "istio"
}

function istio-dind::init {
  init
}

function istio-dind::clean {
  clean
}

function istio-dind::portforward {
  kill_portfwds "3000:3000" "20001:20001" "15032:16686" "9090:9090"

  create_portfwd istio-system service/grafana 3000:3000
  create_portfwd istio-system service/kiali 20001:20001
  create_portfwd istio-system pod/jaeger 15032:16686
  create_portfwd istio-system pod/prometheus 9090:9090
}

target::command $@

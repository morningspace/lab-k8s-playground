#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
. $LAB_HOME/install/targets/istio/istio-base.sh
. $LAB_HOME/install/targets/istio/istio-openshift.sh

function login_as_admin {
  oc login -u system:admin https://$HOST_IP:8443
}

function enable_admission_webhook {
  target::step "Enable AdmissionWebhook"

  OC_INSTALL_HOME=${OC_INSTALL_HOME:-~/openshift.local.clusterup}
  master_config=$OC_INSTALL_HOME/kube-apiserver/master-config
  if cat $master_config.yaml | grep -q "MutatingAdmissionWebhook:"; then
    target::log "AdmissionWebhook detected"
  else
    cp -p $master_config.yaml{,.prepatch}
    cat >> $master_config.patch << EOF
admissionConfig:
  pluginConfig:
    MutatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
    ValidatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
EOF
    oc ex config patch $master_config.yaml.prepatch -p "$(cat $master_config.patch)" > $master_config.yaml

    target::log "Restart Openshift API Server"

    local container_id
    if [[ $(detect_os) == darwin ]]; then
      container_id=$(get_container_id_by_pod master-api-localhost kube-system)
      $(run_docker_as_sudo) "docker restart $container_id"
    else
      container_id=$($(run_docker_as_sudo) "docker ps -l -q --filter 'label=io.kubernetes.container.name=api'")
      $(run_docker_as_sudo) "docker restart $container_id"
    fi
    container_id=$($(run_docker_as_sudo) "docker ps -l -q --filter 'label=io.kubernetes.container.name=apiserver'")
    $(run_docker_as_sudo) "docker restart $container_id"

    target::log "Waiting for health check passed"
    until curl -f -s -k -o /dev/null https://$HOST_IP:8443/healthz; do echo -n .; sleep 1; done
    target::log "[done]"

    target::log "Waiting for oc login passed"
    until echo fakepasswd | oc login -u system:admin >/dev/null 2>&1; do echo -n .; sleep 1; done
    target::log "[done]"

    target::log "Waiting for scc check passed"
    until oc adm policy add-scc-to-user anyuid -z default -n istio-system >/dev/null 2>&1; do echo -n .; sleep 1; done
    target::log "[done]"
  fi
}

function add_endpoints {
  target::step "Add endpoints for istio"
  add_endpoint "istio" "Grafana" "http://grafana-istio-system.@@HOST_IP.nip.io"
  add_endpoint "istio" "Kiali" "http://kiali-istio-system.@@HOST_IP.nip.io"
  add_endpoint "istio" "Jaeger" "http://jaeger-query-istio-system.@@HOST_IP.nip.io"
  add_endpoint "istio" "Prometheus" "http://prometheus-istio-system.@@HOST_IP.nip.io"
}

function add_endpoints_bookinfo {
  target::step "Add endpoints for istio-bookinfo"
  add_endpoint "istio" "Istio Bookinfo" "http://istio-ingressgateway-istio-system.@@HOST_IP.nip.io/productpage"
}

target::command $@

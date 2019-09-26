#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}

. $LAB_HOME/install/targets/istio/istio-base.sh

OC_INSTALL_HOME=${OC_INSTALL_HOME:-~/openshift.local.clusterup}

if [[ $(detect_os) == darwin ]]; then
  target::log "Istio deployment on OpenShift is supported on MacOS"
  exit
fi

function on_before_init {
  target::step "Enable AdmissionWebhook"

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

    target::step "Restart Openshift"

    docker restart origin
    docker restart $(docker ps -l -q --filter "label=io.kubernetes.container.name=api")
    docker restart $(docker ps -l -q --filter "label=io.kubernetes.container.name=apiserver")
    until curl -f -k https://$HOST_IP:8443/healthz; do sleep 1; done

    sleep 60
  fi

  target::step "Add scc to user for istio"

  oc login -u system:admin
  oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z default -n istio-system
  oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-egressgateway-service-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-citadel-service-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-ingressgateway-service-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-cleanup-old-ca-service-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-mixer-post-install-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-mixer-service-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-sidecar-injector-service-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-galley-service-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-security-post-install-account -n istio-system

  target::step "Create cluster role bindings for istio"

  oc get clusterrolebindings kiali-binding 1>/dev/null 2>&1 || \
  oc create clusterrolebinding kiali-binding --clusterrole=cluster-admin --user=system:serviceaccount:istio-system:kiali-service-account
}

function on_after_init {
  target::step "Expose service routes for istio"

  oc get route grafana -n istio-system 1>/dev/null 2>&1 || \
  oc expose svc/grafana --port=http -n istio-system
  oc get route kiali -n istio-system 1>/dev/null 2>&1 || \
  oc expose svc/kiali --port=http-kiali -n istio-system
  oc get route prometheus -n istio-system 1>/dev/null 2>&1 || \
  oc expose svc/prometheus --port=http-prometheus -n istio-system
  oc get route jaeger-query -n istio-system 1>/dev/null 2>&1 || \
  oc expose svc/jaeger-query --port=query-http -n istio-system

  add_endpoint "istio" "Grafana" "http://grafana-istio-system.@@HOST_IP.nip.io"
  add_endpoint "istio" "Kiali" "http://kiali-istio-system.@@HOST_IP.nip.io"
  add_endpoint "istio" "Prometheus" "http://prometheus-istio-system.@@HOST_IP.nip.io"
  add_endpoint "istio" "Jaeger" "http://jaeger-query-istio-system.@@HOST_IP.nip.io"
}

function on_before_clean {
  clean_endpoints "istio"

  target::step "Delete service routes for istio"

  oc get route grafana -n istio-system 1>/dev/null 2>&1 && \
  oc delete route grafana -n istio-system
  oc get route kiali -n istio-system 1>/dev/null 2>&1 && \
  oc delete route kiali -n istio-system
  oc get route prometheus -n istio-system 1>/dev/null 2>&1 && \
  oc delete route prometheus -n istio-system
  oc get route jaeger-query -n istio-system 1>/dev/null 2>&1 && \
  oc delete route jaeger-query -n istio-system

  target::step "Delete scc from user for istio"

  oc adm policy remove-scc-from-user anyuid -z istio-ingress-service-account -n istio-system
  oc adm policy remove-scc-from-user anyuid -z default -n istio-system
  oc adm policy remove-scc-from-user anyuid -z prometheus -n istio-system
  oc adm policy remove-scc-from-user anyuid -z istio-egressgateway-service-account -n istio-system
  oc adm policy remove-scc-from-user anyuid -z istio-citadel-service-account -n istio-system
  oc adm policy remove-scc-from-user anyuid -z istio-ingressgateway-service-account -n istio-system
  oc adm policy remove-scc-from-user anyuid -z istio-cleanup-old-ca-service-account -n istio-system
  oc adm policy remove-scc-from-user anyuid -z istio-mixer-post-install-account -n istio-system
  oc adm policy remove-scc-from-user anyuid -z istio-mixer-service-account -n istio-system
  oc adm policy remove-scc-from-user anyuid -z istio-pilot-service-account -n istio-system
  oc adm policy remove-scc-from-user anyuid -z istio-sidecar-injector-service-account -n istio-system
  oc adm policy remove-scc-from-user anyuid -z istio-galley-service-account -n istio-system
  oc adm policy remove-scc-from-user anyuid -z istio-security-post-install-account -n istio-system

  target::step "Delete cluster role bindings for istio"

  oc get clusterrolebinding kiali-binding 1>/dev/null 2>&1 && \
  oc delete clusterrolebinding kiali-binding
}

function on_before_init_bookinfo {
  target::step "Add scc to group for bookinfo"

  oc adm policy add-scc-to-group privileged system:serviceaccounts -n default
  oc adm policy add-scc-to-group anyuid system:serviceaccounts -n default
}

function on_after_init_bookinfo {
  target::step "Expose service routes for bookinfo"

  oc get route istio-ingressgateway -n istio-system 1>/dev/null 2>&1 || \
  oc expose svc/istio-ingressgateway --port=http2 -n istio-system
  add_endpoint "istio" "Istio Bookinfo" "http://istio-ingressgateway-istio-system.@@HOST_IP.nip.io/productpage"
}

function on_before_clean_bookinfo {
  clean_endpoints "istio" "Istio Bookinfo"

  target::step "Delete service routes for bookinfo"

  oc get route istio-ingressgateway -n istio-system 1>/dev/null 2>&1 && \
  oc delete route istio-ingressgateway -n istio-system

  target::step "Delete scc from group for bookinfo"

  oc adm policy remove-scc-from-group privileged system:serviceaccounts -n default
  oc adm policy remove-scc-from-group anyuid system:serviceaccounts -n default
}

target::command $@

#!/bin/bash

accounts=(
  istio-ingress-service-account
  default
  prometheus
  istio-egressgateway-service-account
  istio-citadel-service-account
  istio-ingressgateway-service-account
  istio-cleanup-old-ca-service-account
  istio-mixer-post-install-account
  istio-mixer-service-account
  istio-pilot-service-account
  istio-sidecar-injector-service-account
  istio-galley-service-account
  istio-security-post-install-account
)

routes_istio=(
  "grafana,http"
  "kiali,http-kiali"
  "prometheus,http-prometheus"
  "jaeger-query,query-http"
)

routes_bookinfo=(
  "istio-ingressgateway,http2"
)

bindings=(
  "kiali-binding,kiali-service-account"
)

function login_as_admin {
  :
}

function enable_admission_webhook {
  :
}

function add_scc_to_user {
  target::step "Add scc to user for istio"
  for $acount in ${accounts[@]}; do
    oc adm policy add-scc-to-user anyuid -z $account -n istio-system
  done
}

function create_role_bindings {
  target::step "Create cluster role bindings for istio"
  for $binding in ${bindings[@]}; do
    oc get clusterrolebindings ${binding%,*} 1>/dev/null 2>&1 || \
    oc create clusterrolebinding ${binding%,*} --clusterrole=cluster-admin \
      --user=system:serviceaccount:istio-system:${binding#*,}
  done
}

function on_before_init {
  login_as_admin
  enable_admission_webhook
  add_scc_to_user
  create_role_bindings
}

function expose_routes {
  target::step "Expose service routes for $1"
  local routes=(${@:2})
  for $route in ${routes[@]}; do
    oc get route ${route%,*} -n istio-system 1>/dev/null 2>&1 || \
    oc expose svc/${route%,*} --port=${route#*,} -n istio-system
  done
}

function expose_routes_istio {
  expose_routes "istio" ${routes_istio[@]}
}

function on_after_init {
  expose_routes_istio
}

function delete_routes {
  target::step "Delete service routes for $1"
  local routes=(${@:2})
  for $route in ${routes[@]}; do
    oc get route ${route%,*} -n istio-system 1>/dev/null 2>&1 && \
    oc delete route ${route%,*} -n istio-system
  done
}

function delete_routes_istio {
  delete_routes "istio" ${routes_istio[@]}
}

function on_before_clean {
  login_as_admin
  delete_routes
}

function delete_scc_from_user {
  target::step "Delete scc from user for istio"
  for $acount in ${accounts[@]}; do
    oc adm policy remove-scc-from-user anyuid -z $account -n istio-system
  done
}

function delete_role_bindings {
  target::step "Delete cluster role bindings for istio"
  for $binding in ${bindings[@]}; do
    oc get clusterrolebinding ${binding%,*} 1>/dev/null 2>&1 && \
    oc delete clusterrolebinding ${binding%,*}
  done
}

function on_after_clean {
  delete_scc_from_user
  delete_role_bindings
}

function on_before_init_bookinfo {
  target::step "Add scc to group for bookinfo"
  oc adm policy add-scc-to-group privileged system:serviceaccounts -n default
  oc adm policy add-scc-to-group anyuid system:serviceaccounts -n default
}

function expose_routes_bookinfo {
  expose_routes "bookinfo" ${routes_bookinf[@]}
}

function on_after_init_bookinfo {
  expose_routes_bookinfo
}

function delete_routes_bookinfo {
  delete_routes "bookinfo" ${routes_bookinfo[@]}
}

function on_before_clean_bookinfo {
  delete_routes_bookinfo
}

function on_after_clean_bookinfo {
  target::step "Delete scc from group for bookinfo"
  oc adm policy remove-scc-from-group privileged system:serviceaccounts -n default
  oc adm policy remove-scc-from-group anyuid system:serviceaccounts -n default
}

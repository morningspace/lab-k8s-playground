#!/bin/bash

function is_app_ready {
  local out
  if ! out="$(kubectl get pod -n $1 -l "$2" -o jsonpath='{ .items[*].status.conditions[?(@.type == "Ready")].status }' 2>/dev/null)"; then
    return 1
  fi
  if ! grep -v False <<<"${out}" | grep -q True; then
    return 1
  fi
  return 0
}

function wait_for_app {
  namespace=$1
  app_name=$2
  app_label=$3
  num_tries=500
  echo "* Waiting for $app_name to be up..."
  while ! is_app_ready $namespace $app_label; do
    if ((--num_tries == 0)); then
      echo "* Error bringing up $app_name" >&2
      exit 1
    fi
    # echo -n "." >&2
    sleep 1
  done
  echo "[done]" >&2
}

function ensure_command {
  if command -v $1 >/dev/null 2>&1; then
    echo "* $1 detected"
    return 0
  fi
  return 1
}

function ensure_box {
  if [[ $(uname -s) == Linux ]]; then
    echo "* vagrant box detected"
    return 0
  fi
  return 1
}

function ensure_k8s_version {
  valid="v1.12 v1.13 v1.14"
  if [[ ! $valid =~ $DIND_K8S_VERSION ]]; then
    echo "* Kubernetes version not supported, valid values: $valid"
    return 1
  fi
  return 0
}
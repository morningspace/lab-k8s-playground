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

function is_app_ready_by_labels {
  local namespace=$1
  local app_labels=("${@:2}");
  local res=()
  for label in ${app_labels[@]}; do
    is_app_ready $namespace "$label" && res+=(True) || res+=(False)
  done
  [[ ${res[@]} =~ False ]] && return 1 || return 0
}

function wait_for_app {
  local namespace=$1
  local app_name=$2
  local app_labels=("${@:3}")
  local num_tries=500
  echo "* Waiting for $app_name to be up..."
  while ! is_app_ready_by_labels $namespace ${app_labels[@]}; do
    if ((--num_tries == 0)); then
      echo "* Error bringing up $app_name" >&2
      exit 1
    fi
    echo -n "." >&2
    sleep 1
  done
  echo "[done]" >&2
}

function kill_portfwds {
  if [[ $# == 0 ]]; then
    killall kubectl
  else
    local mappings=$@
    for mapping in ${mappings[@]}; do
      local existing=$(ps aux | grep [k]ubectl.*$mapping | awk '{print $2}')
      [[ -n $existing ]] && kill $existing
    done
  fi
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
  local valid="v1.12 v1.13 v1.14"
  if [[ ! $valid =~ $DIND_K8S_VERSION ]]; then
    echo "* Kubernetes version not supported, valid values: $valid"
    return 1
  fi
  return 0
}
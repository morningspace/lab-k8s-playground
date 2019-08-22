#!/bin/bash

logs_dir=$LAB_HOME/install/logs
endpoints_dir=$LAB_HOME/install/targets/endpoints

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
  target::step "waiting for $app_name to be up"
  while ! is_app_ready_by_labels $namespace ${app_labels[@]}; do
    if ((--num_tries == 0)); then
      echo "error bringing up $app_name" >&2
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

function create_portfwd {
  local ns=$1 app=${2#*/} apptype=${2%%/*}
  local logfile=$logs_dir/pfwd-$app.log

  mkdir -p $logs_dir

  target::step "Forwarding ${@:2}"
  if [[ $apptype == pod ]]; then
    local pod=$(kubectl -n $ns get pod -l app=$app -o jsonpath='{.items[0].metadata.name}')
    if [[ -n "$pod" ]]; then
      nohup kubectl -n $ns port-forward --address $HOST_IP $pod ${@:3} > $logfile 2>&1 &
      target::log "Done. Please check $logfile"
    fi
  else
    nohup kubectl -n $ns port-forward --address $HOST_IP ${@:2} > $logfile 2>&1 &
    target::log "Done. Please check $logfile"
  fi
}

function ensure_command {
  if command -v $1 >/dev/null 2>&1; then
    echo "$1 detected"
    return 0
  fi
  return 1
}

function ensure_box {
  if [[ $(uname -s) == Linux ]]; then
    echo "vagrant box detected"
    return 0
  fi
  return 1
}

function ensure_k8s_version {
  local valid="v1.12 v1.13 v1.14 v1.15"
  if [[ -z $K8S_VERSION || ! $valid =~ $K8S_VERSION ]]; then
    echo "Kubernetes version not supported, valid values: $valid"
    return 1
  fi
  return 0
}

function add_endpoint {
  mkdir -p $endpoints_dir

  local group_file=$endpoints_dir/$1
  if [ ! -f $group_file ]; then
    touch $group_file
  fi

  if ! cat $group_file | grep -q "^$2"; then
    echo "$2,$3,$4" >> $group_file
  fi
}

function clean_endpoints {
  local group_file=$endpoints_dir/$1
  if [ -z "$2" ] ; then
    rm -f $group_file
  elif [ -f "$group_file" ] ; then
    sed -i "/$2/d" $group_file
  fi
}

function print_endpoints {
  local group=$1
  local endpoints=("${@:2}")

  target::step "$group endpoints"

  local max_len=0
  for endpoint in "${endpoints[@]}" ; do
    IFS=',' read -ra parts <<< "$endpoint"
    (( ${#parts[0]} > $max_len )) && max_len=${#parts[0]}
  done

  for endpoint in "${endpoints[@]}" ; do
    IFS=',' read -ra parts <<< "$endpoint"

    curl -s -k -o /dev/null ${parts[1]}
    local ret=$?
    case $ret in
      0) status="✔";;
      7|6|52) status="✗";;
      *) status="?";;
    esac

    printf "%s %`echo $max_len`s: %s %s\n" $status "${parts[@]}"
  done
}

function get_first_command {
  local pattern="^function $1::\w\+ {$"
  local funcs=($(grep "$pattern" $0 | awk '{print $2}'))
  echo "${funcs[0]#*::}"
}

function target::command {
  local target=${0##*/}
  target=${target%.sh}
  local command=${1:-$(get_first_command $target)}
  if [[ $(type -t $target::$command) == function ]]; then
    $target::$command
  else
    echo "function $target::$command not found in $0"
  fi
}

# yellow => '\033[1;33m'
# normal => '\033[0m'
function target::step {
  echo -e "\033[1;33m» $@...\033[0m"
}

function target::log {
  echo "$1"
}

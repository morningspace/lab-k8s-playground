#!/bin/bash

trap exit INT

logs_dir=$LAB_HOME/install/logs
targets_dir=$LAB_HOME/install/targets
endpoints_dir=$LAB_HOME/install/targets/endpoints

HOST_IP=${HOST_IP:-127.0.0.1}

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
  target::step "Waiting for $app_name to be up"
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

function ensure_os {
  local valid="darwin ubuntu centos rhel"
  local detected=$(detect_os)
  if [[ ! $valid =~ $detected ]]; then
    echo "OS $detected not supported, supported OS: $valid"
    return 1
  fi
  return 0
}

function ensure_os_linux {
  [[ $(uname -s) == Linux ]] && return 0 || return 255
}

function ensure_k8s_version {
  [[ $K8S_PROVIDER == oc ]] && K8S_VERSION= &&return 0

  local valid="v1.12 v1.13 v1.14 v1.15"
  K8S_VERSION=${K8S_VERSION:-v1.14}
  if [[ ! $valid =~ $K8S_VERSION ]]; then
    echo "Kubernetes version not supported, valid values: $valid"
    return 1
  fi
  return 0
}

function ensure_k8s_provider {
  local valid="dind oc crc"

  K8S_PROVIDER=${K8S_PROVIDER:-dind}
  if [[ ! $valid =~ $K8S_PROVIDER ]]; then
    echo "Kubernetes provider not supported, valid values: $valid"
    return 1
  fi

  if [[ -n $1 && $1 != $K8S_PROVIDER ]]; then
    echo "Kubernetes provider must be $1, but is $K8S_PROVIDER"
    return 1
  fi

  return 0
}

function detect_os {
  local os=$(uname -s | tr '[:upper:]' '[:lower:]')
  if [ $os == "linux" ] && [ -r /etc/os-release ] ; then
    os="$(. /etc/os-release && echo "$ID")"
  fi
  echo $os
}

function run_docker_as_sudo {
  if ensure_os_linux && grep -q "^docker:" /etc/group; then
    echo "sg docker -c"
  elif grep -q "^dockerroot:" /etc/group; then
    echo "sg dockerroot -c"
  else
    echo "eval"
  fi  
}

my_registries=(
  "127.0.0.1:5000"
  "${HOSTNAME:-localhost}:5000"
  "mr.io:5000"
)

function get_insecure_registries {
  local registries=(${my_registries[@]})
  if [[ $K8S_PROVIDER == oc ]]; then
    registries+=("172.30.0.0/16")
  fi
  echo "${registries[@]}"
}

function get_insecure_registries_text {
  local registries=($(get_insecure_registries))
  local text=$(printf ", \"%s\"" "${registries[@]}")
  echo ${text:2}
}

function update_docker_daemon_json {
  local daemon_json_file="/etc/docker/daemon.json"
  local jq=()
  if [[ -f $daemon_json_file ]] ; then
    jq+=("$(cat $daemon_json_file)")
  else
    jq+=("{}")
  fi

  for entry in "$@"; do
    jq+=("{ $entry }")
  done

  local json=$(IFS="+"; echo "${jq[*]}")
  jq -n "$json" | sudo tee $daemon_json_file
}

function capitalize {
  local capitalized=""
  capitalized+="$(tr '[:lower:]' '[:upper:]' <<<"${1:0:1}")"
  capitalized+="$(tr '[:upper:]' '[:lower:]' <<<"${1:1}")"
  echo $capitalized
}

function add_endpoint {
  mkdir -p $endpoints_dir

  local group_file=$endpoints_dir/$1
  if [ ! -f $group_file ]; then
    touch $group_file
  fi

  if ! cat $group_file | grep -q -i "^$2"; then
    echo "$2,$3,$4" >> $group_file
  else
    [[ $(detect_os) == darwin ]] && \
      sed -i "" "s%^$2.*$%$2,$3,$4%g" $group_file || \
      sed -i "s%^$2.*$%$2,$3,$4%gI" $group_file
  fi
}

function clean_endpoints {
  local group_file=$endpoints_dir/$1
  if [ -z "$2" ] ; then
    rm -f $group_file
  elif [ -f "$group_file" ] ; then
    [[ $(detect_os) == darwin ]] && \
      sed -i "" "/$2/d" $group_file || \
      sed -i "/$2/d" $group_file
  fi
}

function print_endpoints {
  local group=$1
  local endpoints=("${@:2}")

  printf "$(capitalize "${group/-/ }"):\n"

  local max_len=0
  for endpoint in "${endpoints[@]}" ; do
    IFS=',' read -ra parts <<< "$endpoint"
    (( ${#parts[0]} > $max_len )) && max_len=${#parts[0]}
  done

  for endpoint in "${endpoints[@]}" ; do
    IFS=',' read -ra parts <<< "$endpoint"

    parts[1]=${parts[1]/@@HOST_IP/$HOST_IP}
    curl -s -k -o /dev/null ${parts[1]}
    local ret=$?
    case $ret in
      0) status="✔";;
      7|6|52) status="✗";;
      *) status="?";;
    esac

    printf "  %s %-`echo $max_len`s: %s %s\n" $status "${parts[@]}"
  done

  printf "\n"
}

function printenv_common {
  printf "Common:\n"
  printf "  %-12s: %s\n" LAB_HOME $LAB_HOME
  printf "  %-12s: %s\n" HOST_IP $HOST_IP
  printf "  %-12s: %s\n\n" K8S_PROVIDER $K8S_PROVIDER
}

function printenv_provider {
  local max_len=0
  for key in "$@" ; do
    (( ${#key} > $max_len )) && max_len=${#key}
  done

  printf "Specific to $K8S_PROVIDER:\n"
  for key in "$@" ; do
    printf "  %-`echo $max_len`s: %s\n" $key $(eval "echo \$$key")
  done
  printf "\n"
}

function get_container_id_by_pod {
  local container_id=$(kubectl get pod $1 -n $2 -o jsonpath={.status.containerStatuses[0].containerID})
  echo ${container_id#"docker://"} | sed 's/^\(.\{12\}\).*/\1/'
}

function get_first_command {
  local pattern="^function $1::\w\+ {$"

  local embedded_shells=($(grep "\. " $0 | awk '{print $2}'))
  for embedded_shell in ${embedded_shells[@]}; do
    embedded_file=$(eval "echo $embedded_shell")
    if [[ -f $embedded_file ]]; then
      local funcs=($(grep "$pattern" $embedded_file | awk '{print $2}'))
      [[ ! -z ${funcs[0]} ]] && echo "${funcs[0]#*::}" && return
    fi
  done

  local funcs=($(grep "$pattern" $0 | awk '{print $2}'))
  echo "${funcs[0]#*::}"
}

function create_links {
  target::step "Create link to $2"

  case "$(detect_os)" in
  ubuntu|centos|rhel)
    sudo ln -sf $1 /usr/bin/$2
    sudo ln -sf $1 /usr/sbin/$2
    ;;
  darwin)
    ln -sf $1 /usr/local/bin/$2
    ;;
  esac
}

function target::command {
  local target cmd 
  if [[ $1 =~ :: ]]; then
    target=${1/%::*}
    cmd=${1/#*::}
    cmd=${cmd:-$(get_first_command $target)}
  else
    target=${0##*/}
    target=${target%.sh}
    if [[ $1 != -* && ! -z $1 ]]; then
      cmd=$1
    fi
    cmd=${cmd:-$(get_first_command $target)}
  fi

  if [[ $(type -t $target::$cmd) == function ]]; then
    $target::$cmd ${@:2}
  else
    echo "function $target::$cmd not found in $0"
  fi
}

function target::delegate {
  local target_shell="$targets_dir/$1"
  local target cmd
  if [[ $2 != -* && ! -z $2 ]]; then
    cmd=$2
    shift
  fi
  if [[ ! $cmd =~ :: ]]; then
    target=${0##*/}
    target=${target%.sh}
    cmd=$target::$cmd
  fi

  LAB_HOME=$LAB_HOME $target_shell $cmd ${@:2}
}

# yellow => '1;33'
# purple => '1;35'
# red    => '1;31'
# normal => '0'
function target::step {
  echo -e "\033[1;33m» $@...\033[0m"
}

function target::log {
  echo -e "\033[1mINFO \033[0m $@"
}

function target::warn {
  echo -e "\033[1;35mWARN \033[0m $@"
}

function target::error {
  echo -e "\033[1;31mERROR\033[0m $@"
}

ensure_k8s_provider || exit

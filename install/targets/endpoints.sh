#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

endpoints_dir=$INSTALL_HOME/targets/endpoints

apiserver_port=$($INSTALL_HOME/dind-cluster.sh apiserver-port 2>/dev/null)
endpoints=(
  "Web terminal,https://$HOST_IP:4200"
  "Dashboard,http://$HOST_IP:$apiserver_port/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy"
)
print_endpoints "common" "${endpoints[@]}"

if [[ -d $endpoints_dir ]]; then
  groups=($(ls $endpoints_dir))
  for group in "${groups[@]}" ; do
    endpoints=()
    while IFS='' read -r line || [[ -n "$line" ]] ; do
      endpoints+=("$line")
    done < $endpoints_dir/$group
    print_endpoints $group "${endpoints[@]}"
  done
fi

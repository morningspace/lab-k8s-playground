#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
HOST_IP=${DIND_HOST_IP:-127.0.0.1}

apiserver_port=$($INSTALL_HOME/dind-cluster.sh apiserver-port 2>/dev/null)
endpoints=(
  "Web terminal|https://$HOST_IP:4200"
  "Dashboard|http://$HOST_IP:$apiserver_port/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy"
  "Istio Bookinfo|http://$HOST_IP:31380/productpage"
  "Grafana|http://$HOST_IP:3000"
  "Kiali|http://$HOST_IP:20001"
  "Jaeger|http://$HOST_IP:15032"
  "Prometheus|http://$HOST_IP:9090"
)

for endpoint in "${endpoints[@]}" ; do
  app=${endpoint/%|*}
  url=${endpoint/#*|}

  curl -s -o /dev/null $url

  if [[ $? == 7 ]]; then
    status="✗"
  else
    status="✔"
  fi

  printf "%s %14s: %s\n" $status "$app" $url
done
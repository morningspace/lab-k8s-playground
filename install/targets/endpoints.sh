#!/bin/bash

apiserver_port=$(/vagrant/install/dind-cluster.sh apiserver-port)

endpoints=(
  "Web terminal|https://$DIND_HOST_IP:4200"
  "Dashboard|http://$DIND_HOST_IP:$apiserver_port/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy"
  "Istio Bookinfo|http://$DIND_HOST_IP:31380/productpage"
  "Grafana|http://$DIND_HOST_IP:3000"
  "Kiali|http://$DIND_HOST_IP:20001"
  "Jaeger|http://$DIND_HOST_IP:15032"
  "Prometheus|http://$DIND_HOST_IP:9090"
)

for endpoint in "${endpoints[@]}" ; do
  app=${endpoint/%|*}
  url=${endpoint/#*|}
  status="✗"

  if [[ $app == "Web terminal" ]]; then
    status="✔"
  else
    curl -s -o /dev/null $url && status="✔"
  fi

  printf "%s %14s: %s\n" $status "$app" $url
done
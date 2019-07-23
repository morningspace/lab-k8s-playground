#!/bin/bash

pushd ~/.lab-k8s-cache/istio

kubectl config set-context --current --namespace=default
kubectl label namespace default istio-injection=enabled --overwrite
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

kubectl -n istio-system port-forward --address $DIND_HOST_IP service/istio-ingressgateway 31380:80 >/dev/null &

popd

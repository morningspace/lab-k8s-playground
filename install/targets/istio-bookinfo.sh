#!/bin/bash

pushd ~/.lab-k8s-cache/istio

kubectl config set-context --current --namespace=default
kubectl label namespace default istio-injection=enabled --overwrite
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

popd

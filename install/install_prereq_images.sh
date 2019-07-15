#!/bin/bash

# target registry address
dest_registry=127.0.0.1:5000
# k8s version
k8s_version=${DIND_K8S_VERSION:-v1.13}
# images to be pulled based on k8s version
case $k8s_version in
  "v1.12")
    images=(
    # k8s images
    morningspace/hyperkube:v1.12.8
    morningspace/kubernetes-dashboard-amd64:v1.10.1
    morningspace/pause:3.1
    morningspace/coredns:1.2.2
    morningspace/etcd:3.2.24
    morningspace/kubernetes-helm-tiller:v2.12.3
    # kubeadm-dind-cluster image
    morningspace/kubeadm-dind-cluster:814d9ca036b23adce9e6c683da532e8037820119-v1.12
    );;
  "v1.13")
    images=(
    # k8s images
    morningspace/hyperkube:v1.13.5
    morningspace/kubernetes-dashboard-amd64:v1.10.1
    morningspace/pause:3.1
    morningspace/coredns:1.2.6
    morningspace/etcd:3.2.24
    morningspace/kubernetes-helm-tiller:v2.13.1
    # kubeadm-dind-cluster image
    morningspace/kubeadm-dind-cluster:814d9ca036b23adce9e6c683da532e8037820119-v1.13
    );;
  "v1.14")
    images=(
    # k8s images
    morningspace/hyperkube:v1.14.1
    morningspace/kubernetes-dashboard-amd64:v1.10.1
    morningspace/pause:3.1
    morningspace/coredns:1.3.1
    morningspace/etcd:3.3.10
    morningspace/kubernetes-helm-tiller:v2.14.2
    # kubeadm-dind-cluster image
    morningspace/kubeadm-dind-cluster:814d9ca036b23adce9e6c683da532e8037820119-v1.14
    );;
  *)
    images=();;
esac

pushd /vagrant
docker-compose up -d mr.io

for image in ${images[@]} ; do  
  image_name=${image#*/}
  docker pull $image
  docker tag $image $dest_registry/${image_name/\//-}
  docker push $dest_registry/${image_name/\//-}
done  

docker-compose up -d 
popd

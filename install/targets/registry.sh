#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

ensure_k8s_version || exit

# images to be cached per kubernetes version
case $DIND_K8S_VERSION in
  "v1.12")
    images=(
    # k8s
    k8s.gcr.io/hyperkube:v1.12.8
    k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
    k8s.gcr.io/pause:3.1
    k8s.gcr.io/coredns:1.2.2
    k8s.gcr.io/etcd:3.2.24
    # kubeadm-dind-cluster
    mirantis/kubeadm-dind-cluster:814d9ca036b23adce9e6c683da532e8037820119-v1.12
    # helm
    gcr.io/kubernetes-helm/tiller:v2.12.3
    );;
  "v1.13")
    images=(
    # k8s
    k8s.gcr.io/hyperkube:v1.13.5
    k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
    k8s.gcr.io/pause:3.1
    k8s.gcr.io/coredns:1.2.6
    k8s.gcr.io/etcd:3.2.24
    # kubeadm-dind-cluster
    mirantis/kubeadm-dind-cluster:814d9ca036b23adce9e6c683da532e8037820119-v1.13
    # helm
    gcr.io/kubernetes-helm/tiller:v2.13.1
    );;
  "v1.14")
    images=(
    # k8s
    k8s.gcr.io/hyperkube:v1.14.1
    k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
    k8s.gcr.io/pause:3.1
    k8s.gcr.io/coredns:1.3.1
    k8s.gcr.io/etcd:3.3.10
    # kubeadm-dind-cluster
    mirantis/kubeadm-dind-cluster:814d9ca036b23adce9e6c683da532e8037820119-v1.14
    # helm
    gcr.io/kubernetes-helm/tiller:v2.14.2
    );;
esac

# registries have mirrors on docker hub
registries_mirrored=(
  k8s.gcr.io
  gcr.io
)
# registries that are local cached
registries_cached=(
  k8s.gcr.io
  gcr.io
  quay.io
  morningspace
)

# set up private registries
my_registry=127.0.0.1:5000
ensure_box
if [[ $? == 0 && ! -f /etc/docker/daemon.json ]]; then
  cat << EOF | sudo tee /etc/docker/daemon.json
{
  "insecure-registries" : ["$my_registry"],
  "registry-mirrors": ["http://127.0.0.1:5555"]
}
EOF

  sudo systemctl daemon-reload
  sudo systemctl restart docker
  sudo systemctl show --property=Environment docker
fi

sudo docker network inspect net-registry &>/dev/null || \
sudo docker network create net-registry
sudo docker volume create vol-mr.io

# start to pull images
pushd $LAB_HOME

sudo docker-compose up -d mr.io docker.io-mirror
sleep 3

[ -f install/targets/images.list ] && . install/targets/images.list

for image in ${images[@]} ; do  
  registry=${image%%/*}
  repository=${image#*/}
  if [[ $IS_IN_CHINA == 1 ]]; then
    if [[ ${registries_mirrored[@]} =~ $registry ]]; then
      registry=morningspace
      repository=${repository/\//-}
    fi
  fi

  sudo docker pull $registry/$repository
  
  if [[ ${registries_cached[@]} =~ $registry ]]; then
    sudo docker tag $registry/$repository $my_registry/$repository
    sudo docker push $my_registry/$repository
  fi
done  

sudo docker-compose up -d 

popd

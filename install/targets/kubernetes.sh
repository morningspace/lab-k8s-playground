#!/bin/bash

if [[ ! -f ~/.lab-k8s-cache/kubernetes-dashboard.yaml ]]; then
  download_url=https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
  curl -sL $download_url -o ~/.lab-k8s-cache/kubernetes-dashboard.yaml
fi

cat /etc/environment | grep -q "^# for kubeadm-dind-clusters$" || \
cat << EOF | sudo tee -a /etc/environment
# for kubeadm-dind-clusters
export DIND_REGISTRY_MIRROR=http://docker.io-mirror
export DASHBOARD_URL=/home/vagrant/.lab-k8s-cache/kubernetes-dashboard.yaml
export SKIP_SNAPSHOT=1
EOF

pushd /vagrant

sudo \
  DIND_K8S_VERSION=$DIND_K8S_VERSION \
  NUM_NODES=$NUM_NODES \
  DIND_HOST_IP=$DIND_HOST_IP \
  DIND_REGISTRY_MIRROR=http://docker.io-mirror \
  DASHBOARD_URL=/home/vagrant/.lab-k8s-cache/kubernetes-dashboard.yaml \
  SKIP_SNAPSHOT=1 \
./dind-cluster-wrapper.sh up

sudo chown -R vagrant:vagrant ~/.kube

popd

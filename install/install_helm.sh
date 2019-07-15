#!/bin/bash

pushd /vagrant/install

helm_tar="helm-${HELM_VERSION}-linux-amd64.tar.gz"
helm_tiller="mr.io/kubernetes-helm-tiller:${HELM_VERSION}"
stable_repo="https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts"
if [[ ! -f $helm_tar ]]; then
  curl -sLO "https://get.helm.sh/$helm_tar"
fi
tar -zxvf $helm_tar
sudo cp linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64
helm init -i $helm_tiller --stable-repo-url $stable_repo

cat << EOF >>~/.bashrc

# helm hacks
function helm() {
  if [[ \$1 == "init" ]]; then
    set -- "\$@" -i $helm_tiller --stable-repo-url $stable_repo
    echo "helm init using $helm_tiller, $stable_repo..."
  fi
  command helm \$@
}
EOF

popd

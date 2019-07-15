# set number of vcpus
cpus = '6'
# set amount of memory allocated by vm
memory = '8192'
# set ip of your host machine
host_ip = '192.168.56.100'

# set kubernetes version, supported versions: v1.12, v1.13, v1.14
k8s_version = "v1.14"
# set number of nodes
nodes = 3

# set https_proxy, e.g. 9.2.112.117:8080
https_proxy = ""

# set tools versions per kubernetes version
case k8s_version
when "v1.12"
  kubectl_version = "v1.12.10"
  helm_version = "v2.12.3"
when "v1.13"
  kubectl_version = "v1.13.8"
  helm_version = "v2.13.1"
when "v1.14"
  kubectl_version = "v1.14.4"
  helm_version = "v2.14.2"
else
  puts("Unsupported Kubernetes version... exiting.")
  exit 1
end

###############################################################################
#                  DO NOT MODIFY ANYTHING BELOW THIS POINT                    #
###############################################################################

rsa_private_key = IO.read(Vagrant::Util::Platform.fs_real_path("#{Vagrant.user_data_path}/insecure_private_key"))
user_home = "/home/vagrant"

configure_ssh_keys = <<SCRIPT
echo "#{rsa_private_key}" >> #{user_home}/.ssh/id_rsa
echo "$(cat #{user_home}/.ssh/authorized_keys)" >> #{user_home}/.ssh/id_rsa.pub
echo 'StrictHostKeyChecking no\nUserKnownHostsFile /dev/null\nLogLevel QUIET' >> #{user_home}/.ssh/config
SCRIPT

install_docker = <<SCRIPT
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-cache policy docker-ce
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

usermod -aG docker vagrant

# fix the issue `WARNING: No swap limit support`, need vagrant halt and up
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="cgroup_enable=memory swapaccount=1 /g' /etc/default/grub
update-grub

if [ -n "#{https_proxy}" ]; then
  echo "https_proxy #{https_proxy} defined"
  mkdir -p /etc/systemd/system/docker.service.d
  cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTPS_PROXY=#{https_proxy}"
EOF
fi

cat > /etc/docker/daemon.json <<'EOF'
{
  "insecure-registries" : ["mr.io"]
}
EOF

systemctl daemon-reload
systemctl restart docker
systemctl show --property=Environment docker
SCRIPT

install_docker_compose = <<SCRIPT
pushd /vagrant/install
docker_compose="docker-compose-$(uname -s)-$(uname -m)"
if [[ ! -f ./$docker_compose ]]; then
  curl -sLO "https://github.com/docker/compose/releases/download/1.24.0/$docker_compose"
fi
chmod +x ./$docker_compose
cp ./$docker_compose /usr/local/bin/docker-compose
popd
SCRIPT

install_kubectl = <<SCRIPT
pushd /vagrant/install
if [[ ! -f ./kubectl ]]; then
  curl_kubectl="curl -sLO https://storage.googleapis.com/kubernetes-release/release/#{kubectl_version}/bin/linux/amd64/kubectl"
  if [ -n "#{https_proxy}" ]; then
    echo "https_proxy #{https_proxy} defined"
    https_proxy=#{https_proxy} $curl_kubectl
  else
    $curl_kubectl
  fi
fi
chmod +x ./kubectl
cp ./kubectl /usr/local/bin/kubectl
popd
SCRIPT

prepare_net_and_volume = <<SCRIPT
docker network create net-registry
docker volume create vol-mr.io
SCRIPT

launch_kubernetes = <<SCRIPT
pushd /vagrant/install
if [[ ! -f kubernetes-dashboard.yaml ]]; then
  curl -sLO "https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml"
fi

DIND_K8S_VERSION=#{k8s_version} \
NUM_NODES=#{nodes} \
DIND_HOST_IP=#{host_ip} \
DIND_IMAGE_BASE=127.0.0.1:5000/kubeadm-dind-cluster \
SKIP_SNAPSHOT=1 \
DASHBOARD_URL=/vagrant/install/kubernetes-dashboard.yaml \
../dind-cluster-wrapper.sh up

cp -r /root/.kube #{user_home}/.kube
chown -R vagrant:vagrant #{user_home}/.kube

cat << EOF >>/etc/environment

# environment variables for kubeadm-dind-clusters
export DIND_K8S_VERSION=#{k8s_version}
export NUM_NODES=#{nodes}
export DIND_HOST_IP=#{host_ip}
export DIND_IMAGE_BASE=127.0.0.1:5000/kubeadm-dind-cluster
export SKIP_SNAPSHOT=1
export DASHBOARD_URL=/vagrant/install/kubernetes-dashboard.yaml
export HELM_VERSION=#{helm_version}
EOF
popd
SCRIPT

install_shellinabox = <<SCRIPT
apt-get install -y shellinabox &> /dev/null
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.box_version = "201906.18.0"

  config.vm.synced_folder ".", "/vagrant"

  config.ssh.forward_agent = true
  config.ssh.forward_x11 = true
  config.ssh.insert_key = false
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "lab-k8s-playground-#{k8s_version}"
    vb.customize ["modifyvm", :id, "--cpus", "#{cpus}"]
    vb.customize ["modifyvm", :id, "--memory", "#{memory}"]
  end

  config.vm.provision "shell", inline: configure_ssh_keys, keep_color: true, name: "configure_ssh_keys"
  config.vm.provision "shell", inline: install_docker, keep_color: true, name: "install_docker"
  config.vm.provision "shell", inline: install_docker_compose, keep_color: true, name: "install_docker_compose"
  config.vm.provision "shell", inline: install_kubectl, keep_color: true, name: "install_kubectl"
  config.vm.provision "shell", inline: prepare_net_and_volume, keep_color: true, name: "prepare_net_and_volume"
  config.vm.provision "shell", path: "install/install_prereq_images.sh", keep_color: true, name: "install_prereq_images", env: {"DIND_K8S_VERSION" => "#{k8s_version}"}
  config.vm.provision "shell", inline: launch_kubernetes, keep_color: true, name: "launch_kubernetes"
  config.vm.provision "shell", path: "install/install_helm.sh", keep_color: true, name: "install_helm", env: {"HELM_VERSION" => "#{helm_version}"}, privileged: false
  config.vm.provision "shell", path: "install/install_tools.sh", keep_color: true, name: "install_tools", privileged: false
  config.vm.provision "shell", inline: install_shellinabox, keep_color: true, name:"install_shellinabox"

  # config.vm.network :forwarded_port, guest: 4200, host: 4200, auto_correct: true
  config.vm.network "private_network", ip: "#{host_ip}"
end

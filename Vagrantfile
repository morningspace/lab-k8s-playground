# set number of vcpus
cpus = '6'
# set amount of memory allocated by vm
memory = '8192'

# set Kubernetes version, supported versions: v1.12, v1.13, v1.14
k8s_version = "v1.14"
# set number of worker nodes
nodes = 2
# set host ip of the box
host_ip = '192.168.56.100'

# special optimization for users in China
is_country_cn = 1
# set https proxy
https_proxy = ""

# optional targets to be run, can be customized as your need
targets = "helm tools istio"

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

configure_lab_env = <<SCRIPT
# install web terminal
apt-get install -y shellinabox

# create link to launch.sh
ln -sf /vagrant/install/launch.sh /usr/local/bin/launch

# configure lab cache
mkdir -p /vagrant/install/.lab-k8s-cache
ln -sf /vagrant/install/.lab-k8s-cache #{user_home}/.lab-k8s-cache

# configure env vars
cat << EOF | tee -a /etc/environment

# environment variables for lab-k8s-playground
export DIND_K8S_VERSION=#{k8s_version}
export NUM_NODES=#{nodes}
export DIND_HOST_IP=#{host_ip}
export IS_COUNTRY_CN=#{is_country_cn}
export https_proxy=#{https_proxy}
EOF
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

  config.vm.network "private_network", ip: "#{host_ip}"

  config.vm.provision "shell", inline: configure_ssh_keys, keep_color: true, name: "configure_ssh_keys"
  config.vm.provision "shell", inline: configure_lab_env, keep_color: true, name: "configure_lab_env"
  config.vm.provision :shell do |s|
    s.path = 'install/launch.sh'
    s.name = 'launch_targets'
    s.privileged = false
    s.keep_color = true
    s.args = "default #{targets}"
    s.env = {
      "DIND_K8S_VERSION" => "#{k8s_version}",
      "NUM_NODES" => "#{nodes}",
      "DIND_HOST_IP" => "#{host_ip}",
      "IS_COUNTRY_CN" => "#{is_country_cn}",
      "https_proxy" => "#{https_proxy}"
    }
  end
end

#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
source $LAB_HOME/install/funcs.sh

ensure_command "docker" && exit
ensure_os Linux || exit

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-cache policy docker-ce
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# avoid adding sudo before docker cmd
sudo usermod -aG docker vagrant

# fix the issue `WARNING: No swap limit support`, need vagrant halt and up
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="cgroup_enable=memory swapaccount=1 /g' /etc/default/grub
sudo update-grub

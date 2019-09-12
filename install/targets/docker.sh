#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
source $LAB_HOME/install/funcs.sh

target::step "Start to install docker"
ensure_command "docker" && exit
ensure_os_linux || exit

curl -sSL https://get.docker.com/ | sh

if [[ $? == 0 ]]; then
  target::step "Per OS post installation"

  # avoid adding sudo before docker cmd
  sudo usermod -aG docker $USER

  lsb_dist=""
  if [ -r /etc/os-release ]; then
  	lsb_dist="$(. /etc/os-release && echo "$ID")"
  fi

  case "$lsb_dist" in
  ubuntu)
    # fix the issue `WARNING: No swap limit support`, need vagrant halt and up
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="cgroup_enable=memory swapaccount=1 /g' /etc/default/grub
    sudo update-grub
    ;;
  centos)
    sudo systemctl start docker
    if ! cat /etc/sysctl.conf | grep -q "# Fix bridge-nf-call-iptables disabled warning"; then
      cat << EOF | sudo tee -a /etc/sysctl.conf

# Fix bridge-nf-call-iptables disabled warning
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
      sudo sysctl -p
    fi
    sudo systemctl enable docker.service
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    ;;
  esac
fi

#!/bin/bash

# What we do here?
# - shellinabox: centos, ubuntu, macos?
# - bash completion: centos, ubuntu, macos
# - ca cert: centos, ubuntu, macos
# - .bashrc, env vars: centos, ubuntu, macos
# - lab cache: centos, ubuntu, macos

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

case "$(detect_os)" in
ubuntu)
  target::step "install basic tools"
  sudo apt-get install -y shellinabox bash-completion

  # path to bash completion
  bash_completion="/usr/share/bash-completion/bash_completion"

  target::step "add self-signed ca cert"
  sudo cp $INSTALL_HOME/certs/lab-ca.pem.crt /usr/local/share/ca-certificates/
  sudo update-ca-certificates
  ;;
centos)
  target::step "install basic tools"
  sudo yum install -y epel-release
  sudo yum install -y shellinabox bash-completion
  # https://github.com/shellinabox/shellinabox/issues/327
  sudo sed -i \
    's/^#\s*PasswordAuthentication yes$/PasswordAuthentication yes/g;
     s/^PasswordAuthentication no$/#PasswordAuthentication no/g' \
    /etc/ssh/sshd_config
  sudo service sshd restart
  sudo sed -i \
    's/OPTS="--disable-ssl-menu -s \/:LOGIN"/OPTS="--disable-ssl-menu -s \/:SSH"/g' \
    /etc/sysconfig/shellinaboxd
  sudo service shellinaboxd restart

  # path to bash completion
  bash_completion="/usr/share/bash-completion/bash_completion"

  target::step "add self-signed ca cert"
  sudo cp $INSTALL_HOME/certs/lab-ca.pem.crt /etc/pki/ca-trust/source/anchors/
  sudo update-ca-trust
  ;;
darwin)
  target::step "install basic tools"
  brew install shellinabox bash-completion

  # path to bash completion
  bash_completion="$(brew --prefix)/etc/bash_completion"

  target::step "add self-signed ca cert"
  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $INSTALL_HOME/certs/lab-ca.pem.crt
  ;;
esac

target::step "update .bashrc"
if [ ! -f ~/.bashrc ] || ! $(cat ~/.bashrc | grep -q "^# For playground$") ; then
  cat << EOF >> ~/.bashrc

# For playground
export LAB_HOME=$LAB_HOME
# Customize below env as needed
export HOST_IP=$HOST_IP
export K8S_VERSION=$K8S_VERSION
export NUM_NODES=$NUM_NODES

if [ -f $bash_completion ]; then
  . $bash_completion
fi

if [ -f $INSTALL_HOME/completion.sh ]; then
  . $INSTALL_HOME/completion.sh
fi
EOF
fi

target::step "update .bash_profile"
if [ ! -f ~/.bash_profile ] || ! $(cat ~/.bash_profile | grep -q "~/.bashrc") ; then
  cat << EOF >> ~/.bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
EOF
fi

target::step "create link to launch.sh"
sudo ln -sf $INSTALL_HOME/launch.sh /usr/bin/launch
sudo ln -sf $INSTALL_HOME/launch.sh /usr/sbin/launch

target::step "configure launch cache"
mkdir -p $INSTALL_HOME/.launch-cache
ln -sf $INSTALL_HOME/.launch-cache $HOME/.launch-cache

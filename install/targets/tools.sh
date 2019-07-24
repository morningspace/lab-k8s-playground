#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install
source $INSTALL_HOME/funcs.sh

ensure_box && is_in_box=1 || is_in_box=0

########################
# kubectl autocompletion
########################
echo "* start to install kubectl autocompletion..."
if cat ~/.bashrc | grep -q "^# kubectl autocompletion$"; then
  echo "* kubectl autocompletion detected"
else
  cat << EOF >>~/.bashrc

# kubectl autocompletion
source <(kubectl completion bash)
EOF
  echo "* kubectl autocompletion installed"
fi

########################
# kubectl aliases
########################
echo "* start to install kubectl aliases..."
if [[ ! -f ~/.lab-k8s-cache/.kubectl_aliases ]]; then
  curl -sLo ~/.lab-k8s-cache/.kubectl_aliases \
    https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases
fi
if cat ~/.bashrc | grep -q "^# kubectl aliases$"; then
  echo "* kubectl aliases detected"
else
  cat << EOF >>~/.bashrc

# kubectl aliases
source ~/.lab-k8s-cache/.kubectl_aliases
# function kubectl() { echo "+ kubectl \$@"; command kubectl \$@; }
EOF
  echo "* kubectl aliases installed"
fi

########################
# kubens
########################
echo "* start to install kubedns..."
if [[ ! -f ~/.lab-k8s-cache/kubens ]]; then
  curl -sLo ~/.lab-k8s-cache/kubens \
    https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens
fi
if ! ensure_command "kubens"; then
  sudo ln -sf ~/.lab-k8s-cache/kubens /usr/local/bin/kubens
  sudo chmod +x /usr/local/bin/kubens
  echo "* kubens installed"
fi

########################
# kube-shell
########################
if [[ $is_in_box == 1 ]]; then
  echo "* start to install kube-shell..."
  if [[ ! -f ~/.lab-k8s-cache/get-pip.py ]]; then
    curl -sLo ~/.lab-k8s-cache/get-pip.py https://bootstrap.pypa.io/get-pip.py
  fi
  if ! ensure_command "kube-shell"; then
    python3 ~/.lab-k8s-cache/get-pip.py --user
    $HOME/.local/bin/pip3 install kube-shell --user
    echo "* kube-shell installed"
  fi
fi

########################
# kubebox
########################
if [[ $is_in_box == 1 ]]; then
  echo "* start to install kubebox..."
  if [[ ! -f ~/.lab-k8s-cache/kubebox ]]; then
    curl -sLo ~/.lab-k8s-cache/kubebox \
      https://github.com/astefanutti/kubebox/releases/download/v0.5.0/kubebox-linux
  fi
  if ! ensure_command "kubebox"; then
    sudo ln -sf ~/.lab-k8s-cache/kubebox /usr/local/bin/kubebox
    sudo chmod +x /usr/local/bin/kubebox
    echo "* kubebox installed"
  fi
fi

########################
# kubetail
########################
echo "* start to install kubetail..."
if [[ ! -f ~/.lab-k8s-cache/kubetail ]]; then
  curl -sLo ~/.lab-k8s-cache/kubetail \
    https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail
fi
if ! ensure_command "kubetail"; then
  sudo ln -sf ~/.lab-k8s-cache/kubetail /usr/local/bin/kubetail
  sudo chmod +x /usr/local/bin/kubetail
  echo "* kubetail installed"
fi

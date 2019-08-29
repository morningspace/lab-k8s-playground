#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
source $LAB_HOME/install/funcs.sh

########################
# kubectl autocompletion
########################
target::step "start to install kubectl autocompletion"
if cat ~/.bashrc | grep -q "^# kubectl autocompletion$"; then
  target::log "kubectl autocompletion detected"
else
  cat << EOF >>~/.bashrc

# kubectl autocompletion
source <(kubectl completion bash)
EOF
  target::log "kubectl autocompletion installed"
fi

########################
# kubectl aliases
########################
target::step "start to install kubectl aliases"
if [[ ! -f ~/.lab-k8s-cache/.kubectl_aliases ]]; then
  curl -sLo ~/.lab-k8s-cache/.kubectl_aliases \
    https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases
fi
if cat ~/.bashrc | grep -q "^# kubectl aliases$"; then
  target::log "kubectl aliases detected"
else
  cat << EOF >>~/.bashrc

# kubectl aliases
source ~/.lab-k8s-cache/.kubectl_aliases
# function kubectl() { echo "+ kubectl \$@"; command kubectl \$@; }
EOF
  target::log "kubectl aliases installed"
fi

########################
# kubens
########################
target::step "start to install kubedns"
if [[ ! -f ~/.lab-k8s-cache/kubens ]]; then
  curl -sLo ~/.lab-k8s-cache/kubens \
    https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens
fi
if ! ensure_command "kubens"; then
  sudo ln -sf ~/.lab-k8s-cache/kubens /usr/local/bin/kubens
  sudo chmod +x /usr/local/bin/kubens
  target::log "kubens installed"
fi

########################
# kube-shell
########################
if ensure_os Linux; then
  target::step "start to install kube-shell"
  if [[ ! -f ~/.lab-k8s-cache/get-pip.py ]]; then
    curl -sLo ~/.lab-k8s-cache/get-pip.py https://bootstrap.pypa.io/get-pip.py
  fi
  if ! ensure_command "kube-shell"; then
    python3 ~/.lab-k8s-cache/get-pip.py --user
    $HOME/.local/bin/pip3 install kube-shell --user
    target::log "kube-shell installed"
  fi
fi

########################
# kubebox
########################
target::step "start to install kubebox"
os=$(uname -s)
case $os in
  "Linux") kubebox_cmd="kubebox-linux";;
  "Darwin") kubebox_cmd="kubebox-macos";;
esac
if [[ ! -f ~/.lab-k8s-cache/kubebox ]]; then
  curl -sLo ~/.lab-k8s-cache/kubebox \
    https://github.com/astefanutti/kubebox/releases/download/v0.5.0/$kubebox_cmd
fi
if ! ensure_command "kubebox"; then
  sudo ln -sf ~/.lab-k8s-cache/kubebox /usr/local/bin/kubebox
  sudo chmod +x /usr/local/bin/kubebox
  target::log "kubebox installed"
fi

########################
# kubetail
########################
target::step "start to install kubetail"
if [[ ! -f ~/.lab-k8s-cache/kubetail ]]; then
  curl -sLo ~/.lab-k8s-cache/kubetail \
    https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail
fi
if ! ensure_command "kubetail"; then
  sudo ln -sf ~/.lab-k8s-cache/kubetail /usr/local/bin/kubetail
  sudo chmod +x /usr/local/bin/kubetail
  target::log "kubetail installed"
fi

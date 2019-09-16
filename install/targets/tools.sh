#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
source $LAB_HOME/install/funcs.sh

########################
# kubectl autocompletion
########################
target::step "Start to install kubectl autocompletion"
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
target::step "Start to install kubectl aliases"
if [[ ! -f ~/.launch-cache/.kubectl_aliases ]]; then
  curl -sSLo ~/.launch-cache/.kubectl_aliases \
    https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases
fi
if cat ~/.bashrc | grep -q "^# kubectl aliases$"; then
  target::log "kubectl aliases detected"
else
  cat << EOF >>~/.bashrc

# kubectl aliases
source ~/.launch-cache/.kubectl_aliases
# function kubectl() { echo "+ kubectl \$@"; command kubectl \$@; }
EOF
  target::log "kubectl aliases installed"
fi

########################
# kubens
########################
target::step "Start to install kubens"
if [[ ! -f ~/.launch-cache/kubens ]]; then
  curl -sSLo ~/.launch-cache/kubens \
    https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens
  sudo chmod +x ~/.launch-cache/kubens
fi
if ! ensure_command "kubens"; then
  sudo ln -sf ~/.launch-cache/kubens /usr/bin/kubens
  sudo ln -sf ~/.launch-cache/kubens /usr/sbin/kubens
  target::log "kubens installed"
fi

########################
# kubectx
########################
target::step "Start to install kubectx"
if [[ ! -f ~/.launch-cache/kubectx ]]; then
  curl -sSLo ~/.launch-cache/kubectx \
    https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx
  sudo chmod +x ~/.launch-cache/kubectx
fi
if ! ensure_command "kubectx"; then
  sudo ln -sf ~/.launch-cache/kubectx /usr/bin/kubectx
  sudo ln -sf ~/.launch-cache/kubectx /usr/sbin/kubectx
  target::log "kubectx installed"
fi

########################
# kube-shell
########################
# if [ $(uname -s) == Linux ]; then
#   target::step "Start to install kube-shell"
#   if [[ ! -f ~/.launch-cache/get-pip.py ]]; then
#     curl -sSLo ~/.launch-cache/get-pip.py https://bootstrap.pypa.io/get-pip.py
#   fi
#   if ! ensure_command "kube-shell"; then
#     python3 ~/.launch-cache/get-pip.py --user
#     $HOME/.local/bin/pip3 install kube-shell --user
#     target::log "kube-shell installed"
#   fi
# fi

########################
# kubebox
########################
target::step "Start to install kubebox"
case $(uname -s) in
  "Linux") kubebox_cmd="kubebox-linux";;
  "Darwin") kubebox_cmd="kubebox-macos";;
esac
if [[ ! -f ~/.launch-cache/kubebox ]]; then
  curl -sSLo ~/.launch-cache/kubebox \
    https://github.com/astefanutti/kubebox/releases/download/v0.5.0/$kubebox_cmd
  sudo chmod +x ~/.launch-cache/kubebox
fi
if ! ensure_command "kubebox"; then
  sudo ln -sf ~/.launch-cache/kubebox /usr/bin/kubebox
  sudo ln -sf ~/.launch-cache/kubebox /usr/sbin/kubebox
  target::log "kubebox installed"
fi

########################
# kubetail
########################
target::step "Start to install kubetail"
if [[ ! -f ~/.launch-cache/kubetail ]]; then
  curl -sSLo ~/.launch-cache/kubetail \
    https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail
  sudo chmod +x ~/.launch-cache/kubetail
fi
if ! ensure_command "kubetail"; then
  sudo ln -sf ~/.launch-cache/kubetail /usr/bin/kubetail
  sudo ln -sf ~/.launch-cache/kubetail /usr/sbin/kubetail
  target::log "kubetail installed"
fi

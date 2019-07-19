#!/bin/bash

. /vagrant/install/funcs.sh

########################
# kubectl autocompletion
########################
if [[ ! -f /usr/share/bash-completion/bash_completion ]]; then
  sudo apt-get install -y bash-completion
fi
if cat ~/.bashrc | grep -q "^# kubectl autocompletion$"; then
  echo "* kubectl autocompletion detected"
else
  cat << EOF >>~/.bashrc

# kubectl autocompletion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
EOF
echo "* kubectl autocompletion installed"
fi

########################
# kubectl aliases
########################
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
if [[ ! -f ~/.lab-k8s-cache/kubens ]]; then
  curl -sLo ~/.lab-k8s-cache/kubens \
    https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens
fi
if ! check_command "kubens"; then
  sudo ln -sf ~/.lab-k8s-cache/kubens /usr/local/bin/kubens
  sudo chmod +x /usr/local/bin/kubens
  echo "* kubens installed"
fi

########################
# kube-shell
########################
if [[ ! -f ~/.lab-k8s-cache/get-pip.py ]]; then
  curl -sLo ~/.lab-k8s-cache/get-pip.py https://bootstrap.pypa.io/get-pip.py
  python3 get-pip.py --user
fi
if ! check_command "kube-shell"; then
  sudo pip install kube-shell
  echo "* kube-shell installed"
fi

########################
# kubebox
########################
if [[ ! -f ~/.lab-k8s-cache/kubebox ]]; then
  curl -sLo ~/.lab-k8s-cache/kubebox \
    https://github.com/astefanutti/kubebox/releases/download/v0.5.0/kubebox-linux
fi
if ! check_command "kubebox"; then
  sudo ln -sf ~/.lab-k8s-cache/kubebox /usr/local/bin/kubebox
  sudo chmod +x /usr/local/bin/kubebox
  echo "* kubebox installed"
fi

########################
# kubetail
########################
if [[ ! -f ~/.lab-k8s-cache/kubetail ]]; then
  curl -sLo ~/.lab-k8s-cache/kubetail \
    https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail
fi
if ! check_command "kubetail"; then
  sudo ln -sf ~/.lab-k8s-cache/kubetail /usr/local/bin/kubetail
  sudo chmod +x /usr/local/bin/kubetail
  echo "* kubetail installed"
fi

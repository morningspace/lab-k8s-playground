#!/bin/bash

# kubectl autocompletion
sudo apt-get install -y bash-completion
cat << EOF >>~/.bashrc

# kubectl autocompletion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
EOF

# kubectl aliases
curl -sL https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases -o ~/.kubectl_aliases
cat << 'EOF' >>~/.bashrc

# kubectl aliases
source ~/.kubectl_aliases
function kubectl() { echo "+ kubectl $@"; command kubectl $@; }
EOF

# kubectx and kubens
if [[ ! -d ~/.kubectx ]]; then
  git clone https://github.com/ahmetb/kubectx.git ~/.kubectx
fi
sudo ln -sf ~/.kubectx/kubens /usr/local/bin/kubens
sudo chmod +x /usr/local/bin/kubens

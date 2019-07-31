#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install

targets=(base default)
shells=($(ls -l $INSTALL_HOME/targets/*.sh | awk '{print $9}' | awk -F "/" '{print $NF}'))
targets+=(${shells[@]%.sh})

launch_completions() {
  local words=${targets[@]}
  local input=${COMP_WORDS[@]:(-1)}

  if [[ $input == *"::"* ]]; then
    local shell=${input%::*}
    if [[ ${shells[@]} =~ $shell ]]; then
      input=${input#*::}
      local pattern="^function $shell::\w\+ {$"
      local funcs=($(grep "$pattern" $INSTALL_HOME/targets/$shell.sh | awk '{print $2}'))
      words=(${funcs[@]#*::})
    fi
  fi

  COMPREPLY=($(compgen -W "$(echo ${words[@]})" "$input"))
}

complete -F launch_completions launch

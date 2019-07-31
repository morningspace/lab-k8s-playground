#!/bin/bash

LAB_HOME=${LAB_HOME:-/vagrant}
INSTALL_HOME=$LAB_HOME/install

targets=(base default)
shells=($(ls -l $INSTALL_HOME/targets/*.sh | awk '{print $9}' | awk -F "/" '{print $NF}'))
targets+=(${shells[@]%.sh})

launch_completions() {
  local words=${targets[@]}
  local input="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  
  if [[ $input == "::" ]]; then
    input="$prev::"
  elif [[ $prev == "::" ]]; then
    input="${COMP_WORDS[COMP_CWORD-2]}::$input"
  fi

  if [[ $input == *"::"* ]]; then
    local shell=${input%::*}
    if [[ ${shells[@]} =~ $shell ]]; then
      input=${input#*::}
      local pattern="^function $shell::\w\+ {$"
      local file="$INSTALL_HOME/targets/$shell.sh"
      if [[ -f $file ]]; then
        local funcs=($(grep "$pattern" $file | awk '{print $2}'))
        words=(${funcs[@]#*::})
      else
        words=()
      fi
    fi
  fi

  COMPREPLY=($(compgen -W "$(echo ${words[@]})" "$input"))
}

complete -F launch_completions launch

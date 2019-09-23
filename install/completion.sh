#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
INSTALL_HOME=$LAB_HOME/install

K8S_PROVIDER=${K8S_PROVIDER:-dind}

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
    words=()
    local shell=${input%::*}
    if [[ ${shells[@]} =~ $shell ]]; then
      input=${input#*::}
      local pattern="^function $shell::\S\+ {$"
      local file="$INSTALL_HOME/targets/$shell.sh"
      if [[ -f $file ]]; then
        local delegate_shell=$(grep "^target::delegate" $file | awk '{print $2}')
        if [[ ! -z $delegate_shell ]]; then
          shell=$(eval "echo $delegate_shell")
          file="$INSTALL_HOME/targets/$shell"
        fi
      fi

      if [[ -f $file ]]; then
        local embedded_shells=($(grep "\. " $file | awk '{print $2}'))
        for embedded_shell in ${embedded_shells[@]}; do
          embedded_file=$(eval "echo $embedded_shell")
          if [[ -f $embedded_file ]]; then
            local funcs=($(grep "$pattern" $embedded_file | awk '{print $2}'))
            words+=(${funcs[@]#*::})
          fi
        done

        local funcs=($(grep "$pattern" $file | awk '{print $2}'))
        words+=(${funcs[@]#*::})
      fi
    fi
  fi

  COMPREPLY=($(compgen -W "$(echo ${words[@]})" "$input"))
}

complete -F launch_completions launch

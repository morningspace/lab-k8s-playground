#!/bin/bash

# Sample target

# Load funcs.sh for helper functions
LAB_HOME=${LAB_HOME:-/vagrant}
source $LAB_HOME/install/funcs.sh

# The first command function
# Define as the default command function
# Call by running `launch sample`, or `launch sample::noop`
function sample::noop {
  echo "noop"
}

# Other command functions
# Call by running `launch sample::sayHello`
function sample::hello {
  sayHello $USER
}

# Normal functions
# Invisible to launch utility
function sayHello {
  echo "Hello $1!"
}

target::command $@

#!/bin/bash

setterm -linewrap off
$HOME/workspace/util/net/nic.sh
export PATH=$HOME/.local/bin:$PATH
alias t='sudo $HOME/workspace/util/nas/temp.sh'
alias n='$HOME/workspace/util/net/nic.sh'

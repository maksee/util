#!/bin/bash

$HOME/workspace/util/net/nic.sh
export PATH=$HOME/.local/bin:$PATH
export EDITOR=vim
alias t='sudo $HOME/workspace/util/nas/temp.sh'
alias n='$HOME/workspace/util/net/nic.sh'
if [ -e /usr/bin/virsh ]
then
	virsh list --all
fi

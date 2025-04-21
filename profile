#!/bin/bash

BASE_DIR=$HOME/dev
$BASE_DIR/util/net/nic.sh
$BASE_DIR/util/nas/temp.sh
export PATH=$HOME/.local/bin:$PATH
export EDITOR=vim
alias t='sudo $BASE_DIR/util/nas/temp.sh'
alias n='$BASE_DIR/util/net/nic.sh'
if [ -e /usr/bin/virsh ]
then
	virsh list --all
fi
